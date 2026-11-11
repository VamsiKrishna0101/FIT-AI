import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/ds_motion.dart';
import 'onboarding_coach.dart';

bool _animate(BuildContext context) =>
    OnboardingCoach.liveMotion && !DSMotion.reduced(context);

/// Options arrive one after another, rising softly into place.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggeredEntrance(
      {super.key, required this.index, required this.child});

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  static const _step = 55, _each = 380, _maxStagger = 8;
  late final _controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds:
              _each + math.min(widget.index, _maxStagger) * _step + 120));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_animate(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    final start = (120 + math.min(widget.index, _maxStagger) * _step) / total;
    final curve = CurvedAnimation(
        parent: _controller,
        curve: Interval(start.clamp(0.0, .9), 1, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
        animation: curve,
        child: widget.child,
        builder: (context, child) => Opacity(
            opacity: curve.value,
            child: Transform.translate(
                offset: Offset(0, 14 * (1 - curve.value)), child: child)));
  }
}

/// The name being typed, as a row of squishy coloured letter tiles that pop
/// in one by one.
class NameLetterTiles extends StatelessWidget {
  final String name;
  const NameLetterTiles({super.key, required this.name});

  static const _colors = [
    Color(0xFFFF9A84),
    Color(0xFF7FD8B0),
    Color(0xFFB7A6FF),
    Color(0xFFFFC76B),
    Color(0xFFFF8FB1),
    Color(0xFF8FC8FF),
  ];

  @override
  Widget build(BuildContext context) {
    final letters = name.trim().characters.take(14).toList();
    return ExcludeSemantics(
        child: Wrap(spacing: 7, runSpacing: 7, children: [
      for (var i = 0; i < letters.length; i++)
        if (letters[i].trim().isEmpty)
          const SizedBox(width: 10, height: 44)
        else
          _LetterTile(
              key: ValueKey('name-letter-$i-${letters[i]}'),
              letter: letters[i].toUpperCase(),
              color: _colors[i % _colors.length],
              tilt: (i.isEven ? -1 : 1) * .06),
    ]));
  }
}

class _LetterTile extends StatefulWidget {
  final String letter;
  final Color color;
  final double tilt;
  const _LetterTile(
      {super.key,
      required this.letter,
      required this.color,
      required this.tilt});

  @override
  State<_LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<_LetterTile>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _animate(context) ? _pop.forward() : _pop.value = 1;
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final v = Curves.elasticOut.transform(_pop.value);
        return Transform.rotate(
            angle: widget.tilt + (1 - _pop.value) * .5,
            child: Transform.scale(scale: v, child: child));
      },
      child: Container(
          width: 38,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(widget.color, Colors.white, .35)!,
                    widget.color
                  ]),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: .35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Text(widget.letter,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontVariations: [FontVariation('wght', 900)],
                  color: Color(0xFF2A1420)))));
}

/// A one-shot confetti burst for big moments; it never blocks taps.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  final _pieces = List.generate(70, (i) {
    final random = math.Random(i * 7919);
    return (
      angle: -math.pi / 2 + (random.nextDouble() - .5) * 2.2,
      speed: .55 + random.nextDouble() * .65,
      spin: (random.nextDouble() - .5) * 14,
      size: 5 + random.nextDouble() * 6,
      color: const [
        Color(0xFFFF9A84),
        Color(0xFF7FD8B0),
        Color(0xFFB7A6FF),
        Color(0xFFFFC76B),
        Color(0xFFFF8FB1),
        Colors.white,
      ][i % 6],
      round: i % 3 == 0,
    );
  });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_animate(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: ExcludeSemantics(
          child: RepaintBoundary(
              child: CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(_controller, _pieces)))));
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;
  final List<
      ({
        double angle,
        double speed,
        double spin,
        double size,
        Color color,
        bool round
      })> pieces;
  _ConfettiPainter(this.progress, this.pieces) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * .38);
    final reach = size.height * .55;
    for (final p in pieces) {
      final dx = math.cos(p.angle) * p.speed * reach * t;
      final dy = math.sin(p.angle) * p.speed * reach * t + reach * 1.1 * t * t;
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: p.size, height: p.size * .55),
                const Radius.circular(1.5)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
