import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';

/// Confirmed workout actions waiting for the server. Stored separately from UI
/// caches so signing out does not lose a workout. Each account has its own key.
class WorkoutOfflineStore {
  final storage = const FlutterSecureStorage();

  String key(String owner) => 'fitai_workout_pending_$owner';

  static bool isOffline(Object error) =>
      error is DioException &&
      [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout
      ].contains(error.type);

  static bool canQueue(String method, String suffix) =>
      (method == 'POST' && suffix == '/finish') ||
      (method == 'PUT' && RegExp(r'^/items/[^/]+/sets$').hasMatch(suffix)) ||
      (method == 'DELETE' &&
          RegExp(r'^/items/[^/]+/sets/\d+$').hasMatch(suffix)) ||
      (method == 'POST' &&
          RegExp(r'^/items/[^/]+/complete$').hasMatch(suffix)) ||
      (method == 'PATCH' && RegExp(r'^/items/[^/]+/status$').hasMatch(suffix));

  Future<Map<String, dynamic>> read(String owner) async {
    final raw = await storage.read(key: key(owner));
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> write(String owner, Map<String, dynamic> days) => days.isEmpty
      ? storage.delete(key: key(owner))
      : storage.write(key: key(owner), value: jsonEncode(days));

  Future<void> clear(String owner) => storage.delete(key: key(owner));

  TrainingDay project(Map<String, dynamic> day, List actions,
      {bool blocked = false}) {
    final json = Map<String, dynamic>.from(jsonDecode(jsonEncode(day)) as Map);
    json.remove('pendingSync');
    json.remove('syncBlocked');
    final items = (json['items'] as List? ?? []).cast<Map>();
    if (json['session'] == null) {
      throw const FormatException('Start your workout first.');
    }
    void validateLoad(Map item, List<Map> logs) {
      final bodyweight =
          TodayPlanItemModel.fromJson(Map<String, dynamic>.from(item))
              .isBodyweight;
      if (!bodyweight &&
          logs.any(
              (log) => log['weight'] is! num || (log['weight'] as num) <= 0)) {
        throw const FormatException(
            'Enter the weight you lifted before saving this set.');
      }
    }

    for (final action in actions.cast<Map>()) {
      final suffix = action['suffix'] as String;
      final parts = suffix.split('/');
      final data = action['data'] as Map? ?? {};
      if (suffix == '/finish') {
        if (items.any(
            (item) => !['COMPLETED', 'SKIPPED'].contains(item['status']))) {
          throw const FormatException(
              'Mark each exercise done or skipped before finishing.');
        }
        for (final item
            in items.where((item) => item['status'] == 'COMPLETED')) {
          final logs = List<Map>.from(item['setLogs'] as List? ?? []);
          if (logs.isEmpty) {
            throw const FormatException(
                'Log at least one set before marking this exercise done.');
          }
          validateLoad(item, logs);
        }
        final session = json['session'] as Map;
        session['status'] = 'COMPLETED';
        session['finishedAt'] = action['createdAt'];
        final start = DateTime.tryParse(session['startedAt'] as String? ?? '');
        final finish = DateTime.parse(action['createdAt'] as String);
        if (start != null) {
          session['durationSeconds'] =
              finish.difference(start).inSeconds.clamp(0, 86400);
        }
        continue;
      }
      final item = items.where((row) => row['id'] == parts[2]).firstOrNull;
      if (item == null) {
        throw StateError(
            'Workout changed. Reconnect before logging more sets.');
      }
      final logs = List<Map>.from(item['setLogs'] as List? ?? []);
      void upsert(Map set) {
        final number = set['setNumber'], reps = set['reps'];
        final weight = set['weight'], effort = set['rpe'];
        if (!TodayPlanItemModel.fromJson(Map<String, dynamic>.from(item))
                .isBodyweight &&
            (weight == null || weight is num && weight <= 0)) {
          throw const FormatException(
              'Enter the weight you lifted before saving this set.');
        }
        if (number is! int ||
            number < 1 ||
            number > 100 ||
            reps is! int ||
            reps < 1 ||
            reps > 1000 ||
            (weight != null &&
                (weight is! num ||
                    !weight.isFinite ||
                    weight < 0 ||
                    weight > 1000)) ||
            (effort != null &&
                (effort is! num ||
                    !effort.isFinite ||
                    effort < 1 ||
                    effort > 10))) {
          throw const FormatException('Enter valid reps and load.');
        }
        logs.removeWhere((row) => row['setNumber'] == set['setNumber']);
        logs.add({...set, 'pendingSync': true});
      }

      if (parts[3] == 'sets') {
        if (action['method'] == 'DELETE') {
          logs.removeWhere((row) => row['setNumber'] == int.parse(parts[4]));
        } else {
          upsert(data);
        }
      } else if (parts[3] == 'complete') {
        for (final set in (data['sets'] as List? ?? []).cast<Map>()) {
          upsert(set);
        }
        if (logs.isEmpty) {
          throw const FormatException(
              'Log at least one set before marking this exercise done.');
        }
        validateLoad(item, logs);
        item['status'] = 'COMPLETED';
      } else if (parts[3] == 'status') {
        if (!['NOT_STARTED', 'COMPLETED', 'SKIPPED'].contains(data['status'])) {
          throw const FormatException('Could not save. Please try again.');
        }
        if (data['status'] == 'COMPLETED' && logs.isEmpty) {
          throw const FormatException(
              'Log at least one set before marking this exercise done.');
        }
        if (data['status'] == 'COMPLETED') validateLoad(item, logs);
        item['status'] = data['status'];
      }
      logs.sort(
          (a, b) => (a['setNumber'] as num).compareTo(b['setNumber'] as num));
      item['setLogs'] = logs;
    }
    final logs = items
        .expand((item) => (item['setLogs'] as List? ?? []).cast<Map>())
        .toList();
    json['summary'] = {
      'sets': logs.length,
      'volume': logs.fold<double>(
          0,
          (sum, set) =>
              sum +
              (set['reps'] as num).toDouble() *
                  ((set['weight'] as num?)?.toDouble() ?? 0)),
      'skipped': items.where((item) => item['status'] == 'SKIPPED').length,
    };
    json['pendingSync'] = actions.length;
    json['syncBlocked'] = blocked;
    return TrainingDay(json);
  }
}
