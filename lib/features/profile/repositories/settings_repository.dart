import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../today/repositories/today_repository.dart';

class SettingsRepository {
  String? _owner;

  Future<Map<String, dynamic>> profile() async {
    final owner = await CacheScope.userId();
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>(Endpoints.onboarding);
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed. Reopen Settings.');
    }
    _owner = owner;
    final data = response.data?['data'];
    if (data is! Map) throw StateError('Your profile could not be loaded.');
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveProfile(Map<String, dynamic> changes) async {
    final owner = _owner;
    if (_owner == null || await CacheScope.userId() != _owner) {
      throw StateError('Your session changed. Reopen Settings.');
    }
    await ApiClient.shared.patch(Endpoints.onboarding, data: changes);
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed. Reopen Settings.');
    }
    TodayRepository.shared.invalidate();
    unawaited(TodayRepository.shared
        .fetchFresh(forceRefresh: true)
        .catchError((Object _) => null));
  }

  Future<Map<String, dynamic>> exportData() async {
    final owner = await CacheScope.userId();
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>(Endpoints.privacyExport);
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed.');
    }
    return response.data!;
  }

  Future<void> deleteAccount({required String expectedOwner}) async {
    if (await CacheScope.userId() != expectedOwner) {
      throw StateError('Your session changed.');
    }
    await ApiClient.shared.delete(Endpoints.deleteAccount);
    if (await CacheScope.userId() != expectedOwner) {
      throw StateError('Your session changed.');
    }
    await signOut();
  }

  Future<void> signOut() async {
    await SecureSessionStore.shared.clear();
    TodayRepository.shared.invalidate();
    await TodayRepository.shared.clearUserCaches();
    await OnboardingDraft.clear();
  }
}
