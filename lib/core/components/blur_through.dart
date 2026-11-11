import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

/// Content arrives out of a soft blur and leaves into one: it sharpens while
/// rising into place, and the outgoing content dissolves as it lifts away.
class BlurThrough extends StatelessWidget {
  /// 0 → 1 as the content enters.
  final Animation<double> enter;

  /// 0 → 1 as the content leaves (for example a route's secondary animation).
  final Animation<double>? exit;

  /// Timing within each animation, for example to let content leave before
  /// the next arrives.
  final Curve enterCurve, exitCurve;

  /// A page background that stays solid while the content leaves, so nothing
  /// underneath shows through; the whole page still fades in on entry.
  final Color? background;
  final Widget child;
  const BlurThrough(
      {super.key,
      required this.enter,
      this.exit,
      this.enterCurve = Curves.linear,
      this.exitCurve = Curves.linear,
      this.background,
      required this.child});

  static const _blur = 14.0, _rise = 18.0;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: exit == null ? enter : Listenable.merge([enter, exit]),
      child: child,
      builder: (context, child) {
        final inValue = Curves.easeOutCubic
            .transform(enterCurve.transform(enter.value.clamp(0, 1)));
        final outValue = Curves.easeInCubic
            .transform(exitCurve.transform((exit?.value ?? 0).clamp(0, 1)));
        final sigma = _blur * (1 - inValue) + _blur * outValue;
        Widget result = Transform.translate(
            offset: Offset(0, _rise * (1 - inValue) - _rise * .6 * outValue),
            child: child);
        if (sigma > .05) {
          result = ImageFiltered(
              imageFilter: ImageFilter.blur(
                  sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
              child: result);
        }
        if (background == null) {
          return Opacity(
              opacity: (inValue * (1 - outValue)).clamp(0.0, 1.0),
              child: result);
        }
        return Opacity(
            opacity: inValue.clamp(0.0, 1.0),
            child: ColoredBox(
                color: background!,
                child: Opacity(
                    opacity: (1 - outValue).clamp(0.0, 1.0), child: result)));
      });
}
