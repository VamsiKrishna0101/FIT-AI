import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/ds_colors.dart';
import 'package:setcraft/features/progress/components/progress_visual_cards.dart';
import 'package:setcraft/features/progress/components/progress_visual_charts.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';

Widget page(Widget child) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16), child: child)));

void main() {
  testWidgets('Activity uses white trained-day circles for week and month',
      (tester) async {
    const data = ProgressOverview({
      'range': {'start': '2026-10-03', 'end': '2026-10-30'},
      'summary': {'trainingDays': 1, 'workouts': 1},
      'activity': [
        {'date': '2026-10-30', 'sets': 12, 'completed': true}
      ],
    });
    for (final count in [7, 28]) {
      await tester.pumpWidget(page(ProgressAttendanceCard(
          data: data,
          days: List.generate(
              count,
              (i) => DateTime(2026, 10, 30)
                  .subtract(Duration(days: count - i - 1))),
          onOpen: () {})));
      await tester.pumpAndSettle();
      final trained = tester.widget<Container>(
          find.byKey(const ValueKey('progress-attendance-2026-10-30')));
      final unlogged = tester.widget<Container>(
          find.byKey(const ValueKey('progress-attendance-2026-10-29')));
      expect((trained.decoration as BoxDecoration).color, Colors.white);
      expect((unlogged.decoration as BoxDecoration).color, DSColors.bgRaised);
      expect(find.byType(ProgressColumnChart), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Recent exercises fit content height and remain tappable',
      (tester) async {
    String? opened;
    await tester.pumpWidget(page(ProgressExerciseChartShelf(exercises: [
      for (final id in ['bench', 'row'])
        {
          'id': id,
          'name': id == 'bench' ? 'Barbell bench press' : 'Seated cable row',
          'metric': 'load',
          'latest': {'date': '2026-10-30', 'weight': 60, 'reps': 8},
          'loggedSets': 9,
          'totalReps': 72,
          'volume': 4140,
          'sparkline': [
            {'date': '2026-10-26', 'value': 55},
            {'date': '2026-10-30', 'value': 60},
          ]
        }
    ], onOpen: (row) => opened = row['id'] as String)));
    await tester.pumpAndSettle();
    final bench = find.byKey(const ValueKey('progress-exercise-bench'));
    final row = find.byKey(const ValueKey('progress-exercise-row'));
    expect(tester.getSize(bench).height, lessThan(215));
    expect(tester.getSize(bench).height, tester.getSize(row).height);
    await tester.tap(bench);
    expect(opened, 'bench');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nutrition ring has one-line centre and selectable macro share',
      (tester) async {
    await tester.pumpWidget(page(const ProgressNutritionDonutCard(wellness: {
      'nutrition': [
        {'date': '2026-10-30', 'protein': 25, 'carbs': 25, 'fat': 0}
      ]
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-macro-Protein')));
    await tester.pumpAndSettle();
    final centre = tester.widget<Text>(
        find.byKey(const ValueKey('progress-macro-centre-value')));
    expect(centre.data, '50%');
    expect(centre.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}
