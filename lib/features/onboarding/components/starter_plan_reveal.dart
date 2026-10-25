import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../train/components/exercise_muscle_map.dart';
import '../../train/components/graphite_anatomy.dart';
import '../models/equipment_copy.dart';
import '../models/equipment_models.dart';

/// The reveal uses only the server's public preview and the current owner's
/// saved profile. It never fetches, synthesizes or blurs private workout data.
class StarterPlanReveal extends StatelessWidget {
  final Map<String, dynamic> preview;
  final Map<String, dynamic>? profile;
  const StarterPlanReveal({super.key, required this.preview, this.profile});

  @override
  Widget build(BuildContext context) {
    final groups =
        (preview['muscleGroups'] as List? ?? []).whereType<Map>().toList();
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final first =
        preview['firstWorkout'] is Map ? preview['firstWorkout'] as Map : null;
    final firstExercises =
        (first?['exercises'] as List? ?? []).whereType<Map>().toList();
    final shownNames = firstExercises.map((e) => e['name']).toSet();
    final extra = <Map>[];
    for (final group in groups) {
      for (final exercise
          in (group['exercises'] as List? ?? []).whereType<Map>()) {
        if (shownNames.add(exercise['name'])) extra.add(exercise);
      }
    }
    final name =
        (profile?['name'] as String? ?? '').trim().split(RegExp(r'\s+')).first;
    final goal = switch (profile?['workingToward']) {
      'BUILD_MUSCLE' => 'Build muscle',
      'LOSE_BODY_FAT' || 'LOSE_WEIGHT' => 'Lose body fat',
      'GET_STRONGER' => 'Get stronger',
      'GET_FITTER' => 'Get fitter',
      'BUILD_CONSISTENCY' => 'Build consistency',
      _ => null,
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
    final equipment = (profile?['equipmentIds'] as List? ?? [])
        .whereType<String>()
        .where(EquipmentCatalog.byId.containsKey)
        .toList();
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
    final showBodies = gender == 'MALE' || gender == 'FEMALE';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final language = AppLanguage.values.firstWhere(
        (value) => value.locale.toLanguageTag() == locale,
        orElse: () => AppLanguage.values.firstWhere(
            (value) =>
                value.code.split('-').first ==
                Localizations.localeOf(context).languageCode,
            orElse: () => AppLanguage.uk));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText(
          name.isEmpty ? 'Your plan is ready' : '{name}, your plan is ready',
          key: const ValueKey('starter-ready-title'),
          values: {'name': name},
          style: const TextStyle(
              fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
      FitnessText(goal ?? 'Your training',
          style: const TextStyle(
              fontSize: 36,
              height: 1.12,
              letterSpacing: -1.1,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 8, children: [
        if (level != null) _ProfileDetail(level),
        if (location != null) _ProfileDetail(location),
        if (equipment.isNotEmpty)
          Text(
              equipment
                  .map((id) => EquipmentCopy.item(language, id))
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: FitnessTheme.muted)),
      ]),
      if (muscles.isNotEmpty) ...[
        if (showBodies) ...[
          const SizedBox(height: 22),
          SizedBox(
              height: 258,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final back in [false, true])
                      Expanded(
                          child: Semantics(
                              label: fitnessText(
                                  context, back ? 'Back view' : 'Front view'),
                              image: true,
                              child: GraphiteMuscleFigure(
                                  female: gender == 'FEMALE',
                                  back: back,
                                  primary: muscles,
                                  secondary: const {})))
                  ])),
        ],
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              margin: const EdgeInsets.only(top: 4),
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                  color: const Color(0xFFAE514B),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 9),
          Expanded(
              child: Wrap(
                  key: const ValueKey('starter-muscle-regions'),
                  spacing: 12,
                  runSpacing: 7,
                  children: [
                for (final region in regions.toSet())
                  FitnessText(_regionLabel(region),
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.silver)),
              ])),
        ]),
      ],
      if (days.isNotEmpty) ...[
        const SizedBox(height: 22),
        _WeekReveal(days: days, firstDate: first?['date'] as String?),
      ],
      if (first != null) ...[
        const SizedBox(height: 24),
        const FitnessText('Your first workout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _RevealSurface(
            key: const ValueKey('starter-first-workout'),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitnessText('${first['name'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 21,
                      height: 1.3,
                      letterSpacing: -.4,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 5, children: [
                if (DateTime.tryParse('${first['date']}')
                    case final DateTime date)
                  Text(DateFormat('EEE, d MMM', locale).format(date),
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                if (first['exerciseCount'] is num)
                  FitnessText('{count} exercises',
                      values: {'count': first['exerciseCount']!},
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                if ((first['estimatedMinutes'] as num? ?? 0) > 0)
                  FitnessText('{minutes} min',
                      values: {'minutes': first['estimatedMinutes']!},
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
              ]),
              for (final exercise in firstExercises)
                _ExerciseReveal(exercise: exercise),
            ])),
      ],
      if (extra.isNotEmpty) ...[
        const SizedBox(height: 24),
        const FitnessText('From your week',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _RevealSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              for (final exercise in extra) _ExerciseReveal(exercise: exercise)
            ])),
      ],
      if (preview['source'] == 'rules') ...[
        const SizedBox(height: 16),
        const ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: Border(),
            collapsedShape: Border(),
            title: FitnessText('How this plan was built',
                style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            children: [
              FitnessText(
                  'AI planning is unavailable. This plan uses your confirmed setup and conservative training rules.',
                  style: TextStyle(
                      fontSize: 12, height: 1.5, color: FitnessTheme.muted))
            ]),
      ],
    ]);
  }
}

String _regionLabel(String region) => switch (region.toLowerCase()) {
      'chest' => 'Chest',
      'back' => 'Back',
      'legs' => 'Legs',
      'shoulders' => 'Shoulders',
      'biceps' => 'Biceps',
      'triceps' => 'Triceps',
      'core' => 'Core',
      'glutes' => 'Glutes',
      'forearms' => 'Forearms',
      'quads' => 'Quads',
      'hamstrings' => 'Hamstrings',
      'calves' => 'Calves',
      'lats' => 'Lats',
      'upper_back' => 'Upper back',
      'lower_back' => 'Lower back',
      'arms' => 'Arms',
      _ => region,
    };

class _RevealSurface extends StatelessWidget {
  final Widget child;
  const _RevealSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: FitnessTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF303030))),
      child: child);
}

class _ProfileDetail extends StatelessWidget {
  final String text;
  const _ProfileDetail(this.text);
  @override
  Widget build(BuildContext context) => FitnessText(text,
      style: const TextStyle(
          fontSize: 12, height: 1.5, color: FitnessTheme.muted));
}

class _ExerciseReveal extends StatelessWidget {
  final Map exercise;
  const _ExerciseReveal({required this.exercise});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(height: 1, color: Color(0xFF353535)),
        const SizedBox(height: 14),
        FitnessText('${exercise['name'] ?? ''}',
            style: const TextStyle(
                fontSize: 16, height: 1.4, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        if (exercise['sets'] != null &&
            exercise['repsMin'] != null &&
            exercise['repsMax'] != null)
          FitnessText('{sets} sets · {reps} reps',
              values: {
                'sets': exercise['sets']!,
                'reps': exercise['repsMin'] == exercise['repsMax']
                    ? exercise['repsMax']!
                    : '${exercise['repsMin']}–${exercise['repsMax']}'
              },
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
      ]));
}

class _WeekReveal extends StatefulWidget {
  final List<Map> days;
  final String? firstDate;
  const _WeekReveal({required this.days, this.firstDate});
  @override
  State<_WeekReveal> createState() => _WeekRevealState();
}

class _WeekRevealState extends State<_WeekReveal> {
  String? _date;
  @override
  Widget build(BuildContext context) {
    final days = widget.days
        .where((d) => DateTime.tryParse('${d['date']}') != null)
        .toList();
    if (days.isEmpty) return const SizedBox.shrink();
    final selected = days
            .where((d) => d['date'] == (_date ?? widget.firstDate))
            .firstOrNull ??
        days.first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
        key: const ValueKey('starter-week-schedule'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                const FitnessText('Your week',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                FitnessText('{count} training days',
                    values: {
                      'count': days.where((d) => d['restDay'] != true).length
                    },
                    style: const TextStyle(
                        fontSize: 11, color: FitnessTheme.muted)),
              ]),
          const SizedBox(height: 12),
          _RevealSurface(
              key: const ValueKey('starter-week-card'),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                        builder:
                            (context, box) => Wrap(
                                    spacing: 5,
                                    runSpacing: 9,
                                    children: [
                                      for (final day in days)
                                        SizedBox(
                                            width: (box.maxWidth - 30) / 7,
                                            child: Semantics(
                                                button: true,
                                                selected: selected == day,
                                                label:
                                                    '${DateFormat('EEEE, d MMMM', locale).format(DateTime.parse('${day['date']}'))}, ${fitnessText(context, day['restDay'] == true ? 'Rest day' : '${day['name']}')}',
                                                child: ExcludeSemantics(
                                                    child: Material(
                                                        color: selected == day
                                                            ? const Color(
                                                                0xFFEEEEEE)
                                                            : const Color(
                                                                0xFF2A2A2A),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(9),
                                                        child: InkWell(
                                                            key: ValueKey(
                                                                'starter-day-${day['date']}'),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        9),
                                                            onTap: () => setState(
                                                                () => _date =
                                                                    '${day['date']}'),
                                                            child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            10),
                                                                child: Column(
                                                                    children: [
                                                                      Text(
                                                                          DateFormat('EEEEE', locale).format(DateTime.parse(
                                                                              '${day['date']}')),
                                                                          style: TextStyle(
                                                                              fontSize: 10,
                                                                              color: selected == day ? Colors.black54 : FitnessTheme.muted)),
                                                                      const SizedBox(
                                                                          height:
                                                                              6),
                                                                      Text(
                                                                          DateFormat.d(locale).format(DateTime.parse(
                                                                              '${day['date']}')),
                                                                          style: TextStyle(
                                                                              fontSize: 13,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: selected == day ? Colors.black : FitnessTheme.silver)),
                                                                      const SizedBox(
                                                                          height:
                                                                              7),
                                                                      Container(
                                                                          width: day['restDay'] == true
                                                                              ? 3
                                                                              : 12,
                                                                          height:
                                                                              2,
                                                                          color: selected == day
                                                                              ? Colors.black54
                                                                              : day['restDay'] == true
                                                                                  ? const Color(0xFF555555)
                                                                                  : FitnessTheme.silver),
                                                                    ]))))))),
                                    ])),
                    const SizedBox(height: 17),
                    FitnessText(
                        selected['restDay'] == true
                            ? 'Rest day'
                            : '${selected['name'] ?? ''}',
                        key: const ValueKey('starter-selected-day'),
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(
                        DateFormat('EEE, d MMM', locale)
                            .format(DateTime.parse('${selected['date']}')),
                        style: const TextStyle(
                            fontSize: 12, color: FitnessTheme.muted)),
                  ])),
        ]);
  }
}
