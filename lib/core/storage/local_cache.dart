import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// MARK: - Local Cache Engine in Flutter (SharedPreferences)
class LocalCache {
  static final LocalCache shared = LocalCache._();
  LocalCache._();

  static const String keyAppLanguage = 'cache_app_language';
  static const String keyOnboardingDraft = 'cache_onboarding_draft';
  static const String keyAccessToken = 'cache_access_token';
  static const String keyRefreshToken = 'cache_refresh_token';

  // L1 memory mirror so repeated reads in one session never touch disk.
  final Map<String, Map<String, dynamic>> _memory = {};
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveString(String key, String value) async {
    final prefs = await _p;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _p;
    return prefs.getString(key);
  }

  Future<void> saveJson(String key, Map<String, dynamic> jsonMap) async {
    _memory[key] = jsonMap;
    final prefs = await _p;
    await prefs.setString(key, jsonEncode(jsonMap));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final mem = _memory[key];
    if (mem != null) return mem;
    final prefs = await _p;
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _memory[key] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Synchronous memory-only read (null if not yet loaded this session).
  Map<String, dynamic>? peekJson(String key) => _memory[key];

  // ── Timestamped entries (for TTL-based revalidation) ─────────────────────
  Future<void> saveEntry(String key, Object data) => saveJson(key, {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      });

  /// Returns `(data, age)` or null.
  Future<(Object?, Duration)?> getEntry(String key) async {
    final json = await getJson(key);
    if (json == null || json['savedAt'] is! num) return null;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(
      (json['savedAt'] as num).toInt(),
    );
    final age = DateTime.now().difference(savedAt);
    return age.isNegative ? null : (json['data'], age);
  }

  Future<void> remove(String key) async {
    _memory.remove(key);
    final prefs = await _p;
    await prefs.remove(key);
  }

  Future<void> removeByPrefix(String prefix) async {
    _memory.removeWhere((k, _) => k.startsWith(prefix));
    final prefs = await _p;
    final keys =
        prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
    await Future.wait(keys.map(prefs.remove));
  }
}
