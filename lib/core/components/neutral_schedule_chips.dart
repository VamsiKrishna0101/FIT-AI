import 'package:flutter/material.dart';
import '../theme/fitness_theme.dart';

/// Keep scheduling controls independent of the app's legacy accent chip theme.
class NeutralScheduleChips extends StatelessWidget {
  final Widget child;
  const NeutralScheduleChips({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ChipTheme(
      data: ChipTheme.of(context).copyWith(
        color: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFF3A3A3A)
                : FitnessTheme.canvas),
        selectedColor: const Color(0xFF3A3A3A),
        secondarySelectedColor: const Color(0xFF3A3A3A),
        backgroundColor: FitnessTheme.canvas,
        checkmarkColor: FitnessTheme.silver,
        labelStyle: const TextStyle(color: FitnessTheme.silver),
        secondaryLabelStyle: const TextStyle(color: FitnessTheme.silver),
        side: const BorderSide(color: FitnessTheme.line),
      ),
      child: child);
}
