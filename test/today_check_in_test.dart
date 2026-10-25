import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/core/health/health_models.dart';
import 'package:fitai_mobile/core/health/health_sync_service.dart';
import 'package:fitai_mobile/core/health/phone_sleep_service.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/today/models/daily_check_in_prompt.dart';
import 'package:fitai_mobile/features/today/views/today_home_view.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/features/wellness/views/daily_check_in_sheet.dart';
import 'package:fitai_mobile/features/wellness/repositories/wellness_repository.dart';
import 'today_date_filter_test.dart' show DateAdapter;
import 'health_connection_test.dart' show FakeHealth;

class PromptAdapter extends DateAdapter {
  bool syncedSleep = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    final response = await super.fetch(options, body, cancel);
    if (options.path != '/api/home') return response;
    final data = jsonDecode(await utf8.decoder.bind(response.stream).join())
        as Map<String, dynamic>;
    data['sleepLog'] = null;
    data['readiness'] = null;
    if (syncedSleep) {
      data['healthMetrics'] = {
        'date': CacheScope.todayKey(),
        'source': 'APPLE_HEALTHKIT',
        'sleepMinutes': 450
      };
    }
    return ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }
}

class CheckInRepo extends WellnessRepository {
  Map<String, dynamic>? saved;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> save(String date, int minutes, int? energy,
      {int? rested, int? soreness, PhoneSleepEstimate? estimate}) async {
    if (fail) throw StateError('Offline');
    return saved = {
      'date': date,
      'sleepMinutes': minutes,
      'energy': energy,
      'rested': rested,
      'soreness': soreness
    };
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final owner = 'checkin-${DateTime.now().microsecondsSinceEpoch}';
    final token =
        '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';
    await SecureSessionStore.shared
        .saveTokens(accessToken: token, refreshToken: 'test');
  });

  test('Prompt is once per account/local date, including concurrent claims',
      () async {
    final owner = await CacheScope.userId();
    final day = DateTime(2026, 10, 22);
    expect(
        await Future.wait([
          DailyCheckInPrompt.claim(owner, day),
          DailyCheckInPrompt.claim(owner, day)
        ]),
        [true, false]);
    expect(await DailyCheckInPrompt.claim(owner, day), isFalse);
    expect(
        await DailyCheckInPrompt.claim(owner, DateTime(2026, 10, 23)), isTrue);
    expect(await DailyCheckInPrompt.claim('$owner-other', day), isTrue);
    final storedOwner = '$owner-stored';
    await (await SharedPreferences.getInstance())
        .setBool('setcraft_check_in_prompt_v1_${storedOwner}_2026-10-22', true);
    expect(await DailyCheckInPrompt.claim(storedOwner, day), isFalse);
    expect(await DailyCheckInPrompt.claim('anonymous', day), isFalse);
  });

  for (final synced in [false, true]) {
    testWidgets(
        synced
            ? 'Synced sleep suppresses automatic prompt'
            : 'Missing sleep opens once and X dismissal survives refresh and tab return',
        (tester) async {
      final adapter = PromptAdapter()..syncedSleep = synced;
      final old = ApiClient.shared.client.httpClientAdapter;
      ApiClient.shared.client.httpClientAdapter = adapter;
      addTearDown(() => ApiClient.shared.client.httpClientAdapter = old);
      Widget app(bool active) => MaterialApp(
          home: TodayHomeView(
              isActive: active, onSelectTab: (_) {}, onOpenProfile: () {}));
      await tester.pumpWidget(app(true));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('daily-check-in-sheet'));
      expect(sheet, synced ? findsNothing : findsOneWidget);
      if (!synced) {
        await tester.tap(find.byKey(const ValueKey('daily-check-in-close')));
        await tester.pumpAndSettle();
        unawaited(tester
            .widget<TodayDashboard>(find.byType(TodayDashboard))
            .onRefresh());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(false));
        await tester.pumpWidget(app(true));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'Sheet prefills synced sleep, saves ratings and allows sleep alone',
      (tester) async {
    final repo = CheckInRepo();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDailyCheckInSheet(context,
                        date: DateTime(2026, 10, 22),
                        syncedSleepMinutes: 450,
                        repository: repo),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '7');
    for (final key in [
      'check-in-rest-3',
      'check-in-energy-5',
      'check-in-soreness-1',
      'daily-check-in-save'
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }
    expect(repo.saved, {
      'date': '2026-10-22',
      'sleepMinutes': 450,
      'energy': 5,
      'rested': 3,
      'soreness': 1
    });
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('daily-check-in-save')));
    await tester.tap(find.byKey(const ValueKey('daily-check-in-save')));
    await tester.pumpAndSettle();
    expect(repo.saved!['sleepMinutes'], 450);
    expect(repo.saved!['energy'], isNull);
    expect(tester.takeException(), isNull);
  });

  test('Health integration requests no heart permissions on either platform',
      () {
    for (final provider in [
      HealthProviderType.appleHealthKit,
      HealthProviderType.googleHealthConnect
    ]) {
      final types =
          HealthSyncService.forTesting(health: FakeHealth(), provider: provider)
              .types();
      expect(types, contains(HealthDataType.STEPS));
      expect(types, contains(HealthDataType.SLEEP_ASLEEP));
      expect(types, isNot(contains(HealthDataType.RESTING_HEART_RATE)));
      expect(
          types, isNot(contains(HealthDataType.HEART_RATE_VARIABILITY_RMSSD)));
      expect(
          types, isNot(contains(HealthDataType.HEART_RATE_VARIABILITY_SDNN)));
      expect(types, isNot(contains(HealthDataType.WEIGHT)));
    }
  });
}
