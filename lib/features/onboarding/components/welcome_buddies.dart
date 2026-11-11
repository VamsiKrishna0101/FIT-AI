import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mochi's friends on the welcome screen, one for each thing Mochi helps with.
enum BuddyKind { dumbbell, apple, moon, heart }

/// A small character with a face and its own loop: the dumbbell curls and
/// sweats, the apple bounces, the moon dozes and the heart beats.
class WelcomeBuddy extends StatelessWidget {
  final BuddyKind kind;
  final double size;

  /// Loops 0 → 1; each buddy derives its own rhythm from it.
  final Animation<double> clock;
  const WelcomeBuddy(
      {super.key, required this.kind, required this.size, required this.clock});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: RepaintBoundary(
          child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                  painter: _BuddyPainter(kind: kind, clock: clock)))));
}

class _BuddyPainter extends CustomPainter {
  final BuddyKind kind;
  final Animation<double> clock;
  _BuddyPainter({required this.kind, required this.clock})
      : super(repaint: clock);

  static const _ink = Color(0xFF2A1420);
  static const _blush = Color(0xFFFF7E9A);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final t = clock.value;
    canvas.save();
    canvas.translate(s / 2, s / 2);
    switch (kind) {
      case BuddyKind.dumbbell:
        _dumbbell(canvas, s, t);
      case BuddyKind.apple:
        _apple(canvas, s, t);
      case BuddyKind.moon:
        _moon(canvas, s, t);
      case BuddyKind.heart:
        _heart(canvas, s, t);
    }
    canvas.restore();
  }

  void _shadow(Canvas canvas, double s, double y, double width) =>
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(0, y), width: width, height: s * .06),
          Paint()
            ..color = Colors.black.withValues(alpha: .45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .02));

  /// Shared cute face. [u] is the face width; [closed] gives sleepy or happy
  /// curved eyes; [open] gives an open smile.
  void _face(Canvas canvas, Offset c, double u,
      {bool closed = false, bool open = false, double blink = 1}) {
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = u * .07;
    final blush = Paint()
      ..color = _blush.withValues(alpha: .7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * .03);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(side * u * .44, u * .16),
              width: u * .2,
              height: u * .12),
          blush);
      final e = c + Offset(side * u * .24, -u * .04);
      if (closed || blink < .25) {
        canvas.drawPath(
            Path()
              ..moveTo(e.dx - u * .09, e.dy)
              ..quadraticBezierTo(e.dx, e.dy + u * .08, e.dx + u * .09, e.dy),
            line);
      } else {
        canvas.drawOval(
            Rect.fromCenter(
                center: e, width: u * .16, height: u * .21 * blink),
            ink);
        canvas.drawCircle(e + Offset(-u * .03, -u * .045 * blink), u * .045,
            Paint()..color = Colors.white);
      }
    }
    final m = c + Offset(0, u * .14);
    if (open) {
      final mouth = Path()
        ..moveTo(m.dx - u * .1, m.dy)
        ..quadraticBezierTo(m.dx, m.dy + u * .2, m.dx + u * .1, m.dy)
        ..close();
      canvas.drawPath(mouth, ink);
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawCircle(m + Offset(0, u * .12), u * .06,
          Paint()..color = const Color(0xFFFF6F8E));
      canvas.restore();
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(m.dx - u * .07, m.dy)
            ..quadraticBezierTo(m.dx, m.dy + u * .07, m.dx + u * .07, m.dy),
          line..strokeWidth = u * .055);
    }
  }

  double _blink(double t, double at) {
    final d = (t - at).abs();
    return d < .02 ? d / .02 : 1;
  }

  // Dumbbell: curls itself up and down, with a sweat drop at the top of the lift.
  void _dumbbell(Canvas canvas, double s, double t) {
    final curl = math.sin(t * math.pi * 4);
    _shadow(canvas, s, s * .36, s * .7);
    canvas.save();
    canvas.translate(0, -curl.abs() * s * .06);
    canvas.rotate(curl * .22);
    final plate = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFA9B6FF), Color(0xFF6E7FE8)])
          .createShader(Rect.fromCircle(center: Offset.zero, radius: s * .3));
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(side * s * .43, 0),
                  width: s * .1,
                  height: s * .36),
              Radius.circular(s * .05)),
          plate);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(side * s * .32, 0),
                  width: s * .15,
                  height: s * .54),
              Radius.circular(s * .07)),
          plate);
    }
    final grip = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * .5, height: s * .32),
        Radius.circular(s * .13));
    canvas.drawRRect(
        grip,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFD0D4E0)])
              .createShader(grip.outerRect));
    _face(canvas, Offset(0, s * .01), s * .34,
        open: curl.abs() > .7, blink: _blink(t, .6));
    canvas.restore();
    // Sweat drop when the lift peaks.
    final sweat = (math.sin(t * math.pi * 4 - .6)).clamp(0.0, 1.0);
    if (sweat > .2) {
      final p = Offset(s * .22, -s * .3 + (1 - sweat) * s * .06);
      canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - s * .07)
            ..quadraticBezierTo(
                p.dx + s * .05, p.dy, p.dx, p.dy + s * .02)
            ..quadraticBezierTo(p.dx - s * .05, p.dy, p.dx, p.dy - s * .07),
          Paint()..color = const Color(0xFF8FD3FF).withValues(alpha: sweat));
    }
  }

  // Apple: happy little hops with a squash on landing.
  void _apple(Canvas canvas, double s, double t) {
    final phase = (t * 2) % 1;
    final hop = math.sin(phase * math.pi);
    final squash = phase < .12 ? (1 - phase / .12) * .12 : 0.0;
    _shadow(canvas, s, s * .38, s * .5 * (1 - hop * .3));
    canvas.save();
    canvas.translate(0, -hop * s * .12 + s * .04);
    canvas.scale(1 + squash, 1 - squash);
    final r = s * .3;
    final body = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(-r * .24, r * .02), width: r * 1.6, height: r * 1.9))
      ..addOval(Rect.fromCenter(
          center: Offset(r * .24, r * .02), width: r * 1.6, height: r * 1.9));
    canvas.drawPath(
        body,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.4, -.5),
                  colors: [Color(0xFFFF9B8F), Color(0xFFF2554B), Color(0xFFD63E3A)],
                  stops: [0, .6, 1])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.2)));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * .55, -r * .45), width: r * .4, height: r * .2),
        Paint()..color = Colors.white.withValues(alpha: .45));
    canvas.drawLine(
        Offset(0, -r * .7),
        Offset(r * .08, -r * 1.05),
        Paint()
          ..color = const Color(0xFF8A5A3C)
          ..strokeWidth = s * .04
          ..strokeCap = StrokeCap.round);
    canvas.save();
    canvas.translate(r * .3, -r * .95);
    canvas.rotate(-.5 + math.sin(t * math.pi * 4) * .15);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * .2, 0), width: r * .5, height: r * .24),
        Paint()..color = const Color(0xFF6FD08C));
    canvas.restore();
    _face(canvas, Offset(0, r * .05), s * .42,
        closed: hop > .6, open: hop > .3, blink: _blink(t, .35));
    canvas.restore();
  }

  // Moon: dozes, rocking gently, with floating z's.
  void _moon(Canvas canvas, double s, double t) {
    _shadow(canvas, s, s * .38, s * .46);
    canvas.save();
    canvas.rotate(math.sin(t * math.pi * 2) * .12 - .15);
    final r = s * .32;
    final crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)),
        Path()
          ..addOval(Rect.fromCircle(
              center: Offset(r * .62, -r * .32), radius: r * .78)));
    canvas.drawPath(
        crescent,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.5, -.3),
                  colors: [Color(0xFFE6DDFF), Color(0xFFB09CFF)])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
    _face(canvas, Offset(-r * .42, r * .22), s * .34, closed: true);
    canvas.restore();
    for (var i = 0; i < 2; i++) {
      final phase = (t * 2 + i * .5) % 1;
      final painter = TextPainter(
          text: TextSpan(
              text: 'z',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s * (.13 + i * .04),
                  fontWeight: FontWeight.w800,
                  color: Colors.white
                      .withValues(alpha: math.sin(phase * math.pi) * .85))),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(
          canvas, Offset(s * (.16 + phase * .14), -s * (.18 + phase * .26)));
      painter.dispose();
    }
  }

  // Heart: a lub-dub heartbeat.
  void _heart(Canvas canvas, double s, double t) {
    final f = (t * 3) % 1;
    double beat(double at) {
      final d = (f - at) / .09;
      return d >= 0 && d <= 1 ? math.sin(d * math.pi) : 0;
    }

    final pulse = 1 + beat(0) * .12 + beat(.16) * .08;
    _shadow(canvas, s, s * .38, s * .46 * pulse);
    canvas.save();
    canvas.scale(pulse);
    final w = s * .74;
    final heart = Path()
      ..moveTo(0, w * .38)
      ..cubicTo(-w * .62, -w * .02, -w * .42, -w * .62, 0, -w * .28)
      ..cubicTo(w * .42, -w * .62, w * .62, -w * .02, 0, w * .38)
      ..close();
    canvas.drawPath(
        heart,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.4, -.5),
                  colors: [Color(0xFFFFC2D4), Color(0xFFFF7FA6), Color(0xFFF0577F)],
                  stops: [0, .55, 1])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: w * .6)));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-w * .26, -w * .3), width: w * .2, height: w * .1),
        Paint()..color = Colors.white.withValues(alpha: .5));
    _face(canvas, Offset(0, -w * .04), s * .34,
        open: pulse > 1.06, blink: _blink(t, .82));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BuddyPainter old) => old.kind != kind;
}
