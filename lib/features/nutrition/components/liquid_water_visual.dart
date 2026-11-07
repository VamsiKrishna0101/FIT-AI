import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/device_tilt.dart';
import '../../../core/theme/ds_motion.dart';
import 'liquid_pool_painter.dart';
import 'liquid_surface_simulation.dart';
import 'liquid_water_optics.dart';

/// Hosts rendering still previews can suppress the ambient loop independently
/// of recorded-value transitions and sensor-driven motion.
class LiquidMotion {
  static bool ambientEnabled = true;
  // Every crossing swell and reflection meets again at this boundary.
  static const phaseSpan = math.pi * 20;
  static const period = Duration(seconds: 64);
}

class LiquidWaterVisual extends StatefulWidget {
  final double fraction;
  final Size size;
  final Stream<GravitySample>? motion;
  final bool reactToTilt, perspective;
  final bool ambientMotion;
  final Color tint;
  final double phaseOffset;
  const LiquidWaterVisual(
      {super.key,
      required this.fraction,
      this.size = const Size(80, 96),
      this.motion,
      this.reactToTilt = true,
      this.perspective = true,
      this.ambientMotion = true,
      this.phaseOffset = 0,
      this.tint = const Color(0xFF2997FF)});
  @override
  State<LiquidWaterVisual> createState() => _LiquidWaterVisualState();
}

class _LiquidWaterVisualState extends State<LiquidWaterVisual>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _level = AnimationController.unbounded(
      vsync: this, value: widget.fraction.clamp(0.0, 1.0));
  late final _angle = AnimationController.unbounded(vsync: this);
  late final _depth = AnimationController.unbounded(vsync: this);
  late final _phase = AnimationController.unbounded(vsync: this);
  late final _ripple = AnimationController.unbounded(vsync: this);
  late var _surface = LiquidSurfaceSimulation(seed: widget.phaseOffset);
  Duration? _lastSurfaceTime;
  double _coastRemaining = 0;
  StreamSubscription<GravitySample>? _motion;
  ScrollPosition? _scroll;
  Animation<double>? _routeAnimation, _coverAnimation;
  bool _visible = true,
      _queued = false,
      _reduced = false,
      _current = true,
      _ticker = true;
  bool _foreground = true, _landscape = false;
  double _target = 0, _targetDepth = 0;
  bool _active = false;
  bool _ambient = false;
  ui.FragmentShader? _optics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _phase.addListener(_advanceSurface);
    _optics = LiquidWaterOptics.create();
    if (_optics == null) _loadOptics();
  }

  Future<void> _loadOptics() async {
    final program = await LiquidWaterOptics.load();
    if (!mounted || program == null) return;
    setState(() => _optics = program.fragmentShader());
  }

  @override
  void reassemble() {
    super.reassemble();
    // Development reloads retain the old State, including simulation buffers.
    // Recreate the grid before the rebuilt meter paints with the new code.
    _surface = LiquidSurfaceSimulation(seed: widget.phaseOffset);
    _lastSurfaceTime = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = DSMotion.reduced(context);
    final route = ModalRoute.of(context);
    _current = route?.isCurrent ?? true;
    if (_routeAnimation != route?.animation ||
        _coverAnimation != route?.secondaryAnimation) {
      _routeAnimation?.removeListener(_measureVisibility);
      _coverAnimation?.removeListener(_measureVisibility);
      _routeAnimation = route?.animation;
      _coverAnimation = route?.secondaryAnimation;
      _routeAnimation?.addListener(_measureVisibility);
      _coverAnimation?.addListener(_measureVisibility);
    }
    _ticker = TickerMode.valuesOf(context).enabled;
    _landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final scroll = Scrollable.maybeOf(context)?.position;
    if (_scroll != scroll) {
      _scroll?.removeListener(_measureVisibility);
      _scroll = scroll;
      _scroll?.addListener(_measureVisibility);
    }
    _measureVisibility();
    _configure();
  }

  @override
  void didUpdateWidget(covariant LiquidWaterVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fraction != widget.fraction) {
      final level = widget.fraction.clamp(0.0, 1.0);
      if (_reduced || !_visible || !_current || !_ticker || !_foreground) {
        _level.value = level;
      } else {
        _level.animateTo(level,
            duration: DSMotion.chart, curve: DSMotion.effects);
        _wake(
            energy: (level - oldWidget.fraction).abs().clamp(.08, .6),
            position: .35);
      }
    }
    if (oldWidget.motion != widget.motion ||
        oldWidget.reactToTilt != widget.reactToTilt) {
      _motion?.cancel();
      _motion = null;
    }
    if (oldWidget.phaseOffset != widget.phaseOffset) {
      _surface = LiquidSurfaceSimulation(seed: widget.phaseOffset);
    }
    _configure();
  }

  void _measureVisibility() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final visible = (box.localToGlobal(Offset.zero) & box.size)
          .overlaps(Offset.zero & MediaQuery.sizeOf(context));
      if (_visible != visible) {
        _visible = visible;
        _configure();
      }
    });
  }

  void _configure() {
    final active = !_reduced && _foreground && _current && _ticker && _visible;
    final ambient = active &&
        widget.fraction > 0 &&
        widget.ambientMotion &&
        LiquidMotion.ambientEnabled;
    final changed = ambient != _ambient;
    _ambient = ambient;
    if (active &&
        !_active &&
        (_level.value - widget.fraction.clamp(0.0, 1.0)).abs() > .00001) {
      _level.animateTo(widget.fraction.clamp(0.0, 1.0),
          duration: DSMotion.chart, curve: DSMotion.effects);
    }
    if (active && widget.fraction > 0 && (!_active || changed)) {
      _wake();
    }
    _active = active;
    if (active &&
        widget.reactToTilt &&
        widget.fraction > 0 &&
        _motion == null) {
      _motion = (widget.motion ?? DeviceTilt.samples).listen(
          (sample) => _tilt(
              sample.hasScreenGravity
                  ? sample.angle(landscape: _landscape)
                  : _target,
              sample.pitch()),
          onError: (Object _) {});
    } else if (!active || widget.fraction <= 0) {
      _motion?.cancel();
      _motion = null;
      _angle.stop();
      _depth.stop();
      _phase.stop();
      _lastSurfaceTime = null;
      _ripple.stop();
      _level.stop();
      // An outgoing page stays visible during a fade: hold its exact pose.
      _target = _angle.value;
      _targetDepth = _depth.value;
      if (_reduced || widget.fraction <= 0) {
        _target = 0;
        _targetDepth = 0;
        _angle.value = 0;
        _depth.value = 0;
        _ripple.value = 0;
        _surface.reset();
        _level.value = widget.fraction.clamp(0.0, 1.0);
      }
    }
  }

  void _tilt(double target, [double depth = 0]) {
    // Crossing +/-180 degrees must continue through the nearby edge, rather
    // than spinning the water a full turn in the opposite direction.
    target += ((_target - target) / (math.pi * 2)).round() * math.pi * 2;
    final rollDelta = target - _target;
    final delta = rollDelta.abs() + (depth - _targetDepth).abs();
    if (!widget.reactToTilt ||
        _reduced ||
        !_foreground ||
        !_ticker ||
        !_current ||
        !_visible ||
        delta < .0018) {
      return;
    }
    final energy = (delta * 2.2).clamp(.0, .7);
    _target = target;
    _targetDepth = depth;
    final follow = widget.perspective
        ? const SpringDescription(mass: 1, stiffness: 58, damping: 10.5)
        : const SpringDescription(mass: 1, stiffness: 100, damping: 20);
    const tolerance = Tolerance(distance: .00001, velocity: .0001);
    _angle.animateWith(ScrollSpringSimulation(
        follow, _angle.value, target, _angle.velocity,
        tolerance: tolerance));
    _depth.animateWith(ScrollSpringSimulation(
        follow, _depth.value, depth, _depth.velocity,
        tolerance: tolerance));
    _wake(
        energy: energy,
        position: rollDelta >= 0 ? .82 : .18,
        direction: rollDelta < 0 ? -1 : 1);
  }

  void _advanceSurface() {
    final elapsed = _phase.lastElapsedDuration;
    if (!_active || elapsed == null) return;
    final previous = _lastSurfaceTime;
    _lastSurfaceTime = elapsed;
    if (previous == null || elapsed < previous) return;
    final seconds = (elapsed - previous).inMicroseconds / 1000000;
    _coastRemaining -= seconds;
    // Simulate the vessel's air gap so completed meters retain sea waves.
    _surface.advance(seconds,
        fill: liquidVesselFill(_level.value, perspective: widget.perspective),
        aspectRatio: widget.size.width / widget.size.height,
        ambient: _ambient);
    if (!_ambient &&
        _coastRemaining <= 0 &&
        !_angle.isAnimating &&
        !_depth.isAnimating &&
        !_level.isAnimating &&
        !_ripple.isAnimating) {
      _phase.stop();
    }
  }

  void _wake({double energy = 0, double position = .5, double direction = 1}) {
    const rippleSpring = SpringDescription(mass: 1, stiffness: 16, damping: 8);
    if (energy > 0) {
      _surface.disturb(position: position, velocity: energy * .18 * direction);
      final impulse = energy * 4 * (1 - _ripple.value.clamp(0.0, 1.0));
      _ripple.animateWith(ScrollSpringSimulation(rippleSpring, _ripple.value, 0,
          (_ripple.velocity + impulse).clamp(-6.0, 6.0),
          tolerance: const Tolerance(distance: .00001, velocity: .0001)));
    }
    // Retain one clock through rapid sensor updates. New impulses extend its
    // coast time without restarting phase or discarding the surface velocity.
    _coastRemaining = 4;
    if (!_phase.isAnimating) {
      _lastSurfaceTime = null;
      _phase.repeat(
          min: 0, max: LiquidMotion.phaseSpan, period: LiquidMotion.period);
    }
  }

  void _pointer(Offset point) => _tilt(
      -((point.dx / widget.size.width - .5) * 2.8).clamp(-1.4, 1.4),
      ((point.dy / widget.size.height - .5) * 1.6).clamp(-.8, .8));
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _configure();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll?.removeListener(_measureVisibility);
    _routeAnimation?.removeListener(_measureVisibility);
    _coverAnimation?.removeListener(_measureVisibility);
    _motion?.cancel();
    _optics?.dispose();
    _level.dispose();
    _angle.dispose();
    _depth.dispose();
    _phase.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = kIsWeb ||
        ![TargetPlatform.android, TargetPlatform.iOS]
            .contains(defaultTargetPlatform);
    return RepaintBoundary(
        child: MouseRegion(
            onHover: widget.reactToTilt && interactive
                ? (event) => _pointer(event.localPosition)
                : null,
            onExit: widget.reactToTilt && interactive ? (_) => _tilt(0) : null,
            child: GestureDetector(
                onPanUpdate: widget.reactToTilt && interactive
                    ? (event) => _pointer(event.localPosition)
                    : null,
                onPanEnd:
                    widget.reactToTilt && interactive ? (_) => _tilt(0) : null,
                onHorizontalDragUpdate: widget.reactToTilt && !interactive
                    ? (event) => _pointer(event.localPosition)
                    : null,
                onHorizontalDragEnd:
                    widget.reactToTilt && !interactive ? (_) => _tilt(0) : null,
                child: SizedBox.fromSize(
                    size: widget.size,
                    child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_level, _angle, _depth, _phase, _ripple]),
                        builder: (_, __) => CustomPaint(
                            key: const ValueKey('liquid-water-paint'),
                            painter: LiquidWaterPainter(
                                fraction: _level.value,
                                tilt: _angle.value,
                                depthTilt: _depth.value,
                                wave: _phase.value + widget.phaseOffset,
                                optics: _optics,
                                surface: _surface.heights,
                                settle: _ripple.value.abs() > .00001 ? 0 : 1,
                                energy: _ripple.value.clamp(0.0, 1.0),
                                perspective: widget.perspective,
                                tint: widget.tint)))))));
  }
}

class LiquidWaterPainter extends CustomPainter {
  final double fraction, tilt, depthTilt, wave, settle, energy;
  final bool perspective;
  final Color tint;
  final List<double>? surface;
  final ui.FragmentShader? optics;
  const LiquidWaterPainter(
      {required this.fraction,
      this.tilt = 0,
      this.depthTilt = 0,
      this.perspective = true,
      this.tint = const Color(0xFF2997FF),
      this.wave = 0,
      this.settle = 1,
      this.energy = .4,
      this.optics,
      this.surface});
  @override
  void paint(Canvas canvas, Size size) {
    paintLiquidPool(canvas, size,
        fraction: fraction,
        roll: tilt,
        pitch: depthTilt,
        phase: wave,
        settle: settle,
        energy: energy,
        tint: tint,
        surface: surface,
        optics: optics,
        perspective: perspective);
  }

  @override
  bool shouldRepaint(LiquidWaterPainter old) =>
      old.fraction != fraction ||
      old.tilt != tilt ||
      old.depthTilt != depthTilt ||
      old.perspective != perspective ||
      old.tint != tint ||
      old.wave != wave ||
      old.settle != settle ||
      old.energy != energy ||
      old.optics != optics ||
      old.surface != surface;

  // The canvas is decorative. Parent labels announce the logged amounts;
  // moving waves must not dirty the accessibility tree on every frame.
  @override
  bool shouldRebuildSemantics(LiquidWaterPainter oldDelegate) => false;
}
