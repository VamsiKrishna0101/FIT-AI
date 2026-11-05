import '../../train/repositories/training_repository.dart';
import '../../train/repositories/workout_repository.dart';
import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/storage/session_sign_out.dart';
import '../../today/repositories/today_repository.dart';
import '../../notifications/services/notification_service.dart';
import '../services/settings_device.dart';
import 'package:dio/dio.dart';

class SettingsRepository {
  String? _owner;

  Future<Map<String, dynamic>> profile() async {
    final owner = await CacheScope.userId();
    final data =
        await UserDataCache.shared.load('profile', 'onboarding', () async {
      final response = await ApiClient.shared
          .get<Map<String, dynamic>>(Endpoints.onboarding);
      final data = response.data?['data'];
      if (data is! Map) throw StateError('Your profile could not be loaded.');
      return Map<String, dynamic>.from(data);
    });
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed. Reopen Settings.');
    }
    _owner = owner;
    return data;
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
    await UserDataCache.shared.invalidate('profile');
    await UserDataCache.shared.invalidate('training_map');
    await WorkoutRepository.shared.invalidateExerciseMedia();
    await UserDataCache.shared.invalidate('body');
    TodayRepository.shared.invalidate();
    unawaited(TodayRepository.shared
        .fetchFresh(forceRefresh: true)
        .catchError((Object _) => null));
  }

  Future<Map<String, dynamic>> exportData() async {
    final owner = await CacheScope.userId();
    final token = await SecureSessionStore.shared.accessToken;
    if (token == null) throw StateError('Sign in to export your data.');
    final response = await ApiClient.shared.client.get<Map<String, dynamic>>(
        Endpoints.privacyExport,
        options: Options(extra: {'sessionOwnerToken': token}));
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed.');
    }
    return response.data!;
  }

  Future<void> deleteAccount({required String expectedOwner}) async {
    final token = await SecureSessionStore.shared.accessToken;
    if (token == null) throw StateError('Sign in to delete your account.');
    if (await CacheScope.userId() != expectedOwner) {
      throw StateError('Your session changed.');
    }
    await ApiClient.shared.client.delete(Endpoints.deleteAccount,
        options: Options(extra: {'sessionOwnerToken': token}));
    if (await CacheScope.userId() != expectedOwner) {
      throw StateError('Your session changed.');
    }
    await TrainingRepository.shared.discardPending(expectedOwner);
    await signOut();
  }

  Future<void> signOut() => completeSessionSignOut(
        detachNotifications: NotificationService.shared.detach,
        clearSession: () async {
          await SecureSessionStore.shared.clear();
          TodayRepository.shared.invalidate();
        },
        cleanup: [
          SettingsDevice.clearExports,
          TodayRepository.shared.clearUserCaches,
          OnboardingDraft.clear,
        ],
      );
}
