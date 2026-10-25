import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';
import '../models/body_assessment_models.dart';
import '../models/training_map_models.dart';
import '../models/planned_physique_models.dart';

class BodyAssessmentRepository {
  static final shared = BodyAssessmentRepository();
  Future<Map<String, dynamic>> _read(String path,
          {String bucket = 'body', Map<String, dynamic>? query}) =>
      UserDataCache.shared.load(bucket,
          '${bucket == 'training_map' ? 'v3' : 'v2'}:$path:${query.toString()}',
          () async {
        await _requireSession();
        final response = await ApiClient.shared
            .get<Map<String, dynamic>>(path, queryParameters: query);
        return response.data!;
      },
          ttl: bucket == 'training_map'
              ? const Duration(seconds: 30)
              : const Duration(minutes: 5));

  Future<void> invalidate() async {
    await UserDataCache.shared.invalidate('body');
    await UserDataCache.shared.invalidate('body_real');
  }

  Future<void> _requireSession() async {
    final token = await SecureSessionStore.shared.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to see your body assessments.');
    }
  }

  Future<TrainingMapData> trainingMap(
      {DateTime? date, bool daily = false}) async {
    final data =
        await _read('/api/heatmap/training', bucket: 'training_map', query: {
      'date': CacheScope.todayKey(date ?? DateTime.now()),
      'utcOffsetMinutes': (date ?? DateTime.now()).timeZoneOffset.inMinutes,
      'period': daily ? 'day' : 'week',
    });
    return TrainingMapData.fromJson(data);
  }

  Future<BodyOverview> load() async {
    return BodyOverview.fromJson(await _read('/api/body', bucket: 'body_real'));
  }

  Future<PlannedPhysiqueData> plannedPhysique({DateTime? date}) async {
    await _requireSession();
    // Plan edits must be visible immediately when returning from a workout.
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/heatmap/plan', queryParameters: {
      'date': CacheScope.todayKey(date ?? DateTime.now()),
      'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    });
    return PlannedPhysiqueData.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> history(
          {String? from, String? to, int page = 1}) =>
      _read('/api/body/history', bucket: 'body_real', query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        'page': page,
      });

  Future<BodyComparison> compare(String current, String previous) async {
    return BodyComparison.fromJson(await _read('/api/body/compare',
        query: {'currentId': current, 'previousId': previous}));
  }

  Future<BodyAssessment> entry(String id) async {
    return BodyAssessment.fromJson(await _read('/api/body/entries/$id'));
  }

  Future<BodyAssessment> save(Map<String, dynamic> data,
      {BodyAssessment? existing}) async {
    final response = existing == null
        ? await ApiClient.shared.client.post<Map<String, dynamic>>(
            '/api/body/entries',
            data: data,
            options: Options(receiveTimeout: const Duration(seconds: 95)))
        : await ApiClient.shared.patch<Map<String, dynamic>>(
            '/api/body/entries/${existing.id}',
            data: {
                'metrics': data['metrics'],
                'expectedUpdatedAt': existing.updatedAt
              });
    await invalidate();
    await UserDataCache.shared.invalidate('profile');
    return BodyAssessment.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await ApiClient.shared.delete<void>('/api/body/entries/$id');
    await invalidate();
  }

  Future<BodyAssessment> updateReadings(
      BodyAssessment entry, Map<String, dynamic> readings) async {
    await _requireSession();
    final response = await ApiClient.shared.patch<Map<String, dynamic>>(
        '/api/body/entries/${entry.id}/readings',
        data: {'expectedUpdatedAt': entry.updatedAt, 'readings': readings});
    await invalidate();
    return BodyAssessment.fromJson(response.data!);
  }

  Future<BodyAssessment> deletePhotos(String id) async {
    await _requireSession();
    final response = await ApiClient.shared
        .delete<Map<String, dynamic>>('/api/body/entries/$id/photos');
    await invalidate();
    return BodyAssessment.fromJson(response.data!);
  }

  Future<BodyAssessment> refreshFocus(BodyAssessment entry,
      {required bool Function() cancelled,
      void Function(String)? onStage}) async {
    await _requireSession();
    final owner = await CacheScope.userId();
    if (cancelled()) throw StateError('Report update cancelled.');
    onStage?.call('focus');
    final response = await ApiClient.shared.client
        .post<Map<String, dynamic>>('/api/body/entries/${entry.id}/focus',
            data: {
              'expectedUpdatedAt': entry.updatedAt,
              'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
              'consentToVisualCoaching':
                  entry.visualCoachingConsent && entry.photos.isNotEmpty
            },
            options: Options(receiveTimeout: const Duration(seconds: 180)));
    if (cancelled() || await CacheScope.userId() != owner) {
      throw StateError('Report update cancelled.');
    }
    await invalidate();
    return BodyAssessment.fromJson(response.data!);
  }

  Future<Uint8List> photo(String url) async {
    // Authentication stays on the API client; photos are never public CDN URLs.
    final response = await ApiClient.shared.client.get<List<int>>(url,
        options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<BodyAssessment> review(Map<String, dynamic> data,
      {required bool Function() cancelled,
      void Function(String)? onStage}) async {
    onStage?.call('uploading');
    final user = await CacheScope.userId();
    final response = await ApiClient.shared
        .post<Map<String, dynamic>>('/api/body/reviews', data: data);
    final jobId = response.data!['jobId'] as String;
    var delivered = false;
    try {
      for (var attempt = 0; attempt < 180; attempt++) {
        if (cancelled() || await CacheScope.userId() != user) {
          throw StateError('Estimate cancelled.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        final job = await ApiClient.shared
            .get<Map<String, dynamic>>('/api/body/review-jobs/$jobId');
        if (cancelled() || await CacheScope.userId() != user) {
          throw StateError('Estimate cancelled.');
        }
        onStage?.call(job.data!['stage'] as String? ?? 'outlines');
        if (job.data!['status'] == 'failed') {
          throw StateError(job.data!['error'] as String);
        }
        if (job.data!['status'] == 'cancelled') {
          throw StateError('Estimate cancelled.');
        }
        if (job.data!['status'] == 'ready') {
          final entry = await ApiClient.shared.get<Map<String, dynamic>>(
              '/api/body/entries/${job.data!['assessmentId']}');
          if (await CacheScope.userId() != user || cancelled()) {
            throw StateError('Estimate cancelled.');
          }
          final result = BodyAssessment.fromJson(entry.data!);
          delivered = true;
          await invalidate();
          return result;
        }
      }
      throw StateError(
          'Your estimate is taking longer than expected. Try again shortly.');
    } finally {
      if (!delivered && await CacheScope.userId() == user) {
        try {
          await ApiClient.shared.delete<void>('/api/body/review-jobs/$jobId');
        } catch (_) {}
      }
    }
  }

  static String message(Object error) {
    if (error is DioException && error.response?.data is Map) {
      return (error.response!.data as Map)['error'] as String? ??
          'Could not complete this request.';
    }
    if (error is StateError) return error.message.toString();
    return 'Could not complete this request. Please try again.';
  }
}
