import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/components/motion.dart';
import '../../core/localization/fitness_text.dart';

/// A finite entrance, without image decoding, shaders or a repeating ticker.
class TrialAccessHero extends StatelessWidget {
  final int days;
  const TrialAccessHero({super.key, this.days = 14});
  @override
  Widget build(BuildContext context) => MotionEntrance(
        child: Container(
          key: const ValueKey('trial-access-hero'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            border: Border.all(color: const Color(0xFF363636)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(children: [
            Text(
                NumberFormat.decimalPattern(
                        Localizations.localeOf(context).toLanguageTag())
                    .format(days),
                style: const TextStyle(
                    fontSize: 76,
                    height: 1.05,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -2,
                    color: Colors.white)),
            const SizedBox(width: 15),
            const Expanded(
                child: FitnessText('days of full access',
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCCCCCC)))),
          ]),
        ),
      );
}
