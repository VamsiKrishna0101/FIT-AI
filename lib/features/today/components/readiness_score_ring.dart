import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single reveal on first display, then motion only when the score changes.
class ReadinessScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const ReadinessScoreRing(
      {super.key, required this.score, required this.color});
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$score / 100',
      excludeSemantics: true,
      child: RepaintBoundary(
          child: SizedBox(
              width: 80,
              height: 80,
              child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
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
                                    Text('$score',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 27,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -.8,
                                            height: 1.1)),
                                    const SizedBox(height: 3),
                                    const Text('/ 100',
                                        style: TextStyle(
                                            color: Color(0xFF969696),
                                            fontSize: 9)),
                                  ]))))))));
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  _RingPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, stroke..color = const Color(0xFF383838));
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
