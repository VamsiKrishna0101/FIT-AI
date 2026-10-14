import '../../../../core/theme/ds_motion.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

const planGlow = Color(0xFF00DDA8);

/// Decorative motion is independent of the confirmed planning percentage.
class PlanParticleOrb extends StatefulWidget {
  final int percent;
  final bool animating;

  const PlanParticleOrb({
    super.key,
    required this.percent,
    this.animating = true,
  });

  @override
  State<PlanParticleOrb> createState() => _PlanParticleOrbState();
}

class _PlanParticleOrbState extends State<PlanParticleOrb>
    with TickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  );
  late final _progress = AnimationController(
    vsync: this,
    duration: DSMotion.chart,
    upperBound: 100,
    value: widget.percent.toDouble(),
  );
  late final _particles = _makeParticles();

  List<_Particle> _makeParticles() {
    final random = math.Random(42);
    return List.generate(
        300,
        (_) => _Particle(
              angle: random.nextDouble() * math.pi * 2,
              distance: .48 + math.pow(random.nextDouble(), .36) * .49,
              radius: .35 + random.nextDouble() * 1.7,
              brightness: .25 + random.nextDouble() * .7,
              speed: random.nextBool() ? 1 : -1,
            ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(PlanParticleOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
    if (oldWidget.percent != widget.percent) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _progress.value = widget.percent.toDouble();
      } else {
        _progress.animateTo(widget.percent.toDouble(), curve: DSMotion.effects);
      }
    }
  }

  void _updateMotion() {
    if (DSMotion.reduced(context)) {
      _progress.stop();
      _progress.value = widget.percent.toDouble();
    }
    final enabled = widget.animating &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (enabled && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!enabled) {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: CustomPaint(
                    painter: _OrbPainter(
              motion: _motion,
              particles: _particles,
              progress: _progress,
            ))),
            Semantics(
              label: 'Plan progress ${widget.percent} percent',
              child: ExcludeSemantics(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${widget.percent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2,
                        height: 1.1,
                      )),
                  const SizedBox(height: 9),
                  const FitnessText('YOUR WEEK',
                      style: TextStyle(
                        color: Color(0xFFB9C5C2),
                        fontSize: 10,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              )),
            ),
          ]),
        ),
      );
}

class _Particle {
  final double angle, distance, radius, brightness, speed;
  const _Particle(
      {required this.angle,
      required this.distance,
      required this.radius,
      required this.brightness,
      required this.speed});
}

class _OrbPainter extends CustomPainter {
  final Animation<double> motion;
  final List<_Particle> particles;
  final Animation<double> progress;

  _OrbPainter(
      {required this.motion, required this.particles, required this.progress})
      : super(repaint: Listenable.merge([motion, progress]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .435;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final phase = motion.value * math.pi * 2;
    final paint = Paint();

    paint.shader = const RadialGradient(
      colors: [
        Color(0x0000DDA8),
        Color(0x0000DDA8),
        Color(0x1800DDA8),
        Color(0x5000DDA8),
        Color(0x0000DDA8)
      ],
      stops: [0, .5, .78, .91, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 1.12));
    canvas.drawCircle(center, radius * 1.12, paint);
    paint.shader = null;

    paint.color = planGlow.withValues(alpha: .26);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawCircle(center, radius, paint);
    paint.color = planGlow.withValues(alpha: .85);
    paint.strokeWidth = 1.7;
    canvas.drawArc(
        bounds, -math.pi / 2, math.pi * 2 * progress.value / 100, false, paint);
    paint.style = PaintingStyle.fill;

    for (final particle in particles) {
      final angle = particle.angle + phase * particle.speed;
      final distance = radius * particle.distance;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final shimmer = .78 + .22 * math.sin(phase * 2 + particle.angle);
      final dotRadius = particle.radius * size.shortestSide / 320;

      if (particle.radius > 1.6) {
        paint.color = planGlow.withValues(alpha: .07 * shimmer);
        canvas.drawCircle(point, dotRadius * 3, paint);
      }
      paint.color = planGlow.withValues(alpha: particle.brightness * shimmer);
      canvas.drawCircle(point, dotRadius, paint);
    }

    // Fade the inner particles so the percentage stays crisp and readable.
    paint.shader = const RadialGradient(
      colors: [Color(0xFF0B1110), Color(0xFF0B1110), Color(0x000B1110)],
      stops: [0, .65, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius * .64));
    canvas.drawCircle(center, radius * .64, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
