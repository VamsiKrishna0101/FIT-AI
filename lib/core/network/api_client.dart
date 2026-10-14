import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../localization/language_manager.dart';
import '../storage/secure_session_store.dart';
import 'endpoints.dart';
import '../cache/app_data_mode.dart';

// MARK: - Production Async Dio API Client
class ApiClient {
  static final subscriptionRequired = ValueNotifier<int>(0);
  static final ApiClient shared = ApiClient._();
  late final Dio _dio;
  Future<bool>? _renewing;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Auto JWT Bearer Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] =
              LanguageManager.shared.currentLanguage.code;
          final token = await SecureSessionStore.shared.accessToken;
          await AppDataMode.shared.ensureOwner();
          if (AppDataMode.scopedPath(options.path)) {
            options.extra.putIfAbsent(
                'datasetRevision', () => AppDataMode.shared.revision);
            options.extra.putIfAbsent('dataOwnerToken', () => token);
          }
          final original = options.extra['sessionOwnerToken'];
          if (original is String &&
              !SecureSessionStore.shared.sameOwner(original, token)) {
            return handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: 'Session changed'));
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          final extra = response.requestOptions.extra;
          if (extra.containsKey('datasetRevision') &&
              (extra['datasetRevision'] != AppDataMode.shared.revision ||
                  !SecureSessionStore.shared.sameOwner(
                      extra['dataOwnerToken'] as String?,
                      await SecureSessionStore.shared.accessToken))) {
            return handler.reject(DioException(
                requestOptions: response.requestOptions,
                type: DioExceptionType.cancel,
                message: 'Account or dataset changed'));
          }
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 402 &&
              error.response?.data is Map &&
              error.response?.data['code'] == 'SUBSCRIPTION_REQUIRED') {
            subscriptionRequired.value++;
          }
          final request = error.requestOptions;
          final header = request.headers['Authorization'];
          if (error.response?.statusCode == 401 &&
              request.path != Endpoints.refreshToken &&
              request.extra['sessionRetried'] != true &&
              header is String &&
              header.startsWith('Bearer ')) {
            final oldToken = header.substring(7);
            try {
              if (await _renewSession(oldToken)) {
                request.extra['sessionRetried'] = true;
                request.extra['sessionOwnerToken'] = oldToken;
                request.headers['Authorization'] =
                    'Bearer ${await SecureSessionStore.shared.accessToken}';
                return handler.resolve(await _dio.fetch<dynamic>(request));
              }
            } catch (_) {
              /* Keep the original error; do not retry mutations again. */
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _renewSession(String expiredToken) async {
    final store = SecureSessionStore.shared;
    final current = await store.accessToken;
    if (current != expiredToken) {
      // Another concurrent renewal may already have replaced the access token.
      return store.sameOwner(current, expiredToken);
    }
    final existing = _renewing;
    if (existing != null) return existing;
    final refresh = await store.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    // Re-check after the async storage read so parallel failures share one call.
    if (_renewing != null) return _renewing!;
    final renewal = _requestRenewal(expiredToken, refresh);
    _renewing = renewal;
    try {
      return await renewal;
    } finally {
      if (identical(_renewing, renewal)) _renewing = null;
    }
  }

  Future<bool> _requestRenewal(String oldToken, String refresh) async {
    final store = SecureSessionStore.shared;
    if (await store.accessToken != oldToken) return false;
    final client = Dio(BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        }));
    // Use the same transport (including test adapters), without bearer/retry interceptors.
    client.httpClientAdapter = _dio.httpClientAdapter;
    final response = await client.post<Map<String, dynamic>>(
        Endpoints.refreshToken,
        data: {'refreshToken': refresh});
    final tokens = response.data?['tokens'];
    if (tokens is! Map ||
        tokens['accessToken'] is! String ||
        tokens['refreshToken'] is! String ||
        (tokens['accessToken'] as String).isEmpty ||
        (tokens['refreshToken'] as String).isEmpty) {
      return false;
    }
    return store.saveRefreshedTokens(
        expectedAccessToken: oldToken,
        expectedRefreshToken: refresh,
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String);
  }

  Dio get client => _dio;

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) async {
    return _dio.delete<T>(path);
  }
}
