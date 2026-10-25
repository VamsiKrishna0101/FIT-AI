import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/onboarding/components/training_style_picker.dart';
import 'package:fitai_mobile/features/train/components/workout_warmup.dart';

void main() {
  testWidgets('Training setup preview preserves neutral surfaces',
      (tester) async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    const key = ValueKey('training-preview');
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
                key: key,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          const Text('Your week. Your way.',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          const Text('A starting plan you can make your own.',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 25),
                          FitnessCard(
                              child: Material(
                                  type: MaterialType.transparency,
                                  child: TrainingStylePicker(
                                      draft: OnboardingDraft(
                                          daysPerWeek: 'DAYS_3',
                                          workoutDuration: 'MIN_45',
                                          experienceLevel: 'BEGINNER',
                                          trainingSplit: 'MUSCLE_FOCUSED',
                                          trainingLocation: 'GYM'),
                                      onChanged: (_) {}))),
                          const SizedBox(height: 20),
                          const WorkoutWarmup(warmup: {
                            'durationMinutes': 5,
                            'note': 'Preparation only.',
                            'steps': [
                              {
                                'name': 'Easy movement',
                                'instruction': 'Walk gently.',
                                'seconds': 120
                              }
                            ]
                          }),
                        ]))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(key))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/training-setup-preview.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
