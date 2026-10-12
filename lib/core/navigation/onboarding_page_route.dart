import 'package:flutter/material.dart';

import '../theme/ds_motion.dart';
import '../theme/fitness_theme.dart';

/// A restrained transition shared by app screens and onboarding.
///
/// The incoming page moves a short distance and fades into place. The outgoing
/// page shifts only slightly in the opposite direction, avoiding the stacked
/// scale, fade, and child stagger effects that made step changes feel busy.
class OnboardingPageTransitionsBuilder extends PageTransitionsBuilder {
  const OnboardingPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _OnboardingPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _OnboardingPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _OnboardingPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final Animation<double> incoming = animation.drive<double>(
      CurveTween(curve: DSMotion.standard),
    );
    final Animation<double> outgoing = secondaryAnimation.drive<double>(
      CurveTween(curve: DSMotion.standard),
    );

    final incomingPosition = Tween<Offset>(
      begin: const Offset(0.028, 0),
      end: Offset.zero,
    ).animate(incoming);
    final incomingOpacity = Tween<double>(begin: 0, end: 1).animate(incoming);
    final outgoingPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.012, 0),
    ).animate(outgoing);
    final outgoingOpacity =
        Tween<double>(begin: 1, end: 0.96).animate(outgoing);

    return SlideTransition(
      position: outgoingPosition,
      child: FadeTransition(
        opacity: outgoingOpacity,
        child: SlideTransition(
          position: incomingPosition,
          child: FadeTransition(opacity: incomingOpacity, child: child),
        ),
      ),
    );
  }
}

/// Use the same timing for push and pop so direction changes feel predictable.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    Duration duration = DSMotion.regular,
    Duration reverseDuration = DSMotion.regular,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              FitnessTheme(child: page),
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _OnboardingPageTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          ),
        );
}

class OnboardingPageRoute<T> extends AppPageRoute<T> {
  OnboardingPageRoute({
    required super.page,
    super.duration = DSMotion.pageTransition,
    super.reverseDuration = DSMotion.pageTransition,
  });
}
