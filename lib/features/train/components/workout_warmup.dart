import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

/// Informational preparation is deliberately separate from the working-set logger.
class WorkoutWarmup extends StatelessWidget {
  final Map<String, dynamic>? warmup;
  const WorkoutWarmup({super.key, required this.warmup});
  @override
  Widget build(BuildContext context) {
    final steps = (warmup?['steps'] as List? ?? []).whereType<Map>().toList();
    if (steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FitnessCard(
          padding: EdgeInsets.zero,
          child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: const ValueKey('workout-warmup'),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: const FitnessText('Warm-up',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: FitnessText(
                    'About {minutes} min · before working sets',
                    values: {'minutes': warmup?['durationMinutes'] ?? 5},
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitnessText('${i + 1}. ${steps[i]['name']}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 5),
                              if (steps[i]['reps'] != null)
                                FitnessText('{reps} practice reps',
                                    values: {'reps': steps[i]['reps']},
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.silver)),
                              if ((steps[i]['weightKg'] as num?) != null)
                                FitnessText(
                                    '{weight} kg · lighter than working load',
                                    values: {'weight': steps[i]['weightKg']},
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted)),
                              FitnessText('${steps[i]['instruction']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.muted,
                                      height: 1.45)),
                            ])),
                  FitnessText('${warmup?['note'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: FitnessTheme.muted,
                          height: 1.45)),
                ],
              ))),
    );
  }
}
