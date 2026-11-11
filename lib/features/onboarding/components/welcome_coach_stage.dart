import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';
import 'coach_mascot.dart';
import 'onboarding_coach.dart';
import 'welcome_buddies.dart';

/// The welcome centrepiece: a large Mochi that waves hello, with its buddies
/// for training, food, sleep and heart health playing around it. Mochi is the
/// same hero as on the first question, so "Get started" sends it flying there.
class WelcomeCoachStage extends StatefulWidget {
  final double size;
  const WelcomeCoachStage({super.key, this.size = 140});

  @override
  State<WelcomeCoachStage> createState() => _WelcomeCoachStageState();
}

class _WelcomeCoachStageState extends State<WelcomeCoachStage>
    with TickerProviderStateMixin {
  late final _float = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));
  late final _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false, _waving = false;
  final _timers = <Timer>[];

  static const _buddies = [
    (BuddyKind.dumbbell, Alignment(-.95, -.7)),
    (BuddyKind.apple, Alignment(.97, -.5)),
    (BuddyKind.moon, Alignment(-.9, .78)),
    (BuddyKind.heart, Alignment(.92, .86)),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!OnboardingCoach.liveMotion || DSMotion.reduced(context)) {
      _enter.value = 1;
      return;
    }
    _float.repeat();
    _enter.forward();
    _timers
      ..add(Timer(const Duration(milliseconds: 500),
          () => mounted ? setState(() => _waving = true) : null))
      ..add(Timer(const Duration(milliseconds: 2900),
          () => mounted ? setState(() => _waving = false) : null));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _float.dispose();
    _enter.dispose();
    super.dispose();
  }

  Widget _buddy(int i) => AnimatedBuilder(
      animation: Listenable.merge([_float, _enter]),
      builder: (context, child) {
        final pop = Interval(.25 + i * .12, .7 + i * .08,
                curve: Curves.easeOutBack)
            .transform(_enter.value);
        final drift = math.sin((_float.value + i / 4) * math.pi * 2);
        return Transform.translate(
            offset: Offset(0, drift * 5),
            child: Transform.scale(scale: pop, child: child));
      },
      child: WelcomeBuddy(
          kind: _buddies[i].$1, size: widget.size * .5, clock: _float));

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: size * 2.2,
          height: size * 1.5,
          child: Stack(alignment: Alignment.center, children: [
            // Soft coral glow behind Mochi.
            Container(
                width: size * 1.5,
                height: size * 1.5,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFF9A84).withValues(alpha: .16),
                      const Color(0xFFFF9A84).withValues(alpha: 0)
                    ]))),
            for (var i = 0; i < _buddies.length; i++)
              Align(alignment: _buddies[i].$2, child: _buddy(i)),
            CoachHero(child: CoachMascot(size: size, talking: _waving)),
          ])),
      const SizedBox(height: 10),
      AnimatedBuilder(
          animation: _enter,
          builder: (context, child) {
            final v = const Interval(.45, 1, curve: Curves.easeOutBack)
                .transform(_enter.value);
            return Opacity(
                opacity: v.clamp(0.0, 1.0),
                child: Transform.scale(scale: .85 + .15 * v, child: child));
          },
          child: Container(
              key: const ValueKey('welcome-coach'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1F),
                  borderRadius: BorderRadius.circular(18)),
              child: FitnessText("Hi! I'm Mochi, your AI coach",
                  textAlign: TextAlign.center, style: CoachType.line()))),
    ]);
  }
}
