import 'dart:async';
import '../../progress/repositories/progress_repository.dart';
import '../../../core/cache/user_data_cache.dart';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../today/repositories/today_repository.dart';
import '../models/training_session.dart';
import 'workout_repository.dart';
import 'workout_offline_store.dart';

class TrainingRepository {
  TrainingRepository._();
  static final shared = TrainingRepository._();
  final changes = StreamController<TrainingDay>.broadcast();
  final _requests = <String, Future<TrainingDay>>{};
  final _memory = <String, TrainingDay>{};
  final _mutations = <String, Future<void>>{};
  final _revision = <String, int>{};
  Timer? _refreshTimer;
  final _offline = WorkoutOfflineStore();
  final _queueWrites = <String, Future<void>>{};
  final _retryAfter = <String, DateTime>{};

  Future<T> _queueLock<T>(String owner, Future<T> Function() action) {
    final result =
        (_queueWrites[owner] ?? Future<void>.value()).then((_) => action());
    final tail =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _queueWrites[owner] = tail;
    return result.whenComplete(() {
      if (identical(_queueWrites[owner], tail)) _queueWrites.remove(owner);
    });
  }

  Future<TrainingDay?> _pending(String date) async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return null;
    final days = await _offline.read(owner);
    if (owner != await SecureSessionStore.shared.userId) return null;
    final pending = days[date] as Map?;
    if (pending == null) return null;
    return _offline.project(Map<String, dynamic>.from(pending['day'] as Map),
        pending['actions'] as List,
        blocked: pending['blocked'] == true);
  }

  Future<void> discardPending(String owner) =>
      _queueLock(owner, () => _offline.clear(owner));

  Future<void> syncPending({bool retry = false}) async {
    final owner = await SecureSessionStore.shared.userId;
    final token = await SecureSessionStore.shared.accessToken;
    if (owner == null || token == null) return;
    final days = await _offline.read(owner);
    for (final date in days.keys) {
      final cacheKey = await _key(date);
      final previous = _mutations[cacheKey] ?? Future<void>.value();
      final future = previous.then((_) => _queueLock(owner, () async {
            if (cacheKey != await _key(date)) return;
            await _flush(date, cacheKey, owner, token, retry: retry);
          }));
      _mutations[cacheKey] =
          future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      await future;
    }
  }

  Future<bool> _flush(String date, String cacheKey, String owner, String token,
      {bool retry = false}) async {
    final days = await _offline.read(owner);
    final pending = days[date] as Map?;
    if (pending == null) return true;
    if (!retry && (_retryAfter[cacheKey]?.isAfter(DateTime.now()) ?? false)) {
      return false;
    }
    final actions = List<Map>.from(pending['actions'] as List);
    var day = Map<String, dynamic>.from(pending['day'] as Map);
    while (actions.isNotEmpty) {
      if (cacheKey != await _key(date)) throw StateError('Session changed');
      final action = actions.first;
      try {
        final response = await ApiClient.shared.client.request(
            path(action['suffix'] as String, date),
            data: action['data'],
            options: Options(
                method: action['method'] as String,
                extra: {'sessionOwnerToken': token}));
        if (cacheKey != await _key(date)) throw StateError('Session changed');
        day = {
          ...day,
          ...Map<String, dynamic>.from(response.data['data'] as Map)
        };
        day.remove('pendingSync');
        day.remove('syncBlocked');
        actions.removeAt(0);
        if (actions.isEmpty) {
          days.remove(date);
        } else {
          days[date] = {'day': day, 'actions': actions};
        }
        await _offline.write(owner, days);
      } catch (error) {
        if (WorkoutOfflineStore.isOffline(error)) {
          _retryAfter[cacheKey] =
              DateTime.now().add(const Duration(seconds: 20));
          return false;
        }
        if (error is DioException &&
            [400, 404, 409].contains(error.response?.statusCode)) {
          days[date] = {'day': day, 'actions': actions, 'blocked': true};
          await _offline.write(owner, days);
          changes.add(_offline.project(day, actions, blocked: true));
        }
        rethrow;
      }
    }
    _retryAfter.remove(cacheKey);
    _revision[cacheKey] = (_revision[cacheKey] ?? 0) + 1;
    await _accept(date, cacheKey, day);
    await UserDataCache.shared.invalidate('training_map');
    unawaited(ProgressRepository.shared.invalidate());
    unawaited(
        CacheScope.userKey('training_volume_6').then(LocalCache.shared.remove));
    unawaited(TodayRepository.shared
        .fetchFresh(forceRefresh: true)
        .catchError((Object _) => null));
    return true;
  }

  final _historyRequests = <String, Future<List<Map<String, dynamic>>>>{};
  static const base = '/api/workout/training';

  static String errorMessage(Object error, String fallback) {
    if (error is FormatException) return error.message;
    if (error is DioException &&
        [400, 404, 409].contains(error.response?.statusCode)) {
      final body = error.response?.data;
      final message = body is Map ? body['error'] : null;
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return fallback;
  }

  Future<String> _key(String date) => CacheScope.userKey(
      'training_v2_${LanguageManager.shared.currentLanguage.code}_$date');
  Future<TrainingDay?> cached(String date) async {
    final key = await _key(date);
    final queued = await _pending(date);
    if (queued != null) return queued;
    final entry = await LocalCache.shared.getEntry(key);
    final json = entry?.$1 is Map
        ? Map<String, dynamic>.from(entry!.$1 as Map)
        : await LocalCache.shared.getJson(key);
    if (key != await _key(date)) return null;
    return _memory[key] ??
        (json == null || json['date'] == null ? null : TrainingDay(json));
  }

  String path(String suffix, String date) =>
      '$base$suffix?date=$date&utcOffsetMinutes=${DateTime.now().timeZoneOffset.inMinutes}';

  Future<TrainingDay> load(String date, {bool refresh = false}) async {
    await syncPending(retry: refresh);
    final pending = await _pending(date);
    if (pending != null) return pending;
    final key = await _key(date);
    if (!refresh) {
      final entry = await LocalCache.shared.getEntry(key);
      if (entry != null && entry.$2 < const Duration(seconds: 30)) {
        return _memory[key] ??
            TrainingDay(Map<String, dynamic>.from(entry.$1 as Map));
      }
    }
    if (_requests.containsKey(key)) return _requests[key]!;
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
    return _accept(date, key, response.data['data'], revision: revision);
  }

  Future<TrainingDay> _accept(String date, String key, dynamic json,
      {int? revision}) async {
    if (key != await _key(date)) throw StateError('Session changed');
    final previous = _memory[key] ?? await cached(date);
    if (key != await _key(date)) throw StateError('Session changed');
    if (revision != null && revision != (_revision[key] ?? 0)) {
      await _mutations[key];
      final latest = _memory[key];
      if (latest == null) throw StateError('Workout changed. Retry the sync.');
      return latest;
    }
    final day = TrainingDay(
        {...?previous?.json, ...Map<String, dynamic>.from(json as Map)});
    if (!json.containsKey('week')) {
      day.json['week'] = day.week
          .map((row) => row['date'] == date
              ? {
                  ...row,
                  'status': day.session?['status'] ??
                      (day.restDay
                          ? 'REST_DAY'
                          : day.items.isEmpty
                              ? 'EMPTY'
                              : 'SCHEDULED')
                }
              : row)
          .toList();
    }
    day.json.remove('pendingSync');
    day.json.remove('syncBlocked');
    _memory[key] = day;
    changes.add(day);
    unawaited(
        LocalCache.shared.saveEntry(key, day.json).catchError((Object _) {}));
    return day;
  }

  Future<TrainingDay> mutate(String date, String method, String suffix,
      {Map<String, dynamic>? data}) async {
    final key = await _key(date);
    final token = await SecureSessionStore.shared.accessToken;
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null || token == null) throw StateError('Session changed');
    final previous = _mutations[key] ?? Future<void>.value();
    final future = previous.then((_) => _queueLock(owner, () async {
          if (key != await _key(date)) throw StateError('Session changed');
          _revision[key] = (_revision[key] ?? 0) + 1;
          final allowed = WorkoutOfflineStore.canQueue(method, suffix);
          final flushed = await _flush(date, key, owner, token);
          final current = await cached(date);
          if (!flushed && !allowed) {
            throw const FormatException(
                'Reconnect to sync your workout before making changes.');
          }
          try {
            if (!flushed) {
              throw DioException(
                  requestOptions: RequestOptions(),
                  type: DioExceptionType.connectionError);
            }
            final response = await ApiClient.shared.client.request(
                path(suffix, date),
                data: data,
                options: Options(
                    method: method, extra: {'sessionOwnerToken': token}));
            return await _saved(date, key, response.data['data'],
                routinesChanged: suffix.startsWith('/routines'));
          } catch (error) {
            if (!WorkoutOfflineStore.isOffline(error) ||
                !allowed ||
                current?.started != true) {
              rethrow;
            }
            if (key != await _key(date)) throw StateError('Session changed');
            final days = await _offline.read(owner);
            final pending = days[date] as Map?;
            if (pending?['blocked'] == true) {
              throw const FormatException(
                  'Sync needs attention. Reconnect and retry.');
            }
            final actions = List<Map>.from(pending?['actions'] as List? ?? []);
            actions.add({
              'method': method,
              'suffix': suffix,
              'data': data,
              'createdAt': DateTime.now().toIso8601String()
            });
            final source = Map<String, dynamic>.from(
                pending?['day'] as Map? ?? current!.json);
            final local = _offline.project(source, actions);
            days[date] = {'day': source, 'actions': actions};
            await _offline.write(owner, days);
            _retryAfter[key] = DateTime.now().add(const Duration(seconds: 20));
            if (key != await _key(date)) throw StateError('Session changed');
            changes.add(local);
            return local;
          }
        }));
    _mutations[key] =
        future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return future;
  }

  Future<TrainingDay> _saved(String date, String key, dynamic json,
      {bool routinesChanged = false}) async {
    await UserDataCache.shared.invalidate('training_map');
    if (routinesChanged) await UserDataCache.shared.invalidate('routines');
    final day = await _accept(date, key, json);
    unawaited(ProgressRepository.shared.invalidate());
    unawaited(
        CacheScope.userKey('training_volume_6').then(LocalCache.shared.remove));
    // Coalesce set saves instead of refetching both dashboards after every set.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 700), () async {
      if (key != await _key(date)) return;
      unawaited(WorkoutRepository.shared
          .getTodayWorkoutPlan(forceRefresh: true)
          .catchError((Object _) => null));
      unawaited(TodayRepository.shared
          .fetchFresh(forceRefresh: true)
          .catchError((Object _) => null));
    });
    return day;
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

  Future<Map<String, dynamic>> routine(String date, String id) =>
      UserDataCache.shared.load('routines', id, () async {
        final token = await SecureSessionStore.shared.accessToken;
        final response = await ApiClient.shared.client.get(
            path('/routines/$id', date),
            options: Options(extra: {'sessionOwnerToken': token}));
        return Map<String, dynamic>.from(response.data['data'] as Map);
      });

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
