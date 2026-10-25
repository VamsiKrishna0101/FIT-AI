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
      source: 'check_in_estimate',
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
        tester.getRect(find.byKey(const ValueKey('today-readiness-card'))).top,
        greaterThan(before.bottom));
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
      await tester.scrollUntilVisible(find.text('Daily check-in estimate'), 120,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Daily check-in estimate'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
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
    expect(find.text('How this is calculated'), findsOneWidget);
    expect(find.text('What went into your score'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    Navigator.of(tester.element(find.text('84'))).pop();
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
    expect(find.text('Your readiness check-in'), findsOneWidget);
    expect(find.text('84'), findsNothing);
    expect(find.text('HRV'), findsNothing);
    expect(find.text('A day to recover'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Entered sleep acknowledges an incomplete no-wearable check-in',
      (tester) async {
    final data = HomeData.fromJson({
      ..._data.toJson(),
      'wearableUsage': 'NONE',
      'healthMetrics': null,
      'readiness': null,
      'sleepLog': {'sleepMinutes': 420, 'energy': 3},
    });
    await tester.pumpWidget(_app(data: data));
    expect(find.text('Your readiness check-in'), findsOneWidget);
    expect(find.textContaining('rest, soreness'), findsOneWidget);
    expect(find.text('84'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Complete check-in shows a labelled ring without invented vitals',
      (tester) async {
    final data = HomeData.fromJson({
      ..._data.toJson(),
      'wearableUsage': 'NONE',
      'healthMetrics': null,
      'sleepLog': {
        'sleepMinutes': 420,
        'energy': 3,
        'rested': 3,
        'soreness': 3
      },
      'readiness': {
        'score': 7,
        'label': 'Daily check-in estimate',
        'source': 'check_in_estimate',
        'sleepMinutes': 420,
      },
    });
    await tester.pumpWidget(_app(data: data));
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Daily check-in estimate'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Somewhat rested'), findsOneWidget);
    await tester.tap(find.text('70'));
    await tester.pumpAndSettle();
    expect(find.text('HRV'), findsNothing);
    expect(find.text('Resting HR'), findsNothing);
    expect(find.text('What went into your score'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sleep chart preserves actual duration without heart metric tabs',
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
    expect(label('7 h 42 m'), findsOneWidget);
    expect(label('HRV'), findsNothing);
    expect(label('RHR'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('No reading')), findsNWidgets(6));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
      'Legacy heart-based scores do not populate the manual readiness card',
      (tester) async {
    final data = HomeData.fromJson({
      ..._data.toJson(),
      'readiness': {..._data.readiness!.toJson(), 'source': 'healthkit'},
      'wearableUsage': 'NONE',
    });
    await tester.pumpWidget(_app(data: data));
    final card = find.byKey(const ValueKey('today-readiness-card'));
    expect(
        find.descendant(of: card, matching: find.text('68 ms')), findsNothing);
    expect(
        find.descendant(of: card, matching: find.text('54 bpm')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('Add answer')),
        findsNWidgets(3));
  });

  test('Home cache preserves measurement date, real source and session title',
      () {
    final restored = HomeData.fromJson(_data.toJson());
    expect(restored.readiness!.date, '2026-10-06');
    expect(restored.readiness!.source, 'check_in_estimate');
    expect(restored.readiness!.sleepEfficiency, 91);
    expect(restored.todayWorkout!.sessionTitle, 'Full-body strength');
  });
}
