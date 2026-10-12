import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/cache_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../models/home_models.dart';
import '../../nutrition/repositories/nutrition_repository.dart';
import '../../../core/localization/language_manager.dart';

// MARK: - Centralized Today Home Repository with Zero-Stale SWR Caching
class TodayRepository {
  static final TodayRepository shared = TodayRepository._();
  TodayRepository._();

  final _controller = StreamController<HomeData>.broadcast();
  Stream<HomeData> get homeStream => _controller.stream;

  HomeData? _lastKnown;
  HomeData? get current =>
      _activeLocale == LanguageManager.shared.currentLanguage.code &&
              _activeDataset == AppDataMode.shared.dataset &&
              _activeUserId == AppDataMode.shared.owner &&
              _activeDate == CacheScope.todayKey()
          ? _lastKnown
          : null;
  String? _activeUserId;
  String? _activeLocale;
  String? _activeDataset, _activeDate;
  int _revision = 0;
  Future<HomeData?>? _inFlight;
  String? _inFlightLocale;

  Future<String> _currentUserId() async =>
      await SecureSessionStore.shared.userId ?? 'current_user';

  String _cacheKeyForUser(String userId, [String? locale]) =>
      '${CacheScope.userPrefix}${userId}_home_v11_${locale ?? LanguageManager.shared.currentLanguage.code}_${CacheScope.todayKey()}_${AppDataMode.shared.dataset}';

  /// Historical snapshots never replace today's shared cache or stream.
  Future<HomeData?> loadDate(DateTime selected,
      {bool forceRefresh = false}) async {
    final date = CacheScope.todayKey(selected);
    if (date == CacheScope.todayKey()) {
      await initialize();
      return fetchFresh(forceRefresh: forceRefresh);
    }
    final owner = await _currentUserId();
    final locale = LanguageManager.shared.currentLanguage.code;
    final key =
        '${CacheScope.userPrefix}${owner}_home_v11_${locale}_${date}_real';
    HomeData? cached;
    try {
      final raw = await LocalCache.shared.getJson(key);
      if (raw != null) {
        final parsed = HomeData.fromJson(raw);
        if (parsed.calendarDate == date) cached = parsed;
      }
    } catch (_) {
      // Ignore an invalid cache entry and request the selected day's data.
    }
    try {
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
        Endpoints.home,
        queryParameters: {'date': date, if (forceRefresh) 'refresh': 'true'},
      );
      if (owner != await _currentUserId() ||
          locale != LanguageManager.shared.currentLanguage.code) {
        return null;
      }
      if (response.statusCode == 200 && response.data != null) {
        final data = HomeData.fromJson(response.data!);
        if (data.calendarDate != date) {
          return null;
        }
        await LocalCache.shared.saveJson(key, response.data!);
        return data;
      }
    } catch (_) {}
    return owner == await _currentUserId() &&
            locale == LanguageManager.shared.currentLanguage.code
        ? cached
        : null;
  }

  void invalidate() {
    _revision++;
    _inFlight = null;
  }

  /// Wipe every user-scoped cache (call on sign-out / account switch).
  Future<void> clearUserCaches() async {
    _lastKnown = null;
    _activeUserId = null;
    _activeLocale = null;
    await CacheScope.clearAllUserData();
    await CacheManager.shared.clearAll();
  }

  // ── Load cached data in 0ms, then revalidate in background ───────────────
  Future<HomeData?> initialize() async {
    final locale = LanguageManager.shared.currentLanguage.code;
    final userId = await _currentUserId();
    if (_activeUserId != userId ||
        _activeLocale != locale ||
        _activeDataset != AppDataMode.shared.dataset ||
        _activeDate != CacheScope.todayKey()) {
      _activeUserId = userId;
      _activeLocale = locale;
      _activeDataset = AppDataMode.shared.dataset;
      _activeDate = CacheScope.todayKey();
      _lastKnown = null;
    }

    // 1. Read local cache for immediate 0ms paint
    final key = _cacheKeyForUser(userId, locale);
    final rawJson = await LocalCache.shared.getJson(key);
    if (rawJson != null &&
        key == _cacheKeyForUser(userId, locale) &&
        userId == await _currentUserId() &&
        _activeUserId == userId &&
        _activeLocale == locale &&
        LanguageManager.shared.currentLanguage.code == locale) {
      try {
        final cached = HomeData.fromJson(rawJson);
        _lastKnown = cached;
        _controller.add(cached);
      } catch (_) {}
    }

    // 2. Fetch fresh data from network in background
    fetchFresh(forceRefresh: false).catchError((_) => null);
    return _lastKnown;
  }

  // ── Network Fetch with Cache-Bust Option ─────────────────────────────────
  Future<HomeData?> fetchFresh({bool forceRefresh = false}) async {
    final locale = LanguageManager.shared.currentLanguage.code;
    final owner = await _currentUserId();
    final scope =
        '$owner:$locale:${AppDataMode.shared.dataset}:${CacheScope.todayKey()}';
    if (forceRefresh) invalidate();
    if (!forceRefresh && _inFlight != null && _inFlightLocale == scope) {
      return _inFlight!;
    }
    final future = _fetch(forceRefresh: forceRefresh);
    _inFlight = future;
    _inFlightLocale = scope;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  Future<HomeData?> _fetch({required bool forceRefresh}) async {
    final locale = LanguageManager.shared.currentLanguage.code;
    final revision = _revision, dataset = AppDataMode.shared.dataset;
    final date = CacheScope.todayKey();
    try {
      final userId = await _currentUserId();
      if (_activeUserId != userId ||
          _activeLocale != locale ||
          _activeDataset != dataset ||
          _activeDate != date) {
        _activeUserId = userId;
        _activeLocale = locale;
        _activeDataset = dataset;
        _activeDate = date;
        _lastKnown = null;
      }

      final queryParams = {'date': date, if (forceRefresh) 'refresh': 'true'};
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
        Endpoints.home,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (revision != _revision ||
            dataset != AppDataMode.shared.dataset ||
            date != CacheScope.todayKey() ||
            _activeUserId != userId ||
            await _currentUserId() != userId ||
            LanguageManager.shared.currentLanguage.code != locale) {
          return _lastKnown;
        }
        final fresh = HomeData.fromJson(response.data!);
        _lastKnown = fresh;
        _controller.add(fresh);

        // Keep dashboard cache isolated to the signed-in account.
        await LocalCache.shared
            .saveJson(_cacheKeyForUser(userId, locale), response.data!);

        // Also update Drift SQLite table
        final now = DateTime.now();
        final dateString =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        if (dataset == 'real') {
          unawaited(CacheManager.shared
              .saveTodayDashboard(
                TodayDashboardCacheTableCompanion(
                  userId: drift.Value(userId),
                  dateString: drift.Value(dateString),
                  caloriesConsumed:
                      drift.Value(fresh.nutrition.calories.consumed),
                  caloriesTarget: drift.Value(fresh.nutrition.calories.target),
                  waterLoggedMl: drift.Value(fresh.nutrition.water.consumed),
                  waterTargetMl: drift.Value(fresh.nutrition.water.target),
                  readinessScore: drift.Value(fresh.readiness?.score ?? 0),
                  readinessLabel: drift.Value(fresh.readiness?.label ?? ''),
                  todayWorkoutTitle:
                      drift.Value(fresh.todayWorkout?.workoutTitle),
                  todayWorkoutDurationMinutes:
                      drift.Value(fresh.todayWorkout?.durationMinutes),
                  isWorkoutCompleted:
                      drift.Value(fresh.todayWorkout?.status == 'COMPLETED'),
                  lastCachedAt: drift.Value(DateTime.now()),
                ),
              )
              .catchError((Object _) {}));
        }

        return fresh;
      }
    } on DioException {
      // In offline mode, the cached data is gracefully preserved
    } catch (_) {}
    return _lastKnown;
  }

  Future<void> quickAddWater({int amountMl = 250}) async {
    final saved = await NutritionRepository.shared.logWater(amountMl);
    if (!saved) throw StateError('Could not save water.');
  }

  void dispose() {
    _controller.close();
  }
}
