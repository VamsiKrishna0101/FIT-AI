import 'package:flutter/material.dart';
import '../../../core/theme/ds_motion.dart';

/// Apple iOS style segmented stadium capsule progress bar for onboarding.
/// Features 6.8px stadium pills with luminous white active glow and dark smoked glass inactive pills.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep; // 1-indexed
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              final isFilled = step <= currentStep;

              return Expanded(
                child: AnimatedContainer(
                  duration: DSMotion.duration(context, DSMotion.selection),
                  curve: DSMotion.effects,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 6.0 : 0,
                  ),
                  height: 6.8,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? Colors.white
                        : const Color(0xFF1E222A).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
