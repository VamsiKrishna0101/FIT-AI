import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_language.dart';
import '../models/lifestyle_nutrition_models.dart';

// MARK: - Apple iOS Eating Style Grid (Screen 07)
class EatingStyleGrid extends StatelessWidget {
  final AppLanguage language;
  final EatingStyleOption selectedOption;
  final ValueChanged<EatingStyleOption> onSelected;

  const EatingStyleGrid({
    super.key,
    required this.language,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = EatingStyleOption.values;

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isLast = index == options.length - 1;
          return SizedBox(
            width:
                isLast ? constraints.maxWidth : (constraints.maxWidth - 8) / 2,
            child: _EatingStyleCard(
              option: option,
              label: language.eatingStyleLabel(option.backendValue),
              isSelected: selectedOption == option,
              onTap: () => onSelected(option),
            ),
          );
        }),
      ),
    );
  }
}

class _EatingStyleCard extends StatefulWidget {
  final EatingStyleOption option;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _EatingStyleCard({
    required this.option,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EatingStyleCard> createState() => _EatingStyleCardState();
}

class _EatingStyleCardState extends State<_EatingStyleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:
                isSelected ? const Color(0xFF303030) : const Color(0xFF202020),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FitnessText(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: -0.2,
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 9 : 0,
                    height: isSelected ? 9 : 0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Apple iOS Optional Input for Custom Diet (Screen 07)
class OtherDietInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const OtherDietInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: 80,
        cursorColor: Colors.white,
        style: const TextStyle(
          fontFamily: null,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            fontFamily: null,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          counterText: '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// MARK: - Apple iOS Weekly Food Budget Segmented Bar (Screen 07)
class FoodBudgetSegmentedBar extends StatelessWidget {
  final WeeklyFoodBudgetOption selectedOption;
  final bool isCustomBudget;
  final ValueChanged<WeeklyFoodBudgetOption> onSelected;
  final VoidCallback onCustomTap;
  final String customLabel;

  const FoodBudgetSegmentedBar({
    super.key,
    required this.selectedOption,
    required this.isCustomBudget,
    required this.onSelected,
    required this.onCustomTap,
    required this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    const options = WeeklyFoodBudgetOption.values;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          ...options.map((opt) {
            final isSelected = !isCustomBudget && opt == selectedOption;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _BudgetTab(
                  label: opt.defaultLabel,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(opt);
                  },
                ),
              ),
            );
          }),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _BudgetTab(
                label: customLabel,
                isSelected: isCustomBudget,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCustomTap();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BudgetTab({
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF202020),
          border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
              width: 0.8),
        ),
        child: FitnessText(
          label,
          style: TextStyle(
            fontFamily: null,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: -0.2,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

// MARK: - Apple iOS Custom Budget Stepper Card
class CustomBudgetStepperCard extends StatelessWidget {
  final double currentBudget;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CustomBudgetStepperCard({
    super.key,
    required this.currentBudget,
    required this.onIncrement,
    required this.onDecrement,
  });

  String get _budgetDescription {
    if (currentBudget < 70) {
      return 'Staple proteins & bulk shopping (Eggs, oats, rice, canned tuna)';
    } else if (currentBudget <= 140) {
      return 'Wholesome balanced groceries (Chicken, ground beef, Greek yogurt, fresh greens)';
    } else {
      return 'Performance nutrition (Steaks, wild salmon, organic berries, supplements)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
              Column(
                children: [
                  FitnessText(
                    '\$${currentBudget.round()}',
                    style: const TextStyle(
                      fontFamily: null,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const FitnessText(
                    'per week',
                    style: TextStyle(
                      fontFamily: null,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
            ],
          ),
          const SizedBox(height: 10),
          FitnessText(
            _budgetDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: null,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Icon(widget.icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
