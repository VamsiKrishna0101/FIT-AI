import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

enum ProgressSection { summary, trends, history }

class ProgressSectionControl extends StatelessWidget {
  final ProgressSection selected;
  final ValueChanged<ProgressSection> onChanged;
  const ProgressSectionControl(
      {super.key, required this.selected, required this.onChanged});

  String _label(ProgressSection section) => switch (section) {
        ProgressSection.summary => 'Summary',
        ProgressSection.trends => 'Trends',
        ProgressSection.history => 'History',
      };

  @override
  Widget build(BuildContext context) {
    // Long translations stay legible at accessibility sizes.
    if (MediaQuery.textScalerOf(context).scale(13) > 17) {
      return DecoratedBox(
          decoration: BoxDecoration(
              color: DSColors.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProgressSection>(
                      key: const ValueKey('progress-section-picker'),
                      value: selected,
                      isExpanded: true,
                      dropdownColor: DSColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      items: [
                        for (final section in ProgressSection.values)
                          DropdownMenuItem(
                              value: section,
                              child: Text(fitnessText(context, _label(section)),
                                  style: const TextStyle(fontSize: 13)))
                      ],
                      onChanged: (section) {
                        if (section != null) onChanged(section);
                      }))));
    }
    return DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xFF17181B),
            borderRadius: BorderRadius.circular(15)),
        child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              for (final section in ProgressSection.values)
                Expanded(
                    child: Semantics(
                        selected: section == selected,
                        button: true,
                        child: AnimatedContainer(
                            duration: DSMotion.duration(context, DSMotion.fast),
                            curve: DSMotion.effects,
                            decoration: BoxDecoration(
                                color: section == selected
                                    ? const Color(0xFF35373C)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11)),
                            child: InkWell(
                                key: ValueKey(
                                    'progress-section-${section.name}'),
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => onChanged(section),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 12),
                                    child: Text(
                                        fitnessText(context, _label(section)),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: section == selected
                                                ? progressSilver
                                                : progressMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500))))))),
            ])));
  }
}

/// Select a single source. Measured and estimated readings never share a line.
({List<ProgressPoint> points, String unit, String label, String? source})
    progressBodyPreview(ProgressJson body) {
  final metrics = progressRows(body['metrics']);
  final recorded = metrics.where((metric) => progressRows(metric['series']).any(
      (series) => ProgressPoint.parse(progressRows(series['points']), 'value')
          .isNotEmpty));
  final metric = recorded.where((row) => row['id'] == 'weightKg').firstOrNull ??
      recorded.firstOrNull ??
      metrics.firstOrNull;
  final series = progressRows(metric?['series']);
  final measured = series.where((row) => ![
        'photo_estimate',
        'contour_estimate',
        'manual_estimate'
      ].contains(row['source']));
  final selected = measured
          .where((row) => progressRows(row['points']).isNotEmpty)
          .firstOrNull ??
      series.where((row) => progressRows(row['points']).isNotEmpty).firstOrNull;
  return (
    points: ProgressPoint.parse(progressRows(selected?['points']), 'value'),
    unit: metric?['unit'] as String? ?? 'kg',
    label: metric?['label'] as String? ?? 'Body changes',
    source: selected?['source'] as String?,
  );
}

({List<ProgressPoint> points, String unit, String label})
    progressRecoveryPreview(ProgressJson wellness) {
  final rows = progressRows(wellness['recovery']);
  for (final choice in [
    ('sleep', 'h', 'Sleep'),
    ('recovery', '/100', 'Recovery'),
    ('hrv', 'ms', 'HRV'),
    ('rhr', 'bpm', 'Resting heart rate'),
    ('steps', 'steps', 'Steps'),
    ('activeCalories', 'kcal', 'Active calories'),
  ]) {
    var selected = rows;
    if (choice.$1 == 'hrv') {
      final method = rows
          .where((row) => row['hrv'] != null && row['hrvMethod'] != null)
          .lastOrNull?['hrvMethod'];
      selected = rows.where((row) => row['hrvMethod'] == method).toList();
    }
    final points = ProgressPoint.parse(selected, choice.$1);
    if (points.isNotEmpty) {
      return (points: points, unit: choice.$2, label: choice.$3);
    }
  }
  return (points: const <ProgressPoint>[], unit: 'h', label: 'Sleep');
}

({List<ProgressPoint> points, String unit, String label})
    progressNutritionPreview(ProgressJson wellness) {
  for (final choice in [
    ('calories', 'kcal', 'Calories'),
    ('protein', 'g', 'Protein'),
    ('water', 'L', 'Water'),
    ('carbs', 'g', 'Carbs'),
    ('fat', 'g', 'Fat'),
  ]) {
    final raw =
        ProgressPoint.parse(progressRows(wellness['nutrition']), choice.$1);
    final points = choice.$1 == 'water'
        ? raw.map((p) => ProgressPoint(p.date, p.value / 1000)).toList()
        : raw;
    if (points.isNotEmpty) {
      return (points: points, unit: choice.$2, label: choice.$3);
    }
  }
  return (points: const <ProgressPoint>[], unit: 'kcal', label: 'Nutrition');
}

String? _bodySourceLabel(String? source) =>
    ['photo_estimate', 'contour_estimate'].contains(source)
        ? 'Photo estimate'
        : source == 'manual_estimate'
            ? 'Entered estimate'
            : null;

class ProgressExerciseTrends extends StatelessWidget {
  final List<ProgressJson> exercises;
  final List<String> pins;
  final ValueChanged<ProgressJson> onOpen;
  const ProgressExerciseTrends(
      {super.key,
      required this.exercises,
      this.pins = const [],
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const ProgressSurface(
          child: ProgressEmpty('Log sets to see how your exercises improve.'));
    }
    final available = {for (final row in exercises) row['id']: row};
    final chosen = <ProgressJson>[
      for (final id in pins)
        if (available[id] != null) available[id]!,
    ];
    if (chosen.isEmpty) chosen.addAll(exercises.take(3));
    return ProgressSurface(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(children: [
          for (var i = 0; i < chosen.take(3).length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0x12FFFFFF)),
            _ExerciseTrendRow(
                exercise: chosen[i], onTap: () => onOpen(chosen[i])),
          ],
        ]));
  }
}

class _ExerciseTrendRow extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const _ExerciseTrendRow({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final points =
        ProgressPoint.parse(progressRows(exercise['sparkline']), 'value');
    final latest = exercise['latest'] as Map?;
    final loaded = exercise['metric'] == 'load' ||
        (exercise['metric'] == null &&
            (progressNumber(latest?['weight']) ?? 0) > 0);
    final value = points.lastOrNull?.value ??
        progressNumber(latest?[loaded ? 'weight' : 'reps']);
    final unit = loaded ? 'kg' : 'reps';
    final change = progressNumber(exercise['change']);
    final reps = progressNumber(latest?['reps']);
    final date = exercise['latestDate'] as String?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final caption = loaded && reps != null
        ? '${progressValue(context, reps, unit: 'reps', digits: 0)} · ${fitnessText(context, 'Last session')}'
        : date != null
            ? progressDate(date, locale)
            : fitnessText(context, 'Latest');
    return InkWell(
        key: ValueKey('progress-exercise-${exercise['id']}'),
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LayoutBuilder(builder: (context, box) {
              final expanded = MediaQuery.textScalerOf(context).scale(13) > 18;
              final name = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(progressTitle(exercise['name'] as String? ?? ''),
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(caption,
                        style: const TextStyle(
                            fontSize: 11, height: 1.4, color: progressMuted)),
                  ]);
              final statistic =
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(progressValue(context, value, unit: unit),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (loaded && change != null && change.isFinite) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${change > 0 ? '+' : ''}${progressValue(context, change)}%',
                      style:
                          const TextStyle(color: progressMuted, fontSize: 11)),
                ],
              ]);
              final chart = SizedBox(
                  width: expanded ? 90 : 62,
                  height: 30,
                  child: ExcludeSemantics(
                      child: ProgressSparkline(
                          points: points, color: progressBlue)));
              if (expanded) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      name,
                      const SizedBox(height: 12),
                      Row(children: [
                        if (points.isNotEmpty) chart,
                        const Spacer(),
                        Flexible(child: statistic),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 13, color: progressMuted),
                      ])
                    ]);
              }
              return Row(children: [
                Expanded(child: name),
                if (points.isNotEmpty && box.maxWidth >= 270) ...[
                  const SizedBox(width: 12),
                  chart,
                ],
                const SizedBox(width: 14),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: statistic),
                const SizedBox(width: 9),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: progressMuted),
              ]);
            })));
  }
}

class ProgressBeyondTraining extends StatelessWidget {
  final ProgressOverview data;
  final VoidCallback onBody, onRecovery, onNutrition;
  const ProgressBeyondTraining(
      {super.key,
      required this.data,
      required this.onBody,
      required this.onRecovery,
      required this.onNutrition});

  @override
  Widget build(BuildContext context) {
    final body = progressBodyPreview(data.body);
    final recovery = progressRecoveryPreview(data.wellness);
    final nutrition = progressNutritionPreview(data.wellness);
    final children = [
      if (body.points.isNotEmpty)
        _TrendPreview(
            label: body.label,
            unit: body.unit,
            points: body.points,
            contextLabel: _bodySourceLabel(body.source),
            onTap: onBody),
      if (recovery.points.isNotEmpty)
        _TrendPreview(
            label: recovery.label,
            unit: recovery.unit,
            points: recovery.points,
            average: true,
            onTap: onRecovery),
      if (recovery.points.isEmpty && nutrition.points.isNotEmpty)
        _TrendPreview(
            label: nutrition.label,
            unit: nutrition.unit,
            points: nutrition.points,
            average: true,
            onTap: onNutrition),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgressHeading('Beyond training'),
      if (MediaQuery.textScalerOf(context).scale(14) > 19)
        Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ]
        ])
      else
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ]
        ]),
    ]);
  }
}

class _TrendPreview extends StatelessWidget {
  final String label, unit;
  final List<ProgressPoint> points;
  final bool average;
  final String? contextLabel;
  final VoidCallback onTap;
  const _TrendPreview(
      {required this.label,
      required this.unit,
      required this.points,
      required this.onTap,
      this.contextLabel,
      this.average = false});
  @override
  Widget build(BuildContext context) {
    final value = average
        ? points.fold<double>(0, (sum, row) => sum + row.value) / points.length
        : points.last.value;
    final change = points.last.value - points.first.value;
    return ProgressSurface(
        padding: EdgeInsets.zero,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(fitnessText(context, label),
                                style: const TextStyle(
                                    color: progressMuted, fontSize: 12))),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 12, color: progressMuted),
                      ]),
                      const SizedBox(height: 10),
                      ProgressValueText(
                          progressValue(context, value, unit: unit),
                          size: 23),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: ProgressSparkline(
                              points: points,
                              daily: average,
                              color: progressBlue)),
                      const SizedBox(height: 10),
                      Text(
                          contextLabel != null
                              ? fitnessText(context, contextLabel!)
                              : average
                                  ? fitnessText(context, 'Recorded-day average')
                                  : points.length < 2
                                      ? fitnessText(context, 'Latest reading')
                                      : '${change > 0 ? '+' : ''}${progressValue(context, change, unit: unit)}',
                          style: const TextStyle(
                              fontSize: 11, color: progressMuted)),
                    ]))));
  }
}

class ProgressTrendsList extends StatelessWidget {
  final ProgressOverview data;
  final ValueChanged<String> onOpen;
  const ProgressTrendsList(
      {super.key, required this.data, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final body = progressBodyPreview(data.body);
    final nutrition = progressNutritionPreview(data.wellness);
    final recovery = progressRecoveryPreview(data.wellness);
    final exercises = data.exercises;
    final exercise = exercises.firstOrNull;
    final musclePoints = ProgressPoint.parse(data.weeks, 'sets');
    final items = [
      (
        'training',
        'Training',
        CupertinoIcons.sportscourt,
        ProgressPoint.parse(data.weeks, 'workouts'),
        '${progressValue(context, progressNumber(data.summary['workouts']), digits: 0)} ${fitnessText(context, 'Workouts')}'
      ),
      (
        'exercises',
        'Exercises',
        CupertinoIcons.chart_bar,
        ProgressPoint.parse(progressRows(exercise?['sparkline']), 'value'),
        '${exercises.length} ${fitnessText(context, 'Exercises')}'
      ),
      (
        'muscles',
        'Muscles',
        CupertinoIcons.person,
        musclePoints,
        '${progressValue(context, progressNumber(data.summary['sets']), digits: 0)} ${fitnessText(context, 'Logged sets')}'
      ),
      (
        'body',
        'Body changes',
        CupertinoIcons.resize,
        body.points,
        body.points.isEmpty
            ? ''
            : '${progressValue(context, body.points.last.value, unit: body.unit)}'
                '${_bodySourceLabel(body.source) == null ? '' : ' · ${fitnessText(context, _bodySourceLabel(body.source)!)}'}'
      ),
      (
        'nutrition',
        'Nutrition',
        Icons.restaurant_outlined,
        nutrition.points,
        nutrition.points.isEmpty
            ? ''
            : progressValue(
                context,
                nutrition.points
                        .fold<double>(0, (sum, row) => sum + row.value) /
                    nutrition.points.length,
                unit: nutrition.unit,
                digits: nutrition.unit == 'L' ? 1 : 0)
      ),
      (
        'recovery',
        'Recovery',
        CupertinoIcons.moon,
        recovery.points,
        recovery.points.isEmpty
            ? ''
            : progressValue(
                context,
                recovery.points.fold<double>(0, (sum, row) => sum + row.value) /
                    recovery.points.length,
                unit: recovery.unit)
      ),
    ];
    return ProgressSurface(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0x12FFFFFF), indent: 46),
            InkWell(
                key: ValueKey('progress-trend-${items[i].$1}'),
                onTap: () => onOpen(items[i].$1),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(children: [
                      Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: const Color(0xFF2A2C30),
                              borderRadius: BorderRadius.circular(11)),
                          child: Icon(items[i].$3,
                              size: 18, color: progressSilver)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(fitnessText(context, items[i].$2),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                                items[i].$4.isEmpty || items[i].$5.isEmpty
                                    ? fitnessText(context, 'Not recorded yet')
                                    : items[i].$5,
                                style: const TextStyle(
                                    fontSize: 11, color: progressMuted)),
                          ])),
                      if (items[i].$4.isNotEmpty &&
                          MediaQuery.textScalerOf(context).scale(14) < 20) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                            width: 64,
                            height: 30,
                            child: ExcludeSemantics(
                                child: ProgressSparkline(
                                    points: items[i].$4,
                                    color: progressBlue,
                                    daily: ['nutrition', 'recovery']
                                        .contains(items[i].$1)))),
                      ],
                      const SizedBox(width: 10),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 13, color: progressMuted),
                    ]))),
          ],
        ]));
  }
}
