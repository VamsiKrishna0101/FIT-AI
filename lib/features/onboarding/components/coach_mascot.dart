import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/ds_motion.dart';
import 'onboarding_coach.dart';

enum CoachMood { listening, thinking, cheer, sleepy }

/// Mochi's voice: a rounded, friendly face (Nunito) for everything Mochi says.
abstract final class CoachType {
  static TextStyle line(
          {double size = 15, Color color = const Color(0xFFEDEDF0)}) =>
      TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          height: 1.35,
          letterSpacing: .1,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: color);
}

/// Mochi: a squishy coral jelly coach with big sparkly eyes and rosy cheeks.
/// It breathes, blinks and glances around, hops when the user chooses
/// something, thinks while a plan is built and cheers when it is ready.
class CoachMascot extends StatefulWidget {
  final double size;
  final CoachMood mood;

  /// Mochi waves and opens its mouth while "speaking".
  final bool talking;
  const CoachMascot(
      {super.key,
      this.size = 64,
      this.mood = CoachMood.listening,
      this.talking = false});

  @override
  State<CoachMascot> createState() => _CoachMascotState();
}

class _CoachMascotState extends State<CoachMascot>
    with TickerProviderStateMixin {
  late final _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));
  late final _hop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  Animation<double>? _entrance;

  @override
  void initState() {
    super.initState();
    OnboardingCoach.reactions.addListener(_react);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
    _watchEntrance();
  }

  /// Mochi arrives on a new screen mid-jump (see [CoachHero]); land with a
  /// jelly wobble once the page has finished entering.
  void _watchEntrance() {
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance == _entrance) return;
    _entrance?.removeStatusListener(_entered);
    _entrance = entrance;
    if (entrance != null && entrance.status == AnimationStatus.forward) {
      entrance.addStatusListener(_entered);
    }
  }

  void _entered(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entrance?.removeStatusListener(_entered);
    if (mounted && _live) _hop.forward(from: .5);
  }

  @override
  void didUpdateWidget(CoachMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood && widget.mood == CoachMood.cheer) {
      _react();
    }
  }

  bool get _live =>
      OnboardingCoach.liveMotion &&
      !DSMotion.reduced(context) &&
      TickerMode.valuesOf(context).enabled;

  void _updateMotion() {
    if (_live && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!_live) {
      _idle.stop();
    }
  }

  void _react() {
    if (mounted && _live) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    OnboardingCoach.reactions.removeListener(_react);
    _entrance?.removeStatusListener(_entered);
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: RepaintBoundary(
          child: SizedBox.square(
              dimension: widget.size,
              child: CustomPaint(
                  painter: _RepPainter(
                      idle: _idle,
                      hop: _hop,
                      mood: widget.mood,
                      talking: widget.talking)))));
}

/// Keeps Mochi on screen between onboarding steps. Like a chat avatar, Mochi
/// stays put while each step dissolves into the next; only when Mochi changes
/// size (the large welcome Mochi becoming the small one beside the first
/// question) does it glide and shrink into place with a little hop.
class CoachHero extends StatelessWidget {
  static const tag = 'onboarding-coach';
  final Widget child;
  const CoachHero({super.key, required this.child});

  static double? _width(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.width : null;
  }

  @override
  Widget build(BuildContext context) => Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (context, animation, direction, from, to) {
        final start = _width(from), end = _width(to);
        final travels =
            start != null && end != null && (start - end).abs() > 4;
        return travels
            ? _CoachGlide(animation: animation)
            : LayoutBuilder(
                builder: (context, constraints) =>
                    CoachMascot(size: constraints.biggest.shortestSide));
      },
      child: child);
}

class _CoachGlide extends StatelessWidget {
  final Animation<double> animation;
  const _CoachGlide({required this.animation});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final v = animation.value;
              // A soft hop along the way and a gentle squash on arrival.
              final hop = math.sin(v * math.pi);
              final squash =
                  v > .82 ? math.sin((v - .82) / .18 * math.pi) * .1 : 0.0;
              return Transform.translate(
                  offset: Offset(0, -hop * size * .22),
                  child: Transform.scale(
                      scaleX: 1 + squash,
                      scaleY: 1 - squash,
                      alignment: Alignment.bottomCenter,
                      child: child));
            },
            child: CoachMascot(size: size, mood: CoachMood.cheer));
      });
}

class _RepPainter extends CustomPainter {
  final Animation<double> idle, hop;
  final CoachMood mood;
  final bool talking;
  _RepPainter(
      {required this.idle,
      required this.hop,
      required this.mood,
      required this.talking})
      : super(repaint: Listenable.merge([idle, hop]));

  static const _ink = Color(0xFF2A1420);
  static const _blush = Color(0xFFFF7E9A);
  static const _feet = Color(0xFFEB5F55);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * .34;
    final t = idle.value;
    final h = hop.value;
    final wave = math.sin(t * math.pi * 2);
    final cheering = mood == CoachMood.cheer;
    final happy = cheering || (h > 0 && h < 1);

    // Hop in the first half of the reaction, land with a jelly wobble.
    final jump = h < .5 ? math.sin(h / .5 * math.pi) : 0.0;
    final land = h >= .5
        ? math.sin((h - .5) / .5 * math.pi * 2) * (1 - (h - .5) / .5)
        : 0.0;
    final bounce = cheering ? math.sin(t * math.pi * 8).abs() * .07 : 0.0;
    final lift = (wave * .02 + jump * .17 + bounce) * s;
    // Slow breathing plus the landing squash.
    final squash = wave * .025 + land * .12 - jump * .06;

    final shadowScale = 1 - (lift / s).clamp(-.1, .3);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * .5, s * .95),
            width: s * .52 * shadowScale,
            height: s * .07 * shadowScale),
        Paint()
          ..color = Colors.black.withValues(alpha: .4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .02));

    canvas.save();
    canvas.translate(s * .5, s * .6 - lift);
    canvas.rotate(wave * .03 +
        (mood == CoachMood.thinking
            ? .07
            : mood == CoachMood.sleepy
                ? -.1
                : 0));
    canvas.scale(1 + squash, 1 - squash);
    _feetAndArms(canvas, r, t, cheering);
    _body(canvas, r, t);
    _face(canvas, r, t, happy);
    canvas.restore();

    if (mood == CoachMood.thinking) _thinkingDots(canvas, s, t);
    if (mood == CoachMood.sleepy) _sleepZs(canvas, s, t);
    if (cheering || jump > 0) _sparkles(canvas, s, cheering ? t : h);
  }

  Path _blob(double r, double t) {
    final path = Path();
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final a = i / n * math.pi * 2;
      // A soft jelly edge that ripples slowly.
      final ripple = 1 + .022 * math.sin(a * 3 + t * math.pi * 4);
      var x = math.cos(a) * r * 1.04 * ripple;
      var y = math.sin(a) * r * .94 * ripple;
      // Slightly fuller, flatter bottom like a gumdrop.
      if (y > 0) {
        x *= 1 + .08 * (y / r);
        y *= .9;
      }
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  void _body(Canvas canvas, double r, double t) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r * 1.1);
    canvas.drawPath(
        _blob(r, t),
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.35, -.55),
                  radius: 1.05,
                  colors: [
                    Color(0xFFFFD3C4),
                    Color(0xFFFF9A84),
                    Color(0xFFF06A5C)
                  ],
                  stops: [0, .5, 1])
              .createShader(bounds));
    // Glossy highlight for a squishy, toy-like finish.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * .42, -r * .52),
            width: r * .42,
            height: r * .22),
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .04));
    // A little curl on top.
    canvas.drawPath(
        Path()
          ..moveTo(-r * .02, -r * .84)
          ..quadraticBezierTo(r * .02, -r * 1.12, r * .2, -r * 1.06)
          ..quadraticBezierTo(r * .06, -r * 1.0, r * .1, -r * .84),
        Paint()..color = const Color(0xFFFF9A84));
  }

  void _feetAndArms(Canvas canvas, double r, double t, bool cheering) {
    final feet = Paint()..color = _feet;
    for (final x in [-r * .4, r * .4]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, r * .86), width: r * .38, height: r * .2),
          feet);
    }
    final arm = Paint()..color = const Color(0xFFF7826F);
    for (final side in [-1.0, 1.0]) {
      final double angle;
      if (cheering) {
        angle = -1.25 + math.sin(t * math.pi * 8) * .2;
      } else if (talking && side > 0) {
        angle = -1.0 + math.sin(t * math.pi * 12) * .35; // A little wave.
      } else {
        angle = .35 + math.sin(t * math.pi * 2 + side) * .08;
      }
      canvas.save();
      canvas.translate(side * r * .92, r * .18);
      canvas.rotate(side * -angle);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(side * r * .12, 0),
              width: r * .3,
              height: r * .18),
          arm);
      canvas.restore();
    }
  }

  void _face(Canvas canvas, double r, double t, bool happy) {
    final thinking = mood == CoachMood.thinking;
    final sleepy = mood == CoachMood.sleepy && !happy;
    final gaze = Offset(
        thinking
            ? r * .07
            : sleepy
                ? 0
                : math.sin(t * math.pi * 4) * r * .04,
        thinking ? -r * .07 : 0);
    // Two blinks per idle cycle, the second a quick double blink.
    double open = 1;
    for (final at in const [.31, .78, .84]) {
      final d = (t - at).abs();
      if (d < .025) open = math.min(open, d / .025);
    }
    final ink = Paint()..color = _ink;
    Paint line(double width) => Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * width;

    final blush = Paint()
      ..color = _blush.withValues(alpha: happy ? .85 : .6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .03);
    for (final x in [-r * .58, r * .58]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, r * .2), width: r * .26, height: r * .15),
          blush);
    }

    for (final x in [-r * .3, r * .3]) {
      final c = Offset(x, -r * .12) + gaze;
      if (happy) {
        // Smiling, upward-curved eyes.
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - r * .13, c.dy + r * .05)
              ..quadraticBezierTo(
                  c.dx, c.dy - r * .16, c.dx + r * .13, c.dy + r * .05),
            line(.075));
      } else if (sleepy || open < .25) {
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - r * .1, c.dy)
              ..quadraticBezierTo(c.dx, c.dy + r * .07, c.dx + r * .1, c.dy),
            line(.075));
      } else {
        canvas.drawOval(
            Rect.fromCenter(center: c, width: r * .3, height: r * .4 * open),
            ink);
        // Big and small sparkle highlights.
        canvas.drawCircle(c + Offset(-r * .055, -r * .085 * open), r * .08,
            Paint()..color = Colors.white);
        canvas.drawCircle(c + Offset(r * .06, r * .08 * open), r * .035,
            Paint()..color = Colors.white.withValues(alpha: .85));
      }
    }

    final m = Offset(0, r * .24) + gaze * .4;
    if (thinking) {
      canvas.drawOval(
          Rect.fromCenter(
              center: m + Offset(r * .06, r * .02),
              width: r * .1,
              height: r * .12),
          ink);
    } else if (happy || talking) {
      // Open smile with a little tongue.
      final mouth = Path()
        ..moveTo(m.dx - r * .17, m.dy - r * .02)
        ..quadraticBezierTo(
            m.dx, m.dy + r * .32, m.dx + r * .17, m.dy - r * .02)
        ..close();
      canvas.drawPath(mouth, ink);
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawOval(
          Rect.fromCenter(
              center: m + Offset(0, r * .16), width: r * .2, height: r * .12),
          Paint()..color = const Color(0xFFFF6F8E));
      canvas.restore();
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(m.dx - r * .09, m.dy)
            ..quadraticBezierTo(m.dx, m.dy + r * .08, m.dx + r * .09, m.dy),
          line(.06));
    }
  }

  void _sleepZs(Canvas canvas, double s, double t) {
    for (var i = 0; i < 3; i++) {
      final phase = (t * 2 + i / 3) % 1;
      final painter = TextPainter(
          text: TextSpan(
              text: 'z',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontVariations: const [FontVariation('wght', 800)],
                  fontSize: s * (.1 + phase * .07),
                  color: Colors.white
                      .withValues(alpha: math.sin(phase * math.pi) * .8))),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(canvas,
          Offset(s * (.68 + phase * .16), s * (.26 - phase * .24)));
      painter.dispose();
    }
  }

  void _thinkingDots(Canvas canvas, double s, double t) {
    for (var i = 0; i < 3; i++) {
      final phase = (t * 3 - i * .25) % 1;
      final rise = math.sin(phase * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(s * (.74 + i * .09), s * (.18 - rise * .06)),
          s * .028,
          Paint()..color = Colors.white.withValues(alpha: .35 + .6 * rise));
    }
  }

  void _sparkles(Canvas canvas, double s, double v) {
    const colors = [Color(0xFFFFD166), Colors.white, Color(0xFFFF8FA3)];
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i - 2) * .55;
      final phase = (v * 2 + i * .17) % 1;
      final distance = s * (.42 + phase * .16);
      final center = Offset(s * .5 + math.cos(angle) * distance,
          s * .52 + math.sin(angle) * distance);
      final r = s * .038 * math.sin(phase * math.pi);
      if (r <= 0) continue;
      final star = Path();
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4;
        final len = k.isEven ? r : r * .35;
        final p = center + Offset(math.cos(a) * len, math.sin(a) * len);
        k == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(star..close(), Paint()..color = colors[i % 3]);
    }
  }

  @override
  bool shouldRepaint(_RepPainter old) =>
      old.mood != mood || old.talking != talking;
}
