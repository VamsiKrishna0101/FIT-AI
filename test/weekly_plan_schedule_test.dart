import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/planner/views/widgets/weekly_plan_schedule.dart';

final _payload = <String, dynamic>{
  'workouts': [
    for (var day = 0; day < 7; day++)
      {
        'date': '2026-10-${12 + day}',
        'name': day == 1
            ? 'Rest'
            : day == 2
                ? 'Back and biceps'
                : 'Chest and triceps',
        'restDay': day == 1,
        'estimatedMinutes': 45,
        'exercises': day == 1
            ? []
            : [
                {
                  'exerciseId': day == 2 ? 'row' : 'press',
                  'name': day == 2 ? 'Cable row' : 'Dumbbell floor press',
                  'sets': 3,
                  'repsMin': 10,
                  'repsMax': 10,
                  'weightKg': 14,
                  'weightBasis': 'as_logged',
                  'weightUnit': 'per_hand',
                  'setPrescriptions': [
                    {
                      'setNumber': 1,
                      'repsMin': 10,
                      'repsMax': 10,
                      'weightKg': 12
                    },
                    {
                      'setNumber': 2,
                      'repsMin': 10,
                      'repsMax': 10,
                      'weightKg': 14
                    },
                    {
                      'setNumber': 3,
                      'repsMin': 10,
                      'repsMax': 10,
                      'weightKg': 14
                    },
                  ],
                  'targetRpe': 7,
                  'restSeconds': 90,
                  'reason': 'A familiar movement from your previous logs.',
                },
              ],
      },
  ],
  'nutrition': {
    'status': 'RECOMMENDED',
    'days': [
      for (var day = 0; day < 7; day++)
        {
          'date': '2026-10-${12 + day}',
          'totals': {'calories': 2100 + day * 100, 'protein': 130 + day},
          'meals': [
            {
              'mealType': 'BREAKFAST',
              'foods': [
                {'name': day == 1 ? 'Greek yogurt' : 'Oats', 'grams': 80},
              ]
            },
          ],
        },
    ],
  },
};

Widget _app({double scale = 1, bool reduced = false, Key? capture}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: reduced),
          child: child!),
      home: FitnessTheme(
          child: Scaffold(
        appBar: AppBar(title: const Text('Your weekly plan')),
        body: RepaintBoundary(
            key: capture,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Oct 12 – Oct 18',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    WeeklyPlanSchedule(
                        payload: _payload,
                        showOverview: false,
                        loadExercise: (id) async {
                          final exercise = (_payload['workouts'] as List)
                              .expand((day) => day['exercises'] as List)
                              .cast<Map>()
                              .firstWhere((e) => e['exerciseId'] == id);
                          return WorkoutExerciseModel.fromJson({
                            'id': id,
                            'name': exercise['displayName'] ?? exercise['name'],
                          });
                        }),
                  ]),
            )),
      )),
    );

void main() {
  testWidgets('Refreshing the planner preserves the selected day',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-14')));
    await tester.pumpAndSettle();
    expect(find.text('Cable row'), findsOneWidget);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Cable row'), findsOneWidget);
    expect(find.text('Dumbbell floor press'), findsNothing);
  });
  testWidgets('Reduced motion leaves the day controls immediately usable',
      (tester) async {
    await tester.pumpWidget(_app(reduced: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-13')));
    await tester.pumpAndSettle();
    expect(find.text('Rest & recharge'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets('Localized exercise names display without changing set targets',
      (tester) async {
    final day = (_payload['workouts'] as List).first as Map;
    final exercise = (day['exercises'] as List).first as Map;
    exercise['displayName'] = 'Brystpres med håndvægte';
    addTearDown(() => exercise.remove('displayName'));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Brystpres med håndvægte'), findsOneWidget);
    expect(find.text('Dumbbell floor press'), findsNothing);
    expect(find.text('12–14 kg / hand'), findsOneWidget);
    expect(exercise['name'], 'Dumbbell floor press');
  });

  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });

  testWidgets('Selecting a day changes both the workout and its food',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('12–14 kg / hand'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-13')));
    await tester.pumpAndSettle();
    expect(find.text('Rest & recharge'), findsOneWidget);
    expect(find.text('Dumbbell floor press'), findsNothing);
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.text('Greek yogurt · 80 g'), findsOneWidget);
    expect(find.text('2200 kcal · 131 g protein'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-14')));
    await tester.pumpAndSettle();
    expect(find.text('Oats · 80 g'), findsOneWidget);
    expect(find.text('2300 kcal · 132 g protein'), findsOneWidget);
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();
    expect(find.text('Cable row'), findsOneWidget);
    expect(find.text('Back and biceps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Day details fit a small phone with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(scale: 1.8));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dumbbell floor press'));
    expect(find.text('12–14 kg / hand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Capture the native weekly-plan day layout', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const capture = ValueKey('weekly-plan-day-preview');
    await tester.pumpWidget(_app(capture: capture));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/weekly-plan-day.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
