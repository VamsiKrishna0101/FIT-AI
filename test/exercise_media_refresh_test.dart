import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/core/media/video_cache.dart';
import 'package:setcraft/features/train/repositories/workout_repository.dart';

class _Adapter implements HttpClientAdapter {
  String url = 'https://media.example/videos/0025.gif';
  bool offline = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    return ResponseBody.fromString(
        jsonEncode(offline
            ? {'error': 'Offline'}
            : {
                'data': {
                  'id': 'media-refresh-test',
                  'name': 'Barbell Bench Press',
                  'url': url,
                  'instructions': ['Press with control.'],
                }
              }),
        offline ? 503 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

class _CatalogAdapter implements HttpClientAdapter {
  String url = 'https://media.example/female.mp4';
  int requests = 0;
  bool offline = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests++;
    final exercise = {
      'id': 'scoped-exercise',
      'name': 'Dumbbell Curl',
      'url': url
    };
    final page = options.queryParameters.containsKey('page');
    final detail = options.path.endsWith('/scoped-exercise');
    final body = offline
        ? {'error': 'Offline'}
        : {
            'data': detail ? exercise : [exercise],
            if (page)
              'pagination': {
                'page': 1,
                'pageSize': 24,
                'total': 1,
                'totalPages': 1,
                'hasNext': false
              },
            if (page) 'filters': {'bodyParts': [], 'equipment': []},
          };
    return ResponseBody.fromString(jsonEncode(body), offline ? 503 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'reopening replaces a cached GIF with MP4 and retains the updated offline guide',
      () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'test-media',
        refreshToken: 'test-refresh',
        userId: 'test-media-user');
    final original = ApiClient.shared.client.httpClientAdapter;
    final adapter = _Adapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    expect((await repo.getExerciseDetail('media-refresh-test'))!.isGif, true);
    adapter.url = 'https://media.example/videos/0025-contenthash.mp4';
    final updated = (await repo.getExerciseDetail('media-refresh-test'))!;
    expect(updated.url, adapter.url);
    expect(updated.isGif, false);
    expect(VideoAssetCache.isVideo(updated.url), true);
    adapter.offline = true;
    final cached = (await repo.getExerciseDetail('media-refresh-test'))!;
    expect(cached.url, adapter.url);
    expect(cached.instructions, ['Press with control.']);
  });

  test('catalogue media and offline guides stay scoped when accounts switch',
      () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    Future<void> signIn(String owner) => SecureSessionStore.shared.saveTokens(
        accessToken: 'test-$owner',
        refreshToken: 'refresh-$owner',
        userId: owner);
    final original = ApiClient.shared.client.httpClientAdapter;
    final adapter = _CatalogAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    await signIn('female-catalogue-test');
    expect((await repo.getAllExercises(forceRefresh: true)).single.url,
        adapter.url);
    expect((await repo.getExercisePage()).exercises.single.url, adapter.url);
    expect((await repo.getExerciseDetail('scoped-exercise'))!.url, adapter.url);
    final firstRequests = adapter.requests;
    adapter.url = 'https://media.example/male.mp4';
    await signIn('male-catalogue-test');
    expect((await repo.getExercisePage()).exercises.single.url, adapter.url);
    expect((await repo.getAllExercises()).single.url, adapter.url);
    expect(adapter.requests, greaterThan(firstRequests));
    adapter.offline = true;
    expect(await repo.getExerciseDetail('scoped-exercise'), isNull,
        reason: 'Another account\'s offline guide is not a fallback');
  });

  test('profile media changes invalidate the same account catalogue', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'test-profile-media',
        refreshToken: 'refresh-profile-media',
        userId: 'profile-media-test');
    final original = ApiClient.shared.client.httpClientAdapter;
    final adapter = _CatalogAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    expect((await repo.getExercisePage()).exercises.single.url, adapter.url);
    adapter.url = 'https://media.example/updated.mp4';
    await repo.invalidateExerciseMedia();
    expect((await repo.getExercisePage()).exercises.single.url, adapter.url);
  });

  test('A profile media change removes the previous offline form guide',
      () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'offline-profile',
        refreshToken: 'refresh',
        userId: 'offline-profile-user');
    final original = ApiClient.shared.client.httpClientAdapter;
    final adapter = _CatalogAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    expect((await repo.getExerciseDetail('scoped-exercise'))!.url, adapter.url);
    await repo.invalidateExerciseMedia();
    adapter.offline = true;
    expect(await repo.getExerciseDetail('scoped-exercise'), isNull);
  });
}
