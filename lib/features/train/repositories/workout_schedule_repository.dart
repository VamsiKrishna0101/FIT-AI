import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../today/repositories/today_repository.dart';
import '../../progress/repositories/progress_repository.dart';
import 'training_repository.dart';
import 'workout_repository.dart';

class WorkoutScheduleRepository {
  Future<Map<String, dynamic>> preview(String date,
      {String action = 'SHIFT', List<String>? availableDates}) async {
    await TrainingRepository.shared.ensureScheduleSynced();
    return _request(date, 'preview', {
      'action': action,
      if (availableDates != null) 'availableDates': availableDates
    });
  }

  Future<Map<String, dynamic>> apply(
      String date, Map<String, dynamic> preview, String action) async {
    await TrainingRepository.shared.ensureScheduleSynced();
    final result = await _request(date, 'apply', {
      'action': action,
      'availableDates': preview['availableDates'],
      'fingerprint': preview['fingerprint'],
      'allowSkip': true
    });
    final dates = <String>{
      date,
      ...List<String>.from(preview['candidateDates'] as List? ?? [])
    };
    await TrainingRepository.shared.refreshScheduleDates(dates);
    await UserDataCache.shared.invalidate('plans');
    await UserDataCache.shared.invalidate('training_map');
    await ProgressRepository.shared.invalidate();
    TodayRepository.shared.invalidate();
    await Future.wait([
      TodayRepository.shared
          .fetchFresh(forceRefresh: true)
          .then<void>((_) {}, onError: (Object _) {}),
      WorkoutRepository.shared
          .getTodayWorkoutPlan(forceRefresh: true)
          .then<void>((_) {}, onError: (Object _) {}),
    ]);
    return result;
  }

  Future<Map<String, dynamic>> _request(
      String date, String suffix, Map<String, dynamic> input) async {
    final token = await SecureSessionStore.shared.accessToken;
    final zone = await FlutterTimezone.getLocalTimezone();
    final response = await ApiClient.shared.client.post(
        TrainingRepository.shared.path('/schedule/$suffix', date),
        data: {...input, 'timezone': zone.identifier},
        options: Options(extra: {'sessionOwnerToken': token}));
    if (token != await SecureSessionStore.shared.accessToken) {
      throw StateError('Session changed');
    }
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}
