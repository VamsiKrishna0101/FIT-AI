import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_session_store.dart';
import '../models/progress_models.dart';

class ProgressRepository {
  static final shared = ProgressRepository();
  final updates = StreamController<String>.broadcast();
  final _requests = <String, Future<ProgressJson>>{};
  final _versions = <String, int>{};
  Future<void> _pinWrites = Future<void>.value();
  static const ttl = Duration(minutes: 5);

  Future<String> _key(String path, String period, Map<String, dynamic> query) =>
      CacheScope.userKey(
          'progress_v5_${LanguageManager.shared.currentLanguage.code}_${CacheScope.todayKey()}_${DateTime.now().timeZoneOffset.inMinutes}_${path}_${period}_${query.toString()}');

  Future<ProgressJson?> cached(String path, String period,
      {Map<String, dynamic> query = const {}}) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return null;
    final key = await _key(path, period, query);
    final entry = await LocalCache.shared.getEntry(key);
    if (await CacheScope.userId() != owner ||
        key != await _key(path, period, query) ||
        entry?.$1 is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(entry!.$1 as Map);
  }

  Future<ProgressJson> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') throw StateError('Sign in to see your progress.');
    final key = await _key(path, period, query);
    final entry = refresh ? null : await LocalCache.shared.getEntry(key);
    if (await CacheScope.userId() != owner ||
        key != await _key(path, period, query)) {
      throw StateError('progress_context_changed');
    }
    if (entry?.$1 is Map && await CacheScope.userId() == owner) {
      if (entry!.$2 > ttl) {
        unawaited(_fetch(path, period, query, key, owner)
            .catchError((_) => Map<String, dynamic>.from(entry.$1 as Map)));
      }
      return Map<String, dynamic>.from(entry.$1 as Map);
    }
    return _fetch(path, period, query, key, owner);
  }

  Future<ProgressJson> _fetch(String path, String period,
      Map<String, dynamic> query, String key, String owner) {
    if (_requests.containsKey(key)) return _requests[key]!;
    final version = _versions[owner] ?? 0;
    late Future<ProgressJson> future;
    future = () async {
      try {
        final token = await SecureSessionStore.shared.accessToken;
        final response = await ApiClient.shared.client
            .get<Map<String, dynamic>>('/api/progress$path',
                queryParameters: {
                  'period': period,
                  'date': CacheScope.todayKey(),
                  'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
                  'dataset': AppDataMode.shared.dataset,
                  ...query,
                },
                options: Options(extra: {'sessionOwnerToken': token}));
        if (await CacheScope.userId() != owner ||
            key != await _key(path, period, query) ||
            version != (_versions[owner] ?? 0)) {
          throw StateError('Progress changed. Refresh again.');
        }
        final data = Map<String, dynamic>.from(response.data!['data'] as Map);
        await LocalCache.shared.saveEntry(key, data);
        updates.add(key);
        return data;
      } finally {
        if (identical(_requests[key], future)) {
          _requests.remove(key);
        }
      }
    }();
    _requests[key] = future;
    return future;
  }

  Future<void> invalidate() async {
    final owner = await CacheScope.userId();
    _versions[owner] = (_versions[owner] ?? 0) + 1;
    _requests.clear();
    for (final version in [2, 3, 4, 5]) {
      await LocalCache.shared.removeByPrefix(
          '${CacheScope.userPrefix}${owner}_progress_v${version}_');
    }
    updates.add('invalidated');
  }

  Future<List<String>> pins() async {
    final owner = await CacheScope.userId();
    final key = await CacheScope.userKey('progress_pins');
    final json = await LocalCache.shared.getJson(key);
    if (owner != await CacheScope.userId()) throw StateError('Session changed');
    return (json?['ids'] as List? ?? []).whereType<String>().take(3).toList();
  }

  Future<void> pin(String id) async {
    final ids = await pins();
    await setPinned(id, !ids.contains(id));
  }

  Future<void> setPinned(String id, bool selected) async {
    final owner = await CacheScope.userId();
    final pending = _pinWrites.then((_) async {
      if (owner != await CacheScope.userId()) {
        throw StateError('Session changed');
      }
      final ids = await pins();
      if (selected && !ids.contains(id)) {
        if (ids.length >= 3) {
          throw const FormatException(
              'Your overview already shows three exercises. Remove one before adding another.');
        }
        ids.add(id);
      } else if (!selected) {
        ids.remove(id);
      }
      final key = await CacheScope.userKey('progress_pins');
      if (owner != await CacheScope.userId()) {
        throw StateError('Session changed');
      }
      await LocalCache.shared.saveJson(key, {'ids': ids});
    });
    _pinWrites =
        pending.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await pending;
  }
}
