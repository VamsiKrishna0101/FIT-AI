import 'dart:io';
import 'helpers/calendar_controls.dart';
import 'package:setcraft/core/components/app_date_filter.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/database/cache_manager.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/today/components/weekly_rhythm_calendar.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/today/views/today_home_view.dart';
import 'package:setcraft/features/today/views/readiness_detail_view.dart';
import 'package:setcraft/features/wellness/models/sleep_edit_window.dart';
import 'package:setcraft/features/wellness/repositories/wellness_repository.dart';
import 'package:setcraft/features/wellness/views/daily_check_in_sheet.dart';
import 'training_session_test.dart' show token;
import 'today_date_filter_test.dart' show DateAdapter;
import 'today_check_in_test.dart' show CheckInRepo;

const captureKey = ValueKey('week-calendar-capture');
final today = DateTime(2026, 10, 28, 10);

Widget app(Widget child, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: FitnessTheme(
                child: RepaintBoundary(key: captureKey, child: child!))),
        home: child);

void phone(WidgetTester tester, {Size size = const Size(393, 852)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty &&
      (key == 'weekly-rhythm-calendar' || key.startsWith('today-week-day-'))) {
    await tester.scrollUntilVisible(finder, -180,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/previews').createSync(recursive: true);
    File('build/previews/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  late DateAdapter adapter;
  var owner = 0;
  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('fitai-week-calendar-');
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
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('weekly-calendar-${owner++}'), refreshToken: 'test');
    adapter = DateAdapter()..recordedReadiness = true;
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  test(
      'Sleep edits use the current Monday-to-today window across year boundaries',
      () {
    expect(canEditSleepDate(DateTime(2026, 10, 26), today), isTrue);
    expect(canEditSleepDate(DateTime(2026, 10, 28), today), isTrue);
    expect(canEditSleepDate(DateTime(2026, 10, 25), today), isFalse);
    expect(canEditSleepDate(DateTime(2026, 10, 29), today), isFalse);
    expect(sleepWeekStart(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
    expect(
        canEditSleepDate(DateTime(2026, 12, 28), DateTime(2027, 1, 1)), isTrue);
    expect(canEditSleepDate(DateTime(2026, 12, 27), DateTime(2027, 1, 1)),
        isFalse);
  });

  test(
      'Repository rejects previous-week and future saves before sending a request',
      () async {
    final repo = WellnessRepository(clock: () => today);
    await expectLater(repo.save('2026-10-25', 420, 3), throwsFormatException);
    await expectLater(repo.save('2026-10-29', 420, 3), throwsFormatException);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('Calendar icon opens a week picker and blocks future dates',
      (tester) async {
    phone(tester);
    DateTime? selected;
    await tester.pumpWidget(app(Scaffold(
        body: Center(
            child: WeeklyRhythmCalendarButton(
                selectedDate: today,
                today: today,
                onSelected: (date) => selected = date)))));
    final trigger = find.byKey(const ValueKey('weekly-rhythm-calendar'));
    expect(tester.widget<AppDateFilterButton>(trigger).tooltip, 'Calendar');
    expect(tester.getSize(trigger).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(trigger).height, greaterThanOrEqualTo(44));
    expect(
        tester
            .getSize(find.descendant(of: trigger, matching: find.byType(Icon)))
            .width,
        lessThan(20));
    expect(find.descendant(of: trigger, matching: find.byType(Icon)),
        findsOneWidget);
    expect(find.descendant(of: trigger, matching: find.text('Calendar')),
        findsNothing);
    await tap(tester, 'weekly-rhythm-calendar');
    expect(find.byType(AppCalendar), findsOneWidget);
    expect(
        calendarDropdown<int>(tester, 'week-calendar-month-picker')
            .items
            .singleWhere((item) => item.value == 11)
            .enabled,
        isFalse);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('week-calendar-day-2026-10-29')))
            .onPressed,
        isNull);
    await capture(tester, 'weekly-calendar-current');
    await tap(tester, 'week-calendar-day-2026-10-19');
    expect(find.text('Oct 19 – Oct 25'), findsOneWidget);
    expect(selected, isNull,
        reason: 'Browsing never changes Today before View week');
    await capture(tester, 'weekly-calendar-past');
    await tap(tester, 'week-calendar-view-week');
    expect(selected, DateTime(2026, 10, 19));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Month browsing and This week return to the actual current date',
      (tester) async {
    phone(tester);
    DateTime? selected;
    await tester.pumpWidget(app(Scaffold(
        body: Center(
            child: WeeklyRhythmCalendarButton(
                selectedDate: DateTime(2026, 9, 14),
                today: today,
                onSelected: (date) => selected = date)))));
    await tap(tester, 'weekly-rhythm-calendar');
    expect(find.text('September'), findsOneWidget);
    await selectCalendarOption(tester, 'week-calendar-month-picker', 'August');
    expect(find.text('August'), findsOneWidget);
    await selectCalendarOption(tester, 'week-calendar-filter', 'This week');
    expect(find.text('October'), findsOneWidget);
    await tap(tester, 'week-calendar-view-week');
    expect(selected, DateUtils.dateOnly(today));
  });

  testWidgets(
      'Single day filters Today nutrition, training, and recovery together',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(TodayHomeView(
        clock: () => today, onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    await tap(tester, 'weekly-rhythm-calendar');
    await selectCalendarOption(tester, 'week-calendar-filter', 'Single day');
    await tap(tester, 'week-calendar-day-2026-10-21');
    await tap(tester, 'week-calendar-view-week');
    final dashboard =
        tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.selectedDate, DateTime(2026, 10, 21));
    expect(dashboard.data!.calendarDate, '2026-10-21');
    expect(dashboard.data!.todayWorkout!.workoutTitle, 'Session 2026-10-21');
    expect(dashboard.data!.nutrition.calories.consumed, 2100);
    expect(dashboard.data!.readiness!.date, '2026-10-21');
    expect(
        adapter.requests
            .lastWhere((r) => r.path == '/api/history/recovery')
            .uri
            .queryParameters['date'],
        '2026-10-21');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Previous-week sleep is visible and read-only; this-week days remain editable',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(TodayHomeView(
        clock: () => today, onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    await tap(tester, 'weekly-rhythm-calendar');
    await tap(tester, 'week-calendar-day-2026-10-19');
    await tap(tester, 'week-calendar-view-week');
    var dashboard = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.selectedDate, DateTime(2026, 10, 19));
    expect(dashboard.onSleep, isNull);
    expect(find.byKey(const ValueKey('today-week-day-2026-10-19')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-week-day-2026-10-26')), findsNothing);
    expect(
        adapter.requests
            .where((r) => r.path == '/api/history/recovery')
            .last
            .uri
            .queryParameters['date'],
        '2026-10-19');
    expect(find.byType(DailyCheckInSheet), findsNothing);
    expect(find.text('Past week · Read-only'), findsNothing);
    expect(find.text('3h 10m'), findsOneWidget);
    await capture(tester, 'weekly-past-sleep-readonly');
    await tap(tester, 'today-readiness-card');
    expect(find.byType(ReadinessDetailView), findsOneWidget);
    expect(find.text('Past week · Read-only'), findsOneWidget);
    expect(
        tester
            .widget<ReadinessDetailView>(find.byType(ReadinessDetailView))
            .onEdit,
        isNull);
    expect(find.text('Edit sleep'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, 'weekly-rhythm-calendar');
    await selectCalendarOption(tester, 'week-calendar-filter', 'This week');
    await tap(tester, 'week-calendar-view-week');
    dashboard = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.selectedDate, DateUtils.dateOnly(today));
    expect(dashboard.onSleep, isNotNull);
    await tap(tester, 'today-week-day-2026-10-26');
    dashboard = tester.widget<TodayDashboard>(find.byType(TodayDashboard));
    expect(dashboard.onSleep, isNotNull);
    await tap(tester, 'today-readiness-card');
    await tap(tester, 'readiness-detail-update');
    expect(find.byType(DailyCheckInSheet), findsOneWidget);
    expect(
        tester.widget<DailyCheckInSheet>(find.byType(DailyCheckInSheet)).date,
        DateTime(2026, 10, 26));
    expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'A failed historical load keeps the calendar usable for returning to this week',
      (tester) async {
    phone(tester);
    adapter.failedDate = '2026-10-19';
    await tester.pumpWidget(app(TodayHomeView(
        clock: () => today, onSelectTab: (_) {}, onOpenProfile: () {})));
    await tester.pumpAndSettle();
    await tap(tester, 'weekly-rhythm-calendar');
    await tap(tester, 'week-calendar-day-2026-10-19');
    await tap(tester, 'week-calendar-view-week');
    expect(
        tester.widget<TodayDashboard>(find.byType(TodayDashboard)).loadFailed,
        isTrue);
    expect(
        find.byKey(const ValueKey('weekly-rhythm-calendar')), findsOneWidget);
    await tap(tester, 'weekly-rhythm-calendar');
    await selectCalendarOption(tester, 'week-calendar-filter', 'This week');
    await tap(tester, 'week-calendar-view-week');
    expect(
        tester.widget<TodayDashboard>(find.byType(TodayDashboard)).loadFailed,
        isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('An open sleep sheet cannot save after Sunday rolls into Monday',
      (tester) async {
    phone(tester);
    var now = DateTime(2026, 10, 25, 23, 59);
    final repo = CheckInRepo();
    await tester.pumpWidget(app(Scaffold(
        body: DailyCheckInSheet(
            date: DateTime(2026, 10, 25),
            clock: () => now,
            entry: const {'sleepMinutes': 420},
            repository: repo))));
    await tester.pumpAndSettle();
    now = DateTime(2026, 10, 26, 0, 1);
    await tap(tester, 'daily-check-in-save');
    expect(repo.saved, isNull);
    expect(find.text(pastSleepReadOnly), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A six-row month stays usable at 320 px with large German text',
      (tester) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(app(
        Scaffold(
            body: Center(
                child: WeeklyRhythmCalendarButton(
                    selectedDate: DateTime(2026, 8, 24),
                    today: today,
                    onSelected: (_) {}))),
        locale: 'de',
        scale: 1.8));
    await tap(tester, 'weekly-rhythm-calendar');
    final finalDay = find.byKey(const ValueKey('week-calendar-day-2026-08-31'));
    await tester.scrollUntilVisible(finalDay, 100,
        scrollable: find
            .descendant(
                of: find.byType(WeeklyRhythmCalendar),
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(finalDay);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('week-calendar-view-week')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'weekly-calendar-large-de');
  });
}
