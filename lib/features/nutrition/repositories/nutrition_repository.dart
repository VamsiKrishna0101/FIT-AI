import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../today/repositories/today_repository.dart';
import '../../history/repositories/history_repository.dart';
import '../models/nutrition_diet_models.dart';
import '../models/food_catalog_page.dart';

class NutritionRepository {
  NutritionRepository._();
  static final shared = NutritionRepository._();
  final _plans = StreamController<TodayDietPlanModel?>.broadcast();
  Stream<TodayDietPlanModel?> get dietPlanStream => _plans.stream;
  final _requests = <String, Future<TodayDietPlanModel?>>{};
  TodayDietPlanModel? _current;
  String? _scope;
  int _revision = 0;
  static const ttl = Duration(minutes: 5);
  String get _localScope =>
      '${AppDataMode.shared.owner}:${CacheScope.todayKey()}:${LanguageManager.shared.currentLanguage.code}:${AppDataMode.shared.dataset}';
  TodayDietPlanModel? get currentPlan =>
      _scope == _localScope ? _current : null;

  static (String, String, String) getTodayDateStrings() {
    final date = DateTime.now();
    return (date.day.toString(), date.month.toString(), date.year.toString());
  }

  Future<String> _key() => CacheScope.userDayKey(
      'diet_v3_${LanguageManager.shared.currentLanguage.code}');

  Future<TodayDietPlanModel?> loadDate(DateTime date,
      {bool forceRefresh = false}) async {
    if (CacheScope.todayKey(date) == CacheScope.todayKey()) {
      return getTodayDietPlan(forceRefresh: forceRefresh);
    }
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return null;
    final locale = LanguageManager.shared.currentLanguage.code;
    final key = await CacheScope.userKey(
        'diet_history_v1_${locale}_${CacheScope.todayKey(date)}');
    try {
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
          Endpoints.userNutritionForDate(date.day.toString(),
              date.month.toString(), date.year.toString()));
      if (owner != await CacheScope.userId() ||
          locale != LanguageManager.shared.currentLanguage.code) {
        return null;
      }
      final json = Map<String, dynamic>.from(response.data!['data'] as Map);
      await LocalCache.shared.saveJson(key, json);
      return TodayDietPlanModel.fromJson(json);
    } catch (_) {
      if (owner != await CacheScope.userId() ||
          locale != LanguageManager.shared.currentLanguage.code) {
        return null;
      }
      final cached = await LocalCache.shared.getJson(key);
      return cached == null ? null : TodayDietPlanModel.fromJson(cached);
    }
  }

  Future<TodayDietPlanModel?> getTodayDietPlan(
      {bool forceRefresh = false}) async {
    final key = await _key();
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return null;
    if (!forceRefresh) {
      final entry = await LocalCache.shared.getEntry(key);
      if (entry?.$1 is Map && key == await _key()) {
        final cached = TodayDietPlanModel.fromJson(
            Map<String, dynamic>.from(entry!.$1 as Map));
        _scope = _localScope;
        _current = cached;
        _plans.add(cached);
        if (entry.$2 > ttl) unawaited(_fetch(key).catchError((_) => cached));
        return cached;
      }
    }
    return _fetch(key);
  }

  Future<TodayDietPlanModel?> _fetch(String key) {
    if (_requests[key] != null) return _requests[key]!;
    final revision = _revision;
    late Future<TodayDietPlanModel?> future;
    future = () async {
      try {
        final (day, month, year) = getTodayDateStrings();
        final response = await ApiClient.shared.get<Map<String, dynamic>>(
            Endpoints.userNutritionForDate(day, month, year));
        if (key != await _key() || revision != _revision) {
          throw StateError('Nutrition changed. Refresh again.');
        }
        final json = Map<String, dynamic>.from(response.data!['data'] as Map);
        final plan = TodayDietPlanModel.fromJson(json);
        _current = plan;
        _scope = _localScope;
        await LocalCache.shared.saveEntry(key, json);
        _plans.add(plan);
        return plan;
      } finally {
        if (identical(_requests[key], future)) _requests.remove(key);
      }
    }();
    _requests[key] = future;
    return future;
  }

  Future<void> invalidate() async {
    _revision++;
    _requests.clear();
    _current = null;
    await LocalCache.shared.removeByPrefix(
        '${CacheScope.userPrefix}${await CacheScope.userId()}_diet_v3_');
  }

  Future<bool> _mutate(Future<dynamic> Function() request) async {
    if (AppDataMode.shared.preview) return false;
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return false;
    try {
      await request();
      if (owner != await CacheScope.userId()) return false;
    } catch (_) {
      return false;
    }
    TodayRepository.shared.invalidate();
    try {
      await Future.wait([
        invalidate(),
        ProgressRepository.shared.invalidate(),
        HistoryRepository.shared.invalidate(),
      ]);
    } catch (_) {
      // The server already saved the meal. A local cache failure must not
      // invite a second submission of the same entry.
    }
    // A successful save remains successful if the refresh is offline.
    unawaited(getTodayDietPlan(forceRefresh: true).catchError((_) => null));
    unawaited(TodayRepository.shared.fetchFresh(forceRefresh: true));
    return true;
  }

  Future<bool> logMeal(
      {String? nutritionId,
      Map<String, dynamic>? customFood,
      required String mealType,
      double servings = 1,
      String status = 'LOGGED'}) {
    final (day, month, year) = getTodayDateStrings();
    return _mutate(() => ApiClient.shared.post(Endpoints.logMeal, data: {
          if (nutritionId != null) 'nutritionId': nutritionId,
          if (customFood != null) 'customFood': customFood,
          'mealType': mealType,
          'servings': servings,
          'status': status,
          'day': day,
          'month': month,
          'year': year,
        }));
  }

  Future<bool> logWater(int amountMl) {
    final (day, month, year) = getTodayDateStrings();
    return _mutate(() => ApiClient.shared.post(Endpoints.logWater, data: {
          'amountMl': amountMl,
          'day': day,
          'month': month,
          'year': year,
        }));
  }

  Future<bool> updateMealStatus(String id, String status) =>
      _mutate(() => ApiClient.shared
          .patch(Endpoints.updateMealStatus(id), data: {'status': status}));
  Future<bool> deleteMealLog(String id) =>
      _mutate(() => ApiClient.shared.delete(Endpoints.deleteMealLog(id)));

  Future<List<NutritionFoodItemModel>> searchFoodCatalog(
      {String? query, String? category}) async {
    final key = await CacheScope.userKey(
        'food_catalog_v3_${LanguageManager.shared.currentLanguage.code}_${query ?? ''}_${category ?? ''}');
    final entry = await LocalCache.shared.getEntry(key);
    List<NutritionFoodItemModel> parse(List rows) => rows
        .map((row) => NutritionFoodItemModel.fromJson(
            Map<String, dynamic>.from(row as Map)))
        .toList();
    if (entry?.$1 is List && entry!.$2 < const Duration(hours: 1)) {
      return parse(entry.$1 as List);
    }
    try {
      final response = await ApiClient.shared.get<Map<String, dynamic>>(
          Endpoints.nutritionItems,
          queryParameters: {
            if (query?.isNotEmpty == true) 'search': query,
            if (category?.isNotEmpty == true) 'category': category
          });
      final rows = response.data!['data'] as List;
      await LocalCache.shared.saveEntry(key, rows);
      return parse(rows);
    } catch (_) {
      if (entry?.$1 is List) return parse(entry!.$1 as List);
      rethrow;
    }
  }

  Future<FoodCatalogPage> getFoodPage(
      {int page = 1,
      String search = '',
      String? category,
      String focus = 'ALL',
      String sort = 'NAME',
      String source = 'LIBRARY'}) async {
    final owner = await CacheScope.userId();
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/nutrition/catalog', queryParameters: {
      'page': page,
      'pageSize': 24,
      'search': search.trim(),
      'focus': focus,
      'sort': sort,
      'source': source,
      if (category != null) 'category': category,
    });
    if (owner != await CacheScope.userId()) {
      throw StateError('Your session changed.');
    }
    return FoodCatalogPage.fromJson(
        Map<String, dynamic>.from(response.data!['data'] as Map));
  }

  void dispose() => _plans.close();
}
