import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/cache/app_data_mode.dart';
import 'package:setcraft/core/cache/cache_scope.dart';
import 'package:setcraft/core/database/cache_manager.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/local_cache.dart';
import 'package:setcraft/features/today/repositories/today_repository.dart';
import 'package:setcraft/features/wellness/repositories/wellness_repository.dart';
import 'package:setcraft/features/today/views/today_home_view.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/wellness/views/daily_check_in_sheet.dart';

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic> home = {};
  Object? saveResponse;
  String usage = 'NONE';
  bool offline = false;
  Completer<ResponseBody>? heldHome, heldSave;

  ResponseBody response(Object? data, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(data), status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });

  @override
  Future<ResponseBody> fetch(RequestOptions request, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    if (offline) return response({'error': 'Unavailable'}, 502);
    if (request.path == '/api/home') {
      if (heldHome != null) return await heldHome!.future;
      return response(home);
    }
    if (request.path == '/api/wellness/wearable') {
      if (request.method == 'PUT') usage = request.data['usage'] as String;
      return response({
        'data': {'usage': usage}
      });
    }
    if (request.method == 'PUT') {
      if (heldSave != null) return await heldSave!.future;
      return response({'data': saveResponse});
    }
    return response({'data': null});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Adapter adapter;
  late String owner, date;
  var accountNumber = 0;

  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('fitai-sleep-test-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    await CacheManager.shared.db.customSelect('SELECT 1').get();
    addTearDown(() async {
      await CacheManager.shared.db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });
  });

  String token(String user) =>
      '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
            'userId': user
          })))}.test';

  setUp(() async {
    owner = 'wellness-test-${accountNumber++}';
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': token(owner), 'fitai_user_id': owner});
    SharedPreferences.setMockInitialValues({});
    await LocalCache.shared.removeByPrefix(CacheScope.userPrefix);
    await AppDataMode.shared.ensureOwner();
    date = CacheScope.todayKey();
    adapter = _Adapter();
    adapter.home = {
      'calendarDate': date,
      'dataVersion': 12,
      'wearableUsage': 'NONE',
      'user': {'name': 'Test'},
      'nutrition': {},
      'weeklyStreak': [],
    };
    final old = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = old);
    await TodayRepository.shared.initialize();
    await TodayRepository.shared.fetchFresh(forceRefresh: true);
  });

  Map<String, dynamic> entry() => {
        'date': date,
        'sleepMinutes': 480,
        'energy': 3,
        'rested': 3,
        'soreness': 3,
        'source': 'self_report',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'wearableUsage': 'NONE',
        'readiness': {
          'score': 7,
          'label': 'Daily check-in estimate',
          'source': 'check_in_estimate',
          'date': date,
          'sleepMinutes': 480
        },
      };

  testWidgets(
      'Saving a complete check-in updates Today and survives stale refresh',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    adapter.saveResponse = {
      ...entry(),
      'rested': 5,
      'energy': 5,
      'soreness': 1,
      'readiness': {...(entry()['readiness'] as Map), 'score': 10},
    };
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    if (find.byType(DailyCheckInSheet).evaluate().isEmpty) {
      final action = find.byKey(const ValueKey('today-readiness-card'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('readiness-detail-update')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField).first, '8');
    await tester.enterText(find.byType(TextField).at(1), '0');
    for (final key in [
      'check-in-rest-5',
      'check-in-energy-5',
      'check-in-soreness-1',
      'daily-check-in-save'
    ]) {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pumpAndSettle();
    expect(find.byType(DailyCheckInSheet), findsNothing);
    final card = find.byKey(const ValueKey('today-readiness-card'));
    expect(find.descendant(of: card, matching: find.text('Check-in saved')),
        findsNothing);
    expect(
        find.descendant(of: card, matching: find.text('100')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Energized')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Well rested')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('readiness-complete-check-in')),
        findsNothing);
    expect(
        find.byKey(const ValueKey('readiness-update-check-in')), findsNothing);
    adapter.offline = true;
    await tester.runAsync(() =>
        tester.widget<TodayDashboard>(find.byType(TodayDashboard)).onRefresh());
    await tester.pumpAndSettle();
    expect(
        find.descendant(of: card, matching: find.text('100')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Check-in saved')),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('Malformed success responses never become confirmed sleep', () async {
    adapter.saveResponse = {'message': 'ok'};
    await expectLater(
        WellnessRepository.shared.save(date, 480, 3, rested: 3, soreness: 3),
        throwsStateError);
    expect(TodayRepository.shared.current?.sleepLog, isNull);
  });

  test(
      'Confirmed sleep and its score survive an older response and offline refresh',
      () async {
    adapter.saveResponse = entry();
    final saved = await WellnessRepository.shared
        .save(date, 480, 3, rested: 3, soreness: 3);
    expect(saved['sleepMinutes'], 480);
    expect(TodayRepository.shared.current?.sleepLog?['sleepMinutes'], 480);
    expect(TodayRepository.shared.current?.readiness?.score, 7);
    // A stale server/cache response must not erase the acknowledged write.
    await TodayRepository.shared.fetchFresh(forceRefresh: true);
    expect(TodayRepository.shared.current?.sleepLog?['sleepMinutes'], 480);
    await TodayRepository.shared.loadDate(DateTime.now(), forceRefresh: true);
    expect(TodayRepository.shared.current?.sleepLog?['sleepMinutes'], 480);
    adapter.offline = true;
    final cached = await TodayRepository.shared
        .loadDate(DateTime.now(), forceRefresh: true);
    expect(cached?.sleepLog?['sleepMinutes'], 480);
    expect(cached?.readiness?.source, 'check_in_estimate');
    expect(TodayRepository.shared.refreshFailedFor(DateTime.now()), true);
  });

  test('A newer saved entry is accepted and belongs only to its account',
      () async {
    final saved = entry();
    adapter.saveResponse = saved;
    await WellnessRepository.shared.save(date, 480, 3, rested: 3, soreness: 3);
    adapter.home = {
      ...adapter.home,
      'sleepLog': {
        ...saved,
        'sleepMinutes': 420,
        'updatedAt': DateTime.now()
            .add(const Duration(minutes: 1))
            .toUtc()
            .toIso8601String()
      },
      'readiness': null,
    };
    await TodayRepository.shared.fetchFresh(forceRefresh: true);
    expect(TodayRepository.shared.current?.sleepLog?['sleepMinutes'], 420);
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': token('other-owner'),
      'fitai_user_id': 'other-owner'
    });
    await AppDataMode.shared.ensureOwner();
    adapter.home = {...adapter.home, 'sleepLog': null};
    await TodayRepository.shared.initialize();
    await TodayRepository.shared.fetchFresh(forceRefresh: true);
    expect(TodayRepository.shared.current?.sleepLog, isNull);
  });

  test('Saved wearable choice survives a backend outage', () async {
    await WellnessRepository.shared.setWearableUsage('WEARABLE');
    adapter.offline = true;
    expect(await WellnessRepository.shared.wearableUsage(), 'WEARABLE');
  });

  test('Switching to a wearable preserves a saved manual check-in score',
      () async {
    adapter.saveResponse = entry();
    await WellnessRepository.shared.save(date, 480, 3, rested: 3, soreness: 3);
    adapter.heldHome = Completer<ResponseBody>();
    await WellnessRepository.shared.setWearableUsage('WEARABLE');
    expect(TodayRepository.shared.current?.wearableUsage, 'WEARABLE');
    expect(
        TodayRepository.shared.current?.readiness?.source, 'check_in_estimate');
    expect(TodayRepository.shared.current?.sleepLog?['sleepMinutes'], 480);
    adapter.heldHome!.complete(adapter.response({
      ...adapter.home,
      'wearableUsage': 'WEARABLE',
      'sleepLog': adapter.saveResponse,
      'readiness': null,
    }));
    await TodayRepository.shared.fetchFresh();
    expect(TodayRepository.shared.current?.readiness, isNull);
  });

  test('Switching accounts during a save never confirms it for the new account',
      () async {
    adapter.heldSave = Completer<ResponseBody>();
    final saving =
        WellnessRepository.shared.save(date, 480, 3, rested: 3, soreness: 3);
    final expectation = expectLater(saving, throwsA(anything));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': token('other-owner'),
      'fitai_user_id': 'other-owner'
    });
    await AppDataMode.shared.ensureOwner();
    adapter.heldSave!.complete(adapter.response({'data': entry()}));
    await expectation;
    expect(TodayRepository.shared.current, isNull);
  });
}
