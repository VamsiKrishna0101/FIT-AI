import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Local editorial artwork; the lower canvas stays black behind the actions.
class WelcomeBackgroundImage extends StatelessWidget {
  static const asset = 'assets/branding/setcraft-welcome-editorial-v1.webp';
  const WelcomeBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: ColoredBox(
          color: const Color(0xFF000000),
          child: LayoutBuilder(builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
            final compact = constraints.maxHeight < 700 || largeText;
            final top = MediaQuery.viewPaddingOf(context).top;
            final width = math.min(constraints.maxWidth, 600.0);
            final height = compact ? constraints.maxHeight * .58 : width * 1.5;
            final decodeWidth = math.min(
                1024, (width * MediaQuery.devicePixelRatioOf(context)).ceil());
            return Stack(fit: StackFit.expand, children: [
              Positioned(
                  top: top,
                  left: (constraints.maxWidth - width) / 2,
                  width: width,
                  height: height,
                  child: Image.asset(asset,
                      key: const ValueKey('welcome-editorial-image'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: decodeWidth,
                      gaplessPlayback: true,
                      errorBuilder: (_, error, stack) =>
                          const SizedBox.expand())),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: compact
                              ? const [0, .18, .34, .48, 1]
                              : const [0, .35, .58, .76, 1],
                          colors: const [
                    Color(0x11000000),
                    Color(0x00000000),
                    Color(0x80000000),
                    Color(0xFF000000),
                    Color(0xFF000000)
                  ]))),
            ]);
          })));
}
