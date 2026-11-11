import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';

import '../models/training_schedule_models.dart';
import 'onboarding_coach.dart';

// MARK: - Apple iOS Premium Schedule Frequency Segmented Pills
class ScheduleFrequencyPills extends StatelessWidget {
  final DaysPerWeekOption? selectedOption;
  final ValueChanged<DaysPerWeekOption> onSelected;

  const ScheduleFrequencyPills({
    super.key,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
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
        children: DaysPerWeekOption.values.map((option) {
          final label = option.daysCount == 6 ? '6+' : '${option.daysCount}';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _FrequencyPill(
                label: '${label}d',
                isSelected: option == selectedOption,
                onTap: () {
                  OnboardingCoach.select();
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

class _FrequencyPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FrequencyPill> createState() => _FrequencyPillState();
}

class _FrequencyPillState extends State<_FrequencyPill> {
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
              fontSize: 15,
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
