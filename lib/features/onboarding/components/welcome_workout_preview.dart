import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';

/// A single illustrative exercise; the user's plan is created after setup.
class WelcomeWorkoutPreview extends StatelessWidget {
  const WelcomeWorkoutPreview({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('welcome-workout-preview'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF292929), width: .7),
        ),
        child: const Row(children: [
          ExcludeSemantics(
              child: Icon(Icons.fitness_center_rounded,
                  size: 20, color: Color(0xFFCECECE))),
          SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitnessText('Dumbbell bench press',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFFECECEC),
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 3),
              FitnessText('3 sets · 10 reps',
                  style: TextStyle(
                      fontSize: 11, height: 1.4, color: Color(0xFF999999))),
            ],
          )),
          SizedBox(width: 12),
          SizedBox(
              width: 72,
              child: FitnessText('WORKOUT PREVIEW',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 8,
                      height: 1.5,
                      letterSpacing: 1.1,
                      color: Color(0xFF8C8C8C)))),
        ]),
      );
}
