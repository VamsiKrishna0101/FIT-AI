import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

/// Real public exercise samples. Locked exercise details stay on the server.
class StarterMusclePreview extends StatelessWidget {
  final Map<String, dynamic> preview;
  const StarterMusclePreview({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final groups = (preview['muscleGroups'] as List).whereType<Map>().toList();
    final samples = groups
        .where((group) => (group['exercises'] as List? ?? []).isNotEmpty)
        .toList();
    final hidden = groups
        .where((group) => (group['exercises'] as List? ?? []).isEmpty)
        .toList();
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final first = preview['firstWorkout'] as Map?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = days.where((day) => day['restDay'] != true).length;
    final exerciseCount = groups.fold<int>(
        0,
        (total, group) =>
            total + ((group['exerciseCount'] as num?)?.toInt() ?? 0));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 16, runSpacing: 6, children: [
        FitnessText('{count} training days',
            values: {'count': count},
            style: const TextStyle(fontSize: 13, color: FitnessTheme.silver)),
        FitnessText('{count} exercises',
            values: {'count': exerciseCount},
            style: const TextStyle(fontSize: 13, color: FitnessTheme.muted)),
      ]),
      const SizedBox(height: 8),
      if (first?['date'] is String)
        FitnessText('Starts {date}',
            values: {
              'date': DateFormat.MMMd(locale)
                  .format(DateTime.parse(first!['date'] as String)),
            },
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
            color: FitnessTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF303030))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var index = 0; index < samples.length; index++) ...[
            if (index > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1, color: Color(0xFF353535))),
            _ExerciseSample(group: samples[index]),
          ],
          if (hidden.isNotEmpty ||
              samples.any((group) => (group['lockedCount'] as num? ?? 0) > 0))
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: Color(0xFF353535)),
                    const SizedBox(height: 16),
                    if (hidden.isNotEmpty) ...[
                      Wrap(spacing: 14, runSpacing: 8, children: [
                        for (final group in hidden)
                          FitnessText(_title(group['region'].toString()),
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.silver)),
                      ]),
                      const SizedBox(height: 16),
                    ],
                    const _LockedPreview(),
                    const SizedBox(height: 10),
                    const FitnessText('Unlock every exercise with your trial.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: FitnessTheme.muted)),
                  ]),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      ExpansionTile(
        key: const ValueKey('starter-week-schedule'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: const FitnessText('See your weekly schedule',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        children: [
          for (final day in days)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 98,
                          child: Text(
                              DateFormat('EEE, d MMM', locale).format(
                                  DateTime.parse(day['date'] as String)),
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                      Expanded(
                          child: FitnessText(
                              day['restDay'] == true
                                  ? 'Rest day'
                                  : day['name'].toString(),
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4))),
                    ])),
        ],
      ),
      if (preview['source'] == 'rules')
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(bottom: 12),
          shape: Border(),
          collapsedShape: Border(),
          title: FitnessText('How this plan was built',
              style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          children: [
            FitnessText(
                'AI planning is unavailable. This plan uses your confirmed setup and conservative training rules.',
                style: TextStyle(
                    fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
          ],
        ),
    ]);
  }
}

String _title(String value) =>
    value.isEmpty ? '' : value[0].toUpperCase() + value.substring(1);

class _ExerciseSample extends StatelessWidget {
  final Map group;
  const _ExerciseSample({required this.group});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: FitnessText(_title(group['region'].toString()),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FitnessTheme.silver))),
            const SizedBox(width: 12),
            FitnessText('{count} exercises',
                values: {'count': group['exerciseCount'] ?? 0},
                style:
                    const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          ]),
          for (final exercise
              in (group['exercises'] as List? ?? []).whereType<Map>()) ...[
            const SizedBox(height: 10),
            FitnessText(_title(exercise['name'].toString()),
                style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.2)),
            const SizedBox(height: 6),
            FitnessText('{sets} sets · {reps} reps',
                values: {
                  'sets': exercise['sets'],
                  'reps': exercise['repsMin'] == exercise['repsMax']
                      ? exercise['repsMax']
                      : '${exercise['repsMin']}–${exercise['repsMax']}',
                },
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          ],
        ]),
      );
}

class _LockedPreview extends StatelessWidget {
  const _LockedPreview();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
            child: ClipRect(
                child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final fraction in [.76, .48])
              Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: FractionallySizedBox(
                      widthFactor: fraction,
                      child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                              color:
                                  const Color(0xFF737373).withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(3))))),
          ]),
        ))),
      );
}
