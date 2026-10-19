import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_native/liquid_glass_native.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart' as glass;

import '../theme/ds_colors.dart';
import 'animated_tab_stack.dart';

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

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static double _height(BuildContext context) =>
      60 + (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(0, 14);

  static double _bottomMargin(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom + 12;

  static double scrollBottomInset(BuildContext context) =>
      math.max(
          _isIOS ? 100.0 : 0.0, _height(context) + _bottomMargin(context)) +
      32;

  @override
  State<LiquidSilverBottomBar> createState() => _LiquidSilverBottomBarState();
}

class _LiquidSilverBottomBarState extends State<LiquidSilverBottomBar> {
  static const _platform = MethodChannel('fitai/navigation');
  static const _maxWidth = 320.0;
  static const _sideMargin = 32.0;
  bool _nativeGlassAvailable = false;
  int? _previewIndex;
  bool _dragCancelled = false;

  int get selectedIndex => widget.selectedIndex;
  int get _visibleIndex => _previewIndex ?? selectedIndex;
  List<String> get labels => widget.labels;

  @override
  void initState() {
    super.initState();
    if (LiquidSilverBottomBar._isIOS) _checkNativeGlass();
  }

  Future<void> _checkNativeGlass() async {
    try {
      final available =
          await _platform.invokeMethod<bool>('supportsLiquidGlass');
      if (mounted && available == true) {
        setState(() => _nativeGlassAvailable = true);
      }
    } on PlatformException {
      // Keep navigation usable if the platform bridge is unavailable.
    } on MissingPluginException {
      // Widget previews and older app hosts use the Flutter dock.
    }
  }

  void _selectTab(int index) {
    if (index == selectedIndex) return;
    HapticFeedback.selectionClick();
    widget.onTabSelected(index);
  }

  Widget _nativeDock(BuildContext context) {
    // Pin the plugin's host to the bottom edge. UIKit supplies the capsule's
    // floating gap and home-indicator inset inside its 100pt native view.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sideMargin),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: LiquidGlassTabBar(
            // The plugin updates selection in place; labels need a new native
            // view when the account language changes.
            key: ValueKey(List<String>.of(labels).join('\u0000')),
            currentIndex: selectedIndex,
            brightness: Brightness.dark,
            tint: DSColors.navGlassText,
            items: [
              TabItem(label: labels[0], sfSymbol: 'sun.max'),
              TabItem(label: labels[1], sfSymbol: 'flame'),
              TabItem(label: labels[2], sfSymbol: 'person.crop.rectangle'),
              TabItem(label: labels[3], sfSymbol: 'chart.bar'),
            ],
            onTap: _selectTab,
          ),
        ),
      ),
    );
  }

  static final _blur = ImageFilter.blur(sigmaX: 18, sigmaY: 18);
  static const _icons = [
    CupertinoIcons.sun_max,
    CupertinoIcons.flame,
    CupertinoIcons.person_crop_rectangle,
    CupertinoIcons.chart_bar,
  ];

  static const _glassSettings = glass.LiquidGlassSettings(
    glassColor: DSColors.navGlassTint,
    thickness: 7,
    blur: 18,
    refractiveIndex: 1.06,
    lightIntensity: .22,
    ambientStrength: .025,
    saturation: 1,
    chromaticAberration: 0,
  );

  Widget _glassSurface(BuildContext context, Widget child) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final contents = DecoratedBox(
      decoration: const BoxDecoration(gradient: DSColors.navGlassSheenGradient),
      child: reducedMotion || highContrast
          ? child
          : glass.GlassGlow(
              glowColor: DSColors.navTouchGlow,
              glowRadius: 1.15,
              child: child,
            ),
    );

    // UIKit owns the native iPhone material. Only Android uses this shader.
    if (!LiquidSilverBottomBar._isIOS &&
        !highContrast &&
        ImageFilter.isShaderFilterSupported) {
      return glass.LiquidGlass.withOwnLayer(
        key: const ValueKey('navigation-refractive-glass'),
        shape: const glass.LiquidRoundedSuperellipse(borderRadius: 30),
        settings: _glassSettings,
        child: contents,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: _blur,
        child: CustomPaint(
          foregroundPainter: const _SilverRimPainter(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highContrast ? DSColors.bgElevated : null,
              gradient: highContrast ? null : DSColors.navGlassGradient,
              border: highContrast
                  ? Border.all(color: DSColors.textSecondary)
                  : null,
              borderRadius: BorderRadius.circular(30),
            ),
            child: glass.GlassGlowLayer(child: contents),
          ),
        ),
      ),
    );
  }

  Widget _contents(BuildContext context, Duration duration) => Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: AnimatedAlign(
              alignment:
                  Alignment(-1 + _visibleIndex * 2 / (labels.length - 1), 0),
              duration: duration,
              curve: AnimatedTabStack.curve,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: const DecoratedBox(
                  key: ValueKey('navigation-active-lens'),
                  decoration:
                      BoxDecoration(gradient: DSColors.navGlassLensGradient),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(child: _tab(context, index, duration)),
          ]),
        ),
      ]);

  void _previewTab(Offset position, Size size) {
    final inside = position.dx >= 0 &&
        position.dx <= size.width &&
        position.dy >= -24 &&
        position.dy <= size.height + 24;
    final index = inside
        ? ((position.dx - 6) / ((size.width - 12) / labels.length))
            .floor()
            .clamp(0, labels.length - 1)
        : null;

    if (_previewIndex != index) setState(() => _previewIndex = index);
  }

  void _finishDrag() {
    if (_dragCancelled) {
      _cancelDrag();
      return;
    }
    final index = _previewIndex;
    if (index == null) return;
    setState(() => _previewIndex = null);
    // Preview locally while dragging; open the destination once on release.
    _selectTab(index);
  }

  void _cancelDrag() {
    _dragCancelled = true;
    if (_previewIndex == null) return;
    _previewIndex = null;
    // Accessibility changes can cancel a gesture while its subtree is removed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeGlassAvailable) return _nativeDock(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AnimatedTabStack.duration;

    return DecoratedBox(
      key: const ValueKey('navigation-backdrop'),
      decoration: const BoxDecoration(gradient: DSColors.navScrimGradient),
      child: Padding(
        padding: EdgeInsets.fromLTRB(_sideMargin, 40, _sideMargin,
            LiquidSilverBottomBar._bottomMargin(context)),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SizedBox(
              key: const ValueKey('navigation-capsule'),
              width: double.infinity,
              height: LiquidSilverBottomBar._height(context),
              child: _DockTouchFeedback(
                enabled: !MediaQuery.disableAnimationsOf(context),
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = constraints.biggest;
                  return _glassSurface(
                    context,
                    Listener(
                      onPointerDown: (_) => _dragCancelled = false,
                      onPointerCancel: (_) => _dragCancelled = true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (details) =>
                            _previewTab(details.localPosition, size),
                        onHorizontalDragUpdate: (details) =>
                            _previewTab(details.localPosition, size),
                        onHorizontalDragEnd: (_) => _finishDrag(),
                        onHorizontalDragCancel: _cancelDrag,
                        child: _contents(context, duration),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, Duration duration) {
    final selected = _visibleIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      label: labels[index],
      excludeSemantics: true,
      child: Tooltip(
        message: labels[index],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _selectTab(index),
          child: AnimatedOpacity(
            opacity: selected ? 1 : .7,
            duration: duration,
            curve: AnimatedTabStack.curve,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icons[index], color: DSColors.navGlassText, size: 20),
                const SizedBox(height: 3),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DSColors.navGlassText,
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keep touch animation local to the dock, including cancelled gestures.
class _DockTouchFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _DockTouchFeedback({required this.child, required this.enabled});

  @override
  State<_DockTouchFeedback> createState() => _DockTouchFeedbackState();
}

class _DockTouchFeedbackState extends State<_DockTouchFeedback> {
  int? _pointer;
  Offset _origin = Offset.zero;
  Offset _stretch = Offset.zero;

  @override
  void didUpdateWidget(_DockTouchFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _stretch = Offset.zero;
    }
  }

  void _release(int pointer) {
    if (pointer != _pointer) return;
    setState(() {
      _pointer = null;
      _stretch = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (event) {
        if (_pointer != null) return;
        setState(() {
          _pointer = event.pointer;
          _origin = event.localPosition;
        });
      },
      onPointerMove: (event) {
        if (event.pointer != _pointer) return;
        setState(() {
          _stretch = (event.localPosition - _origin).withResistance(.12) * .22;
        });
      },
      onPointerUp: (event) => _release(event.pointer),
      onPointerCancel: (event) => _release(event.pointer),
      child: AnimatedScale(
        scale: _pointer == null ? 1 : 1.015,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _stretch),
          duration: Duration(milliseconds: _pointer == null ? 380 : 80),
          curve: _pointer == null ? Curves.easeOutBack : Curves.easeOutCubic,
          builder: (context, value, child) =>
              glass.RawLiquidStretch(stretchPixels: value, child: child!),
          child: widget.child,
        ),
      ),
    );
  }
}

/// One faint edge catches light without outlining a second capsule.
class _SilverRimPainter extends CustomPainter {
  const _SilverRimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rim = RRect.fromRectAndRadius(
        bounds.deflate(.5), Radius.circular(size.height / 2));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x26FFFFFF), Color(0x0CFFFFFF), Color(0x08FFFFFF)],
        stops: [0, .4, 1],
      ).createShader(bounds);
    canvas.drawRRect(rim, paint);
  }

  @override
  bool shouldRepaint(_SilverRimPainter oldDelegate) => false;
}
