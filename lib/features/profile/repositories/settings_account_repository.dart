import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';

/// Binds all reads and writes to the account that opened this settings page.
class SettingsAccountRepository {
  String? _ownerToken;
  Future<void> open() async {
    final token = await SecureSessionStore.shared.accessToken;
    if (token == null) throw StateError('Sign in to manage your account.');
    if (_ownerToken != null &&
        !SecureSessionStore.shared.sameOwner(_ownerToken, token)) {
      throw StateError('Your account changed. Reopen Settings.');
    }
    _ownerToken ??= token;
  }

  Future<dynamic> request(String method, String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? query,
      bool bytes = false}) async {
    await open();
    final token = _ownerToken!;
    final response = await ApiClient.shared.client.request<dynamic>(path,
        data: data,
        queryParameters: query,
        options: Options(
            method: method,
            responseType: bytes ? ResponseType.bytes : ResponseType.json,
            extra: {'sessionOwnerToken': token}));
    if (!SecureSessionStore.shared
        .sameOwner(token, await SecureSessionStore.shared.accessToken)) {
      throw StateError('Your account changed. Reopen Settings.');
    }
    return bytes ? response.data : response.data?['data'] ?? response.data;
  }
}

String accountSettingsError(Object error) {
  if (error is StateError) return error.message.toString();
  final data = error is DioException ? error.response?.data : null;
  return data is Map && data['error'] is String
      ? data['error'] as String
      : 'Could not connect. Please try again.';
}
