import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart' as glass;
import '../theme/ds_colors.dart';
import '../theme/ds_motion.dart';
import 'navigation_glyph.dart';

/// Use backdrop refraction on iOS when Impeller supports shader filters.
/// Other renderers use the same translucent finish over a blurred backdrop.
bool get _supportsLiquidOptics =>
    ui.ImageFilter.isShaderFilterSupported &&
    defaultTargetPlatform == TargetPlatform.iOS;

/// A compact, icon-only floating dock. Labels remain available to assistive
/// technology and tooltips without changing the dock's geometry by locale.
class LiquidSilverBottomBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> labels;
  const LiquidSilverBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.labels,
  })  : assert(labels.length == 4),
        assert(selectedIndex >= 0 && selectedIndex < 4);

  /// Scaffold supplies the dock inset; leave breathing room above that inset.
  static double scrollBottomInset(BuildContext context) =>
      24 + MediaQuery.paddingOf(context).bottom;

  @override
  State<LiquidSilverBottomBar> createState() => _LiquidSilverBottomBarState();
}

class _LiquidSilverBottomBarState extends State<LiquidSilverBottomBar>
    with WidgetsBindingObserver {
  static const _icons = [
    NavigationGlyphKind.today,
    NavigationGlyphKind.train,
    NavigationGlyphKind.body,
    NavigationGlyphKind.progress,
  ];
  int? _previewIndex, _pointer;
  final _pointers = <int>{};
  double? _previewPosition;
  double _dragStretch = 0;
  bool _pressed = false, _dragging = false, _dragCancelled = false;
  bool _refreshScheduled = false;
  bool _deferredRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() => _scheduleRefresh();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(int index) {
    if (index == widget.selectedIndex) return;
    HapticFeedback.selectionClick();
    widget.onTabSelected(index);
  }

  void _scheduleRefresh() {
    if (!mounted) return;
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _deferredRefresh = true;
    } else {
      setState(() {});
    }
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    // Pointer cancellation can happen during an accessibility subtree rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      if (_pointers.isEmpty) _dragCancelled = false;
      if (_deferredRefresh) {
        _deferredRefresh = false;
        setState(() {});
      }
    });
  }

  void _clearPreview() {
    _previewIndex = null;
    _previewPosition = null;
    _pressed = false;
    _dragging = false;
    _dragStretch = 0;
    _scheduleRefresh();
  }

  void _preview(Offset point, Size size, TextDirection direction,
      {required bool dragging}) {
    if (_dragCancelled) return;
    final inside = point.dx >= 0 &&
        point.dx < size.width &&
        point.dy >= -24 &&
        point.dy <= size.height + 24;
    if (!inside) {
      _clearPreview();
      return;
    }
    final slotWidth = size.width / 4;
    final physicalIndex = (point.dx / slotWidth).floor().clamp(0, 3);
    final index =
        direction == TextDirection.rtl ? 3 - physicalIndex : physicalIndex;
    final physicalPosition = (point.dx / slotWidth - .5).clamp(0.0, 3.0);
    final position = dragging
        ? direction == TextDirection.rtl
            ? 3 - physicalPosition
            : physicalPosition
        : index.toDouble();
    final travel =
        (position - (_previewPosition ?? widget.selectedIndex)).abs();
    // A light detent each time the dragged lens crosses into another tab.
    if (dragging && _previewIndex != null && index != _previewIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _previewIndex = index;
      _previewPosition = position;
      _dragStretch = dragging ? (travel * .25).clamp(0.0, .12) : 0;
      _pressed = true;
      _dragging = dragging;
    });
  }

  void _down(PointerDownEvent event, Size size, TextDirection direction) {
    if ((event.buttons & kPrimaryButton) == 0) return;
    _pointers.add(event.pointer);
    if (_pointers.length > 1) {
      // A second finger must not activate a second destination.
      _dragCancelled = true;
      _clearPreview();
      return;
    }
    _pointer = event.pointer;
    _dragCancelled = false;
    _preview(event.localPosition, size, direction, dragging: false);
  }

  void _up(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (_pointer == event.pointer) {
      _pointer = null;
      _pressed = false;
    }
    _scheduleRefresh();
  }

  void _cancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_pointer == event.pointer) _pointer = null;
    _dragCancelled = true;
    _clearPreview();
  }

  void _release() {
    final target = _previewIndex;
    final canSelect = !_dragCancelled && target != null;
    _clearPreview();
    if (canSelect) _select(target);
  }

  void _tap(int index) {
    if (_dragCancelled || _pointers.isNotEmpty) return;
    _clearPreview();
    _select(index);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final reduced = DSMotion.reduced(context) ||
        WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    final duration = reduced ? Duration.zero : DSMotion.selection;
    final highContrast = MediaQuery.highContrastOf(context);
    final direction = Directionality.of(context);
    return Padding(
      key: const ValueKey('navigation-bar'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: LayoutBuilder(builder: (context, constraints) {
              final size = Size(constraints.maxWidth - 4, 48);
              // The lens paints above the icons so its optics bend them, and
              // outside the dock's clip so a pressed lens can swell past it.
              return Stack(clipBehavior: Clip.none, children: [
                _GlassCapsule(
                  key: const ValueKey('navigation-capsule'),
                  highContrast: highContrast,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: SizedBox(
                      key: const ValueKey('navigation-tabs'),
                      height: size.height,
                      child: Listener(
                        onPointerDown: (event) => _down(event, size, direction),
                        onPointerUp: _up,
                        onPointerCancel: _cancel,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (event) => _preview(
                              event.localPosition, size, direction,
                              dragging: true),
                          onHorizontalDragUpdate: (event) => _preview(
                              event.localPosition, size, direction,
                              dragging: true),
                          onHorizontalDragEnd: (_) => _release(),
                          onHorizontalDragCancel: _clearPreview,
                          child: Row(children: [
                            for (var index = 0; index < 4; index++)
                              Expanded(child: _tab(index, duration)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Stack(clipBehavior: Clip.none, children: [
                      _LiquidSelection(
                        position:
                            _previewPosition ?? widget.selectedIndex.toDouble(),
                        dragging: _dragging,
                        pressed: _pressed,
                        dragStretch: _dragStretch,
                        reducedMotion: reduced,
                        highContrast: highContrast,
                        direction: direction,
                        width: size.width,
                        height: size.height,
                        icons: _lensIcons,
                      ),
                    ]),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  /// Crisp glyphs shown only inside the lens, magnified while it is held.
  Widget _lensIcons(double scale) => Row(children: [
        for (var index = 0; index < 4; index++)
          Expanded(
            child: SizedBox(
              height: 48,
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: NavigationGlyph(
                      kind: _icons[index], color: DSColors.navGlassText),
                ),
              ),
            ),
          ),
      ]);

  Widget _tab(int index, Duration duration) {
    final selected = (_previewIndex ?? widget.selectedIndex) == index;
    return Semantics(
      button: true,
      selected: widget.selectedIndex == index,
      label: widget.labels[index],
      onTap: () => _select(index),
      excludeSemantics: true,
      child: Tooltip(
        message: widget.labels[index],
        child: InkWell(
          key: ValueKey('navigation-tab-$index'),
          onTap: () => _tap(index),
          borderRadius: BorderRadius.circular(100),
          splashFactory: NoSplash.splashFactory,
          focusColor: const Color(0x26FFFFFF),
          hoverColor: const Color(0x0AFFFFFF),
          highlightColor: Colors.transparent,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
                end:
                    selected ? DSColors.navGlassText : const Color(0xFFB3B3B3)),
            duration: duration,
            curve: DSMotion.effects,
            builder: (context, color, _) => SizedBox(
              height: 48,
              child: Center(
                  child: NavigationGlyph(
                      kind: _icons[index],
                      color: color ?? DSColors.navGlassText)),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule(
      {super.key, required this.highContrast, required this.child});
  final bool highContrast;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: _NavigationGlass(
          highContrast: highContrast,
          child: CustomPaint(
            foregroundPainter: _GlassRim(highContrast: highContrast),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      );
}

/// The shell refracts the page; the moving lens refracts the shell and icons.
/// They paint as siblings so the two backdrop passes never nest.
class _NavigationGlass extends StatelessWidget {
  const _NavigationGlass({
    required this.highContrast,
    required this.child,
    this.lens = false,
    this.pressure = 0,
  });
  final bool highContrast, lens;
  final double pressure;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (highContrast) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: ColoredBox(
            color: lens ? const Color(0xFF535A63) : DSColors.bgRaised,
            child: child),
      );
    }

    // Black translucent glass keeps the original dark dock. Refraction and
    // the fine rim supply the glass effect without a silver surface fill.
    final finish = DecoratedBox(
      key: ValueKey(lens ? 'navigation-lens-finish' : 'navigation-dock-finish'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: lens
              ? [
                  Color.lerp(const Color(0x80404040), const Color(0x88484848),
                      pressure)!,
                  Color.lerp(const Color(0x70242424), const Color(0x782C2C2C),
                      pressure)!,
                  Color.lerp(const Color(0x80303030), const Color(0x88383838),
                      pressure)!,
                ]
              : const [
                  Color(0xAA202020),
                  Color(0x99121212),
                  Color(0xAA0A0A0A),
                ],
          stops: const [0, .55, 1],
        ),
      ),
      child: child,
    );

    final Widget surface;
    if (_supportsLiquidOptics) {
      surface = glass.LiquidGlass.withOwnLayer(
        shape: const glass.LiquidRoundedRectangle(borderRadius: 100),
        settings: glass.LiquidGlassSettings(
          glassColor: const Color(0x08000000),
          thickness: lens ? 8 + pressure * 4 : 12,
          blur: lens ? .6 : 12,
          refractiveIndex: lens ? 1.16 + pressure * .04 : 1.12,
          // Dispersion splits the icon edges into RGB fringes at this scale.
          chromaticAberration: 0,
          lightAngle: -math.pi / 3,
          lightIntensity: lens ? .12 + pressure * .08 : .08,
          ambientStrength: .01,
          saturation: 1,
        ),
        child: finish,
      );
    } else {
      final blurSigma = lens ? .6 : 22.0;
      surface = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: finish,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: surface,
    );
  }
}

/// A single continuous lens tracks the finger and carries velocity into a
/// damped spring when released or retargeted. Hit targets never move with it.
class _LiquidSelection extends StatefulWidget {
  const _LiquidSelection({
    required this.position,
    required this.dragging,
    required this.pressed,
    required this.dragStretch,
    required this.reducedMotion,
    required this.highContrast,
    required this.direction,
    required this.width,
    required this.height,
    required this.icons,
  });
  final double position, dragStretch, width, height;
  final bool dragging, pressed, reducedMotion, highContrast;
  final TextDirection direction;

  /// Builds the icon row at a given magnification; clipped to the lens.
  final Widget Function(double scale) icons;

  @override
  State<_LiquidSelection> createState() => _LiquidSelectionState();
}

class _LiquidSelectionState extends State<_LiquidSelection>
    with TickerProviderStateMixin {
  // Slightly under-damped: the lens overshoots once and settles like liquid.
  static const _spring =
      SpringDescription(mass: 1, stiffness: 460, damping: 28);
  late double _target;
  late final AnimationController _motion, _press;

  @override
  void initState() {
    super.initState();
    _target = widget.position;
    _motion = AnimationController.unbounded(vsync: this, value: widget.position)
      ..addStatusListener(_settled);
    _press = AnimationController(
        vsync: this, duration: DSMotion.press, value: widget.pressed ? 1 : 0);
  }

  void _settled(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        !widget.dragging &&
        _motion.value != _target) {
      _motion.value = _target;
    }
  }

  @override
  void didUpdateWidget(_LiquidSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _motion.stop();
      _target = widget.position;
      _motion.value = _target;
      _press.value = widget.pressed ? 1 : 0;
      return;
    }
    if (oldWidget.pressed != widget.pressed || oldWidget.reducedMotion) {
      _press.animateTo(widget.pressed ? 1 : 0, curve: DSMotion.effects);
    }
    if (widget.dragging) {
      _motion.stop();
      _target = widget.position;
      _motion.value = widget.position;
    } else if (widget.position != _target || oldWidget.dragging) {
      final velocity = _motion.velocity.clamp(-12.0, 12.0);
      _target = widget.position;
      _motion.animateWith(SpringSimulation(
          _spring, _motion.value, _target, velocity,
          tolerance: const Tolerance(distance: .0001, velocity: .001)));
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_motion, _press]),
        builder: (context, _) {
          final physicalPosition = widget.direction == TextDirection.rtl
              ? 3 - _motion.value
              : _motion.value;
          final pressure = widget.reducedMotion ? 0.0 : _press.value;
          final stretch = widget.reducedMotion
              ? 0.0
              : widget.dragging
                  ? .06 + widget.dragStretch * 1.4
                  : (_motion.velocity.abs() * .018).clamp(0.0, .22);
          final slot = widget.width / 4;
          // Holding swells the lens past the dock like a drop of glass;
          // speed squashes it, wide and short, in the direction of travel.
          final width = (slot - 8) * (1 + stretch + pressure * .14);
          final height = 42 * (1 + pressure * .20 - stretch * .22);
          final center = ((physicalPosition + .5) * slot)
              .clamp(width / 2, widget.width - width / 2);
          final lens = Rect.fromLTWH(center - width / 2,
              (widget.height - height) / 2 - pressure * 2, width, height);
          return Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fromRect(
                    rect: lens,
                    child: _NavigationGlass(
                      lens: true,
                      pressure: pressure,
                      highContrast: widget.highContrast,
                      child: CustomPaint(
                        key: const ValueKey('navigation-active-pill'),
                        foregroundPainter: _GlassRim(
                            highContrast: widget.highContrast,
                            lens: true,
                            pressure: pressure),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _LensClipper(lens),
                      child: widget.icons(1 + pressure * .12),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      );
}

class _LensClipper extends CustomClipper<Path> {
  const _LensClipper(this.lens);
  final Rect lens;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(lens, Radius.circular(lens.height / 2)));

  @override
  bool shouldReclip(_LensClipper oldClipper) => oldClipper.lens != lens;
}

class _GlassRim extends CustomPainter {
  const _GlassRim(
      {required this.highContrast, this.lens = false, this.pressure = 0});
  final bool highContrast, lens;
  final double pressure;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(.5);
    final rim = RRect.fromRectAndRadius(bounds, const Radius.circular(100));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.2 : (lens ? .75 : .55);
    if (highContrast) {
      paint.color = DSColors.silver;
    } else if (lens) {
      // Lens rim: bold top-left specular hit fading to a bottom-right glimmer.
      // The alpha scales with pressure so it brightens when held.
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .72 + pressure * .18),
          Colors.white.withValues(alpha: .38 + pressure * .10),
          Colors.white.withValues(alpha: .10),
          Colors.white.withValues(alpha: .06),
          Colors.white.withValues(alpha: .32 + pressure * .08),
        ],
        stops: const [0.0, 0.22, 0.50, 0.72, 1.0],
      ).createShader(bounds);
    } else {
      // Dock rim: subtle specular on top-left corner only.
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .38),
          Colors.white.withValues(alpha: .14),
          Colors.white.withValues(alpha: .06),
          Colors.white.withValues(alpha: .18),
        ],
        stops: const [0, .32, .70, 1],
      ).createShader(bounds);
    }
    canvas.drawRRect(rim, paint);
  }

  @override
  bool shouldRepaint(_GlassRim oldDelegate) =>
      highContrast != oldDelegate.highContrast ||
      lens != oldDelegate.lens ||
      pressure != oldDelegate.pressure;
}
