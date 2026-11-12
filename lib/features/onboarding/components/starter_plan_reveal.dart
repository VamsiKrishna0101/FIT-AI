import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../train/components/exercise_thumbnail.dart';
import '../../train/models/workout_exercise_models.dart';
import '../../train/views/exercise_detail_screen.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

class StarterPlanReveal extends StatelessWidget {
  final Map<String, dynamic> preview;
  final Map<String, dynamic>? profile;
  final bool locked;
  const StarterPlanReveal(
      {super.key, required this.preview, this.profile, this.locked = true});
  String _day(BuildContext context, Map day) {
    final date = DateTime.tryParse(day['date']?.toString() ?? '');
    return date == null
        ? ''
        : DateFormat.E(Localizations.localeOf(context).toLanguageTag())
            .format(date);
  }

  Widget _row(BuildContext context, Map day) => Padding(
      key: ValueKey('starter-day-${day['date']}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(
            width: 48,
            child: Text(_day(context, day),
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted))),
        Expanded(
            child: FitnessText(
                day['restDay'] == true
                    ? 'Rest day'
                    : day['name']?.toString() ?? 'Workout',
                style: const TextStyle(
                    fontSize: 14, height: 1.4, fontWeight: FontWeight.w500))),
        if (day['restDay'] != true && day['estimatedMinutes'] != null) ...[
          const SizedBox(width: 10),
          FitnessText('{minutes} min',
              values: {'minutes': day['estimatedMinutes']},
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ],
      ]));
  Widget _exercise(BuildContext context, Map sample) {
    final raw = sample['exercise'];
    final exercise = WorkoutExerciseModel.fromJson({
      'bodyPart': '',
      'target': '',
      'equipment': '',
      'difficulty': '',
      if (raw is Map) ...Map<String, dynamic>.from(raw),
      'id': sample['exerciseId'] ?? (raw is Map ? raw['id'] : null) ?? '',
      'name': sample['name'] ?? (raw is Map ? raw['name'] : null) ?? '',
    });
    final gender = switch (profile?['gender']) {
      'FEMALE' => 'female',
      'MALE' => 'male',
      _ => null,
    };
    final reps = sample['repsMin'] == sample['repsMax']
        ? sample['repsMin'].toString()
        : '${sample['repsMin']}–${sample['repsMax']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF171719),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: ValueKey('starter-exercise-${exercise.id}'),
          borderRadius: BorderRadius.circular(22),
          onTap: exercise.id.isEmpty
              ? null
              : () => Navigator.of(context).push(AppPageRoute<void>(
                  page: ExerciseDetailView(
                      exercise: exercise,
                      mediaGender: gender,
                      loadDetail: raw is! Map))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              ExerciseThumbnail(exercise: exercise, size: 88),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(exercise.name,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    FitnessText('{sets} sets · {reps} reps',
                        values: {'sets': sample['sets'] ?? '', 'reps': reps},
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: FitnessTheme.muted)),
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: FitnessTheme.muted),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final training = days.where((day) => day['restDay'] != true).toList();
    final first =
        preview['firstWorkout'] is Map ? preview['firstWorkout'] as Map : null;
    final samples = (first?['exercises'] as List? ?? []).whereType<Map>();
    final goal = switch (profile?['workingToward']) {
      'BUILD_MUSCLE' => 'Build muscle',
      'LOSE_BODY_FAT' || 'LOSE_WEIGHT' => 'Lose body fat',
      'GET_STRONGER' => 'Get stronger',
      'GET_FITTER' => 'Get fitter',
      _ => 'Your training',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FitnessText('Your plan is ready',
          key: ValueKey('starter-ready-title'),
          style: TextStyle(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -.8)),
      const SizedBox(height: 10),
      Text(
          [
            fitnessText(context, goal),
            fitnessText(context, '{count} training days',
                values: {'count': training.length})
          ].join(' · '),
          style: const TextStyle(
              fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
      if (preview['adaptationNote'] is String &&
          (preview['adaptationNote'] as String).trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
            key: const ValueKey('starter-adaptation-note'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFF171719),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF28292C), width: .8)),
            child: Text(preview['adaptationNote'] as String,
                style: const TextStyle(
                    fontSize: 12, height: 1.4, color: FitnessTheme.silver))),
      ],
      const SizedBox(height: 28),
      if (samples.isNotEmpty) ...[
        const FitnessText('Your first workout',
            style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 8),
        FitnessText(first?['name']?.toString() ?? 'Workout',
            style: const TextStyle(
                fontSize: 22, height: 1.3, fontWeight: FontWeight.w500)),
        const SizedBox(height: 18),
        for (final sample in samples) _exercise(context, sample),
        const SizedBox(height: 20),
      ],
      const FitnessText('Your week',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Container(
          key: const ValueKey('starter-week-schedule'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFF171719),
              borderRadius: BorderRadius.circular(22)),
          child: Column(children: [
            for (final day in training.take(3)) _row(context, day)
          ])),
      Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
              key: const ValueKey('starter-full-week'),
              onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  useSafeArea: true,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF171719),
                  builder: (context) => ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .8),
                      child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          children: [
                            const FitnessText('Your recommended week',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            for (final day in days) _row(context, day),
                          ]))),
              child: const FitnessText('View full week',
                  style: TextStyle(fontSize: 12, color: FitnessTheme.silver)))),
    ]);
  }
}
