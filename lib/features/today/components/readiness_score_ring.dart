import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single reveal on first display, then motion only when the score changes.
class ReadinessScoreRing extends StatelessWidget {
  final int? score;
  final Color color;
  final double size;
  const ReadinessScoreRing(
      {super.key, required this.score, required this.color, this.size = 132});
  @override
  Widget build(BuildContext context) => Semantics(
      label: score == null ? 'Readiness not available' : '$score / 100',
      excludeSemantics: true,
      child: RepaintBoundary(
          child: SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (score ?? 0).clamp(0, 100) / 100),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => CustomPaint(
                      painter: _RingPainter(value, color), child: child),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(score == null ? '—' : '$score',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size * .31,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -.8,
                                            height: 1.1)),
                                    const SizedBox(height: 3),
                                    Text(score == null ? 'READINESS' : 'OF 100',
                                        style: TextStyle(
                                            color: const Color(0xFF969696),
                                            letterSpacing: 1,
                                            fontSize: size * .065)),
                                  ]))))))));
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  _RingPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var index = 0; index < 60; index++) {
      final angle = index / 60 * math.pi * 2 - math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + direction * (radius - 2),
          center + direction * (radius - 5), tick);
    }
    final rect = (Offset.zero & size).deflate(size.shortestSide * .075);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, stroke..color = const Color(0xFF303234));
    if (value <= 0) return;
    stroke.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: .5), color, Colors.white, color],
        stops: const [0, .35, .65, 1]).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, stroke);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}
