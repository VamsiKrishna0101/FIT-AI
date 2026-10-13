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
  OnboardingPageRoute(
      {required super.page,
      super.duration = DSMotion.pageTransition,
      super.reverseDuration = DSMotion.pageTransition});
}
