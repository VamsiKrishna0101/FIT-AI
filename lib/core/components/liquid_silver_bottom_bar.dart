import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_native/liquid_glass_native.dart';

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
      60 + (MediaQuery.textScalerOf(context).scale(10) - 10).clamp(0, 14);

  static double _bottomMargin(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom + 32;

  static double scrollBottomInset(BuildContext context) =>
      (_isIOS ? 100 : _height(context)) + _bottomMargin(context) + 28;

  @override
  State<LiquidSilverBottomBar> createState() => _LiquidSilverBottomBarState();
}

class _LiquidSilverBottomBarState extends State<LiquidSilverBottomBar> {
  static const _platform = MethodChannel('fitai/navigation');
  bool _nativeGlassAvailable = false;

  int get selectedIndex => widget.selectedIndex;
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
    // UIKit adds its own inset around the visible capsule inside this 100pt
    // host. Leave that space intact instead of clipping the system glass.
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 12, 12, LiquidSilverBottomBar._bottomMargin(context) - 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 372),
          child: LiquidGlassTabBar(
            // The plugin updates selection in place; labels need a new native
            // view when the account language changes.
            key: ValueKey(List<String>.of(labels).join('\u0000')),
            currentIndex: selectedIndex,
            brightness: Brightness.dark,
            tint: const Color(0xFFF3F3F5),
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

  static final _blur = ImageFilter.blur(sigmaX: 14, sigmaY: 14);
  static const _icons = [
    CupertinoIcons.sun_max,
    CupertinoIcons.flame,
    CupertinoIcons.person_crop_rectangle,
    CupertinoIcons.chart_bar,
  ];
  static const _activeIcons = [
    CupertinoIcons.sun_max_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.person_crop_rectangle_fill,
    CupertinoIcons.chart_bar_fill,
  ];

  @override
  Widget build(BuildContext context) {
    if (_nativeGlassAvailable) return _nativeDock(context);

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AnimatedTabStack.duration;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          28, 12, 28, LiquidSilverBottomBar._bottomMargin(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: SizedBox(
            key: const ValueKey('navigation-capsule'),
            width: double.infinity,
            height: LiquidSilverBottomBar._height(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x45000000),
                    blurRadius: 26,
                    spreadRadius: -4,
                    offset: Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Color(0x08E6EEFF),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: _blur,
                  child: CustomPaint(
                    foregroundPainter: const _SilverRimPainter(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x1CFFFFFF),
                            Color(0x07DCE2EA),
                            Color(0x12FFFFFF),
                          ],
                          stops: [0, .52, 1],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // One backdrop blur serves both the dock and its lens.
                          // The lens moves beneath the fixed icon/label hit areas.
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: AnimatedAlign(
                                alignment: Alignment(
                                    -1 +
                                        selectedIndex * 2 / (labels.length - 1),
                                    0),
                                duration: duration,
                                curve: AnimatedTabStack.curve,
                                child: FractionallySizedBox(
                                  widthFactor: 1 / labels.length,
                                  heightFactor: 1,
                                  child: CustomPaint(
                                    key: const ValueKey(
                                        'navigation-active-lens'),
                                    foregroundPainter:
                                        const _SilverRimPainter(selected: true),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0x38FFFFFF),
                                            Color(0x12FFFFFF),
                                            Color(0x20E8EDF5),
                                          ],
                                          stops: [0, .6, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Row(children: [
                              for (var index = 0;
                                  index < labels.length;
                                  index++)
                                Expanded(child: _tab(context, index, duration)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, Duration duration) {
    final selected = selectedIndex == index;
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
            opacity: selected ? 1 : .86,
            duration: duration,
            curve: AnimatedTabStack.curve,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Icon(
                    selected ? _activeIcons[index] : _icons[index],
                    key: ValueKey(selected),
                    color: const Color(0xFFF3F3F5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF3F3F5),
                    fontSize: 10,
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

/// Fine directional reflections keep the glass clear instead of tinting it gray.
class _SilverRimPainter extends CustomPainter {
  final bool selected;

  const _SilverRimPainter({this.selected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rim = RRect.fromRectAndRadius(
        bounds.deflate(.6), Radius.circular(size.height / 2));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: selected
            ? const [
                Color(0xA6FFFFFF),
                Color(0x26FFFFFF),
                Color(0x18FFFFFF),
                Color(0x85FFFFFF),
              ]
            : const [
                Color(0x99FFFFFF),
                Color(0x30FFFFFF),
                Color(0x12FFFFFF),
                Color(0x70FFFFFF),
              ],
        stops: const [0, .32, .62, 1],
      ).createShader(bounds);
    canvas.drawRRect(rim, paint);

    if (!selected) {
      // A second inset edge catches light like the reference's glass lip.
      paint
        ..strokeWidth = .55
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x05FFFFFF), Color(0x08FFFFFF), Color(0x40FFFFFF)],
          stops: [0, .65, 1],
        ).createShader(bounds);
      canvas.drawRRect(rim.deflate(2.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SilverRimPainter oldDelegate) =>
      selected != oldDelegate.selected;
}
