import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_session_store.dart';
import '../models/body_assessment_models.dart';
import '../models/training_map_models.dart';

class BodyAssessmentRepository {
  static final shared = BodyAssessmentRepository();
  Future<void> _requireSession() async {
    final token = await SecureSessionStore.shared.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to see your body assessments.');
    }
  }

  Future<TrainingMapData> trainingMap(
      {DateTime? date, bool daily = false}) async {
    await _requireSession();
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/heatmap/training', queryParameters: {
      'date': CacheScope.todayKey(date ?? DateTime.now()),
      'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      if (daily) 'period': 'day',
    });
    return TrainingMapData.fromJson(response.data!);
  }

  Future<BodyOverview> load() async {
    await _requireSession();
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>('/api/body');
    return BodyOverview.fromJson(response.data!);
  }

  Future<BodyComparison> compare(String current, String previous) async {
    final response = await ApiClient.shared.get<Map<String, dynamic>>(
        '/api/body/compare',
        queryParameters: {'currentId': current, 'previousId': previous});
    return BodyComparison.fromJson(response.data!);
  }

  Future<BodyAssessment> entry(String id) async {
    await _requireSession();
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>('/api/body/entries/$id');
    return BodyAssessment.fromJson(response.data!);
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
    return BodyAssessment.fromJson(response.data!);
  }

  Future<void> delete(String id) =>
      ApiClient.shared.delete<void>('/api/body/entries/$id');
  Future<BodyAssessment> deletePhotos(String id) async {
    await _requireSession();
    final response = await ApiClient.shared
        .delete<Map<String, dynamic>>('/api/body/entries/$id/photos');
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
                  entry.visualCoachingConsent && entry.photos.length == 4
            },
            options: Options(receiveTimeout: const Duration(seconds: 180)));
    if (cancelled() || await CacheScope.userId() != owner) {
      throw StateError('Report update cancelled.');
    }
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
