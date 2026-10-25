import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/onboarding/models/training_style.dart';
import 'package:fitai_mobile/features/onboarding/components/training_style_picker.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_scaffold.dart';
import 'package:fitai_mobile/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';
import 'package:fitai_mobile/features/train/components/workout_warmup.dart';

void main() {
  testWidgets(
      'Focus allows more than three muscles and Full body restores balance',
      (tester) async {
    final controller = OnboardingController(
        load: () async => OnboardingDraft(
            daysPerWeek: 'DAYS_3',
            trainingSplit: 'MUSCLE_FOCUSED',
            focusMuscles: ['chest', 'biceps', 'triceps']),
        save: (_) async {});
    await controller.initialize();
    await tester.pumpWidget(MaterialApp(
        home: TrainingPreferencesView(
            controller: controller, onContinue: () {})));
    await tester.pumpAndSettle();
    final shoulder = find.text('Shoulders').first;
    await tester.ensureVisible(shoulder);
    await tester.tap(shoulder);
    await tester.pumpAndSettle();
    expect(controller.draft.focusMuscles.length, 4);
    final balanced = find.byKey(const ValueKey('focus-full-body'));
    await tester.ensureVisible(balanced);
    await tester.tap(balanced);
    await tester.pumpAndSettle();
    expect(controller.draft.focusMuscles, isEmpty);
    expect(controller.draft.trainingSplit, 'MUSCLE_FOCUSED');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  test('All muscle-day previews match the shared server schedule contract', () {
    final cases = jsonDecode(
        File('test/fixtures/training_styles.json').readAsStringSync()) as Map;
    for (final entry in cases.entries) {
      expect(TrainingStylePreview.focused(int.parse(entry.key)), entry.value);
    }
  });
  test(
      'Recommendation responds to profile; a beginner can keep custom muscle days',
      () {
    final draft = OnboardingDraft(
        daysPerWeek: 'DAYS_6_PLUS',
        workoutDuration: 'MIN_45',
        experienceLevel: 'INTERMEDIATE',
        workingToward: 'GET_STRONGER',
        trainingLocation: 'GYM');
    expect(TrainingStylePreview(draft).recommended, 'PUSH_PULL_LEGS');
    draft.experienceLevel = 'BEGINNER';
    expect(TrainingStylePreview(draft).recommended, 'MUSCLE_FOCUSED');
    draft.trainingSplit = 'CUSTOM';
    draft.trainingDays = ['THURSDAY', 'MONDAY'];
    draft.customTrainingSplit = {
      'MONDAY': ['chest', 'triceps'],
      'THURSDAY': ['back', 'legs']
    };
    final preview = TrainingStylePreview(draft);
    expect(preview.groups, [
      ['chest', 'triceps'],
      ['back', 'legs']
    ]);
    expect(preview.incompleteCustom, false);
  });
  testWidgets('Recommendation exposes readable alternatives at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final draft =
        OnboardingDraft(daysPerWeek: 'DAYS_3', experienceLevel: 'BEGINNER');
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MediaQuery(
                    data: const MediaQueryData(
                        textScaler: TextScaler.linear(1.6)),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: TrainingStylePicker(
                            draft: draft, onChanged: (v) => selected = v)))))));
    expect(find.text('Recommended for you'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('training-style-alternatives')), 200);
    await tester.tap(find.byKey(const ValueKey('training-style-alternatives')));
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('training-style-MUSCLE_FOCUSED'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
    expect(selected, 'MUSCLE_FOCUSED');
    expect(find.text('Upper / lower'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Final preferences continue directly without a confirmation checkbox',
      (tester) async {
    var continued = 0;
    final controller = OnboardingController(
        load: () async => OnboardingDraft(name: 'Elena', daysPerWeek: 'DAYS_3'),
        save: (_) async {});
    await controller.initialize();
    await tester.pumpWidget(MaterialApp(
        home: TrainingPreferencesView(
            controller: controller, onContinue: () => continued++)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!();
      await tester.pumpAndSettle();
    }
    final scaffold =
        tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold));
    scaffold.onContinue!();
    await tester.pumpAndSettle();
    expect(continued, 1);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(controller.draft.completedStep, 7);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
      'Warm-up is informational and never exposes working-set log controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: WorkoutWarmup(warmup: {
      'durationMinutes': 5,
      'note': 'Preparation only',
      'steps': [
        {'name': 'Easy movement', 'instruction': 'Walk gently', 'seconds': 120},
        {
          'name': 'Chest press',
          'instruction': 'Use a light load',
          'seconds': 180,
          'reps': 8,
          'weightKg': 5
        }
      ]
    }))));
    await tester.tap(find.text('Warm-up'));
    await tester.pumpAndSettle();
    expect(find.text('8 practice reps'), findsOneWidget);
    expect(find.text('Log set'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
