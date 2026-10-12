// Profile-only reference of the previous independent 28px blur filters.
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS-style liquid silver bottom navigation.
///
/// Reference layout:
/// [ Overview | Notes | Calendar | Tasks ]   [ + ]
class LegacySilverBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreate;
  final List<String> labels;
  final String createLabel;
  final Widget? actionChild;

  const LegacySilverBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onCreate,
    required this.labels,
    this.createLabel = 'Create',
    this.actionChild,
  })  : assert(labels.length == 4),
        assert(selectedIndex >= 0 && selectedIndex < 4);

  static const double _dockHeight = 58;
  static const double _createSize = 58;
  static const double _gap = 12;

  /// Use this for ListView / ScrollView bottom padding
  /// so content isn't hidden behind the floating dock.
  static double scrollBottomInset(BuildContext context) {
    // extendBody adds the dock height to padding; viewPadding is the device inset.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return _dockHeight + _bottomMargin(safeBottom) + 18;
  }

  static double _bottomMargin(double safeBottom) =>
      safeBottom > 0 ? safeBottom + 4 : 14;

  /// FitAI's Today / Train / Body / Progress destinations.
  static const List<IconData> _icons = [
    CupertinoIcons.sun_max,
    CupertinoIcons.flame,
    CupertinoIcons.person_crop_rectangle,
    CupertinoIcons.chart_bar,
  ];

  static const List<IconData> _activeIcons = [
    CupertinoIcons.sun_max_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.person_crop_rectangle_fill,
    CupertinoIcons.chart_bar_fill,
  ];

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return RepaintBoundary(
      child: BackdropGroup(
          child: Align(
        alignment: Alignment.bottomCenter,
        // A bottomNavigationBar must size to its contents, not the screen height.
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            _bottomMargin(safeBottom),
          ),
          child: SizedBox(
            height: _createSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Main glass navigation capsule
                Expanded(
                  child: _SilverGlass(
                    borderRadius: 30,
                    child: SizedBox(
                      height: _dockHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Row(
                          children: List.generate(
                            4,
                            (index) => _buildTab(index),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: _gap),

                /// Separate circular create button
                _CreateButton(
                  size: _createSize,
                  label: createLabel,
                  onTap: onCreate,
                  child: actionChild,
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildTab(int index) {
    final bool selected = selectedIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: labels[index],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;

            HapticFeedback.selectionClick();
            onTabSelected(index);
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: selected ? 1 : 0.78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? _activeIcons[index] : _icons[index],
                    key: ValueKey(selected),
                    size: 20,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1,
                    letterSpacing: -0.15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.78),
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

/// Circular glass + button.
class _CreateButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final String label;
  final Widget? child;

  const _CreateButton({
    required this.size,
    required this.onTap,
    required this.label,
    this.child,
  });

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
        },
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: _SilverGlass(
              borderRadius: widget.size / 2,
              stronger: true,
              child: Center(
                child: widget.child ??
                    Icon(
                      CupertinoIcons.add,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.96),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable liquid silver glass.
///
/// Layers:
/// 1. backdrop blur
/// 2. translucent dark/silver material
/// 3. top silver reflection
/// 4. bottom depth
/// 5. thin specular border
class _SilverGlass extends StatelessWidget {
  // Both non-overlapping capsules share one backdrop capture/filter pass.
  static final _blur = ImageFilter.blur(sigmaX: 28, sigmaY: 28);
  final Widget child;
  final double borderRadius;
  final bool stronger;

  const _SilverGlass({
    required this.child,
    required this.borderRadius,
    this.stronger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),

        /// Soft floating shadow under the glass.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 26,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: _blur,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),

              /// Base translucent "silver smoke"
              color: const Color(0xFF7C7C7C).withValues(
                alpha: stronger ? 0.20 : 0.17,
              ),

              /// Thin bright silver edge.
              border: Border.all(
                width: 0.75,
                color: Colors.white.withValues(alpha: 0.32),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// Dark glass depth.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [
                          0.0,
                          0.20,
                          0.55,
                          1.0,
                        ],
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.15),
                          Color.fromRGBO(255, 255, 255, 0.08),
                          Color.fromRGBO(90, 90, 90, 0.12),
                          Color.fromRGBO(15, 15, 15, 0.25),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Horizontal liquid silver shine.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [
                          0.00,
                          0.20,
                          0.43,
                          0.63,
                          0.82,
                          1.00,
                        ],
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.14),
                          Color.fromRGBO(255, 255, 255, 0.04),
                          Color.fromRGBO(255, 255, 255, 0.01),
                          Color.fromRGBO(255, 255, 255, 0.08),
                          Color.fromRGBO(255, 255, 255, 0.03),
                          Color.fromRGBO(255, 255, 255, 0.11),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Strong curved-looking top highlight.
                Positioned(
                  left: 20,
                  right: 20,
                  top: 0.6,
                  height: 1.2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.52),
                            Colors.white.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                /// Slight light reflection in upper half.
                Positioned(
                  top: 0,
                  left: 4,
                  right: 4,
                  height: 24,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(borderRadius),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                /// Bottom glass rim.
                Positioned(
                  bottom: 0.5,
                  left: 17,
                  right: 17,
                  height: 1,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
