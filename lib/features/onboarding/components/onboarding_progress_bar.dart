import 'package:flutter/material.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';

/// Completed screens in the setup journey, without a visible step count.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double? progress;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
    this.progress,
  }) : assert(totalSteps > 0);

  @override
  Widget build(BuildContext context) {
    final completed =
        (progress ?? (currentStep - 1) / totalSteps).clamp(0.0, 1.0);
    final previous = ((currentStep - 2) / totalSteps).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: previous, end: completed),
          duration: DSMotion.duration(context, DSMotion.regular),
          curve: DSMotion.standard,
          builder: (context, progress, _) => Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF292929)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  key: const ValueKey('onboarding-progress-fill'),
                  widthFactor: progress,
                  heightFactor: 1,
                  child: const ColoredBox(color: FitnessTheme.silver),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
