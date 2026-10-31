import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/cache/cache_scope.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/core/storage/local_cache.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/nutrition/views/food_library_view.dart';
import 'package:setcraft/features/nutrition/views/nutrition_view.dart';
import 'package:setcraft/features/today/views/today_home_view.dart';
import 'package:setcraft/features/today/views/readiness_detail_view.dart';
import 'package:setcraft/features/today/repositories/today_repository.dart';

class DateAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  String? heldDate;
  bool recordedReadiness = false;
  bool holdOptional = false;
  final optionalReady = Completer<void>();
  String? failedDate;
  final release = Completer<void>();
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    requests.add(options);
    if (holdOptional && options.path != '/api/home') {
      await optionalReady.future;
    }
    final date = options.uri.queryParameters['date'] ?? CacheScope.todayKey();
    if (options.path == '/api/home' && date == failedDate) {
      return ResponseBody.fromString('{"error":"Unavailable"}', 503, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (options.path == '/api/home' && date == heldDate) await release.future;
    final selected = DateTime.parse(date);
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final Object response;
    if (options.path == '/api/home') {
      response = {
        'calendarDate': date,
        'user': {'name': 'Recorded user', 'streakDays': 0},
        'readiness': recordedReadiness
            ? {
                'date': date,
                'score': selected.day / 10,
                'label': 'Recorded readiness $date',
                'source': 'check_in_estimate',
                'sleepMinutes': selected.day * 10,
              }
            : null,
        'sleepLog': {'date': date, 'sleepMinutes': selected.day * 10},
        'todayWorkout': {
          'userWorkoutId': date,
          'workoutTitle': 'Session $date',
          'exerciseCount': 1,
          'status': 'NOT_STARTED'
        },
        'nutrition': {
          'calories': {'consumed': selected.day * 100, 'target': 2000},
          'water': {'consumed': selected.day * 50, 'target': 2500}
        },
        'weeklyStreak': List.generate(
            7,
            (i) => {
                  'day': 'DAY',
                  'dateNum': monday.add(Duration(days: i)).day,
                  'status': 'UNAVAILABLE'
                }),
      };
    } else if (options.path == '/api/history/recovery') {
      response = {
        'data': [
          {'date': date, 'sleepHours': 7.5}
        ]
      };
    } else {
      response = {'data': []};
    }
    return ResponseBody.fromString(jsonEncode(response), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> tapDay(WidgetTester tester, Finder day) async {
  await tester.scrollUntilVisible(day, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(day);
  await tester.tap(day);
}

void main() {
  late DateAdapter adapter;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final owner = 'today-filter-${DateTime.now().microsecondsSinceEpoch}';
    final token =
        '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';
    await SecureSessionStore.shared
        .saveTokens(accessToken: token, refreshToken: 'test');
    adapter = DateAdapter();
    final old = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = old);
  });

  testWidgets(
      'Today plus opens Add meal directly and Back returns to the same Today tab',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final original = tester.state(find.byType(TodayHomeView));
    await tester.scrollUntilVisible(find.byTooltip('Add meal'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byTooltip('Add meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add meal'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodLibraryView), findsOneWidget);
    expect(find.byType(NutritionView, skipOffstage: false), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(FoodLibraryView), findsNothing);
    expect(tester.state(find.byType(TodayHomeView)), same(original));
    expect(Navigator.of(tester.element(find.byType(TodayHomeView))).canPop(),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Week selection updates every dated card and rejects late responses',
      (tester) async {
    adapter.recordedReadiness = true;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final now = DateUtils.dateOnly(DateTime.now());
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final held = monday;
    final latest = monday.add(const Duration(days: 1));
    // Choose two days other than today's date so today's shared SWR cache cannot interfere.
    final first = DateUtils.isSameDay(held, now)
        ? monday.add(const Duration(days: 2))
        : held;
    final second = DateUtils.isSameDay(latest, now)
        ? monday.add(const Duration(days: 3))
        : latest;
    adapter.heldDate = CacheScope.todayKey(first);
    await tapDay(tester,
        find.byKey(ValueKey('today-week-day-${CacheScope.todayKey(first)}')));
    await tester.pump();
    await tapDay(tester,
        find.byKey(ValueKey('today-week-day-${CacheScope.todayKey(second)}')));
    await tester.pumpAndSettle();
    adapter.release.complete();
    await tester.pumpAndSettle();
    final dashboard =
        tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.data!.calendarDate, CacheScope.todayKey(second));
    expect(dashboard.data!.todayWorkout!.workoutTitle,
        'Session ${CacheScope.todayKey(second)}');
    expect(dashboard.data!.nutrition.calories.consumed, second.day * 100);
    expect(dashboard.data!.sleepLog!['sleepMinutes'], second.day * 10);
    expect(dashboard.data!.readiness!.date, CacheScope.todayKey(second));
    expect(dashboard.data!.readiness!.score, second.day / 10);
    expect(adapter.requests.where((r) => r.path == '/api/heatmap/training'),
        isEmpty);
    expect(
        adapter.requests.every((r) => !r.path.contains('/preview/')), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Empty recovery opens its details and a dated sheet without invented scores',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('today-readiness-heading'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(ReadinessDetailView), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('readiness-detail-update')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('How are you feeling today?')),
        findsOneWidget);
    expect(find.text('0 / 100'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Invalid dated cache is bypassed; failed day loads stop and retry the same day',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final selected = DateUtils.isSameDay(monday, today)
        ? monday.add(const Duration(days: 1))
        : monday;
    final date = CacheScope.todayKey(selected);
    final owner = await SecureSessionStore.shared.userId;
    await LocalCache.shared.saveJson(
        'fitai_u_${owner}_home_v9_en_${date}_real', {'user': 'invalid'});
    adapter.failedDate = date;
    await tapDay(tester, find.byKey(ValueKey('today-week-day-$date')));
    await tester.pumpAndSettle();
    var dashboard = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.loading, isFalse);
    expect(dashboard.loadFailed, isTrue);
    expect(find.byKey(const ValueKey('today-readiness-card')), findsNothing);
    adapter.failedDate = null;
    adapter.recordedReadiness = true;
    await tapDay(tester, find.byKey(ValueKey('today-week-day-$date')));
    await tester.pumpAndSettle();
    dashboard = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.data!.calendarDate, date);
    expect(dashboard.data!.readiness!.date, date);
    expect(dashboard.loadFailed, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Today starts sections together and reuses fresh data on tab return',
      (tester) async {
    adapter.heldDate = CacheScope.todayKey();
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (_, value, __) => TodayHomeView(
                isActive: value, onSelectTab: (_) {}, onOpenProfile: () {}))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(adapter.requests.any((r) => r.path == '/api/home'), isTrue);
    expect(
        adapter.requests.any((r) => r.path == '/api/history/recovery'), isTrue);
    expect(adapter.requests.where((r) => r.path == '/api/heatmap/training'),
        isEmpty);
    adapter.release.complete();
    await tester.pumpAndSettle();
    final before = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(before.data, isNotNull);
    expect(adapter.requests.where((r) => r.path == '/api/home').length, 1);
    final requestCount = adapter.requests.length;
    active.value = false;
    await tester.pump();
    active.value = true;
    await tester.pumpAndSettle();
    final after = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(identical(after.data, before.data), isTrue);
    expect(after.loading, isFalse);
    expect(adapter.requests.length, requestCount);

    // A save invalidates Home, so returning must fetch even inside the TTL.
    TodayRepository.shared.invalidate();
    active.value = false;
    await tester.pump();
    active.value = true;
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.path == '/api/home').length, 2);

    // Explicit refresh still bypasses the cache and issues exactly one Home request.
    await tester.runAsync(after.onRefresh);
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.path == '/api/home').length, 3);
    expect(
        adapter.requests
            .lastWhere((r) => r.path == '/api/home')
            .uri
            .queryParameters['refresh'],
        'true');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Slow history never blocks or rebuilds the main cards',
      (tester) async {
    adapter.holdOptional = true;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: TodayHomeView(onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final before = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(before.loading, isFalse);
    expect(before.data!.calendarDate, CacheScope.todayKey());
    expect(before.recoveryUpdates!.value, isEmpty);
    // Dio's transport futures run outside the widget test's frame clock.
    await tester.runAsync(() async {
      adapter.optionalReady.complete();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    final after = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(identical(before, after), isTrue);
    expect(after.recoveryUpdates!.value.single.sleepHours, 7.5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
