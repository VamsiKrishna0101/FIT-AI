import 'dart:async';
import '../../progress/repositories/progress_repository.dart';
import '../../history/repositories/history_repository.dart';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../today/repositories/today_repository.dart';
import '../models/training_session.dart';
import 'workout_repository.dart';

class TrainingRepository {
  TrainingRepository._();
  static final shared = TrainingRepository._();
  final changes = StreamController<TrainingDay>.broadcast();
  final _requests = <String, Future<TrainingDay>>{};
  final _memory = <String, TrainingDay>{};
  final _mutations = <String, Future<void>>{};
  final _revision = <String, int>{};
  final _historyRequests = <String, Future<List<Map<String, dynamic>>>>{};
  static const base = '/api/workout/training';

  Future<String> _key(String date) => CacheScope.userKey(
      'training_v2_${LanguageManager.shared.currentLanguage.code}_$date');
  Future<TrainingDay?> cached(String date) async {
    final key = await _key(date);
    final json = await LocalCache.shared.getJson(key);
    return _memory[key] ?? (json == null ? null : TrainingDay(json));
  }

  String path(String suffix, String date) =>
      '$base$suffix?date=$date&utcOffsetMinutes=${DateTime.now().timeZoneOffset.inMinutes}';

  Future<TrainingDay> load(String date, {bool refresh = false}) async {
    final key = await _key(date);
    if (!refresh && _requests.containsKey(key)) return _requests[key]!;
    final future = _fetch(date, key);
    _requests[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_requests[key], future)) _requests.remove(key);
    }
  }

  Future<TrainingDay> _fetch(String date, String key) async {
    final revision = _revision[key] ?? 0;
    final token = await SecureSessionStore.shared.accessToken;
    final response = await ApiClient.shared.client.get(path('', date),
        options: Options(extra: {'sessionOwnerToken': token}));
    if (revision != (_revision[key] ?? 0)) {
      await _mutations[key];
      if (key != await _key(date)) throw StateError('Session changed');
      if (_memory[key] != null) return _memory[key]!;
      throw StateError('Workout changed. Retry the sync.');
    }
    return _accept(date, key, response.data['data']);
  }

  Future<TrainingDay> _accept(String date, String key, dynamic json) async {
    if (key != await _key(date)) throw StateError('Session changed');
    final day = TrainingDay(Map<String, dynamic>.from(json as Map));
    _memory[key] = day;
    await LocalCache.shared.saveJson(key, day.json);
    changes.add(day);
    return day;
  }

  Future<TrainingDay> mutate(String date, String method, String suffix,
      {Map<String, dynamic>? data}) async {
    final key = await _key(date);
    final token = await SecureSessionStore.shared.accessToken;
    final previous = _mutations[key] ?? Future<void>.value();
    final future = previous.then((_) async {
      if (key != await _key(date)) throw StateError('Session changed');
      _revision[key] = (_revision[key] ?? 0) + 1;
      final response = await ApiClient.shared.client.request(path(suffix, date),
          data: data,
          options:
              Options(method: method, extra: {'sessionOwnerToken': token}));
      final day = await _accept(date, key, response.data['data']);
      await ProgressRepository.shared.invalidate();
      await HistoryRepository.shared.invalidate();
      unawaited(
          WorkoutRepository.shared.getTodayWorkoutPlan(forceRefresh: true));
      unawaited(TodayRepository.shared.fetchFresh(forceRefresh: true));
      return day;
    });
    _mutations[key] =
        future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return future;
  }

  Future<Map<String, dynamic>> previous(String date, String exerciseId) async {
    final key =
        await CacheScope.userKey('training_previous_${exerciseId}_$date');
    final cached = await LocalCache.shared.getJson(key);
    if (cached != null) return cached;
    final token = await SecureSessionStore.shared.accessToken;
    final response = await ApiClient.shared.client.get(
        path('/previous/$exerciseId', date),
        options: Options(extra: {'sessionOwnerToken': token}));
    if (!SecureSessionStore.shared
        .sameOwner(token, await SecureSessionStore.shared.accessToken)) {
      throw StateError('Session changed');
    }
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    await LocalCache.shared.saveJson(key, data);
    return data;
  }

  Future<void> setRest(String date, int seconds) async {
    final key = await CacheScope.userKey('training_rest_$date');
    await LocalCache.shared.saveJson(key, {
      'end':
          DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch
    });
  }

  Future<DateTime?> restEnds(String date) async {
    final value = await LocalCache.shared
        .getJson(await CacheScope.userKey('training_rest_$date'));
    return value?['end'] is num
        ? DateTime.fromMillisecondsSinceEpoch((value!['end'] as num).toInt())
        : null;
  }

  Future<List<Map<String, dynamic>>> volumeHistory(
      {bool refresh = false}) async {
    final key = await CacheScope.userKey('training_volume_6');
    if (!refresh) {
      final entry = await LocalCache.shared.getEntry(key);
      if (entry != null && entry.$2 < const Duration(minutes: 5)) {
        return (entry.$1 as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      }
    }
    final pending = _historyRequests[key];
    if (pending != null) return pending;
    final future = _fetchVolume(key);
    _historyRequests[key] = future;
    try {
      return await future;
    } finally {
      _historyRequests.remove(key);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVolume(String key) async {
    final token = await SecureSessionStore.shared.accessToken;
    final response = await ApiClient.shared.client.get('/api/history/volume',
        queryParameters: {'weeks': 6},
        options: Options(extra: {'sessionOwnerToken': token}));
    if (!SecureSessionStore.shared
        .sameOwner(token, await SecureSessionStore.shared.accessToken)) {
      throw StateError('Session changed');
    }
    final data = (response.data['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    await LocalCache.shared.saveEntry(key, data);
    return data;
  }
}
