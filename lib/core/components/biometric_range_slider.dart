import 'package:flutter/material.dart';

// MARK: - Whoop 5.0 Seamless Biometric Range Slider (No Clunky Background Boxes)
class BiometricRangeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String valueDisplay;
  final String unit;
  final double min;
  final double max;
  final String minLabel;
  final String maxLabel;
  final String impactTag;
  final Color impactColor;
  final List<Color> gradientColors;
  final bool showDivider;

  const BiometricRangeSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueDisplay,
    required this.unit,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    required this.impactTag,
    this.impactColor = const Color(0xFF30D158),
    this.gradientColors = const [
      Color(0xFF30D158), // Emerald (Optimal)
      Color(0xFFFFD60A), // Gold / Amber (Moderate)
      Color(0xFFFF453A), // Coral / Red (Elevated)
    ],
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final range = (max - min).clamp(0.0001, double.infinity);
    final ratio = ((value - min) / range).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header Row (Metric Name + Longevity Impact) ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Metric Title (Bold SF Pro style)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Impact Tag (Crisp text with delta)
              Text(
                impactTag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: impactColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. Track & Glowing Pin Thumb ──────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final pinOffset =
                  (trackWidth * ratio).clamp(14.0, trackWidth - 14.0);

              return Column(
                children: [
                  // Floating Value Tag directly above the pin
                  SizedBox(
                    height: 18,
                    child: Stack(
                      children: [
                        Positioned(
                          left: (pinOffset - 28).clamp(0.0, trackWidth - 56.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2126),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  valueDisplay,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                if (unit.isNotEmpty) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Horizontal Gradient Line
                  SizedBox(
                    height: 14,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // The Slender Gradient Bar
                        Container(
                          height: 4.0,
                          width: trackWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(colors: gradientColors),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors.first
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),

                        // The Glowing Pin Thumb
                        Positioned(
                          left: pinOffset - 6.5,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF07080A),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  blurRadius: 7,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 4),

          // ── 3. Endpoint Labels ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          if (showDivider) ...[
            const SizedBox(height: 14),
            Divider(
              height: 0.5,
              thickness: 0.5,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ],
        ],
      ),
    );
  }
}
