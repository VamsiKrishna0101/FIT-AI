import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/ds_motion.dart';

/// Paint-only entry. Stable children do not replay when a form or cache refreshes.
class MotionEntrance extends StatefulWidget {
  final Widget child;
  final int order;
  const MotionEntrance({super.key, required this.child, this.order = 0});

  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: DSMotion.reveal)..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context) ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          if (_controller.isAnimating) _controller.value = 1;
        },
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final start = widget.order.clamp(0, 3) * .08;
            final progress = _controller.value;
            final value = DSMotion.effects
                .transform(((progress - start) / (1 - start)).clamp(0.0, 1.0));
            return Opacity(
                opacity: value,
                child: Transform.translate(
                    offset: Offset(0, (1 - value) * 8), child: child));
          },
        ),
      );
}

/// A small interruptible spring follows the press without owning the tap gesture.
class MotionPress extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const MotionPress({super.key, required this.child, this.enabled = true});

  @override
  State<MotionPress> createState() => _MotionPressState();
}

class _MotionPressState extends State<MotionPress>
    with SingleTickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);

  void _press(bool down) {
    if (!widget.enabled || DSMotion.reduced(context)) return;
    _scale.animateWith(SpringSimulation(
        DSMotion.pressSpring, _scale.value, down ? .985 : 1, _scale.velocity));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) {
      _scale.stop();
      _scale.value = 1;
    }
  }

  @override
  void didUpdateWidget(MotionPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _scale.stop();
      _scale.value = 1;
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: AnimatedBuilder(
            animation: _scale,
            child: widget.child,
            builder: (context, child) =>
                Transform.scale(scale: _scale.value, child: child)),
      );
}

/// Data labels stay exact. Only the graph's drawing reveals, once per real change.
class MotionProgress extends StatefulWidget {
  final Object dataKey;
  final Widget Function(BuildContext context, double progress) builder;
  final Duration duration;
  const MotionProgress(
      {super.key,
      required this.dataKey,
      required this.builder,
      this.duration = DSMotion.chart});

  @override
  State<MotionProgress> createState() => _MotionProgressState();
}

class _MotionProgressState extends State<MotionProgress>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: widget.duration);
  bool _started = false;

  void _reveal() {
    if (DSMotion.reduced(context) || !TickerMode.valuesOf(context).enabled) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reveal();
    } else if (DSMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(MotionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.dataKey != widget.dataKey) _reveal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          if (_controller.isAnimating) _controller.value = 1;
        },
        child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                widget.builder(context, _controller.value)),
      );
}

class MotionValue extends StatelessWidget {
  final double value;
  final Widget Function(BuildContext context, double value) builder;
  const MotionValue({super.key, required this.value, required this.builder});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: DSMotion.duration(context, DSMotion.chart),
        curve: DSMotion.effects,
        builder: (context, value, _) => builder(context, value),
      );
}

class MotionChartReveal extends StatelessWidget {
  final Object dataKey;
  final Widget child;
  const MotionChartReveal(
      {super.key, required this.dataKey, required this.child});

  @override
  Widget build(BuildContext context) => MotionProgress(
      dataKey: dataKey,
      builder: (context, value) => ClipRect(
          clipper: _ChartRevealClipper(value),
          child: RepaintBoundary(child: child)));
}

class _ChartRevealClipper extends CustomClipper<Rect> {
  final double value;
  const _ChartRevealClipper(this.value);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * value, size.height);
  @override
  bool shouldReclip(_ChartRevealClipper old) => old.value != value;
}

class MotionFeedback extends StatelessWidget {
  final Widget child;
  const MotionFeedback({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: DSMotion.duration(context, DSMotion.feedback),
        switchInCurve: DSMotion.effects,
        switchOutCurve: DSMotion.effects,
        transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
                scale: Tween<double>(begin: .88, end: 1).animate(animation),
                child: child)),
        layoutBuilder: (current, previous) =>
            Stack(alignment: Alignment.center, children: [
          for (final child in previous)
            IgnorePointer(child: ExcludeSemantics(child: child)),
          if (current != null) current,
        ]),
        child: child,
      );
}
