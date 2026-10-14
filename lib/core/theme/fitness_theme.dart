import 'ds_colors.dart';
import 'package:flutter/material.dart';

/// Shared with Today's quiet black canvas and silver controls.
class FitnessTheme extends StatelessWidget {
  static const canvas = DSColors.bg;
  static const surface = DSColors.bgCard;
  static const silver = DSColors.silver;
  static const muted = DSColors.muted;
  static const line = DSColors.border;
  static const blue = DSColors.blue;
  static const violet = DSColors.violet;
  static const coral = DSColors.coral;
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
              surfaceContainerLowest: canvas,
              surfaceContainerLow: surface,
              surfaceContainer: surface,
              surfaceContainerHigh: DSColors.bgRaised,
              surfaceContainerHighest: DSColors.bgRaised,
              onSurface: Colors.white,
              onSurfaceVariant: muted,
              surfaceTint: Colors.transparent),
          scaffoldBackgroundColor: canvas,
          canvasColor: canvas,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: canvas,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
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
          color: FitnessTheme.surface,
          border: Border.all(color: DSColors.border, width: .7),
          borderRadius: BorderRadius.circular(20)),
      child: child);
}
