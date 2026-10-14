import '../../../core/theme/ds_colors.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// MARK: - Apple iOS Premium About You Controls

/// Apple Frosted Liquid Glass Text Field for Name Input
/// Ultra-clean, zero decorative icon clutter, pure Apple typography & glass finish.
class LiquidNameInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const LiquidNameInput({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: DSColors.bgCard,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FitnessText(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: null,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: null,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: null,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
                color: Color(0xFF636366),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-Width Apple iOS Segmented Control for Gender Selection
/// Monochromatic frosted glass aesthetic matching GoalCard.
class AppleGenderSelector extends StatelessWidget {
  final String selectedGender; // 'MALE' or 'FEMALE'
  final String maleLabel;
  final String femaleLabel;
  final ValueChanged<String> onSelected;

  const AppleGenderSelector({
    super.key,
    required this.selectedGender,
    required this.maleLabel,
    required this.femaleLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GenderTab(
              title: maleLabel,
              isSelected: selectedGender == 'MALE',
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected('MALE');
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _GenderTab(
              title: femaleLabel,
              isSelected: selectedGender == 'FEMALE',
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected('FEMALE');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: DSColors.bgCard,
          border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
              width: 0.8),
        ),
        alignment: Alignment.center,
        child: FitnessText(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: null,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: -0.2,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

/// Apple Biometrics Section Header with Integrated Segmented Unit Switcher
class BiometricsHeaderWithUnits extends StatelessWidget {
  final String title;
  final bool isImperial;
  final String imperialLabel;
  final String metricLabel;
  final ValueChanged<bool> onUnitChanged;

  const BiometricsHeaderWithUnits({
    super.key,
    required this.title,
    required this.isImperial,
    required this.imperialLabel,
    required this.metricLabel,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FitnessText(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),
        // Apple Segmented Switcher for Units
        Container(
          height: 30,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: DSColors.bgCard,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UnitTab(
                label: imperialLabel,
                isSelected: isImperial,
                onTap: () {
                  if (!isImperial) {
                    HapticFeedback.selectionClick();
                    onUnitChanged(true);
                  }
                },
              ),
              const SizedBox(width: 3),
              _UnitTab(
                label: metricLabel,
                isSelected: !isImperial,
                onTap: () {
                  if (isImperial) {
                    HapticFeedback.selectionClick();
                    onUnitChanged(false);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              width: 0.8),
        ),
        alignment: Alignment.center,
        child: FitnessText(
          label,
          style: TextStyle(
            fontFamily: null,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

/// Apple Frosted Goal Delta Summary Pill
class AppleGoalSummaryBadge extends StatelessWidget {
  final String text;

  const AppleGoalSummaryBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        ),
      ),
      child: Center(
        child: FitnessText(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: null,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFE5E5EA),
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
