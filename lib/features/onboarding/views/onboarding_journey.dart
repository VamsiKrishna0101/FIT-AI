import 'package:flutter/widgets.dart';
import '../viewmodels/onboarding_controller.dart';
import 'goal_selection_view.dart';

/// Original Setcraft setup sequence, sharing one saved draft across its routes.
abstract final class OnboardingJourney {
  static Widget start(OnboardingController controller) =>
      GoalSelectionView(controller: controller);
}
