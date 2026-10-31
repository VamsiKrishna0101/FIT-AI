import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/views/widgets/plan_week_list.dart';
import '../../train/components/exercise_muscle_map.dart';
import '../../train/components/graphite_anatomy.dart';

/// Only public server previews are used before membership is active.
class StarterPlanReveal extends StatelessWidget {
  final Map<String, dynamic> preview;
  final Map<String, dynamic>? profile;
  final bool locked;
  const StarterPlanReveal(
      {super.key, required this.preview, this.profile, this.locked = true});

  @override
  Widget build(BuildContext context) {
    final groups =
        (preview['muscleGroups'] as List? ?? []).whereType<Map>().toList();
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final first = preview['firstWorkout'] as Map?;
    final samples = <Map>[];
    final seen = <String>{};
    for (final entry in [
      ...(first?['exercises'] as List? ?? []).whereType<Map>(),
      ...groups.expand((g) => (g['exercises'] as List? ?? []).whereType<Map>()),
    ]) {
      if (samples.length == 2) break;
      if (seen.add('${entry['name']}')) samples.add(entry);
    }
    final name =
        (profile?['name'] as String? ?? '').trim().split(RegExp(r'\s+')).first;
    final goal = switch (profile?['workingToward']) {
      'BUILD_MUSCLE' => 'Build muscle',
      'LOSE_BODY_FAT' || 'LOSE_WEIGHT' => 'Lose body fat',
      'GET_STRONGER' => 'Get stronger',
      'GET_FITTER' => 'Get fitter',
      'BUILD_CONSISTENCY' => 'Build consistency',
      _ => 'Your training',
    };
    final level = switch (profile?['experience']) {
      'BEGINNER' => 'Beginner',
      'INTERMEDIATE' => 'Intermediate',
      'ADVANCED' => 'Advanced',
      _ => null,
    };
    final location = switch (profile?['trainingLocation']) {
      'GYM' => 'Gym',
      'HOME' => 'Home',
      'OUTDOORS' => 'Outdoors',
      'MIX' => 'Gym & home',
      _ => null,
    };
    final selected =
        (profile?['focusMuscles'] as List? ?? []).whereType<String>().toList();
    final regions = selected.isNotEmpty
        ? selected
        : groups.map((g) => '${g['region']}').toList();
    final muscles = <String>{};
    for (final region in regions) {
      muscles.addAll(switch (region.toLowerCase()) {
        'back' => {'lats', 'upper_back', 'lower_back'},
        'legs' => {'quads', 'hamstrings', 'glutes', 'calves'},
        'arms' => {'biceps', 'triceps', 'forearms'},
        _ => exerciseMuscleIds([region]),
      });
    }
    final gender = profile?['gender'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText(
          name.isEmpty ? 'Your plan is ready' : '{name}, your plan is ready',
          key: const ValueKey('starter-ready-title'),
          values: {'name': name},
          style: const TextStyle(
              fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
      FitnessText(goal,
          style: const TextStyle(
              fontSize: 30,
              height: 1.15,
              letterSpacing: -.8,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 6, children: [
        if (level != null)
          FitnessText(level,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        if (location != null)
          FitnessText(location,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      ]),
      if (days.isNotEmpty) ...[
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(
              child: FitnessText('Your recommended week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          FitnessText('{count} training days',
              values: {'count': days.where((d) => d['restDay'] != true).length},
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ]),
        const SizedBox(height: 12),
        PlanWeekList(
            key: const ValueKey('starter-week-schedule'),
            days: days,
            locked: locked,
            compact: true,
            keyPrefix: 'starter-day'),
      ],
      if (samples.isNotEmpty) ...[
        const SizedBox(height: 20),
        const FitnessText('Exercise preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        FitnessCard(
            key: const ValueKey('starter-first-workout'),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final sample in samples)
                    Padding(
                        padding: EdgeInsets.only(
                            top: sample == samples.first ? 0 : 14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sample != samples.first) ...[
                                const Divider(
                                    height: 1, color: FitnessTheme.line),
                                const SizedBox(height: 12),
                              ],
                              FitnessText('${sample['name']}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              if (sample['sets'] != null &&
                                  sample['repsMin'] != null &&
                                  sample['repsMax'] != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: FitnessText(
                                        '{sets} sets · {reps} reps',
                                        values: {
                                          'sets': sample['sets']!,
                                          'reps': sample['repsMin'] ==
                                                  sample['repsMax']
                                              ? sample['repsMax']!
                                              : '${sample['repsMin']}–${sample['repsMax']}'
                                        },
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted))),
                            ])),
                  if (locked) ...[
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: FitnessTheme.line),
                    const SizedBox(height: 16),
                    const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline,
                              color: FitnessTheme.silver, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                              child: FitnessText('Unlock your full plan',
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: FitnessTheme.muted))),
                        ]),
                  ],
                ])),
      ],
      if (muscles.isNotEmpty && (gender == 'MALE' || gender == 'FEMALE')) ...[
        const SizedBox(height: 16),
        Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const ValueKey('starter-muscle-focus'),
              tilePadding: EdgeInsets.zero,
              title: const FitnessText('Muscle focus',
                  style: TextStyle(fontSize: 13, color: FitnessTheme.muted)),
              children: [
                SizedBox(
                    height: 165,
                    child: Row(children: [
                      for (final back in [false, true])
                        Expanded(
                            child: GraphiteMuscleFigure(
                                female: gender == 'FEMALE',
                                back: back,
                                primary: muscles,
                                secondary: const {})),
                    ]))
              ],
            )),
      ],
    ]);
  }
}
