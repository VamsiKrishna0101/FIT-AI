import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/components/liquid_chrome_button.dart';
import 'package:fitai_mobile/core/health/health_models.dart';
import 'package:fitai_mobile/core/health/health_normalizer.dart';
import 'package:fitai_mobile/core/health/health_sync_service.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/health/views/health_setup_gate.dart';
import 'package:fitai_mobile/features/health/views/health_connection_view.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/models/home_models.dart';

HealthDataPoint point(HealthDataType type, DateTime from, DateTime to,
        {String id = 'sample',
        String source = 'watch',
        double value = 1,
        HealthValue? healthValue}) =>
    HealthDataPoint(
        uuid: id,
        value: healthValue ?? NumericHealthValue(numericValue: value),
        type: type,
        unit: HealthDataUnit.COUNT,
        dateFrom: from,
        dateTo: to,
        sourcePlatform: HealthPlatformType.googleHealthConnect,
        sourceDeviceId: 'device',
        sourceId: source,
        sourceName: source);

class FakeHealth extends Health {
  Set<HealthDataType> supported = {
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE
  };
  Set<HealthDataType> granted = {};
  int authCalls = 0, reads = 0;
  List<HealthDataType> lastRequested = [];
  bool authorizeResult = false;
  int? total = 123;
  Completer<int?>? heldSteps;
  DateTime? stepsFrom, stepsTo;
  final queries = <({HealthDataType type, DateTime from, DateTime to})>[];
  List<HealthDataPoint> points = [];
  @override
  Future<void> configure() async {}
  @override
  bool isDataTypeAvailable(HealthDataType type) => supported.contains(type);
  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async =>
      HealthConnectSdkStatus.sdkAvailable;
  @override
  Future<bool?> hasPermissions(List<HealthDataType> types,
          {List<HealthDataAccess>? permissions}) async =>
      types.every(granted.contains);
  @override
  Future<bool> requestAuthorization(List<HealthDataType> types,
      {List<HealthDataAccess>? permissions}) async {
    authCalls++;
    expect(permissions, everyElement(HealthDataAccess.READ));
    lastRequested = types;
    return authorizeResult;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
      {required List<HealthDataType> types,
      Map<HealthDataType, HealthDataUnit>? preferredUnits,
      required DateTime startTime,
      required DateTime endTime,
      List<RecordingMethod> recordingMethodsToFilter = const []}) async {
    reads++;
    queries.add((type: types.single, from: startTime, to: endTime));
    return points.where((p) => types.contains(p.type)).toList();
  }

  @override
  Future<int?> getTotalStepsInInterval(DateTime startTime, DateTime endTime,
      {bool includeManualEntry = true}) async {
    reads++;
    stepsFrom = startTime;
    stepsTo = endTime;
    if (heldSteps != null) return await heldSteps!.future;
    return total;
  }
}

class HealthAdapter implements HttpClientAdapter {
  final posts = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    if (o.path == '/api/home') {
      return ResponseBody.fromString('{"error":"Unavailable"}', 503, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (o.path == '/api/healthkit/sync') {
      posts.add(Map<String, dynamic>.from(o.data as Map));
      if (fail) {
        return ResponseBody.fromString('{"error":"Offline"}', 503, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
      }
    }
    final Object data = o.path == '/api/healthkit/sync'
        ? {
            'data': {'recoveryScore': null, 'aiNote': null}
          }
        : {'data': null};
    return ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> signIn(String owner) => SecureSessionStore.shared.saveTokens(
    accessToken:
        '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test',
    refreshToken: 'test');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  const normalizer = HealthNormalizer();
  final date = DateTime(2026, 10, 10);
  late FakeHealth health;
  late HealthAdapter adapter;
  late HealthSyncService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await signIn('health-owner');
    health = FakeHealth();
    adapter = HealthAdapter();
    final old = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = old);
    service = HealthSyncService.forTesting(
        health: health,
        provider: HealthProviderType.googleHealthConnect,
        now: () => DateTime(2026, 10, 10, 12));
    addTearDown(service.dispose);
  });
  test(
      'sleep union excludes awake and does not double-count stages or duplicate UUIDs',
      () {
    final start = DateTime(2026, 10, 9, 22), end = DateTime(2026, 10, 10, 6);
    final generic = point(HealthDataType.SLEEP_ASLEEP, start, end);
    final payload = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        dataPoints: [
          generic,
          generic,
          point(HealthDataType.SLEEP_DEEP, start, DateTime(2026, 10, 10, 1),
              id: 'deep'),
          point(HealthDataType.SLEEP_AWAKE, DateTime(2026, 10, 10, 2),
              DateTime(2026, 10, 10, 2, 30),
              id: 'awake'),
          point(HealthDataType.SLEEP_ASLEEP, DateTime(2026, 10, 8, 22),
              DateTime(2026, 10, 9, 6),
              id: 'old-night'),
        ]);
    expect(payload.sleepTotalMinutes, 450);
    expect(payload.sleepDeepMinutes, 180);
    expect(payload.sleepEfficiency, isNull);
    expect(payload.metricMetadata['sleepTotalMinutes']!['source'], 'watch');
  });
  test('movement is platform-aggregated, not raw mirrored or overnight steps',
      () {
    final payload = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        aggregatedSteps: 0,
        energyAggregated: true,
        aggregatedActiveCalories: 17,
        dataPoints: [
          point(HealthDataType.STEPS, date, date.add(const Duration(hours: 1)),
              value: 200),
          point(HealthDataType.ACTIVE_ENERGY_BURNED, date,
              date.add(const Duration(hours: 1)),
              value: 500),
        ]);
    expect(payload.steps, 0);
    expect(payload.activeCalories, 17);
    expect(payload.toJson().containsKey('restingHR'), false);
    expect(payload.metricMetadata['activeCalories']!['method'],
        'platform_aggregate');
  });
  test(
      'Android stages sharing a UUID retain pre-midnight intervals and respect origin names',
      () {
    final a = point(HealthDataType.SLEEP_DEEP, DateTime(2026, 10, 9, 23),
        DateTime(2026, 10, 9, 23, 30),
        id: 'night');
    final b = point(HealthDataType.SLEEP_DEEP, DateTime(2026, 10, 9, 23, 30),
        DateTime(2026, 10, 10, 1),
        id: 'night');
    final c = point(HealthDataType.SLEEP_LIGHT, DateTime(2026, 10, 10, 1),
        DateTime(2026, 10, 10, 6),
        id: 'night');
    final mirror = point(HealthDataType.SLEEP_ASLEEP, DateTime(2026, 10, 9, 22),
        DateTime(2026, 10, 10, 7),
        id: 'mirror', source: 'mirror-app');
    for (final p in [a, b, c, mirror]) {
      p.sourceId = '';
    }
    final payload = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        dataPoints: [a, b, c, mirror, a]);
    expect(payload.sleepDeepMinutes, 120);
    expect(payload.sleepTotalMinutes, 420);
    expect(payload.metricMetadata['sleepTotalMinutes']!['source'], 'watch');
  });
  test('Apple in-bed time alone is not reported as time asleep', () {
    final payload = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.appleHealthKit,
        dataPoints: [
          point(HealthDataType.SLEEP_IN_BED, DateTime(2026, 10, 9, 22),
              DateTime(2026, 10, 10, 6)),
        ]);
    expect(payload.sleepTotalMinutes, isNull);
    expect(payload.sleepEfficiency, isNull);
  });
  test('HRV methods stay distinct and body readings use the latest sample', () {
    final raw = [
      point(HealthDataType.HEART_RATE_VARIABILITY_RMSSD, date, date, value: 52),
      point(HealthDataType.HEART_RATE_VARIABILITY_SDNN, date, date, value: 31),
      point(HealthDataType.WEIGHT, date, date.add(const Duration(hours: 1)),
          value: 82, id: 'weight-old'),
      point(HealthDataType.WEIGHT, date, date.add(const Duration(hours: 3)),
          value: 81, id: 'weight-new')
    ];
    final android = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        dataPoints: raw);
    final apple = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.appleHealthKit,
        dataPoints: raw);
    expect(android.hrv, 52);
    expect(android.hrvMethod, 'RMSSD');
    expect(apple.hrv, 31);
    expect(apple.hrvMethod, 'SDNN');
    expect(apple.weight, 81);
  });
  test('workout IDs are stable; unavailable calories are not fabricated', () {
    final p = point(
        HealthDataType.WORKOUT, date, date.add(const Duration(minutes: 30)),
        id: 'stable',
        healthValue: WorkoutHealthValue(
            workoutActivityType: HealthWorkoutActivityType.RUNNING));
    final a = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        dataPoints: [p, p]);
    final b = normalizer.normalize(
        targetDate: date,
        provider: HealthProviderType.googleHealthConnect,
        dataPoints: [p]);
    expect(a.externalWorkouts.length, 1);
    expect(a.externalWorkouts.single.externalId,
        b.externalWorkouts.single.externalId);
    expect(a.externalWorkouts.single.toJson().containsKey('activeCalories'),
        false);
  });
  test('setup is optional and account-scoped with no automatic authorization',
      () async {
    expect(await service.needsSetup(), true);
    await service.initialize();
    expect(health.authCalls, 0);
    expect(health.reads, 0);
    await service.skipSetup();
    expect(await service.needsSetup(), false);
    await service.syncIfEnabled();
    expect(health.reads, 0);
    await signIn('other-health-owner');
    expect(await service.needsSetup(), true);
  });
  test(
      'partial Android read access works even when authorization returns false',
      () async {
    health.granted = {HealthDataType.STEPS};
    expect(await service.requestPermissions(), true);
    expect(health.lastRequested, isNot(contains(HealthDataType.WEIGHT)));
    expect(service.readableTypes, {HealthDataType.STEPS});
    final result = await service.syncToday();
    expect(result.success, true);
    expect(result.snapshot!.steps, 123);
    expect(adapter.posts.single.keys, isNot(contains('sleepTotalMinutes')));
    expect(health.stepsFrom, date);
    expect(health.stepsTo, DateTime(2026, 10, 10, 12));
  });
  test(
      'Next-day login preserves health sharing and syncs without reauthorization',
      () async {
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    expect((await service.syncToday()).success, true);
    final calls = health.authCalls;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fitai_health_v2_health-owner_history_done', true);
    await SecureSessionStore.shared.clear();
    await signIn('health-owner');
    final nextDay = HealthSyncService.forTesting(
        health: health,
        provider: HealthProviderType.googleHealthConnect,
        now: () => DateTime(2026, 10, 11, 12));
    addTearDown(nextDay.dispose);
    expect(await nextDay.needsSetup(), false);
    await nextDay.syncIfEnabled();
    expect(nextDay.enabled, true);
    expect(health.authCalls, calls);
    expect(adapter.posts.last['date'], '2026-10-11');
    expect(nextDay.lastSyncTime, DateTime(2026, 10, 11, 12));
  });
  test('Existing enabled choice repairs a missing setup marker', () async {
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fitai_health_v2_health-owner_decided');
    expect(await service.needsSetup(), false);
    expect(prefs.getBool('fitai_health_v2_health-owner_decided'), true);
    expect(prefs.getBool('fitai_health_v2_health-owner_enabled'), true);
  });
  test('Previous sync does not re-enable a disconnected or different account',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'fitai_health_v2_health-owner_last_sync', date.millisecondsSinceEpoch);
    await prefs.setBool('fitai_health_v2_health-owner_enabled', false);
    expect(await service.needsSetup(), false);
    await service.initialize();
    expect(service.enabled, false);
    await signIn('other-health-owner');
    expect(await service.needsSetup(), true);
    await service.initialize();
    expect(service.enabled, false);
  });
  test('body sharing is opt-in even when OS scale access was granted earlier',
      () async {
    health.granted = {
      HealthDataType.STEPS,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE
    };
    health.points = [
      point(HealthDataType.WEIGHT, date, date.add(const Duration(hours: 8)),
          value: 81.2)
    ];
    await service.requestPermissions();
    expect((await service.syncToday()).snapshot!.weight, isNull);
    expect(health.lastRequested, isNot(contains(HealthDataType.WEIGHT)));
    await service.requestPermissions(includeBody: true);
    expect(health.lastRequested, contains(HealthDataType.WEIGHT));
    expect((await service.syncToday()).snapshot!.weight, 81.2);
  });
  test(
      'same-day simultaneous syncs upload once and keep midnight movement boundaries',
      () async {
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    health.heldSteps = Completer<int?>();
    final a = service.syncToday(), b = service.syncToday();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    health.heldSteps!.complete(456);
    expect((await a).success, true);
    expect((await b).snapshot!.steps, 456);
    expect(adapter.posts.length, 1);
    await service.syncToday(date: DateTime(2026, 10, 9));
    expect(health.stepsFrom, DateTime(2026, 10, 9));
    expect(health.stepsTo, date);
    expect(service.lastSnapshot!.date, '2026-10-10');
  });
  test('account change while reading cancels upload', () async {
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    health.heldSteps = Completer<int?>();
    final sync = service.syncToday();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await signIn('new-health-owner');
    health.heldSteps!.complete(123);
    expect((await sync).success, false);
    expect(adapter.posts, isEmpty);
    await service.initialize();
    expect(service.lastSnapshot, isNull);
    expect(service.enabled, false);
  });
  test('a missing native Android step aggregate creates no zero snapshot',
      () async {
    health.granted = {HealthDataType.STEPS};
    health.total = null;
    await service.requestPermissions();
    final result = await service.syncToday();
    expect(result.success, true);
    expect(result.snapshot!.steps, isNull);
    expect(adapter.posts, isEmpty);
    expect(result.message, contains('No readable records'));
  });
  test('failed upload can retry; history backfill stays within seven days',
      () async {
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    adapter.fail = true;
    expect((await service.syncToday()).success, false);
    expect(service.lastSyncTime, isNull);
    adapter.fail = false;
    expect((await service.syncToday()).success, true);
    await service.syncRecentDays();
    await service.syncRecentDays();
    expect(adapter.posts.map((p) => p['date']).toSet().length, 7);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('fitai_health_v2_health-owner_history_done'),
        true);
  });
  test(
      'iOS authorization completion never fabricates denied readings or uploads empty snapshots',
      () async {
    final apple = HealthSyncService.forTesting(
        health: health,
        provider: HealthProviderType.appleHealthKit,
        now: () => DateTime(2026, 10, 10, 12));
    addTearDown(apple.dispose);
    health.authorizeResult = true;
    health.total = null;
    expect(await apple.requestPermissions(), true);
    final result = await apple.syncToday();
    expect(result.success, true);
    expect(result.snapshot!.steps, isNull);
    expect(adapter.posts, isEmpty);
    expect(result.message, contains('No readable records'));
    expect(
        health.queries
            .where((q) => q.type == HealthDataType.SLEEP_ASLEEP)
            .single
            .from,
        DateTime(2026, 10, 9, 12));
  });
  for (final layout in [
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(320, 720), scale: 1.8),
  ]) {
    testWidgets(
        'health actions stay reachable while scrolling at ${layout.size} / ${layout.scale}',
        (tester) async {
      tester.view.physicalSize = layout.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var completed = false;
      const preview = ValueKey('health-preview');
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(layout.scale),
                      padding: const EdgeInsets.only(top: 24, bottom: 24)),
                  child: RepaintBoundary(
                      key: preview,
                      child: HealthConnectionView(
                          service: service,
                          onComplete: () => completed = true))))));
      await tester.pumpAndSettle();
      final connect = find.text('Connect Health Connect');
      final later = find.text('Set up later');
      expect(find.byType(LiquidChromeButton), findsOneWidget);
      expect(connect.hitTestable(), findsOneWidget);
      expect(later.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (layout.scale == 1) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(preview))
              .toImage(pixelRatio: 2);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('build/health-onboarding-preview.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      final footer = find.byKey(const ValueKey('health-action-footer'));
      final before = tester.getRect(footer);
      await tester.drag(find.byKey(const ValueKey('health-connection-scroll')),
          const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(footer), before);
      expect(connect.hitTestable(), findsOneWidget);
      expect(later.hitTestable(), findsOneWidget);
      expect(health.authCalls, 0);
      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(completed, true);
      expect(health.authCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('skip setup opens Today without permission prompts',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: HealthSetupGate(
            service: service,
            child: const Scaffold(body: Text('Real Today')))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Set up later'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up later'));
    await tester.pumpAndSettle();
    expect(find.text('Real Today'), findsOneWidget);
    expect(health.authCalls, 0);
  });
  testWidgets(
      'steps-only Today shows recorded zero without inventing readiness',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: TodayDashboard(
                data: HomeData.fromJson({
                  'calendarDate': '2026-10-10',
                  'user': <String, dynamic>{},
                  'nutrition': <String, dynamic>{},
                  'weeklyStreak': [],
                  'healthMetrics': {
                    'date': '2026-10-10',
                    'source': 'health_connect',
                    'steps': 0
                  }
                }),
                now: DateTime(2026, 10, 10),
                onRefresh: () async {},
                onProfile: () {},
                onSession: () {},
                onTrain: () {},
                onNutrition: () {},
                onBody: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('Health data synced'), findsOneWidget);
    expect(find.text('Connect your health'), findsNothing);
    expect(find.text('Health connection'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-readiness-card')));
    await tester.pumpAndSettle();
    expect(find.text('Synced sleep'), findsOneWidget);
    expect(find.text('Synced heart readings'), findsOneWidget);
    expect(find.text('Missing'), findsNWidgets(2));
    expect(find.text('Connect your health'), findsNothing);
    expect(find.text('0 / 100'), findsNothing);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'saved legacy readings show their date without a fabricated HRV method',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    health.granted = {HealthDataType.STEPS};
    await service.requestPermissions();
    service.lastSnapshot = const HealthSnapshotPayload(
        date: '2026-10-10', sourceProvider: 'GOOGLE_HEALTH_CONNECT', hrv: 42);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(), home: HealthConnectionView(service: service)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('42 ms'), 150);
    await tester.pumpAndSettle();
    expect(find.text('42 ms'), findsOneWidget);
    expect(find.text('Readings · 2026-10-10'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
