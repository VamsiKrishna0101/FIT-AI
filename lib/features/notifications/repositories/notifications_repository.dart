import 'package:dio/dio.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';

class NotificationsRepository {
  String? _ownerToken;
  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, dynamic>? data, String? ownerToken]) async {
    final store = SecureSessionStore.shared;
    final token = ownerToken ?? await store.accessToken;
    if (token == null) throw StateError('Sign in to manage notifications.');

    final response =
        await ApiClient.shared.client.request<Map<String, dynamic>>(
      '/api/notifications/$path',
      data: data,
      options: Options(method: method, extra: {'sessionOwnerToken': token}),
    );
    if (!store.sameOwner(token, await store.accessToken)) {
      throw StateError('Your account changed. Reopen notifications.');
    }
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> preferences() async {
    final token = await SecureSessionStore.shared.accessToken;
    final data = await UserDataCache.shared.load('notifications', 'preferences',
        () async {
      final response = await request('GET', 'preferences', null, token);
      return Map<String, dynamic>.from(response['data'] as Map);
    }, ttl: const Duration(seconds: 30));
    _ownerToken = token;
    return data;
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> changes,
      {String? ownerToken}) async {
    final response = await request(
        'PATCH', 'preferences', changes, ownerToken ?? _ownerToken);
    await UserDataCache.shared.invalidate('notifications');
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<void> register(Map<String, dynamic> device,
      {String? ownerToken}) async {
    await request('PUT', 'device', device, ownerToken);
  }

  Future<void> remove(String installation) async {
    await request('DELETE', 'device/$installation', null, _ownerToken);
  }

  Future<void> snooze(String id, String installation) async {
    await request('POST', '$id/snooze', {'installationId': installation});
  }

  Future<void> opened(String id) async {
    await request('POST', '$id/opened');
  }

  Future<void> test(String installation) async {
    await request(
        'POST', 'test', {'installationId': installation}, _ownerToken);
  }
}
