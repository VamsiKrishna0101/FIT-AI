import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/auth/data/auth_repository.dart';
import 'package:fitai_mobile/features/body_scan/views/body_view.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/body_focus_panel.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';

String _token(String owner) =>
    '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.'
    '${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.synthetic-signature';

class _Adapter implements HttpClientAdapter {
  final paths = <String>[];
  Map<String, dynamic>? registration;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add(options.path);
    final Object response;
    if (options.path.endsWith('/login') || options.path.endsWith('/register')) {
      if (options.path.endsWith('/register')) {
        registration = Map<String, dynamic>.from(options.data as Map);
      }
      response = {
        'user': {'id': 'signed-in-owner', 'email': 'synthetic@example.test'},
        'tokens': {
          'accessToken': 'opaque-test-token',
          'refreshToken': 'synthetic-refresh'
        }
      };
    } else if (options.path == '/api/body') {
      response = {
        'profile': {
          'gender': 'MALE',
          'height': 175,
          'weight': 75,
          'focusMuscles': []
        },
        'records': [
          {
            'id': 'saved-body',
            'recordedDate': '2026-10-07',
            'updatedAt': '2026-10-07T10:00:00.000Z',
            'status': 'SAVED',
            'method': 'photo_review',
            'metrics': {
              'weightKg': {'value': 75, 'source': 'profile'}
            },
            'photos': [
              {
                'id': 'private-photo',
                'view': 'front',
                'url': '/api/body/photos/private-photo'
              }
            ],
            'summary': 'Synthetic saved focus.',
            'quality': {'focusStatus': 'ready'},
            'observations': [
              {
                'region': 'chest',
                'kind': 'suggested_focus',
                'basis': 'profile_goal',
                'observation': 'Synthetic goal-based guidance.'
              }
            ]
          }
        ]
      };
    } else if (options.path == '/api/heatmap/training') {
      response = jsonDecode(
          File('test/fixtures/training_map.json').readAsStringSync());
    } else {
      throw StateError('Unexpected test request ${options.path}');
    }
    return ResponseBody.fromString(jsonEncode(response), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => initializeDateFormatting());
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  test('login persists the authenticated response user ID, not only tokens',
      () async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final auth = await AuthRepository().signIn(
        email: 'synthetic@example.test', password: 'synthetic-password');
    expect(auth.user.id, 'signed-in-owner');
    expect(await SecureSessionStore.shared.userId, 'signed-in-owner');
    expect(await CacheScope.userId(), 'signed-in-owner');
  });
  test(
      'registration sends onboarding without a companion and clears draft after success',
      () async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final draft = OnboardingDraft(
        workingToward: 'BUILD_MUSCLE',
        name: 'Synthetic member',
        age: 27,
        gender: 'MALE',
        heightCm: 178,
        weightKg: 80,
        experienceLevel: 'BEGINNER',
        daysPerWeek: 'DAYS_3',
        workoutDuration: 'MIN_30',
        trainingLocation: 'HOME',
        equipmentIds: ['dumbbells'],
        activityLevel: 'MODERATE',
        sleepDuration: 'HOURS_7_TO_8',
        eatingStyle: 'VEGETARIAN');
    await draft.save();
    await AuthRepository().registerVerifiedEmail(
        email: 'synthetic@example.test',
        password: 'synthetic-password',
        draft: draft);
    expect(adapter.registration?.containsKey('companion'), isFalse);
    expect((adapter.registration?['onboarding'] as Map)['weight'], 80);
    expect((adapter.registration?['onboarding'] as Map)['equipmentIds'],
        ['dumbbells']);
    expect((await OnboardingDraft.load()).weightKg, isNull);
    expect(await CacheScope.userId(), 'signed-in-owner');
  });
  test(
      'existing token-only sessions recover cache identity without logging in again',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': _token('existing-owner')});
    expect(await CacheScope.userId(), 'existing-owner');
    expect(await const FlutterSecureStorage().read(key: 'fitai_user_id'),
        'existing-owner');
  });
  test('a new account does not inherit the previous account cache identity',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': _token('new-owner'),
      'fitai_user_id': 'previous-owner'
    });
    expect(await CacheScope.userId(), 'new-owner');
    await SecureSessionStore.shared.clear();
    expect(await CacheScope.userId(), 'anonymous');
  });
  testWidgets(
      'token-only session loads saved Body history and prefills onboarding weight',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': _token('existing-owner')});
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: BodyView(onTrain: () {})));
    await tester.pumpAndSettle();
    expect(adapter.paths, contains('/api/body'));
    await tester.tap(find.text('Physique'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to see your body assessments.'), findsNothing);
    expect(
        tester
            .widget<BodyFocusPanel>(find.byType(BodyFocusPanel))
            .assessment
            ?.id,
        isNull,
        reason: 'An entered measurement is not a photo assessment');
    await tester.tap(find.text('Photo scan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(TextField), 180,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '75.0');
    expect(tester.takeException(), isNull);
  });
}
