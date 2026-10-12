import 'package:flutter/material.dart';
import '../theme/ds_colors.dart';

// Shared dark dashboard card. Kept intentionally light so dense screens scroll smoothly.
class LiquidGlassBox extends StatelessWidget {
  final Widget child;
  final Color? glow;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.glow,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.borderRadius = 28.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: DSColors.specularBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.035),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      padding: const EdgeInsets.all(0.8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DSColors.glassCardGradient,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      stops: const [0, 0.26, 1],
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.018),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: Container(
                  height: 0.7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFB8C1C8).withValues(alpha: 0.20),
                        const Color(0xFF9DA7AF).withValues(alpha: 0.09),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius - 1),
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(child: content);
  }
}

// Shared compact chip for secondary workout metadata.
class LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isElevated;
  final VoidCallback? onTap;

  const LiquidGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 16.0,
    this.isElevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: DSColors.specularBorder,
      ),
      padding: const EdgeInsets.all(0.7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: isElevated ? DSColors.bgRaised : DSColors.bgInset,
              ),
            ),
            if (isElevated)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.015),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius - 1),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );

    return pill;
  }
}

/// Lightweight silver-glass action surface shared by primary screen controls.
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool prominent;
  final EdgeInsetsGeometry padding;

  const LiquidGlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 44,
    this.borderRadius = 24,
    this.prominent = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: DSColors.specularBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(0.8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: prominent
                      ? DSColors.actionGlassGradient
                      : DSColors.glassControlGradient,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  height: 0.7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFB8C1C8).withValues(
                          alpha: prominent ? 0.32 : 0.18,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius - 1),
                child: Padding(
                  padding: padding,
                  child: Center(child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact icon tile shared by dashboard sections.
class LiquidOrbIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const LiquidOrbIcon({
    super.key,
    required this.icon,
    this.iconColor,
    this.size = 36.0,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DSColors.specularBorder,
      ),
      padding: const EdgeInsets.all(0.7),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: DSColors.bgRaised,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

// MARK: - Metallic Silver Sparkline Histogram Bars
/// Restrained histogram bars for compact health metrics.
class LiquidSparklineBars extends StatelessWidget {
  final List<double> values;
  final double width;
  final double height;

  const LiquidSparklineBars({
    super.key,
    this.values = const [0.35, 0.50, 0.40, 0.70, 0.60, 0.85],
    this.width = 38.0,
    this.height = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((val) {
          final barH = (val.clamp(0.18, 1.0) * height);
          return Container(
            width: 3.5,
            height: barH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              color: Colors.white.withValues(alpha: 0.56),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Quiet status label used on workout and recovery cards.
class LiquidStatusBadge extends StatelessWidget {
  final String label;
  final Color dotColor;
  final TextStyle? textStyle;

  const LiquidStatusBadge({
    super.key,
    required this.label,
    this.dotColor = const Color(0xFF30D158),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPill(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ),
    );
  }
}
