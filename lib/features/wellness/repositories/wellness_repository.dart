import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../today/repositories/today_repository.dart';
import '../../history/repositories/history_repository.dart';
import '../../../core/health/phone_sleep_service.dart';

class WellnessRepository {
  static final shared = WellnessRepository();
  Future<String> wearableUsage() async {
    final owner = await CacheScope.userId();
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/wellness/wearable');
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    final usage =
        (response.data?['data'] as Map?)?['usage'] as String? ?? 'UNKNOWN';
    await PhoneSleepService.shared.setUsage(usage, expectedOwner: owner);
    return usage;
  }

  Future<void> setWearableUsage(String usage) async {
    final owner = await CacheScope.userId();
    await ApiClient.shared.put<Map<String, dynamic>>('/api/wellness/wearable',
        data: {'usage': usage});
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    await PhoneSleepService.shared.setUsage(usage, expectedOwner: owner);
    TodayRepository.shared.invalidate();
    unawaited(Future.wait([
      ProgressRepository.shared.invalidate(),
      HistoryRepository.shared.invalidate(),
    ]).then<void>((_) {}, onError: (Object _, StackTrace __) {}));
  }

  Future<Map<String, dynamic>?> load(String date) async {
    final key = await CacheScope.userKey('wellness_v2_$date');
    try {
      final response = await ApiClient.shared
          .get<Map<String, dynamic>>('/api/wellness/check-in/$date');
      final entry = (response.data?['data'] as Map?)?.cast<String, dynamic>();
      if (key == await CacheScope.userKey('wellness_v2_$date')) {
        await LocalCache.shared.saveJson(key, {'entry': entry});
        return entry;
      }
      return null;
    } catch (_) {
      return ((await LocalCache.shared.getJson(key))?['entry'] as Map?)
          ?.cast<String, dynamic>();
    }
  }

  Future<void> save(String date, int minutes, int? energy,
      {int? rested, int? soreness, PhoneSleepEstimate? estimate}) async {
    final owner = await CacheScope.userId();
    final key = await CacheScope.userKey('wellness_v2_$date');
    if (!key.startsWith('${CacheScope.userPrefix}${owner}_')) {
      throw StateError('Session changed');
    }
    final response = await ApiClient.shared
        .put<Map<String, dynamic>>('/api/wellness/check-in/$date', data: {
      'sleepMinutes': minutes,
      'energy': energy,
      'rested': rested,
      'soreness': soreness,
      'source': estimate == null ? 'self_report' : 'phone_estimate_confirmed',
      'sleepStartedAt': estimate?.start.toUtc().toIso8601String(),
      'sleepEndedAt': estimate?.end.toUtc().toIso8601String(),
      'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    });
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    TodayRepository.shared.invalidate();
    // A committed save must not wait for disk cache cleanup to finish.
    unawaited(Future.wait([
      LocalCache.shared.saveJson(key, {'entry': response.data?['data']}),
      ProgressRepository.shared.invalidate(),
      HistoryRepository.shared.invalidate(),
    ]).then<void>((_) {}, onError: (Object _, StackTrace __) {}));
  }
}
