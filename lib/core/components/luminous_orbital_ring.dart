import '../theme/ds_motion.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// MARK: - Whoop 5.0 Luminous Stardust Orbital Ring Hero
class LuminousOrbitalRing extends StatefulWidget {
  final double score;
  final String label;
  final String title;
  final String leftMetric;
  final String leftLabel;
  final String rightMetric;
  final String rightLabel;
  final Color primaryGlow;
  final Color secondaryGlow;
  final double size;

  const LuminousOrbitalRing({
    super.key,
    required this.score,
    this.label = 'READINESS SCORE',
    this.title = 'FITAI RECOVERY',
    this.leftMetric = '+4.2%',
    this.leftLabel = 'VS BASELINE',
    this.rightMetric = '-0.8x',
    this.rightLabel = 'STRAIN PACE',
    this.primaryGlow = const Color(0xFFE5A93C),
    this.secondaryGlow = const Color(0xFF30D158),
    this.size = 176.0,
  });

  @override
  State<LuminousOrbitalRing> createState() => _LuminousOrbitalRingState();
}

class _LuminousOrbitalRingState extends State<LuminousOrbitalRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: DSMotion.chart,
      upperBound: .03,
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) {
      _rotationCtrl.stop();
      _rotationCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Hero Ring with Flanking Satellites ───────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Satellite Metric Pill
              Expanded(
                child: _SatellitePill(
                  metric: widget.leftMetric,
                  label: widget.leftLabel,
                  alignment: CrossAxisAlignment.center,
                ),
              ),

              // Center Stardust Hero Ring
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A) Rotating Particle Canvas
                    AnimatedBuilder(
                      animation: _rotationCtrl,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _StardustRingPainter(
                            rotation: _rotationCtrl.value * 2 * math.pi,
                            primaryColor: widget.primaryGlow,
                            secondaryColor: widget.secondaryGlow,
                          ),
                        );
                      },
                    ),

                    // B) Inner Frosted Glass Lens
                    Container(
                      width: widget.size * 0.72,
                      height: widget.size * 0.72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 0.85,
                          colors: [
                            const Color(0xFF1E2125),
                            const Color(0xFF0E1013),
                            const Color(0xFF050608).withValues(alpha: 0.96),
                          ],
                        ),
                        border: Border.all(
                          color: widget.primaryGlow.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryGlow.withValues(alpha: 0.18),
                            blurRadius: 28,
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Numeric Score with Tabular Figures
                          Text(
                            widget.score > 0
                                ? widget.score.toInt().toString()
                                : '—',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.2,
                              height: 1.05,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Micro Subtitle
                          Text(
                            widget.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right Satellite Metric Pill
              Expanded(
                child: _SatellitePill(
                  metric: widget.rightMetric,
                  label: widget.rightLabel,
                  alignment: CrossAxisAlignment.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SatellitePill extends StatelessWidget {
  final String metric;
  final String label;
  final CrossAxisAlignment alignment;

  const _SatellitePill({
    required this.metric,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metric,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Colors.white.withValues(alpha: 0.52),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// MARK: - Stardust Ring Canvas Painter
class _StardustRingPainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color secondaryColor;

  static final List<_StarParticle> _cachedStars = _generateStars(52);

  _StardustRingPainter({
    required this.rotation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static List<_StarParticle> _generateStars(int count) {
    final rand = math.Random(1337);
    return List.generate(count, (i) {
      final baseRadius = 0.40 + rand.nextDouble() * 0.08;
      final speedMult = 0.7 + rand.nextDouble() * 0.6;
      final angle = rand.nextDouble() * 2 * math.pi;
      final size = 0.8 + rand.nextDouble() * 2.2;
      final alpha = 0.35 + rand.nextDouble() * 0.65;
      final isSecondary = rand.nextDouble() > 0.65;
      return _StarParticle(
        baseRadius: baseRadius,
        angle: angle,
        speedMultiplier: speedMult,
        size: size,
        alpha: alpha,
        isSecondary: isSecondary,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Ambient Glow Torus
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          primaryColor.withValues(alpha: 0.05),
          primaryColor.withValues(alpha: 0.35),
          secondaryColor.withValues(alpha: 0.45),
          primaryColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.76));

    canvas.drawCircle(center, radius * 0.76, glowPaint);

    // 2. Continuous Micro Track Ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          primaryColor.withValues(alpha: 0.15),
          primaryColor.withValues(alpha: 0.85),
          secondaryColor.withValues(alpha: 0.90),
          primaryColor.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.76));

    canvas.drawCircle(center, radius * 0.76, trackPaint);

    // 3. Stardust Micro Particles
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final star in _cachedStars) {
      final currentAngle = star.angle + (rotation * star.speedMultiplier);
      final r = radius * star.baseRadius * 2;
      final px = center.dx + r * math.cos(currentAngle);
      final py = center.dy + r * math.sin(currentAngle);

      final color = star.isSecondary ? secondaryColor : primaryColor;
      starPaint.color = color.withValues(alpha: star.alpha);

      // Star point
      canvas.drawCircle(Offset(px, py), star.size, starPaint);

      // Bright core highlight for larger particles
      if (star.size > 2.0) {
        starPaint.color = Colors.white.withValues(alpha: star.alpha * 0.85);
        canvas.drawCircle(Offset(px, py), star.size * 0.5, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StardustRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _StarParticle {
  final double baseRadius;
  final double angle;
  final double speedMultiplier;
  final double size;
  final double alpha;
  final bool isSecondary;

  const _StarParticle({
    required this.baseRadius,
    required this.angle,
    required this.speedMultiplier,
    required this.size,
    required this.alpha,
    required this.isSecondary,
  });
}
