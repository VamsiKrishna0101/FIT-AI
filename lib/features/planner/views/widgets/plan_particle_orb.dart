import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/ds_colors.dart';
import '../../../../core/localization/fitness_text.dart';

/// A star-filled planning orb; its percentage is always server-confirmed.
class PlanParticleOrb extends StatefulWidget {
  final int percent;
  final bool animating;
  const PlanParticleOrb(
      {super.key, required this.percent, this.animating = true});
  @override
  State<PlanParticleOrb> createState() => _PlanParticleOrbState();
}

class _PlanParticleOrbState extends State<PlanParticleOrb>
    with TickerProviderStateMixin {
  late final _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
      animationBehavior: AnimationBehavior.preserve);
  late final _progress = AnimationController(
      vsync: this,
      duration: DSMotion.chart,
      upperBound: 100,
      value: widget.percent.clamp(0, 100).toDouble(),
      animationBehavior: AnimationBehavior.preserve);
  late final _stars = List.generate(160, (index) {
    final random = math.Random(1042 + index * 31);
    return _Star(
        random.nextDouble() * math.pi * 2,
        math.sqrt(.36 + random.nextDouble() * .62),
        .35 + random.nextDouble() * .85,
        .35 + random.nextDouble() * .65,
        index % 8 == 0,
        index.isEven ? 1 : -1);
  });
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
      _progress.animateTo(widget.percent.clamp(0, 100).toDouble(),
          duration: DSMotion.reduced(context) ? DSMotion.fast : DSMotion.chart,
          curve: DSMotion.effects);
    }
  }

  void _updateMotion() {
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
                    painter: _ProgressPainter(
                        stars: _stars,
                        motion: _motion,
                        progress: _progress,
                        active: widget.animating,
                        gentle: DSMotion.reduced(context)))),
            Semantics(
                label: 'Plan progress ${widget.percent} percent',
                child: ExcludeSemantics(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => Text('${_progress.value.round()}%',
                          key: const ValueKey('plan-progress-label'),
                          style: const TextStyle(
                              fontSize: 44,
                              height: 1.1,
                              letterSpacing: -2,
                              fontWeight: FontWeight.w500,
                              color: Colors.white))),
                  const SizedBox(height: 9),
                  const FitnessText('YOUR WEEK',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: DSColors.muted)),
                ]))),
          ])));
}

class _Star {
  final double angle, distance, radius, brightness;
  final bool sparkle;
  final int direction;
  const _Star(this.angle, this.distance, this.radius, this.brightness,
      this.sparkle, this.direction);
}

class _ProgressPainter extends CustomPainter {
  final Animation<double> motion, progress;
  final List<_Star> stars;
  final bool active, gentle;
  _ProgressPainter(
      {required this.motion,
      required this.progress,
      required this.stars,
      required this.active,
      required this.gentle})
      : super(repaint: Listenable.merge([motion, progress]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .42;
    final phase = motion.value * math.pi * 2;
    final paint = Paint();
    paint.shader = const RadialGradient(colors: [
      Color(0x00000000),
      Color(0x00000000),
      Color(0x0FE2E2E2),
      Color(0x00E2E2E2)
    ], stops: [
      0,
      .5,
      .85,
      1
    ]).createShader(Rect.fromCircle(center: center, radius: radius * 1.12));
    canvas.drawCircle(center, radius * 1.12, paint);
    paint.shader = null;
    for (final star in stars) {
      final angle = star.angle + phase * star.direction * (gentle ? 0 : 1);
      final point = center +
          Offset(math.cos(angle), math.sin(angle)) * radius * star.distance;
      final shimmer = gentle
          ? .82 + .12 * math.sin(phase * 2 + star.angle)
          : .62 + .38 * math.sin(phase * 5 + star.angle * 3);
      final opacity = (star.brightness * shimmer).clamp(0.0, 1.0);
      final dot = star.radius * size.shortestSide / 220;
      if (star.sparkle) {
        paint.color = DSColors.silver.withValues(alpha: opacity * .10);
        canvas.drawCircle(point, dot * 4.5, paint);
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(star.angle + (gentle ? 0 : phase * .25));
        final tip = dot * 3;
        final path = Path()
          ..moveTo(0, -tip)
          ..quadraticBezierTo(tip * .13, -tip * .13, tip, 0)
          ..quadraticBezierTo(tip * .13, tip * .13, 0, tip)
          ..quadraticBezierTo(-tip * .13, tip * .13, -tip, 0)
          ..quadraticBezierTo(-tip * .13, -tip * .13, 0, -tip)
          ..close();
        paint.color = Colors.white.withValues(alpha: .4 + opacity * .6);
        canvas.drawPath(path, paint);
        canvas.restore();
      } else {
        paint.color = DSColors.silver.withValues(alpha: opacity * .8);
        canvas.drawCircle(point, dot, paint);
      }
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round
      ..color = DSColors.silver.withValues(alpha: .12);
    final bounds = Rect.fromCircle(center: center, radius: radius * 1.035);
    canvas.drawCircle(center, radius * 1.035, paint);
    paint
      ..strokeWidth = 1.2
      ..color = DSColors.silver.withValues(alpha: .62);
    canvas.drawArc(
        bounds, -math.pi / 2, math.pi * 2 * progress.value / 100, false, paint);
    // A separate orbit signals ongoing work without inventing progress.
    if (active && !gentle) {
      final orbit = Rect.fromCircle(center: center, radius: radius * 1.1);
      final head = phase * 2 - math.pi / 2;
      for (var segment = 0; segment < 18; segment++) {
        paint
          ..strokeWidth = 1.8
          ..color = Colors.white.withValues(alpha: (1 - segment / 18) * .8);
        canvas.drawArc(orbit, head - segment * .045, .05, false, paint);
      }
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white;
      canvas.drawCircle(
          center + Offset(math.cos(head), math.sin(head)) * radius * 1.1,
          2,
          paint);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.gentle != gentle ||
      oldDelegate.stars != stars;
}
