import 'package:flutter/material.dart';

/// Shared with Today's quiet black canvas and silver controls.
class FitnessTheme extends StatelessWidget {
  static const canvas = Color(0xFF111111);
  static const surface = Color(0xFF202020);
  static const silver = Color(0xFFE2E2E2);
  static const muted = Color(0xFF969696);
  static const line = Color(0x14FFFFFF);
  static const blue = Color(0xFF689FFF);
  static const violet = Color(0xFFA28BFA);
  static const coral = Color(0xFFED927F);
  final Widget child;
  const FitnessTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family =
        theme.platform == TargetPlatform.iOS ? 'CupertinoSystemText' : 'Inter';
    return Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
              fontFamily: family,
              bodyColor: Colors.white,
              displayColor: Colors.white),
          colorScheme: theme.colorScheme.copyWith(
              primary: silver,
              secondary: silver,
              surface: surface,
              onSurface: Colors.white,
              onSurfaceVariant: muted,
              surfaceTint: Colors.transparent),
          scaffoldBackgroundColor: canvas,
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(14)))),
        ),
        child: DefaultTextStyle.merge(
            style: TextStyle(fontFamily: family), child: child));
  }
}

class FitnessCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FitnessCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: FitnessTheme.surface, borderRadius: BorderRadius.circular(20)),
      child: child);
}
