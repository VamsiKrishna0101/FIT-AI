import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';

class BodyProgressCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const BodyProgressCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.highlighted = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .085)),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlighted
                  ? [const Color(0xFF353535), const Color(0xFF1D1D1D)]
                  : [const Color(0xFF252525), const Color(0xFF181818)]),
        ),
        child: child,
      );
}

class BodyNavigationRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;

  const BodyNavigationRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: FitnessTheme.silver, size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    FitnessText(subtitle,
                        style: const TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 11,
                            height: 1.4)),
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: FitnessTheme.muted, size: 20),
            ]),
          ),
        ),
      );
}
