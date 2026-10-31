import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/training_schedule_models.dart';

// MARK: - Apple iOS Premium Duration Segmented Stadium Bar (Screen 04)
/// Unified 4-option frosted glass segmented control matching ScheduleFrequencyPills.
class DurationGridChips extends StatelessWidget {
  final WorkoutDurationOption? selectedDuration;
  final ValueChanged<WorkoutDurationOption> onSelected;
  final String Function(WorkoutDurationOption) titleBuilder;

  const DurationGridChips({
    super.key,
    required this.selectedDuration,
    required this.onSelected,
    required this.titleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const options = WorkoutDurationOption.values;

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
        children: options.map((option) {
          final isSelected = selectedDuration == option;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DurationPill(
                label: titleBuilder(option),
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(option);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DurationPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DurationPill> createState() => _DurationPillState();
}

class _DurationPillState extends State<_DurationPill> {
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: null,
              fontSize: 14.5,
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
