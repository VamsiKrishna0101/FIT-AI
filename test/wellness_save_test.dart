import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/app_data_mode.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/core/database/cache_manager.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/local_cache.dart';
import 'package:fitai_mobile/features/today/repositories/today_repository.dart';
import 'package:fitai_mobile/features/wellness/repositories/wellness_repository.dart';

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
