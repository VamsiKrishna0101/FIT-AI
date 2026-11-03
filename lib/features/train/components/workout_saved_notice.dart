import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../models/training_session.dart';
import '../views/saved_routines_view.dart';

void showWorkoutSavedNotice(BuildContext context, TrainingDay day) {
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(fitnessText(context, 'Saved to My workouts')),
      action: SnackBarAction(
          label: fitnessText(context, 'My workouts'),
          onPressed: () {
            if (navigator.mounted) {
              navigator.push(
                  AppPageRoute<void>(page: SavedRoutinesView(initial: day)));
            }
          })));
}
