import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/training_schedule_models.dart';

// MARK: - Full-Width Liquid Glass Location Cards (Screen 05 — Apple iOS Focus)
class LocationGridCards extends StatelessWidget {
  final TrainingLocationOption? selectedLocation;
  final ValueChanged<TrainingLocationOption> onSelected;
  final String Function(TrainingLocationOption) titleBuilder;

  const LocationGridCards({
    super.key,
    required this.selectedLocation,
    required this.onSelected,
    required this.titleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const options = TrainingLocationOption.values;

    return Column(
      children: options.map((option) {
        final isSelected = selectedLocation == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LocationAppleCard(
            option: option,
            isSelected: isSelected,
            title: titleBuilder(option),
            onTap: () => onSelected(option),
          ),
        );
      }).toList(),
    );
  }
}

class LocationAppleCard extends StatefulWidget {
  final TrainingLocationOption option;
  final bool isSelected;
  final String title;
  final VoidCallback onTap;

  const LocationAppleCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.title,
    required this.onTap,
  });

  @override
  State<LocationAppleCard> createState() => _LocationAppleCardState();
}

class _LocationAppleCardState extends State<LocationAppleCard> {
  bool _pressed = false;

  String get _subtitle {
    switch (widget.option) {
      case TrainingLocationOption.gym:
        return 'Barbells, dumbbells & machines';
      case TrainingLocationOption.home:
        return 'Dumbbells, resistance bands or mat';
      case TrainingLocationOption.outdoors:
        return 'Parks, tracks & calisthenics';
      case TrainingLocationOption.mix:
        return 'Flexible hybrid routine across spaces';
    }
  }

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
        scale: _pressed ? 0.98 : (isSelected ? 1.01 : 1.0),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF202020),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.10),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              // Title & Micro-copy Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FitnessText(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: null,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FitnessText(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: null,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.1,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.55)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Apple Minimal Radio Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.20),
                    width: 1.6,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 10 : 0,
                  height: isSelected ? 10 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
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
