import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/progress/components/exercise_progress_content.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/progress_trend_tiles.dart';
import 'package:setcraft/features/progress/components/progress_workout_history.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';

const session = <String, dynamic>{
  'id': 'session-1',
  'date': '2026-10-20',
  'name': 'Upper body',
  'status': 'COMPLETED',
  'durationSeconds': 3240,
  'sets': 2,
  'records': 1,
  'volume': 400,
  'exercises': [
    {
      'id': 'bench',
      'name': 'Bench press',
      'entries': [
        {'setNumber': 1, 'weight': null, 'reps': 10, 'rpe': null},
        {'setNumber': 2, 'weight': 40, 'reps': 10, 'rpe': 7},
      ]
    },
  ],
};

Widget page(Widget child,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale)),
                child: FitnessTheme(child: child))));

void main() {
  testWidgets('History groups months and opens the selected session',
      (tester) async {
    String? selected;
    await tester.pumpWidget(page(Scaffold(
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: ProgressWorkoutHistory(sessions: const [
                  session,
                  {
                    'id': 'older',
                    'name': 'Lower body',
                    'date': '2026-09-30',
                    'sets': 2,
                    'status': 'COMPLETED',
                  }
                ], onSession: (row) => selected = row['id'] as String))))));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('New records · 1'), findsOneWidget);
    await tester.tap(find.text('Lower body'));
    expect(selected, 'older');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Recap preserves missing weight and opens the selected exercise trend',
      (tester) async {
    String? selected;
    await tester.pumpWidget(page(ProgressWorkoutRecap(
        session: session,
        onExercise: (row) => selected = row['id'] as String)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressSetTable), findsOneWidget);
    // The first set has neither a weight nor an effort rating.
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
    await tester.ensureVisible(find.text('Exercise progress'));
    await tester.tap(find.text('Exercise progress'));
    expect(selected, 'bench');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Exercise history sits below the chart and retains logged set values',
      (tester) async {
    await tester.pumpWidget(page(const Scaffold(
        body: SingleChildScrollView(
            child: ExerciseProgressContent(data: {
      'series': [
        {'date': '2026-10-20', 'load': 40, 'reps': 10}
      ],
      'history': [
        {
          'date': '2026-10-20',
          'entries': [
            {'setNumber': 1, 'weight': null, 'reps': 10}
          ]
        }
      ],
    })))));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(find.byType(ProgressSetHistory), findsOneWidget);
    await tester.tap(find.byType(ProgressSetHistory));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(ProgressSetTable), matching: find.text('—')),
        findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recap and paired metric cards fit narrow German with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page(const ProgressWorkoutRecap(session: session),
        locale: const Locale('de'), scale: 1.6));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Bench press'), 160,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final points = [
      ProgressPoint(DateTime(2026, 10, 1), 75),
      ProgressPoint(DateTime(2026, 10, 20), 74.5)
    ];
    await tester.pumpWidget(page(
        Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: ProgressMetricPreview(
                                  title: 'Weight',
                                  unit: 'kg',
                                  points: points,
                                  onTap: () {})),
                          const SizedBox(width: 12),
                          Expanded(
                              child: ProgressMetricPreview(
                                  title: 'Recovery',
                                  unit: '/100',
                                  points: points,
                                  onTap: () {})),
                        ])))),
        locale: const Locale('de'),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
