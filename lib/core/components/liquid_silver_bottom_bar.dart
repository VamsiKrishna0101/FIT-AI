import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../theme/ds_colors.dart';
import '../theme/ds_motion.dart';
import 'navigation_glyph.dart';

/// Height of one tab (icon over label) and the glass margin around the row.
/// 44pt keeps Apple's minimum tap height while trimming the dock's bulk.
const double _tabHeight = 44;
const double _shellInset = 3;
const double _pillInset = 2;
const Color _unselected = Color(0xFF8E8E93);

/// Gentle, neutral saturation lift so page colours glow through the frost
/// without tinting greys.
List<double> _saturation(double s) {
  const r = .2126, g = .7152, b = .0722;
  final i = 1 - s;
  return [
    i * r + s, i * g, i * b, 0, 0, //
    i * r, i * g + s, i * b, 0, 0, //
    i * r, i * g, i * b + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// A calm floating tab bar: one dark frosted capsule, a soft hairline rim,
/// and a quiet filled pill that glides behind the selected tab.
/// Identical on iOS and Android.
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
  bool _pressed = false, _dragging = false, _dragCancelled = false;
  bool _refreshScheduled = false, _deferredRefresh = false;

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
    // A light detent each time the dragged pill crosses into another tab.
    if (dragging && _previewIndex != null && index != _previewIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _previewIndex = index;
      _previewPosition = position;
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
    // Float clear of the home indicator with visible page beneath the glass.
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      key: const ValueKey('navigation-bar'),
      padding: EdgeInsets.fromLTRB(32, 8, 32, bottom),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 372),
            child: LayoutBuilder(builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth - _shellInset * 2, _tabHeight);
              return _GlassCapsule(
                key: const ValueKey('navigation-capsule'),
                highContrast: highContrast,
                child: Padding(
                  padding: const EdgeInsets.all(_shellInset),
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
                        // The pill sits behind the icons, so every tab face
                        // is drawn exactly once and never doubles up.
                        child: Stack(children: [
                          _SelectionPill(
                            position: _previewPosition ??
                                widget.selectedIndex.toDouble(),
                            dragging: _dragging,
                            pressed: _pressed,
                            reducedMotion: reduced,
                            highContrast: highContrast,
                            direction: direction,
                            width: size.width,
                            height: size.height,
                          ),
                          Row(children: [
                            for (var index = 0; index < 4; index++)
                              Expanded(child: _tab(index, duration)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

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
                end: selected ? DSColors.navGlassText : _unselected),
            duration: duration,
            curve: DSMotion.effects,
            builder: (context, color, _) => _TabFace(
                kind: _icons[index],
                label: widget.labels[index],
                color: color ?? DSColors.navGlassText),
          ),
        ),
      ),
    );
  }
}

/// Icon over a small label, as in the iOS tab bar. Like UITabBar, labels do
/// not grow with text scaling; tooltips and semantics carry the full label.
class _TabFace extends StatelessWidget {
  const _TabFace(
      {required this.kind, required this.label, required this.color});
  final NavigationGlyphKind kind;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
        .copyWith(
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
            color: color);
    return SizedBox(
      height: _tabHeight,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        NavigationGlyph(kind: kind, color: color, size: 20),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ExcludeSemantics(
              child: Text(label,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: style),
            ),
          ),
        ),
      ]),
    );
  }
}

/// One frosted pass, one soft shadow, one hairline rim.
class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule(
      {super.key, required this.highContrast, required this.child});
  final bool highContrast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(100);
    final Widget surface = highContrast
        ? ColoredBox(color: DSColors.bgRaised, child: child)
        : BackdropFilter(
            filter: ui.ImageFilter.compose(
              outer: ui.ImageFilter.blur(
                  sigmaX: 24, sigmaY: 24, tileMode: TileMode.mirror),
              inner: ColorFilter.matrix(_saturation(1.25)),
            ),
            child: DecoratedBox(
              key: const ValueKey('navigation-dock-finish'),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C1F1F22), Color(0x9E151517)],
                ),
              ),
              child: child,
            ),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
              color: Color(0x59000000),
              blurRadius: 28,
              spreadRadius: -6,
              offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          foregroundPainter: _Hairline(highContrast: highContrast),
          child: Material(type: MaterialType.transparency, child: surface),
        ),
      ),
    );
  }
}

/// The selection glides with a critically damped spring: no bounce, no
/// swelling, no stretch. A press only brightens it slightly.
class _SelectionPill extends StatefulWidget {
  const _SelectionPill({
    required this.position,
    required this.dragging,
    required this.pressed,
    required this.reducedMotion,
    required this.highContrast,
    required this.direction,
    required this.width,
    required this.height,
  });
  final double position, width, height;
  final bool dragging, pressed, reducedMotion, highContrast;
  final TextDirection direction;

  @override
  State<_SelectionPill> createState() => _SelectionPillState();
}

class _SelectionPillState extends State<_SelectionPill>
    with TickerProviderStateMixin {
  static const _spring =
      SpringDescription(mass: 1, stiffness: 520, damping: 46);
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
  void didUpdateWidget(_SelectionPill oldWidget) {
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
          final physical = widget.direction == TextDirection.rtl
              ? 3 - _motion.value
              : _motion.value;
          final pressure = widget.reducedMotion ? 0.0 : _press.value;
          final slot = widget.width / 4;
          final width = slot - _pillInset * 2;
          final height = widget.height - _pillInset * 2;
          final center = ((physical + .5) * slot)
              .clamp(width / 2, widget.width - width / 2);
          final fill = widget.highContrast
              ? const Color(0xFF535A63)
              : Color.lerp(const Color(0x24FFFFFF), const Color(0x30FFFFFF),
                  pressure)!;
          return Positioned(
            left: center - width / 2,
            top: _pillInset,
            width: width,
            height: height,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  key: const ValueKey('navigation-active-pill'),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: widget.highContrast
                            ? DSColors.silver
                            : const Color(0x1AFFFFFF),
                        width: widget.highContrast ? 1 : .5),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// A single hairline: a little brighter along the top edge, where light hits.
class _Hairline extends CustomPainter {
  const _Hairline({required this.highContrast});
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.2 : .6;
    if (highContrast) {
      paint.color = DSColors.silver;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .22),
          Colors.white.withValues(alpha: .07),
        ],
      ).createShader(bounds);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(100)), paint);
  }

  @override
  bool shouldRepaint(_Hairline oldDelegate) =>
      highContrast != oldDelegate.highContrast;
}
