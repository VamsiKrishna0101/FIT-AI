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
    final key = await CacheScope.userKey('wearable_usage_v1');
    String? usage;
    try {
      final response = await ApiClient.shared
          .get<Map<String, dynamic>>('/api/wellness/wearable');
      usage = (response.data?['data'] as Map?)?['usage'] as String?;
      if (!['UNKNOWN', 'WEARABLE', 'NONE'].contains(usage)) {
        throw const FormatException('Invalid wearable preference response');
      }
    } catch (_) {
      usage = (await LocalCache.shared.getJson(key))?['usage'] as String?;
      if (!['UNKNOWN', 'WEARABLE', 'NONE'].contains(usage)) rethrow;
    }
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    unawaited(LocalCache.shared
        .saveJson(key, {'usage': usage}).catchError((Object _) {}));
    await _syncPhoneUsage(usage!, owner);
    return usage;
  }

  Future<void> setWearableUsage(String usage) async {
    final owner = await CacheScope.userId();
    final response = await ApiClient.shared.put<Map<String, dynamic>>(
        '/api/wellness/wearable',
        data: {'usage': usage});
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    if ((response.data?['data'] as Map?)?['usage'] != usage) {
      throw StateError('The server did not confirm your wearable preference.');
    }
    final key = await CacheScope.userKey('wearable_usage_v1');
    unawaited(LocalCache.shared
        .saveJson(key, {'usage': usage}).catchError((Object _) {}));
    await _syncPhoneUsage(usage, owner);
    await TodayRepository.shared.applyWearableUsage(usage, owner: owner);
    unawaited(Future.wait([
      ProgressRepository.shared.invalidate(),
      HistoryRepository.shared.invalidate(),
    ]).then<void>((_) {}, onError: (Object _, StackTrace __) {}));
  }

  Future<void> _syncPhoneUsage(String usage, String owner) async {
    try {
      await PhoneSleepService.shared.setUsage(usage, expectedOwner: owner);
    } catch (_) {
      // A native sensor failure does not undo the saved account preference.
      if (owner != await CacheScope.userId()) {
        throw StateError('Session changed');
      }
    }
  }

  Future<Map<String, dynamic>?> load(String date) async {
    final owner = await CacheScope.userId();
    final key = await CacheScope.userKey('wellness_v2_$date');
    try {
      final response = await ApiClient.shared
          .get<Map<String, dynamic>>('/api/wellness/check-in/$date');
      final entry = (response.data?['data'] as Map?)?.cast<String, dynamic>();
      if (owner == await CacheScope.userId() &&
          key == await CacheScope.userKey('wellness_v2_$date')) {
        await LocalCache.shared.saveJson(key, {'entry': entry});
        return owner == await CacheScope.userId() ? entry : null;
      }
      return null;
    } catch (_) {
      final cached = ((await LocalCache.shared.getJson(key))?['entry'] as Map?)
          ?.cast<String, dynamic>();
      return owner == await CacheScope.userId() ? cached : null;
    }
  }

  Future<Map<String, dynamic>> save(String date, int minutes, int? energy,
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
    final entry = (response.data?['data'] as Map?)?.cast<String, dynamic>();
    if (entry == null ||
        entry['date'] != date ||
        entry['sleepMinutes'] != minutes ||
        entry['energy'] != energy ||
        entry['rested'] != rested ||
        entry['soreness'] != soreness ||
        entry['source'] !=
            (estimate == null ? 'self_report' : 'phone_estimate_confirmed') ||
        DateTime.tryParse(entry['updatedAt']?.toString() ?? '') == null) {
      throw StateError(
          'The server did not confirm this sleep entry. Try again.');
    }
    await TodayRepository.shared.applyConfirmedSleep(entry, owner: owner);
    // A committed save must not wait for disk cache cleanup to finish.
    unawaited(Future.wait([
      LocalCache.shared.saveJson(key, {'entry': entry}),
      ProgressRepository.shared.invalidate(),
      HistoryRepository.shared.invalidate(),
    ]).then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    return entry;
  }
}
