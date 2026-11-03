import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/navigation/profile_setup_gate.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/auth/data/auth_repository.dart';

class _ProfileAdapter implements HttpClientAdapter {
  bool exists = false, failSave = false;
  int? getStatus;
  Map<String, dynamic>? saved;
  final methods = <String>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    expect(options.path, '/api/onboarding');
    methods.add(options.method);
    final status = options.method == 'GET'
        ? (getStatus ?? (exists ? 200 : 404))
        : failSave
            ? 503
            : 201;
    if (options.method == 'POST' && !failSave) {
      saved = Map<String, dynamic>.from(options.data as Map);
      exists = true;
    }
    return ResponseBody.fromString(
        jsonEncode(status >= 400
            ? {'message': 'Profile request unavailable'}
            : {'success': true, 'data': {}}),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

OnboardingDraft _draft({int age = 27}) => OnboardingDraft(
    name: 'Test member',
    age: age,
    gender: 'FEMALE',
    heightCm: 165,
    weightKg: 65,
    workingToward: 'BUILD_MUSCLE',
    experienceLevel: 'BEGINNER',
    daysPerWeek: 'DAYS_3',
    workoutDuration: 'MIN_30',
    trainingLocation: 'HOME',
    equipmentIds: ['dumbbells'],
    activityLevel: 'MODERATE',
    sleepDuration: 'HOURS_7_TO_8',
    eatingStyle: 'VEGETARIAN');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ProfileAdapter adapter;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'test-token', 'fitai_user_id': 'test-member'});
    SharedPreferences.setMockInitialValues({});
    await OnboardingDraft.clear();
    adapter = _ProfileAdapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  test('reset account saves confirmed setup, including actual age', () async {
    final draft = _draft();
    await draft.save();
    await AuthRepository().completeMissingProfile(draft);
    expect(adapter.methods, ['GET', 'POST']);
    expect(adapter.saved?['age'], 27);
    expect(adapter.saved?['gender'], 'FEMALE');
    expect((await OnboardingDraft.load()).age, isNull);
  });
  test('Training setup saves without fabricated body measurements', () async {
    final draft = _draft()
      ..heightCm = null
      ..weightKg = null
      ..targetWeightKg = null;
    await AuthRepository().completeMissingProfile(draft);
    expect(adapter.saved?['age'], 27);
    for (final field in ['height', 'weight', 'targetWeight']) {
      expect(adapter.saved!.containsKey(field), false);
    }
  });
  test('existing profile is never overwritten by a device draft', () async {
    adapter.exists = true;
    await AuthRepository().completeMissingProfile(_draft());
    expect(adapter.methods, ['GET']);
    expect(adapter.saved, isNull);
  });
  test('minor age is preserved instead of silently promoted to adult',
      () async {
    await AuthRepository().completeMissingProfile(_draft(age: 17));
    expect(adapter.saved?['age'], 17);
  });
  test('failed save retains the draft for retry', () async {
    adapter.failSave = true;
    final draft = _draft();
    await draft.save();
    await expectLater(AuthRepository().completeMissingProfile(draft),
        throwsA(isA<DioException>()));
    expect((await OnboardingDraft.load()).age, 27);
  });
  test('server failure does not masquerade as missing profile', () async {
    adapter.getStatus = 500;
    await expectLater(AuthRepository().completeMissingProfile(_draft()),
        throwsA(isA<DioException>()));
    expect(adapter.methods, ['GET']);
  });
  testWidgets('missing profile opens setup before personalized app',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ProfileSetupGate(
            setup: Text('Complete setup'), child: Text('Personalized app'))));
    await tester.pumpAndSettle();
    expect(find.text('Complete setup'), findsOneWidget);
    expect(find.text('Personalized app'), findsNothing);
  });
  testWidgets('saved profile opens app without repeated onboarding',
      (tester) async {
    adapter.exists = true;
    await tester.pumpWidget(const MaterialApp(
        home: ProfileSetupGate(
            setup: Text('Complete setup'), child: Text('Personalized app'))));
    await tester.pumpAndSettle();
    expect(find.text('Personalized app'), findsOneWidget);
    expect(find.text('Complete setup'), findsNothing);
  });
  testWidgets('network failure offers retry without bypassing profile check',
      (tester) async {
    adapter.getStatus = 500;
    await tester.pumpWidget(const MaterialApp(
        home: ProfileSetupGate(
            setup: Text('Complete setup'), child: Text('Personalized app'))));
    await tester.pumpAndSettle();
    expect(find.text('Personalized app'), findsNothing);
    expect(find.text('Complete setup'), findsNothing);
    adapter.getStatus = null;
    adapter.exists = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Personalized app'), findsOneWidget);
  });
}
