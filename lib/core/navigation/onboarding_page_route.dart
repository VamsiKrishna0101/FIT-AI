import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../theme/ds_motion.dart';
import '../theme/fitness_theme.dart';

/// Native page movement keeps the screen opaque throughout navigation.
class OnboardingPageTransitionsBuilder extends PageTransitionsBuilder {
  const OnboardingPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return const CupertinoPageTransitionsBuilder()
        .buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}

class AppPageRoute<T> extends CupertinoPageRoute<T> {
  final Duration _duration;
  final Duration _reverseDuration;

  AppPageRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 380),
    Duration reverseDuration = const Duration(milliseconds: 320),
  })  : _duration = duration,
        _reverseDuration = reverseDuration,
        super(
            builder: (_) => RepaintBoundary(child: FitnessTheme(child: page)));

  bool get _reducedMotion =>
      navigator != null &&
      MediaQuery.maybeOf(navigator!.context)?.disableAnimations == true;

  @override
  Duration get transitionDuration => _reducedMotion ? Duration.zero : _duration;

  @override
  Duration get reverseTransitionDuration =>
      _reducedMotion ? Duration.zero : _reverseDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return super
        .buildTransitions(context, animation, secondaryAnimation, child);
  }
}

class OnboardingPageRoute<T> extends AppPageRoute<T> {
  /// Release the Continue button once the next screen has entered.
  /// Navigator.push itself completes only when the user comes back.
  Future<void> open(BuildContext context) async {
    final entered = Completer<void>();
    final result = Navigator.of(context).push<T>(this);
    final motion = controller;

    void finish() {
      if (!entered.isCompleted) entered.complete();
    }

    void statusChanged(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        finish();
      }
    }

    motion?.addStatusListener(statusChanged);
    if (motion == null || motion.isCompleted) finish();
    unawaited(result.then((_) => finish()));

    try {
      await entered.future;
    } finally {
      motion?.removeStatusListener(statusChanged);
    }
  }

  OnboardingPageRoute(
      {required super.page,
      super.duration = DSMotion.pageTransition,
      super.reverseDuration = DSMotion.pageTransition});
}
