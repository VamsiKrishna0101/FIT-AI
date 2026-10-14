import 'package:flutter/material.dart';

import '../localization/fitness_text.dart';
import '../theme/fitness_theme.dart';
import '../theme/ds_motion.dart';

/// Use a stable child key for refreshes, and a new key for a new selection.
class ContentTransition extends StatelessWidget {
  const ContentTransition({super.key, required this.child});

  final Widget child;

  static const duration = DSMotion.regular;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedSize(
      duration: duration,
      curve: DSMotion.effects,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .018),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final child in previous)
              IgnorePointer(child: ExcludeSemantics(child: child)),
            if (current != null) current,
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Quiet placeholders reserve card space without inventing any readings.
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key, this.cards = 3});

  final int cards;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading your data',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FitnessText('Loading your data…',
                style: TextStyle(color: FitnessTheme.muted, fontSize: 12)),
            const SizedBox(height: 18),
            for (var index = 0; index < cards; index++) ...[
              FitnessCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 120, height: 14),
                    const SizedBox(height: 18),
                    _line(height: 32),
                    const SizedBox(height: 12),
                    _line(width: 160, height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );

  Widget _line({double? width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .08),
              Colors.white.withValues(alpha: .035)
            ],
          ),
        ),
      );
}
