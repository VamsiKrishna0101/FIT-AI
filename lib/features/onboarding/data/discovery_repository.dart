import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/storage/local_cache.dart';

class DiscoveryPreparation {
  final String owner;
  final bool show;
  const DiscoveryPreparation(this.owner, {required this.show});
}

class DiscoveryRepository {
  const DiscoveryRepository();
  Future<String?> owner() => SecureSessionStore.shared.userId;

  Future<DiscoveryPreparation> prepareAccountEntry() async {
    final user = await owner();
    if (user == null) throw StateError('Session changed');
    bool show = false;
    try {
      final local =
          await LocalCache.shared.getString('discovery-completed-$user') == '1';
      show = !(local || await completed(user));
    } catch (_) {
      // An optional survey never obstructs membership access.
    }
    if (await owner() != user) throw StateError('Session changed');
    return DiscoveryPreparation(user, show: show);
  }

  Future<bool> completed(String user) async {
    if (await owner() != user) throw StateError('Session changed');
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/onboarding/discovery');
    if (await owner() != user) throw StateError('Session changed');
    return response.data?['data']?['completed'] == true;
  }

  Future<void> save(String user, String? source) async {
    if (await owner() != user) throw StateError('Session changed');
    await ApiClient.shared
        .post('/api/onboarding/discovery', data: {'source': source});
    if (await owner() != user) throw StateError('Session changed');
  }
}
