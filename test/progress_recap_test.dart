import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/fitness_copy.dart';
import 'package:setcraft/features/progress/components/progress_dashboard.dart';
import 'package:setcraft/features/progress/components/progress_personal_bests.dart';
import 'package:setcraft/features/progress/components/progress_training_hero.dart';
import 'package:setcraft/features/progress/components/progress_weekly_bars.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';
import 'progress_overview_redesign_test.dart' as fixture;

const habits = ProgressOverview({
  'range': {'start': '2026-10-03', 'end': '2026-10-30'},
  'wellness': {
    'recovery': [
      {'date': '2026-10-05', 'sleep': 8},
      {'date': '2026-10-06', 'sleep': null},
      {'date': '2026-10-07', 'sleep': 6},
    ],
    'nutrition': [
      {'date': '2026-10-05', 'protein': 100},
      {'date': '2026-10-06', 'protein': null, 'water': 1000},
      {'date': '2026-10-07', 'protein': 0},
    ],
  },
});

const personalBest = <String, dynamic>{
  'exerciseId': 'bench',
  'name': 'Bench press',
  'date': '2026-10-30',
  'weight': 60,
  'reps': 8,
  'kinds': ['load', 'set_volume'],
};

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('Recap compares workouts and keeps volume out of the headline',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressTrainingHero(summary: const {
      'workouts': 12,
      'workoutChange': 2,
      'previousWorkouts': 10,
      'hasPreviousTraining': true,
    }, weeks: const [
      {'date': '2026-10-05', 'workouts': 0, 'volume': 5000},
      {'date': '2026-10-12', 'workouts': 12, 'volume': 9000},
    ], previousRangeLabel: 'Sep 5 – Oct 2', onOpen: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('12 workouts completed'), findsOneWidget);
    expect(find.text('+2 workouts vs previous period'), findsOneWidget);
    expect(find.text('Sep 5 – Oct 2'), findsOneWidget);
    expect(find.text('Workouts per week'), findsOneWidget);
    expect(find.text('Total Volume'), findsNothing);
    expect(
        tester
            .widget<ProgressWeeklyBars>(find.byType(ProgressWeeklyBars))
            .points
            .map((p) => p.value),
        [0, 12]);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
      'A first period does not claim improvement from an empty baseline',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressTrainingHero(summary: const {
      'workouts': 2,
      'workoutChange': 2,
      'hasPreviousTraining': false,
    }, weeks: const [], onOpen: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('+2 workouts vs previous period'), findsNothing);
    expect(find.text('Keep logging to build your comparison over time.'),
        findsOneWidget);
  });

  testWidgets('Exercise comparisons keep the actual reps beside each weight',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressExerciseTrends(exercises: [
      {
        ...fixture.bench,
        'first': {'weight': 50, 'reps': 10},
        'latest': {'weight': 60, 'reps': 6}
      },
      fixture.pullUp,
    ], onOpen: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('50 kg × 10 reps'), findsOneWidget);
    expect(find.text('60 kg × 6 reps'), findsOneWidget);
    expect(find.text('6 reps'), findsOneWidget);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('+20%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Old cached exercise data never invents the first set',
      (tester) async {
    fixture.phone(tester);
    final cached = {...fixture.bench}
      ..remove('first')
      ..remove('firstDate');
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressExerciseTrends(exercises: [cached], onOpen: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('First session'), findsNothing);
    expect(find.text('60 kg × 8 reps'), findsOneWidget);
    expect(find.text('Open exercise for earlier sessions.'), findsOneWidget);
  });

  testWidgets('One session shows a baseline prompt and pins still lead',
      (tester) async {
    fixture.phone(tester);
    final single = {...fixture.bench, 'sessions': 1, 'firstDate': '2026-10-30'};
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressExerciseTrends(
            exercises: [single, fixture.pullUp],
            pins: const ['pull-up'],
            onOpen: (_) {}))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Pull-up')).dy,
        lessThan(tester.getTopLeft(find.text('Bench press')).dy));
    expect(find.text('Log another session to compare.'), findsOneWidget);
    expect(find.text('First session'), findsOneWidget); // Only the pull-up.
  });

  testWidgets(
      'Habits exclude missing days, retain recorded zero and show coverage',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressBeyondTraining(
            data: habits,
            onBody: () {},
            onRecovery: () {},
            onNutrition: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('7 h 0 min'), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
    expect(find.text('2 of 28 days logged'), findsNWidgets(2));
    expect(find.text('Supporting habits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A personal best shows the achievement and opens its exercise',
      (tester) async {
    fixture.phone(tester);
    ProgressJson? opened;
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressPersonalBests(
            records: const [personalBest],
            onExercise: (exercise) => opened = exercise))));
    await tester.pumpAndSettle();
    expect(find.text('60 kg × 8 reps'), findsOneWidget);
    expect(find.textContaining('Heavier weight'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('progress-personal-best-bench')));
    expect(opened, {'id': 'bench', 'name': 'Bench press'});
  });

  for (final language in AppLanguage.values) {
    testWidgets(
        'Complete recap supports narrow ${language.code} with large text',
        (tester) async {
      fixture.phone(tester, width: 320);
      final data = ProgressOverview({
        ...fixture.overview.json,
        ...habits.json,
        'personalBests': [personalBest],
      });
      await tester.pumpWidget(fixture.page(ProgressOverviewView(initial: data),
          locale: language.locale, scale: 1.6, dock: true));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ProgressOverviewView));
      for (final key in [
        'Recent exercises',
        'Daily trends',
        'Macro split',
        'Heaviest set per session',
        '{count} of {days} days logged',
        'Your last 4 weeks'
      ]) {
        if (language.locale.languageCode != 'en') {
          expect(fitnessText(context, key), isNot(key));
        }
      }
      // Walk the entire lazy list, so lower sections are laid out too.
      for (var i = 0; i < 12; i++) {
        await tester.drag(
            find.byType(CustomScrollView).first, const Offset(0, -320));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.byKey(const ValueKey('progress-view-all-history')),
          findsOneWidget);
    });
  }

  testWidgets('Phone preview includes comparisons and real achievements',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(
        ProgressOverviewView(
            initial: ProgressOverview({
          ...fixture.overview.json,
          ...habits.json,
          'personalBests': [personalBest]
        })),
        dock: true));
    await tester.pumpAndSettle();
    await fixture.capture(tester, 'progress-recap-top');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('progress-view-all-history')), 240,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await fixture.capture(tester, 'progress-recap-trends');
  });

  test('Range coverage counts calendar days across daylight-saving changes',
      () {
    expect(
        const ProgressOverview({
          'range': {'start': '2026-03-01', 'end': '2026-03-31'}
        }).dayCount,
        31);
    expect(const ProgressOverview({}).dayCount, isNull);
  });
}
