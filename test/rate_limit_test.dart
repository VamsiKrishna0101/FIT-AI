import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';

class _LimitAdapter implements HttpClientAdapter {
  int calls = 0;
  int status = 429;
  dynamic body = {'code': 'RATE_LIMITED', 'retryAfterSeconds': 42};

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
      'retry-after': ['42'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _LimitAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'unchanged-access', refreshToken: 'unchanged-refresh');
    await LanguageManager.shared.restoreAccountLanguage('en');
    adapter = _LimitAdapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  Future<DioException> save() async {
    try {
      await ApiClient.shared.post('/api/wellness/check-in/2026-10-15');
      fail('A limited save cannot succeed.');
    } on DioException catch (error) {
      return error;
    }
  }

  test('429 explains the wait without retrying a save or refreshing tokens',
      () async {
    final error = await save();
    expect(error.response?.statusCode, 429);
    expect(error.message, 'Please try again in 42 seconds.');
    expect(error.response?.data['error'], error.message);
    expect(error.response?.data['code'], 'RATE_LIMITED');
    expect(error.response?.data['retryAfterSeconds'], 42);
    expect(adapter.calls, 1);
    expect(await SecureSessionStore.shared.accessToken, 'unchanged-access');
    expect(await SecureSessionStore.shared.refreshToken, 'unchanged-refresh');
  });

  test('503 limiter outage is localized and preserves the rejected request',
      () async {
    await LanguageManager.shared.restoreAccountLanguage('de-CH');
    adapter.status = 503;
    adapter.body = {'code': 'RATE_LIMIT_UNAVAILABLE', 'retryAfterSeconds': 30};
    final error = await save();
    expect(error.response?.statusCode, 503);
    expect(error.message,
        'Der Dienst ist vorübergehend ausgelastet. Bitte versuche es in 30 Sekunden erneut.');
    expect(adapter.calls, 1);
    expect(await SecureSessionStore.shared.refreshToken, 'unchanged-refresh');
  });

  test('non-JSON gateway rate limit uses Retry-After', () async {
    adapter.body = 'Too many requests';
    final error = await save();
    expect(error.message, 'Please try again in 42 seconds.');
    expect(adapter.calls, 1);
  });

  test('other 503 errors keep their original meaning', () async {
    adapter.status = 503;
    adapter.body = {
      'error': 'Health provider unavailable',
      'code': 'PROVIDER_DOWN'
    };
    final error = await save();
    expect(error.response?.data['error'], 'Health provider unavailable');
    expect(adapter.calls, 1);
  });
}
