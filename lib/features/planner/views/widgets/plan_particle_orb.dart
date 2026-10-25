import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/ds_colors.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

const planGlow = DSColors.silver;

/// Activity motion stays alive while waiting for confirmed planning progress.
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
    animationBehavior: AnimationBehavior.preserve,
  );
  late final _progress = AnimationController(
    vsync: this,
    duration: DSMotion.chart,
    upperBound: 100,
    value: widget.percent.toDouble(),
    animationBehavior: AnimationBehavior.preserve,
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
      // Count only to the latest server-confirmed value, never a timed estimate.
      _progress.animateTo(widget.percent.toDouble(),
          duration: DSMotion.reduced(context) ? DSMotion.fast : DSMotion.chart,
          curve: DSMotion.effects);
    }
  }

  void _updateMotion() {
    // This is ongoing activity feedback. Keep it subtle with reduced motion,
    // and pause it whenever the route/app stops being active.
    final enabled = widget.animating && TickerMode.valuesOf(context).enabled;
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
              active: widget.animating,
              gentle: DSMotion.reduced(context),
            ))),
            Semantics(
              label: 'Plan progress ${widget.percent} percent',
              child: ExcludeSemantics(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => Text('${_progress.value.round()}%',
                        key: const ValueKey('plan-progress-label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -2,
                          height: 1.1,
                        )),
                  ),
                  const SizedBox(height: 9),
                  const FitnessText('YOUR WEEK',
                      style: TextStyle(
                        color: DSColors.muted,
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
  final bool active, gentle;

  _OrbPainter(
      {required this.motion,
      required this.particles,
      required this.progress,
      required this.active,
      required this.gentle})
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
        Color(0x00E2E2E2),
        Color(0x00E2E2E2),
        Color(0x18E2E2E2),
        Color(0x50E2E2E2),
        Color(0x00E2E2E2)
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
    if (active) {
      // A separate moving highlight communicates activity even during a long
      // model call. It never extends the server-confirmed progress arc.
      final activityRadius = radius + 6;
      paint.color = planGlow.withValues(alpha: gentle ? .5 : .75);
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 1.5;
      canvas.drawArc(Rect.fromCircle(center: center, radius: activityRadius),
          phase * 3 - math.pi / 2, math.pi * .18, false, paint);
      paint.strokeCap = StrokeCap.butt;
    }
    paint.style = PaintingStyle.fill;

    for (final particle in particles) {
      final angle =
          particle.angle + phase * particle.speed * (gentle ? .35 : 1);
      final distance = radius * particle.distance;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final shimmer = .78 + .22 * math.sin(phase * 4 + particle.angle);
      final dotRadius = particle.radius * size.shortestSide / 320;

      if (particle.radius > 1.6) {
        paint.color = planGlow.withValues(alpha: .07 * shimmer);
        canvas.drawCircle(point, dotRadius * 3, paint);
      }
      paint.color = planGlow.withValues(alpha: particle.brightness * shimmer);
      canvas.drawCircle(point, dotRadius, paint);
      if (particle.radius > 1.9) {
        paint.strokeWidth = .7;
        canvas.drawLine(point - Offset(dotRadius * 2, 0),
            point + Offset(dotRadius * 2, 0), paint);
        canvas.drawLine(point - Offset(0, dotRadius * 2),
            point + Offset(0, dotRadius * 2), paint);
      }
    }

    // Fade the inner particles so the percentage stays crisp and readable.
    paint.shader = const RadialGradient(
      colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
      stops: [0, .65, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius * .64));
    canvas.drawCircle(center, radius * .64, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.gentle != gentle;
}
