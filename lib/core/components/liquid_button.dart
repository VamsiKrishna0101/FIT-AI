import 'motion.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ds_colors.dart';
import '../theme/ds_radius.dart';
import '../theme/ds_typography.dart';

/// A shared, glass-finished primary action for the app.
///
/// Uses Flutter's built-in backdrop blur, so it has a consistent glass-like
/// fallback on Android and older iOS versions without a third-party package.
class LiquidButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final double height;
  final bool isLoading;
  final bool showArrow;
  final bool isAccent;
  final String? semanticLabel;

  const LiquidButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height = 58,
    this.isLoading = false,
    this.showArrow = true,
    this.isAccent = true,
    this.semanticLabel,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _activate() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final label = widget.semanticLabel ?? widget.title;
    final accentGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        DSColors.accent.withValues(alpha: enabled ? 0.84 : 0.70),
        const Color(0xFF83FF72).withValues(alpha: enabled ? 0.80 : 0.66),
      ],
    );
    final surfaceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1C1C1E).withValues(alpha: enabled ? 0.92 : 0.54),
        const Color(0xFF141414).withValues(alpha: enabled ? 0.88 : 0.54),
      ],
    );
    final labelColor =
        widget.isAccent ? DSColors.onAccent : DSColors.textPrimary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _activate : null,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: MotionPress(
          enabled: enabled,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: DSRadius.capsuleRadius,
              boxShadow: enabled && widget.isAccent
                  ? [
                      BoxShadow(
                        color: DSColors.accent
                            .withValues(alpha: _pressed ? 0.12 : 0.22),
                        blurRadius: _pressed ? 14 : 22,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: DSRadius.capsuleRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                        widget.isAccent ? accentGradient : surfaceGradient,
                    borderRadius: DSRadius.capsuleRadius,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: enabled ? (widget.isAccent ? 0.42 : 0.18) : 0.10,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft specular reflection gives the tinted surface depth.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withValues(
                                    alpha: widget.isAccent ? 0.30 : 0.14),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.isLoading)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: labelColor,
                          ),
                        )
                      else ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.showArrow ? 64 : 20,
                          ),
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: DSTypography.family,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: labelColor,
                            ),
                          ),
                        ),
                        if (widget.showArrow)
                          Positioned(
                            right: 10,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                    alpha: widget.isAccent ? 0.28 : 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                      alpha: widget.isAccent ? 0.42 : 0.14),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: labelColor,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
