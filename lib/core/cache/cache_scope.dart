import '../storage/local_cache.dart';
import '../storage/secure_session_store.dart';
import 'app_data_mode.dart';

// MARK: - Cache Scope
// Every user-data cache key is scoped by signed-in user AND calendar day so a
// re-login never shows another account's data and yesterday's plan never
// appears as today's.
class CacheScope {
  CacheScope._();

  static const String userPrefix = 'fitai_u_';

  static Future<String> userId() async =>
      await SecureSessionStore.shared.userId ?? 'anonymous';

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// e.g. `fitai_u_<uid>_plan_2026-10-03`
  static Future<String> userDayKey(String bucket) async =>
      userKey('${bucket}_${todayKey()}');

  /// e.g. `fitai_u_<uid>_history_recovery_30`
  static Future<String> userKey(String bucket) async {
    await AppDataMode.shared.ensureOwner();
    return '$userPrefix${await userId()}_${bucket}_${AppDataMode.shared.dataset}';
  }

  /// Wipe every user-scoped cache entry (call on sign-out / account switch).
  static Future<void> clearAllUserData() =>
      LocalCache.shared.removeByPrefix(userPrefix);
}
