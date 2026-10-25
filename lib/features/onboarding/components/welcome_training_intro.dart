import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';
import 'training_hero.dart';

/// A brief entrance, with no loop, timer or delay before the primary action.
class WelcomeTrainingIntro extends StatefulWidget {
  const WelcomeTrainingIntro({super.key});
  @override
  State<WelcomeTrainingIntro> createState() => _WelcomeTrainingIntroState();
}

class _WelcomeTrainingIntroState extends State<WelcomeTrainingIntro>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
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

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRect(
            child: AnimatedBuilder(
                animation: _entrance,
                child: TrainingHero(
                    height:
                        MediaQuery.sizeOf(context).height < 740 ? 210 : 330),
                builder: (context, child) => Transform.scale(
                    scale: 1.035 -
                        Curves.easeOutCubic.transform(_entrance.value) * .035,
                    child: child))),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FitnessText('Ready for your next chapter?',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFA8A8A8), height: 1.5)),
              const SizedBox(height: 12),
              for (var index = 0; index < 3; index++)
                AnimatedBuilder(
                    animation: _entrance,
                    child: FitnessText(
                        const [
                          'Build muscle',
                          'Get stronger',
                          'Stay consistent'
                        ][index],
                        style: TextStyle(
                            fontSize: 36,
                            height: 1.12,
                            letterSpacing: -1.1,
                            fontWeight: FontWeight.w700,
                            color: index == 2
                                ? const Color(0xFFAAAAAA)
                                : Colors.white)),
                    builder: (context, child) {
                      final value = Interval(index * .16, .68 + index * .16,
                              curve: Curves.easeOutCubic)
                          .transform(_entrance.value);
                      return Opacity(
                          key: ValueKey('welcome-goal-$index'),
                          opacity: value,
                          alwaysIncludeSemantics: true,
                          child: Transform.translate(
                              offset: Offset(0, (1 - value) * 14),
                              child: child));
                    }),
              const SizedBox(height: 17),
              const FitnessText('Your goals, your plan',
                  style: TextStyle(
                      fontSize: 15, height: 1.5, color: Color(0xFFA8A8A8))),
            ])),
      ]);
}
