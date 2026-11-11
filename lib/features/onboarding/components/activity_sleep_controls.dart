import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';

import '../models/lifestyle_nutrition_models.dart';
import 'onboarding_coach.dart';

// MARK: - Apple iOS Activity Level Segmented Selector (Screen 06)
class ActivityLevelSegmented extends StatelessWidget {
  final ActivityLevelOption selectedOption;
  final ValueChanged<ActivityLevelOption> onSelected;

  const ActivityLevelSegmented({
    super.key,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = ActivityLevelOption.values;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selectedOption;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ActivityPill(
                label: opt.defaultLabel,
                isSelected: isSelected,
                onTap: () {
                  OnboardingCoach.select();
                  onSelected(opt);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ActivityPill> createState() => _ActivityPillState();
}

class _ActivityPillState extends State<_ActivityPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: DSMotion.duration(context, DSMotion.press),
        curve: DSMotion.effects,
        child: AnimatedContainer(
          duration: DSMotion.duration(context, DSMotion.selection),
          curve: DSMotion.effects,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: DSColors.bgCard,
            border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                width: 0.8),
          ),
          child: FitnessText(
            widget.label,
            style: TextStyle(
              fontFamily: null,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: -0.2,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Apple iOS Sleep Duration Segmented Control (Screen 06)
class SleepDurationChips extends StatelessWidget {
  final SleepDurationOption selectedOption;
  final ValueChanged<SleepDurationOption> onSelected;

  const SleepDurationChips({
    super.key,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = SleepDurationOption.values;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selectedOption;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _SleepPill(
                label: opt.defaultLabel,
                isSelected: isSelected,
                onTap: () {
                  OnboardingCoach.select();
                  onSelected(opt);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SleepPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SleepPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SleepPill> createState() => _SleepPillState();
}

class _SleepPillState extends State<_SleepPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: DSMotion.duration(context, DSMotion.press),
        curve: DSMotion.effects,
        child: AnimatedContainer(
          duration: DSMotion.duration(context, DSMotion.selection),
          curve: DSMotion.effects,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: DSColors.bgCard,
            border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                width: 0.8),
          ),
          child: FitnessText(
            widget.label,
            style: TextStyle(
              fontFamily: null,
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: -0.2,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
