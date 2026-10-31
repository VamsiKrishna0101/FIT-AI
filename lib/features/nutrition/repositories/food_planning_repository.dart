import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/network/api_client.dart';
import '../models/nutrition_diet_models.dart';
import 'nutrition_repository.dart';

class FoodPlanningRepository {
  FoodPlanningRepository._();
  static final shared = FoodPlanningRepository._();
  static const _base = '/api/nutrition/me/food-planning';
  Future<dynamic> _call(String route,
      {String method = 'GET', Map<String, dynamic>? data}) async {
    if (AppDataMode.shared.preview) {
      throw Exception('Switch to live data to manage your meals and routines.');
    }
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') throw Exception('Sign in to manage your meals.');
    try {
      final response = await ApiClient.shared.client
          .request<Map<String, dynamic>>('$_base$route',
              data: data,
              options: Options(
                  method: method,
                  receiveTimeout:
                      Duration(seconds: route == '/suggest' ? 240 : 30)));
      if (owner != await CacheScope.userId()) {
        throw Exception('Your account changed. Open Nutrition again.');
      }
      if (method != 'GET') {
        await NutritionRepository.shared.foodPlanningChanged();
      }
      return response.data?['data'];
    } on DioException catch (e) {
      final message = e.response?.data;
      throw Exception(message is Map && message['error'] is String
          ? message['error']
          : 'Could not save. Please try again.');
    }
  }

  Future<Map<String, dynamic>> settings() async =>
      Map<String, dynamic>.from(await _call('/settings') as Map);
  Future<void> saveSettings(String mode, List<String> mealSlots) async {
    final zone = await FlutterTimezone.getLocalTimezone();
    await _call('/settings', method: 'PUT', data: {
      'mode': mode,
      'mealSlots': mealSlots,
      'timezone': zone.identifier
    });
  }

  Future<List<NutritionFoodItemModel>> meals() async => (await _call('/meals')
          as List)
      .map((e) =>
          NutritionFoodItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  Future<NutritionFoodItemModel> saveMeal(Map<String, dynamic> data) async =>
      NutritionFoodItemModel.fromJson(Map<String, dynamic>.from(
          await _call('/meals', method: 'POST', data: data) as Map));
  Future<List<Map<String, dynamic>>> routines() async =>
      (await _call('/routines') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Future<void> saveRoutine(Map<String, dynamic> data, {String? id}) async {
    await _call('/routines${id == null ? '' : '/$id'}',
        method: id == null ? 'POST' : 'PUT', data: data);
  }

  Future<void> removeRoutine(String id) async {
    await _call('/routines/$id', method: 'DELETE');
  }

  Future<Map<String, dynamic>> day(DateTime date) async =>
      Map<String, dynamic>.from(
          await _call('/day/${CacheScope.todayKey(date)}') as Map);
  Future<void> act(DateTime date, String key, String action,
      {Map<String, dynamic>? replacement}) async {
    final zone = await FlutterTimezone.getLocalTimezone();
    await _call('/day/${CacheScope.todayKey(date)}/action',
        method: 'POST',
        data: {
          'sourceKey': key,
          'action': action,
          'timezone': zone.identifier,
          if (replacement != null) 'replacement': replacement
        });
  }

  Future<String> suggest(DateTime date) async {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final zone = await FlutterTimezone.getLocalTimezone();
    final result = await _call('/suggest', method: 'POST', data: {
      'weekStart': CacheScope.todayKey(monday),
      'timezone': zone.identifier
    }) as Map;
    return result['reason'] as String? ?? 'Your food suggestions are ready.';
  }
}
