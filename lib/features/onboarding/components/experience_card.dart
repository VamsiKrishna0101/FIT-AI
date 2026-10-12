import 'package:flutter/material.dart';
import '../models/experience_level.dart';
import 'onboarding_scaffold.dart';

class ExperienceCard extends StatelessWidget {
  final ExperienceLevel level;
  final String title, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const ExperienceCard(
      {super.key,
      required this.level,
      required this.title,
      required this.subtitle,
      required this.isSelected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => OnboardingChoice(
      title: title, subtitle: subtitle, selected: isSelected, onTap: onTap);
}
