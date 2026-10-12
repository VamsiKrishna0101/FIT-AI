import 'package:fitai_mobile/core/theme/ds_colors.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _data = HomeData(
  user: HomeUser(name: 'Vikram Kumar', streakDays: 1),
  healthMetrics: HomeHealthMetrics(
      date: '2026-10-06',
      source: 'healthkit',
      steps: 6840,
      activeCalories: 420,
      sleepMinutes: 462,
      hrv: 68,
      hrvMethod: 'SDNN',
      restingHR: 54),
  readiness: HomeReadiness(
      score: 8.4,
      label: 'Optimal Recovery',
      aiTarget: 'Sample guidance for this day.',
      source: 'healthkit',
      date: '2026-10-06',
      hrvMs: 68,
      restingHrBpm: 54,
      sleepMinutes: 462,
      sleepEfficiency: 91,
      steps: 6840,
      activeCalories: 420),
  todayWorkout: HomeTodayWorkout(
      userWorkoutId: 'preview',
      weekLabel: 'Week 4',
      workoutTitle: 'Pec deck fly',
      sessionTitle: 'Full-body strength',
      category: 'strength',
      exerciseCount: 6,
      durationMinutes: 48,
      status: 'NOT_STARTED',
      aiNote: 'Use a comfortable load for your planned sets.'),
  nutrition: HomeNutrition(
      calories: MacroTarget(consumed: 1480, target: 2200),
      protein: MacroTarget(consumed: 100, target: 160),
      carbs: MacroTarget(consumed: 189, target: 250),
      fat: MacroTarget(consumed: 37, target: 65),
      water: MacroTarget(consumed: 1450, target: 2800)),
  weeklyStreak: [
    WeekDay(day: 'MON', status: 'UNAVAILABLE'),
    WeekDay(day: 'TUE', status: 'NOT_STARTED', isToday: true),
    WeekDay(day: 'WED', status: 'UNAVAILABLE'),
    WeekDay(day: 'THU', status: 'UNAVAILABLE'),
    WeekDay(day: 'FRI', status: 'UNAVAILABLE'),
    WeekDay(day: 'SAT', status: 'UNAVAILABLE'),
    WeekDay(day: 'SUN', status: 'UNAVAILABLE')
  ],
);

Widget _app(
        {HomeData? data = _data,
        double textScale = 1,
        VoidCallback? onProfile,
        VoidCallback? onSession}) =>
    MaterialApp(
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                    backgroundColor: DSColors.dashboardBg,
                    body: TodayDashboard(
                      data: data,
                      now: DateTime(2026, 10, 6, 10),
                      onRefresh: () async {},
                      onProfile: onProfile ?? () {},
                      onSession: onSession ?? () {},
                      onTrain: () {},
                      onNutrition: () {},
                      onBody: () {},
                    )),
              )),
    );

void main() {
  testWidgets('Today header and profile stay fixed while content scrolls',
      (tester) async {
    await tester.pumpWidget(_app());
    final header = find.byKey(const ValueKey('today-fixed-header'));
    final before = tester.getRect(header);
    expect(
        tester.getRect(find.byKey(const ValueKey('today-chart-card'))).top,
        greaterThan(tester
            .getRect(find.byKey(const ValueKey('today-weekly-rhythm')))
            .bottom));
    expect(
        tester.getRect(find.byKey(const ValueKey('today-chart-card'))).bottom,
        lessThan(tester.getTopLeft(find.text('Readiness').first).dy));
    expect(
        tester
            .getRect(find.byKey(const ValueKey('today-weekly-rhythm')))
            .bottom,
        lessThan(tester.getTopLeft(find.text('Readiness').first).dy));
    final profileBefore = tester.getRect(find.text('VK'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getRect(header), before);
    expect(tester.getRect(find.text('VK')), profileBefore);
    expect(find.text('VK').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in [(320.0, 1.0), (393.0, 1.0), (320.0, 1.7)]) {
    testWidgets('Today fits width $width and text scale $scale',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 852);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(textScale: scale));
      await tester.scrollUntilVisible(find.text('Apple Health'), 120,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Apple Health'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Recorded sleep'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Recorded sleep'), findsOneWidget);
      expect(find.text('Recovery · last 7 days'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Fat'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('37 / 65 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('See your body progress'), 250,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Profile, readiness details and session actions work',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    var profiles = 0;
    var sessions = 0;
    await tester.pumpWidget(
        _app(onProfile: () => profiles++, onSession: () => sessions++));
    await tester.tap(find.text('VK'));
    expect(profiles, 1);
    await tester.tap(find.text('84'));
    await tester.pumpAndSettle();
    expect(find.text('Sample guidance for this day.'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(BottomSheet), matching: find.text('84 / 100')),
        findsOneWidget);
    Navigator.of(tester.element(find.text('84 / 100').last)).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Start session'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Start session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'));
    expect(sessions, 1);
  });

  testWidgets('Missing readings do not display invented values or a rest day',
      (tester) async {
    await tester.pumpWidget(_app(data: null));
    expect(find.text('No readiness for this day'), findsOneWidget);
    expect(find.text('84'), findsNothing);
    expect(find.text('HRV'), findsNothing);
    expect(find.text('A day to recover'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('One compact chart switches between actual readings',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-chart-card')), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const ValueKey('today-chart-card')));
    await tester.pumpAndSettle();
    final chart = find.byKey(const ValueKey('today-chart-card'));
    expect(tester.getSize(chart).height, lessThan(180));
    Finder label(String text) =>
        find.descendant(of: chart, matching: find.text(text));
    expect(label('84 / 100'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('No reading')), findsNWidgets(6));
    await tester.tap(label('HRV'));
    await tester.pump();
    expect(label('68 ms'), findsOneWidget);
    await tester.tap(label('Sleep'));
    await tester.pump();
    expect(label('7 h 42 m'), findsOneWidget);
    await tester.tap(label('RHR'));
    await tester.pump();
    expect(label('54 bpm'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  test('Home cache preserves measurement date, real source and session title',
      () {
    final restored = HomeData.fromJson(_data.toJson());
    expect(restored.readiness!.date, '2026-10-06');
    expect(restored.readiness!.source, 'healthkit');
    expect(restored.readiness!.sleepEfficiency, 91);
    expect(restored.todayWorkout!.sessionTitle, 'Full-body strength');
  });
}
