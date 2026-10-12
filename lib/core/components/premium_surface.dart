import 'package:flutter/material.dart';

import '../theme/ds_colors.dart';

class PremiumSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: DSColors.border, width: 0.7),
    );
    return Material(
      color: color ?? DSColors.bgCard,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PremiumSectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const PremiumSectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DSColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.35,
            ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTrailingTap,
            style: TextButton.styleFrom(
              foregroundColor: DSColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(44, 40),
            ),
            child: Text(trailing!),
          ),
      ],
    );
  }
}

class PremiumProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const PremiumProgressBar({
    super.key,
    required this.value,
    this.color = DSColors.accent,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
