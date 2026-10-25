import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/media/video_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';
import '../../today/repositories/today_repository.dart';
import '../models/workout_exercise_models.dart';
import '../models/exercise_catalog_page.dart';
import '../../../core/localization/language_manager.dart';

// MARK: - Central Workout Repository with Optimistic Updates & SWR Cache
class WorkoutRepository {
  static final WorkoutRepository shared = WorkoutRepository._();
  WorkoutRepository._();

  final _planController = StreamController<TodayPlanModel?>.broadcast();
  Stream<TodayPlanModel?> get planStream => _planController.stream;

  TodayPlanModel? _currentPlan;
  TodayPlanModel? get currentPlan =>
      _currentPlanLocale == LanguageManager.shared.currentLanguage.code
          ? _currentPlan
          : null;
  String? _currentPlanLocale;
  String? _currentPlanKey;

  Future<TodayPlanModel?>? _inFlightPlan;
  String? _inFlightPlanLocale;

  List<WorkoutExerciseModel>? _catalog;
  String? _catalogLocale;
  String? _catalogOwner;
  int _catalogRevision = 0;
  List<WorkoutExerciseModel>? get cachedCatalog =>
      _catalogOwner == AppDataMode.shared.owner &&
              _catalogLocale == LanguageManager.shared.currentLanguage.code
          ? _catalog
          : null;
  final _catalogRequests = <String, Future<List<WorkoutExerciseModel>>>{};
  static Future<String> _catalogKey(String locale) =>
      CacheScope.userKey('exercise_catalog_v5_$locale');

  Future<String> _ensureCatalogOwner() async {
    final owner = await CacheScope.userId();
    if (_catalogOwner != owner) {
      _catalogOwner = owner;
      _catalog = null;
      _pageCache.clear();
      _pageRequests.clear();
      _catalogRequests.clear();
    }
    return owner;
  }

  Future<void> invalidateExerciseMedia() async {
    _catalogRevision++;
    _catalog = null;
    _pageCache.clear();
    _pageRequests.clear();
    _catalogRequests.clear();
    await UserDataCache.shared.invalidate('exercise_detail');
    final owner = await CacheScope.userId();
    try {
      await LocalCache.shared.removeByPrefix(
          '${CacheScope.userPrefix}${owner}_exercise_catalog_v5_');
    } catch (_) {/* Optional cache cleanup must not hide a saved profile. */}
  }

  static Future<String> _planKey() => CacheScope.userDayKey(
      'plan_v2_${LanguageManager.shared.currentLanguage.code}');
  static const Duration _catalogTtl = Duration(days: 7);
  final _pageCache = <String, ({DateTime saved, ExerciseCatalogPage data})>{};
  final _pageRequests = <String, Future<ExerciseCatalogPage>>{};

  Future<ExerciseCatalogPage> getExercisePage(
      {int page = 1,
      int pageSize = 24,
      String search = '',
      String? bodyPart,
      String? equipment,
      String? mediaGender,
      bool forceRefresh = false}) async {
    final owner = await _ensureCatalogOwner();
    final revision = _catalogRevision;
    final locale = LanguageManager.shared.currentLanguage.code;
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (bodyPart != null) 'bodyPart': bodyPart,
      if (equipment != null) 'equipment': equipment,
      if (mediaGender != null) 'mediaGender': mediaGender,
    };
    final key =
        '$owner:$revision:$locale:${Uri(queryParameters: query.map((key, value) => MapEntry(key, value.toString()))).query}';
    final cached = _pageCache[key];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.saved) < const Duration(minutes: 5)) {
      return cached.data;
    }
    final pending = _pageRequests[key];
    if (pending != null) return pending;
    final future = () async {
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
          Endpoints.workoutExercises,
          queryParameters: query);
      if (await CacheScope.userId() != owner ||
          revision != _catalogRevision ||
          LanguageManager.shared.currentLanguage.code != locale) {
        throw StateError('Language changed');
      }
      final result = ExerciseCatalogPage.fromJson(response.data!);
      if (_pageCache.length >= 50) _pageCache.remove(_pageCache.keys.first);
      _pageCache[key] = (saved: DateTime.now(), data: result);
      return result;
    }();
    _pageRequests[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_pageRequests[key], future)) _pageRequests.remove(key);
    }
  }

  // ── Helper to resolve current day enum ──────────────────────────────────────
  static String getTodayDayOfWeek() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'MONDAY';
      case DateTime.tuesday:
        return 'TUESDAY';
      case DateTime.wednesday:
        return 'WEDNESDAY';
      case DateTime.thursday:
        return 'THURSDAY';
      case DateTime.friday:
        return 'FRIDAY';
      case DateTime.saturday:
        return 'SATURDAY';
      case DateTime.sunday:
      default:
        return 'SUNDAY';
    }
  }

  // ── Fetch Today's Workout Plan (Instant Local Paint + Background SWR) ────────
  Future<TodayPlanModel?> getTodayWorkoutPlan({bool forceRefresh = false}) {
    // Dedupe: home card + plan view + detail often ask at the same moment.
    final locale = LanguageManager.shared.currentLanguage.code;
    if (!forceRefresh &&
        _inFlightPlan != null &&
        _inFlightPlanLocale == locale) {
      return _inFlightPlan!;
    }
    final future = _loadPlan(forceRefresh: forceRefresh);
    _inFlightPlan = future;
    _inFlightPlanLocale = locale;
    future.whenComplete(() {
      if (identical(_inFlightPlan, future)) _inFlightPlan = null;
    });
    return future;
  }

  Future<TodayPlanModel?> _loadPlan({required bool forceRefresh}) async {
    final day = getTodayDayOfWeek();
    final cacheKey = await _planKey();

    // New user or new calendar day ⇒ memory copy is stale.
    if (_currentPlanKey != cacheKey) {
      _currentPlan = null;
      _currentPlanKey = cacheKey;
      _currentPlanLocale = LanguageManager.shared.currentLanguage.code;
    }

    // 1. Instant paint from local cache
    if (!forceRefresh && _currentPlan == null) {
      final cachedJson = await LocalCache.shared.getJson(cacheKey);
      if (cachedJson != null) {
        try {
          _emit(TodayPlanModel.fromJson(cachedJson));
        } catch (_) {}
      }
    }

    // 2. Fresh network sync
    try {
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
        Endpoints.userWorkouts(day),
        queryParameters: {'date': CacheScope.todayKey()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'];
        if (data == null && await _planKey() == cacheKey) {
          _currentPlan = null;
          _planController.add(null);
          await LocalCache.shared.remove(cacheKey);
          return null;
        }
        if (data != null && data is Map<String, dynamic>) {
          if (await _planKey() != cacheKey) {
            return _currentPlan; // user switched mid-request
          }
          final fresh = TodayPlanModel.fromJson(data);
          _emit(fresh);
          await LocalCache.shared.saveJson(cacheKey, data);
          return fresh;
        }
      }
    } on DioException {
      // Graceful offline fallback: keep cached plan
    } catch (_) {}

    return _currentPlan;
  }

  void _emit(TodayPlanModel plan) {
    _currentPlan = plan;
    _planController.add(plan);
    _warmVideos(plan);
  }

  void _persistCurrent() {
    final plan = _currentPlan;
    final key = _currentPlanKey;
    if (plan == null || key == null) return;
    unawaited(LocalCache.shared.saveJson(key, plan.toJson()));
  }

  // Pre-initialise the active exercise's video and download the rest to disk,
  // so the first video is already decoding before the user even sees the card.
  void _warmVideos(TodayPlanModel plan) {
    if (plan.items.isEmpty) return;
    final active = plan.items.firstWhere(
      (it) => it.isPending,
      orElse: () => plan.items.first,
    );
    final activeUrl = active.exercise.url?.trim();
    if (VideoAssetCache.isPlayable(activeUrl)) {
      VideoControllerPool.shared.warm(activeUrl!);
    }
    unawaited(VideoAssetCache.prefetchAll(
      plan.items.map((i) => i.exercise.url?.trim()),
    ));
  }

  // ── Mark Exercise Complete (Optimistic 0ms UI) ──────────────────────────────
  Future<bool> markItemComplete(String itemId) async {
    final before =
        _currentPlan?.items.where((item) => item.id == itemId).firstOrNull;
    final key = _currentPlanKey;
    _optimisticallyUpdateStatus(itemId, 'COMPLETED');

    try {
      final response = await ApiClient.shared.patch(
        Endpoints.completeWorkoutItem(itemId),
      );
      if (response.statusCode == 200) {
        // Bust home cache to reflect newly completed count
        TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null);
        return true;
      }
    } catch (_) {
      // Revert if error
      // Retain the original item even if an offline refresh also fails.
    }
    _restoreItem(before, key);
    return false;
  }

  // ── Mark Exercise Skipped (Optimistic 0ms UI) ───────────────────────────────
  Future<bool> markItemSkip(String itemId) async {
    final before =
        _currentPlan?.items.where((item) => item.id == itemId).firstOrNull;
    final key = _currentPlanKey;
    _optimisticallyUpdateStatus(itemId, 'SKIPPED');

    try {
      final response = await ApiClient.shared.patch(
        Endpoints.skipWorkoutItem(itemId),
      );
      if (response.statusCode == 200) {
        TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null);
        return true;
      }
    } catch (_) {
      // Restore locally before the next network revalidation.
    }
    _restoreItem(before, key);
    return false;
  }

  Future<bool> resetItemStatus(String itemId) async {
    final before =
        _currentPlan?.items.where((item) => item.id == itemId).firstOrNull;
    final key = _currentPlanKey;
    _optimisticallyUpdateStatus(itemId, 'NOT_STARTED');
    try {
      final response = await ApiClient.shared.patch(
          Endpoints.updateWorkoutItem(itemId),
          data: {'status': 'NOT_STARTED'});
      if (response.statusCode == 200) {
        unawaited(TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null));
        return true;
      }
    } catch (_) {/* Restore the previous checklist state on failure. */}
    _restoreItem(before, key);
    return false;
  }

  // ── Update Target Sets / Reps / Weight (Optimistic) ─────────────────────────
  Future<bool> updateWorkoutItem(
    String itemId, {
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    int? restSeconds,
  }) async {
    final before =
        _currentPlan?.items.where((item) => item.id == itemId).firstOrNull;
    final key = _currentPlanKey;
    if (_currentPlan != null) {
      final updatedItems = _currentPlan!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: targetWeight,
            restSeconds: restSeconds,
          );
        }
        return item;
      }).toList();

      final updatedPlan = _currentPlan!.copyWith(items: updatedItems);
      _currentPlan = updatedPlan;
      _planController.add(updatedPlan);
      _persistCurrent();
    }

    try {
      final payload = <String, dynamic>{};
      if (targetSets != null) payload['targetSets'] = targetSets;
      if (targetReps != null) payload['targetReps'] = targetReps;
      if (targetWeight != null) payload['targetWeight'] = targetWeight;
      if (restSeconds != null) payload['restSeconds'] = restSeconds;

      final response = await ApiClient.shared.patch(
        Endpoints.updateWorkoutItem(itemId),
        data: payload,
      );
      if (response.statusCode == 200) return true;
    } catch (_) {
      // Failed changes must not remain in the offline plan cache.
    }
    _restoreItem(before, key);
    return false;
  }

  void _restoreItem(TodayPlanItemModel? before, String? key) {
    if (before == null || _currentPlan == null || _currentPlanKey != key) {
      return;
    }
    final items = _currentPlan!.items
        .map((item) => item.id == before.id ? before : item)
        .toList();
    _currentPlan = _currentPlan!.copyWith(items: items);
    _planController.add(_currentPlan);
    _persistCurrent();
  }

  // ── Add Item to Today's Plan (DB Exercise or Custom) ─────────────────────────
  Future<bool> addWorkoutItem({
    String? workoutId,
    Map<String, dynamic>? customExercise,
    int targetSets = 3,
    String targetReps = '10',
    double targetWeight = 0.0,
    int restSeconds = 60,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userWorkoutId': _currentPlan?.id,
        'dayOfWeek': getTodayDayOfWeek(),
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'restSeconds': restSeconds,
      };

      if (workoutId != null) {
        payload['workoutId'] = workoutId;
      } else if (customExercise != null) {
        payload['customExercise'] = customExercise;
      }

      final response = await ApiClient.shared.post(
        Endpoints.addWorkoutItem,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Re-fetch to get complete object with DB IDs
        await getTodayWorkoutPlan(forceRefresh: true);
        TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Delete Exercise from Plan (Optimistic) ──────────────────────────────────
  Future<bool> deleteWorkoutItem(String itemId) async {
    if (_currentPlan != null) {
      final updatedItems =
          _currentPlan!.items.where((item) => item.id != itemId).toList();
      final updatedPlan = _currentPlan!.copyWith(items: updatedItems);
      _currentPlan = updatedPlan;
      _planController.add(updatedPlan);
      _persistCurrent();
    }

    try {
      final response = await ApiClient.shared.delete(
        Endpoints.deleteWorkoutItem(itemId),
      );
      if (response.statusCode == 200) {
        TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null);
        return true;
      }
    } catch (_) {
      await getTodayWorkoutPlan(forceRefresh: true);
    }
    return false;
  }

  // ── Browse Exercise Database (7-day SWR cache) ───────────────────────────────
  /// Returns the cached catalog immediately when available and revalidates in
  /// the background once it is older than [_catalogTtl].
  Future<List<WorkoutExerciseModel>> getAllExercises({
    String? category,
    String? bodyPart,
    bool forceRefresh = false,
  }) async {
    final owner = await _ensureCatalogOwner();
    final revision = _catalogRevision;
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_catalogLocale != locale) {
      _catalog = null;
      _catalogLocale = locale;
    }
    final filtered =
        (category?.isNotEmpty ?? false) || (bodyPart?.isNotEmpty ?? false);
    if (filtered) return _fetchCatalog(category: category, bodyPart: bodyPart);

    if (!forceRefresh) {
      if (_catalog != null) return _catalog!;
      final entry = await LocalCache.shared.getEntry(await _catalogKey(locale));
      if (await CacheScope.userId() != owner ||
          revision != _catalogRevision ||
          LanguageManager.shared.currentLanguage.code != locale) {
        return [];
      }
      if (entry != null && entry.$1 is List) {
        final list = _parseCatalog(entry.$1 as List);
        if (list.isNotEmpty) {
          _catalog = list;
          if (entry.$2 > _catalogTtl) unawaited(_refreshCatalog());
          return list;
        }
      }
    }
    return _refreshCatalog();
  }

  Future<List<WorkoutExerciseModel>> _refreshCatalog() async {
    final owner = await _ensureCatalogOwner();
    final revision = _catalogRevision;
    final locale = LanguageManager.shared.currentLanguage.code;
    final requestKey = '$owner:$revision:$locale';
    return _catalogRequests[requestKey] ??= () async {
      try {
        final list = await _fetchCatalog();
        if (await CacheScope.userId() != owner ||
            revision != _catalogRevision ||
            LanguageManager.shared.currentLanguage.code != locale) {
          return <WorkoutExerciseModel>[];
        }
        if (list.isNotEmpty) {
          _catalog = list;
          await LocalCache.shared.saveEntry(
            await _catalogKey(locale),
            list.map((e) => e.toJson()).toList(),
          );
        }
        return _catalog ?? list;
      } finally {
        _catalogRequests.remove(requestKey);
      }
    }();
  }

  /// Call early (e.g. when Home appears) so the library opens instantly.
  void prefetchCatalog() {
    if (_catalog == null) unawaited(getAllExercises());
  }

  List<WorkoutExerciseModel> _parseCatalog(List raw) {
    final seen = <String>{};
    final out = <WorkoutExerciseModel>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      final m = WorkoutExerciseModel.fromJson(e);
      // Distinct exercise variants can share a translated name.
      if (m.id.isEmpty || !seen.add(m.id)) continue;
      out.add(m);
    }
    return out;
  }

  Future<List<WorkoutExerciseModel>> _fetchCatalog({
    String? category,
    String? bodyPart,
  }) async {
    final owner = await CacheScope.userId();
    final locale = LanguageManager.shared.currentLanguage.code;
    try {
      final query = <String, dynamic>{};
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (bodyPart != null && bodyPart.isNotEmpty) query['bodyPart'] = bodyPart;

      final response = await ApiClient.shared.get<Map<String, dynamic>>(
        Endpoints.workoutExercises,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data!['data'] as List?;
        if (rawList != null &&
            await CacheScope.userId() == owner &&
            LanguageManager.shared.currentLanguage.code == locale) {
          return _parseCatalog(rawList);
        }
      }
    } catch (_) {}
    return cachedCatalog ?? [];
  }

  Future<WorkoutExerciseModel?> getExerciseDetail(String id,
      {String? mediaGender}) async {
    final owner = await CacheScope.userId();
    final locale = LanguageManager.shared.currentLanguage.code;
    final variantKey = mediaGender == null ? id : '$id:$mediaGender';
    final key =
        await CacheScope.userKey('exercise_detail_v5_${locale}_$variantKey');
    try {
      // Revalidate form guides on open so media replacements are visible now;
      // the saved guide below remains the offline fallback.
      final data = await UserDataCache.shared
          .load('exercise_detail', variantKey, () async {
        final response = await ApiClient.shared.get<Map<String, dynamic>>(
            Endpoints.workoutExerciseDetail(id),
            queryParameters: {
              if (mediaGender != null) 'mediaGender': mediaGender
            });
        return Map<String, dynamic>.from(response.data!['data'] as Map);
      }, ttl: const Duration(days: 1), refresh: true);
      if (await CacheScope.userId() != owner ||
          LanguageManager.shared.currentLanguage.code != locale) {
        return null;
      }
      await LocalCache.shared.saveJson(key, data);
      return WorkoutExerciseModel.fromJson(data);
    } catch (_) {/* A downloaded form guide remains available offline. */}
    final data = await LocalCache.shared.getJson(key);
    if (data != null &&
        await CacheScope.userId() == owner &&
        LanguageManager.shared.currentLanguage.code == locale) {
      return WorkoutExerciseModel.fromJson(data);
    }
    return null;
  }

  // ── Private Helper ──────────────────────────────────────────────────────────
  void _optimisticallyUpdateStatus(String itemId, String status) {
    if (_currentPlan != null) {
      final updatedItems = _currentPlan!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            status: status,
            completedAt: status == 'COMPLETED' ? DateTime.now() : null,
          );
        }
        return item;
      }).toList();

      final updatedPlan = _currentPlan!.copyWith(items: updatedItems);
      _currentPlan = updatedPlan;
      _planController.add(updatedPlan);
      _persistCurrent();
    }
  }

  void dispose() {
    _planController.close();
  }
}
