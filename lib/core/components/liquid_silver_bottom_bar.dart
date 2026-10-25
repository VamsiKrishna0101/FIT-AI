import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_native/liquid_glass_native.dart';

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
      64 + (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(0, 14);

  static double _bottomMargin(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom + 8;

  static double scrollBottomInset(BuildContext context) =>
      math.max(
          _isIOS ? 100.0 : 0.0, _height(context) + _bottomMargin(context)) +
      32;

  @override
  State<LiquidSilverBottomBar> createState() => _LiquidSilverBottomBarState();
}

class _LiquidSilverBottomBarState extends State<LiquidSilverBottomBar> {
  static const _platform = MethodChannel('fitai/navigation');
  static const _maxWidth = 376.0;
  static const _sideMargin = 20.0;
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

  static final _blur = ImageFilter.blur(sigmaX: 12, sigmaY: 12);
  static const _icons = [
    CupertinoIcons.sun_max,
    CupertinoIcons.flame,
    CupertinoIcons.person_crop_rectangle,
    CupertinoIcons.chart_bar,
  ];

  Widget _glassSurface(BuildContext context, Widget child) {
    final highContrast = MediaQuery.highContrastOf(context);
    return ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
            filter: _blur,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: highContrast
                        ? DSColors.bgCard
                        : const Color(0xF21C1C1C),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: highContrast
                            ? DSColors.textSecondary
                            : const Color(0xFF393939),
                        width: .7)),
                child: child)));
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
                  decoration: BoxDecoration(
                      color: Color(0xFF343434),
                      borderRadius: BorderRadius.all(Radius.circular(25))),
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
        padding: EdgeInsets.fromLTRB(_sideMargin, 24, _sideMargin,
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
            opacity: selected ? 1 : .68,
            duration: duration,
            curve: AnimatedTabStack.curve,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icons[index], color: DSColors.navGlassText, size: 21),
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
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
          final delta = event.localPosition - _origin;
          _stretch = Offset(delta.dx.clamp(-8, 8).toDouble(),
              delta.dy.clamp(-5, 5).toDouble());
        });
      },
      onPointerUp: (event) => _release(event.pointer),
      onPointerCancel: (event) => _release(event.pointer),
      child: AnimatedScale(
        scale: _pointer == null ? 1 : 1.005,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _stretch),
          duration: Duration(milliseconds: _pointer == null ? 380 : 80),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
              key: const ValueKey('navigation-touch-offset'),
              offset: value,
              child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
