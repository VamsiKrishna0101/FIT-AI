import '../localization/language_manager.dart';
import '../storage/local_cache.dart';
import 'cache_scope.dart';

/// Short-lived, account and language scoped data. Simultaneous reads share a request.
class UserDataCache {
  UserDataCache._();

  static final shared = UserDataCache._();

  final _requests = <String, Future<Map<String, dynamic>>>{};
  final _versions = <String, int>{};

  Future<Map<String, dynamic>> load(
    String bucket,
    String suffix,
    Future<Map<String, dynamic>> Function() fetch, {
    Duration ttl = const Duration(minutes: 5),
    bool refresh = false,
  }) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') throw StateError('Sign in to load your data.');

    final language = LanguageManager.shared.currentLanguage.code;
    final scope = '$owner:$bucket';
    final key = await CacheScope.userKey('data_${bucket}_${language}_$suffix');
    final cached = await LocalCache.shared.getEntry(key);
    final value = cached?.$1 is Map ? cached!.$1 as Map : null;
    final version = _versions.putIfAbsent(
        scope, () => value?['version'] is int ? value!['version'] as int : 0);

    if (!refresh) {
      if (value?['value'] is Map &&
          value?['version'] == version &&
          cached!.$2 < ttl &&
          owner == await CacheScope.userId() &&
          language == LanguageManager.shared.currentLanguage.code &&
          version == (_versions[scope] ?? 0)) {
        return Map<String, dynamic>.from(value!['value'] as Map);
      }
    }

    final pending = _requests[key];
    if (pending != null) return pending;

    late Future<Map<String, dynamic>> request;
    request = () async {
      try {
        final data = await fetch();
        if (owner != await CacheScope.userId() ||
            language != LanguageManager.shared.currentLanguage.code ||
            version != (_versions[scope] ?? 0)) {
          throw StateError('Your data changed. Please retry.');
        }

        try {
          await LocalCache.shared
              .saveEntry(key, {'version': version, 'value': data});
        } catch (_) {
          /* A cache write must not hide a successful server response. */
        }
        if (owner != await CacheScope.userId() ||
            language != LanguageManager.shared.currentLanguage.code ||
            version != (_versions[scope] ?? 0)) {
          throw StateError('Your data changed. Please retry.');
        }
        return data;
      } finally {
        if (identical(_requests[key], request)) _requests.remove(key);
      }
    }();

    _requests[key] = request;
    return request;
  }

  Future<void> invalidate(String bucket) async {
    final owner = await CacheScope.userId();
    final scope = '$owner:$bucket';
    _versions[scope] = (_versions[scope] ?? 0) + 1;

    final prefix = '${CacheScope.userPrefix}${owner}_data_${bucket}_';
    _requests.removeWhere((key, _) => key.startsWith(prefix));
    try {
      await LocalCache.shared.removeByPrefix(prefix);
    } catch (_) {
      /* The revision still prevents reuse of invalidated entries. */
    }
  }
}
