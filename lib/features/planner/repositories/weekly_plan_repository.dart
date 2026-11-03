import '../../body_scan/models/body_measurement_baseline.dart';
import 'dart:async';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../today/repositories/today_repository.dart';
import '../../nutrition/repositories/nutrition_repository.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../train/repositories/workout_repository.dart';
import '../../train/repositories/training_repository.dart';
import '../../body_scan/models/body_assessment_models.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';

class WeeklyPlanRepository {
  final _syncedRuns = <String>{};

  Future<Map<String, dynamic>> _read(String path,
          {Map<String, dynamic>? query,
          Duration ttl = const Duration(minutes: 5)}) =>
      UserDataCache.shared.load('plans', 'real-v3:$path:${query.toString()}',
          () async {
        final response = await ApiClient.shared
            .get<Map<String, dynamic>>(path, queryParameters: query);
        return Map<String, dynamic>.from(response.data!['data'] as Map);
      }, ttl: ttl);
  Future<BodyOverview> bodyOverview() => BodyAssessmentRepository.shared.load();

  static bool hasEnteredMeasurements(BodyOverview body, DateTime now) =>
      BodyMeasurementBaseline(body, now: now).isComplete;

  Future<Map<String, dynamic>> availability() async {
    return _read('/api/plans/availability', ttl: const Duration(seconds: 30));
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final data =
        await UserDataCache.shared.load('plans', 'real-list-v3', () async {
      final response =
          await ApiClient.shared.get<Map<String, dynamic>>('/api/plans');
      return {'plans': response.data?['data'] ?? []};
    });
    return (data['plans'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((plan) => plan['synthetic'] != true)
        .toList();
  }

  Future<Map<String, dynamic>> history({String? cursor}) async {
    return _read('/api/plans/history',
        query: {if (cursor != null) 'cursor': cursor});
  }

  Future<Map<String, dynamic>> filteredHistory(
          {String? cursor, required Map<String, dynamic> query}) =>
      _read('/api/plans/history',
          query: {...query, if (cursor != null) 'cursor': cursor});

  Future<Map<String, dynamic>> savedPlan(String id) async {
    return _read('/api/plans/saved/$id');
  }

  Future<Map<String, dynamic>> generate(
      {required DateTime weekStart,
      DateTime? startDate,
      List<DateTime>? trainingDates}) async {
    await UserDataCache.shared.invalidate('plans');
    final zone = await FlutterTimezone.getLocalTimezone();
    final response = await ApiClient.shared
        .post<Map<String, dynamic>>('/api/plans/generate', data: {
      'weekStart': CacheScope.todayKey(weekStart),
      'timezone': zone.identifier,
      if (startDate != null) 'startDate': CacheScope.todayKey(startDate),
      if (trainingDates != null)
        'trainingDates': trainingDates.map(CacheScope.todayKey).toList(),
    });
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<Map<String, dynamic>> run(String id) async {
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>('/api/plans/runs/$id');
    final run = Map<String, dynamic>.from(response.data!['data'] as Map);
    if (run['status'] == 'COMPLETED' &&
        run['plan'] is Map &&
        (run['plan'] as Map)['status'] == 'ACTIVE' &&
        _syncedRuns.add('${await CacheScope.userId()}:$id')) {
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
    await UserDataCache.shared.invalidate('plans');
    await UserDataCache.shared.invalidate('training_map');
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
    await UserDataCache.shared.invalidate('plans');
    final response = await ApiClient.shared
        .post<Map<String, dynamic>>('/api/plans/runs/$id/retry');
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }
}
