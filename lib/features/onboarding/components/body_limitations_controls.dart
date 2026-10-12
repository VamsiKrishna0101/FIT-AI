import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lifestyle_nutrition_models.dart';

// MARK: - Apple iOS Body Limitations Multi-Select Chips (Screen 08)
class BodyLimitationsChips extends StatelessWidget {
  final Set<BodyLimitationOption> selectedLimitations;
  final ValueChanged<BodyLimitationOption> onToggle;

  const BodyLimitationsChips({
    super.key,
    required this.selectedLimitations,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const options = BodyLimitationOption.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedLimitations.contains(opt);

        return _LimitationChip(
          option: opt,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle(opt);
          },
        );
      }).toList(),
    );
  }
}

class _LimitationChip extends StatefulWidget {
  final BodyLimitationOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LimitationChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LimitationChip> createState() => _LimitationChipState();
}

class _LimitationChipState extends State<_LimitationChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final opt = widget.option;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF303030) : const Color(0xFF202020),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: .9,
            ),
          ),
          child: FitnessText(
            opt.defaultLabel,
            style: TextStyle(
              fontFamily: null,
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: -0.2,
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Apple iOS Custom Injury & Rehab Note Card
class CustomInjuryNoteCard extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onQuickPresetTap;

  const CustomInjuryNoteCard({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    required this.onQuickPresetTap,
  });

  static const _injuryPresets = [
    'Herniated Disc',
    'Rotator Cuff',
    'Meniscus Tear',
    'Sciatica',
    'Tennis Elbow',
    'Plantar Fasciitis',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Injury Presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _injuryPresets.map((preset) {
              final isMatching = controller.text.contains(preset);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onQuickPresetTap(preset);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMatching
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMatching
                          ? Colors.white.withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: FitnessText(
                    preset,
                    style: TextStyle(
                      fontFamily: null,
                      fontSize: 12,
                      fontWeight:
                          isMatching ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: -0.2,
                      color:
                          isMatching ? Colors.white : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Custom Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF101214),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: null,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: null,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
