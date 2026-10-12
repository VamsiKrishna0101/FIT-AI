import 'package:flutter/material.dart';
import '../theme/ds_colors.dart';
import '../theme/ds_radius.dart';

// MARK: - Reusable Liquid Glass Container in Flutter
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? glowColor;
  final double glowRadius;
  final double glowOpacity;
  final Color surfaceColor;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double surfaceOpacity;
  final bool showSheen;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = DSRadius.card,
    this.glowColor,
    this.glowRadius = 32.0,
    this.glowOpacity = 0.2,
    this.surfaceColor = DSColors.bgCard,
    this.padding,
    this.blurSigma = 0.0,
    this.surfaceOpacity = 1.0,
    this.showSheen = true,
  });

  @override
  Widget build(BuildContext context) {
    final base = surfaceColor.withValues(alpha: surfaceOpacity);
    final top = Color.lerp(base, const Color(0xFF5A6269), 0.20)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: DSColors.specularBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: glowOpacity * 0.18),
              blurRadius: glowRadius,
              spreadRadius: 1,
            ),
        ],
      ),
      padding: const EdgeInsets.all(0.8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, base, DSColors.bgElevated],
                    stops: const [0, 0.24, 1],
                  ),
                ),
              ),
            ),
            if (showSheen)
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                height: 28,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: DSColors.glassSheen,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}
