import 'dart:async';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../today/repositories/today_repository.dart';
import '../../nutrition/repositories/nutrition_repository.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../train/repositories/workout_repository.dart';
import '../../train/repositories/training_repository.dart';

class WeeklyPlanRepository {
  Future<Map<String, dynamic>> availability() async {
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/plans/availability');

    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>('/api/plans');
    return (response.data?['data'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> history({String? cursor}) async {
    final response = await ApiClient.shared.get<Map<String, dynamic>>(
      '/api/plans/history',
      queryParameters: {if (cursor != null) 'cursor': cursor},
    );
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<Map<String, dynamic>> savedPlan(String id) async {
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/plans/saved/$id');
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<Map<String, dynamic>> generate({required DateTime weekStart}) async {
    final zone = await FlutterTimezone.getLocalTimezone();
    final response = await ApiClient.shared
        .post<Map<String, dynamic>>('/api/plans/generate', data: {
      'weekStart': CacheScope.todayKey(weekStart),
      'timezone': zone.identifier,
    });
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<Map<String, dynamic>> run(String id) async {
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>('/api/plans/runs/$id');
    final run = Map<String, dynamic>.from(response.data!['data'] as Map);
    if (run['status'] == 'COMPLETED' &&
        run['plan'] is Map &&
        (run['plan'] as Map)['status'] == 'ACTIVE') {
      unawaited(refreshSchedule());
    }
    return run;
  }

  Future<void> activate(String id) async {
    await ApiClient.shared
        .post<Map<String, dynamic>>('/api/plans/$id/activate');
    await refreshSchedule();
  }

  Future<void> refreshSchedule() async {
    TodayRepository.shared.invalidate();
    await Future.wait([
      ProgressRepository.shared.invalidate(),
      NutritionRepository.shared.invalidate(),
      WorkoutRepository.shared.getTodayWorkoutPlan(forceRefresh: true),
      TrainingRepository.shared.load(CacheScope.todayKey(), refresh: true),
      TodayRepository.shared.fetchFresh(forceRefresh: true),
    ].map((future) =>
        future.then<void>((_) {}, onError: (Object _, StackTrace __) {})));
  }

  Future<Map<String, dynamic>> retry(String id) async {
    final response = await ApiClient.shared
        .post<Map<String, dynamic>>('/api/plans/runs/$id/retry');
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }
}
