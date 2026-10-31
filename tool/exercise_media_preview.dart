// Read-only device preview. It does not sign in or change a workout/account.
// Pass a public GIF URL as EXERCISE_PROBE_GIF with --dart-define-from-file.
import 'package:flutter/material.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_detail_view.dart';
import 'package:setcraft/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.shared.init();
  const url = String.fromEnvironment('EXERCISE_PROBE_GIF');
  if (!url.startsWith('https://')) throw StateError('Provide a public GIF URL');
  runApp(const app.SetcraftApp(
      initialHome: ExerciseDetailView(
          loadDetail: false,
          exercise: WorkoutExerciseModel(
              id: 'media-preview',
              name: 'all fours squad stretch',
              bodyPart: 'Upper legs',
              target: 'Quads',
              secondaryMuscles: ['Hamstrings', 'Glutes'],
              equipment: 'Body weight',
              difficulty: 'BEGINNER',
              category: 'Upper legs',
              description: '',
              url: url,
              instructions: [
                'Start on all fours with your hands directly under your shoulders and your knees directly under your hips.',
                'Extend one leg straight back, keeping your knee bent and your foot flexed.',
                'Slowly lower your hips towards the ground, feeling a stretch in your quads.',
                'Hold this position for 20–30 seconds.',
                'Switch legs and repeat the stretch on the other side.',
              ]))));
}
