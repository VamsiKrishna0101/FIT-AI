import 'package:setcraft/core/theme/ds_colors.dart';
import 'package:setcraft/features/nutrition/components/nutrition_summary_card.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        DateTime? selectedDate,
        VoidCallback? onProfile,
        VoidCallback? onSession,
        VoidCallback? onTrain}) =>
    MaterialApp(
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                    backgroundColor: DSColors.dashboardBg,
                    body: TodayDashboard(
                      data: data,
                      selectedDate: selectedDate,
                      now: DateTime(2026, 10, 6, 10),
                      onRefresh: () async {},
                      onProfile: onProfile ?? () {},
                      onSession: onSession ?? () {},
                      onTrain: onTrain ?? () {},
                      onNutrition: () {},
                    )),
              )),
    );

void main() {
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
  });
  testWidgets('Today sections follow the requested reading order',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-rhythm-range')), findsNothing);
    expect(tester.getSize(find.byType(NutritionSummaryCard)).height,
        lessThan(220));
    for (final label in ['Protein', 'Carbs', 'Fat']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('View all'), findsNothing);
    expect(find.text('Recovery'), findsOneWidget);
    expect(find.text('Training readiness'), findsNothing);
    expect(find.byKey(const ValueKey('today-readiness-date')), findsNothing);
    final session = find.byKey(const ValueKey('today-session-card'));
    expect(find.descendant(of: session, matching: find.text('Week 4')),
        findsNothing);
    final title = tester.getRect(find.text('Full-body strength'));
    final badge = tester.getRect(find.text('Not started'));
    expect(title.top, lessThanOrEqualTo(badge.top));
    expect(title.left, lessThan(badge.left));
    final keys = [
      'today-weekly-rhythm',
      'today-section-readiness',
      'today-session-card',
      'today-recorded-sleep-heading',
      'today-section-nutrition'
    ];
    final tops = keys
        .map((key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy)
        .toList();
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]));
    }
  });

  testWidgets(
      'Today keeps only one nutrition section during rapid date changes',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(selectedDate: DateTime(2026, 10, 6)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Protein'), 250,
          scrollable: find.byType(Scrollable).first);
      for (final day in [5, 6, 4]) {
        await tester.pumpWidget(_app(selectedDate: DateTime(2026, 10, day)));
        for (final elapsed in [0, 40, 100]) {
          await tester.pump(Duration(milliseconds: elapsed));
          expect(find.byType(NutritionSummaryCard), findsOneWidget);
          for (final label in ['Protein', 'Carbs', 'Fat']) {
            expect(find.text(label), findsOneWidget,
                reason:
                    'The outgoing day must not duplicate the nutrition row');
          }
        }
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Session action stays correct for planned, resumed, completed and rest days',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (status, label) in [
      ('NOT_STARTED', 'Start session'),
      ('IN_PROGRESS', 'Continue session'),
      ('COMPLETED', 'Review session'),
      ('REST_DAY', 'Open plan')
    ]) {
      var sessions = 0, plans = 0;
      final data = HomeData.fromJson({
        ..._data.toJson(),
        'todayWorkout': {..._data.todayWorkout!.toJson(), 'status': status}
      });
      await tester.pumpWidget(_app(
          data: data, onSession: () => sessions++, onTrain: () => plans++));
      await tester.scrollUntilVisible(find.text(label), 180,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      expect(sessions, status == 'REST_DAY' ? 0 : 1);
      expect(plans, status == 'REST_DAY' ? 1 : 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

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
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('today-readiness-card')), 120,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Check-in saved'), findsNothing);
      expect(find.text('84'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Fat'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('37 / 65 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Muscles this week'), findsNothing);
      expect(find.text('See your body progress'), findsNothing);
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
    expect(find.text('How this is calculated'), findsNothing);
    expect(find.text('Your check-in'), findsOneWidget);
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
    expect(find.text('How are you feeling?'), findsOneWidget);
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
    expect(find.text('Progress saved'), findsOneWidget);
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
    expect(find.text('Check-in saved'), findsNothing);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Somewhat rested'), findsOneWidget);
    await tester.tap(find.text('70'));
    await tester.pumpAndSettle();
    expect(find.text('HRV'), findsNothing);
    expect(find.text('Resting HR'), findsNothing);
    expect(find.text('Your check-in'), findsOneWidget);
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
    expect(find.bySemanticsLabel(RegExp('No reading')), findsNWidgets(5));
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
        findsNothing);
    expect(find.byKey(const ValueKey('today-readiness-ring')), findsNothing);
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
