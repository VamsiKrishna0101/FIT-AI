import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';

/// The welcome promise and what it covers, with a reduced-motion-aware entrance.
class WelcomeTrainingIntro extends StatefulWidget {
  final bool compact;
  const WelcomeTrainingIntro({super.key, this.compact = false});
  @override
  State<WelcomeTrainingIntro> createState() => _WelcomeTrainingIntroState();
}

class _WelcomeTrainingIntroState extends State<WelcomeTrainingIntro>
    with SingleTickerProviderStateMixin {
  late final _entrance =
      AnimationController(vsync: this, duration: DSMotion.reveal);
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) {
      _entrance.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _item(int index, Widget child) => AnimatedBuilder(
        animation: _entrance,
        child: child,
        builder: (context, child) {
          final value =
              Interval(index * .08, .84 + index * .08, curve: DSMotion.effects)
                  .transform(_entrance.value);
          return Opacity(
            key: ValueKey('welcome-goal-$index'),
            opacity: value,
            alwaysIncludeSemantics: true,
            child: Transform.translate(
                offset: Offset(0, (1 - value) * 10), child: child),
          );
        },
      );
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item(
              0,
              Semantics(
                  header: true,
                  child: FitnessText('Your plan, built around you.',
                      style: TextStyle(
                          fontSize: widget.compact ? 30 : 34,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.9,
                          color: Colors.white)))),
          const SizedBox(height: 12),
          _item(
              1,
              const FitnessText(
                  'Personal workouts, nutrition & recovery.\nSee your progress, all in one place.',
                  style: TextStyle(
                      fontSize: 15, height: 1.45, color: Color(0xFF9A9AA2)))),
        ],
      );
}
