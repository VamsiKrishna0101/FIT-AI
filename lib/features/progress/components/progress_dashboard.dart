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
    final count = ProgressSection.values.length;
    final duration = DSMotion.duration(context, DSMotion.regular);
    return DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xFF111113),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: DSColors.border, width: .7)),
        child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(children: [
              // One raised pill glides between sections instead of each tab
              // fading its own background.
              Positioned.fill(
                  child: AnimatedAlign(
                      duration: duration,
                      curve: Curves.easeOutBack,
                      alignment: AlignmentDirectional(
                          count == 1
                              ? 0.0
                              : -1 + 2 * selected.index / (count - 1),
                          0),
                      child: FractionallySizedBox(
                          widthFactor: 1 / count,
                          heightFactor: 1,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF3C3F45),
                                        Color(0xFF2A2C31)
                                      ]),
                                  border: Border.all(
                                      color: DSColors.borderHi, width: .7),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 3)),
                                  ]))))),
              Row(children: [
                for (final section in ProgressSection.values)
                  Expanded(
                      child: Semantics(
                          selected: section == selected,
                          button: true,
                          child: InkWell(
                              key: ValueKey('progress-section-${section.name}'),
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => onChanged(section),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 11),
                                  child: AnimatedDefaultTextStyle(
                                      duration: DSMotion.duration(
                                          context, DSMotion.fast),
                                      curve: DSMotion.effects,
                                      style: TextStyle(
                                          color: section == selected
                                              ? DSColors.textPrimary
                                              : progressMuted,
                                          fontSize: 13,
                                          fontWeight: section == selected
                                              ? FontWeight.w600
                                              : FontWeight.w500),
                                      child: Text(
                                          fitnessText(context, _label(section)),
                                          textAlign: TextAlign.center)))))),
              ]),
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
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (scale <= 1.28) {
      // Pinned exercises lead the shelf; the most recent fill the rest.
      final shelf = [
        ...chosen,
        ...exercises.where((row) => !chosen.contains(row)),
      ].take(6).toList();
      return SizedBox(
          height: 92 + scale * 96,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: shelf.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _ExerciseCard(
                  exercise: shelf[i], onTap: () => onOpen(shelf[i]))));
    }
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

/// A shelf card: the exercise, its latest top value, the period change and a
/// sparkline of recent sessions in the strength hue.
class _ExerciseCard extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const _ExerciseCard({required this.exercise, required this.onTap});

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
    final change = progressNumber(exercise['change']);
    final reps = progressNumber(latest?['reps']);
    final date = exercise['latestDate'] as String?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final caption = loaded && reps != null
        ? '${progressValue(context, reps, unit: 'reps', digits: 0)} · ${fitnessText(context, 'Last session')}'
        : date != null
            ? progressDate(date, locale)
            : fitnessText(context, 'Latest');
    return SizedBox(
        width: 158,
        child: ProgressSurface(
            accent: progressStrength,
            padding: EdgeInsets.zero,
            child: InkWell(
                key: ValueKey('progress-exercise-${exercise['id']}'),
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(progressTitle(exercise['name'] as String? ?? ''),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: progressMuted)),
                          const Spacer(),
                          ProgressValueText(
                              progressValue(
                                  context, value, unit: loaded ? 'kg' : 'reps'),
                              size: 22),
                          if (loaded && change != null && change.isFinite) ...[
                            const SizedBox(height: 6),
                            ProgressChangeChip(
                                change: change,
                                label:
                                    '${change > 0 ? '+' : ''}${progressValue(context, change)}%'),
                          ],
                          if (points.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ExcludeSemantics(
                                    child: ProgressSparkline(
                                        points: points,
                                        color: progressStrength))),
                          ],
                        ])))));
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
            color: progressBody,
            icon: CupertinoIcons.resize,
            contextLabel: _bodySourceLabel(body.source),
            onTap: onBody),
      if (recovery.points.isNotEmpty)
        _TrendPreview(
            label: recovery.label,
            unit: recovery.unit,
            points: recovery.points,
            color: progressRecovery,
            icon: CupertinoIcons.moon_fill,
            average: true,
            onTap: onRecovery),
      if (nutrition.points.isNotEmpty)
        _TrendPreview(
            label: nutrition.label,
            unit: nutrition.unit,
            points: nutrition.points,
            color: progressNutrition,
            icon: Icons.restaurant_rounded,
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
        // Two columns; an odd last tile spans the row so the grid stays even.
        LayoutBuilder(builder: (context, box) {
          final half = (box.maxWidth - 12) / 2;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                  width: children.length.isOdd && i == children.length - 1
                      ? box.maxWidth
                      : half,
                  child: children[i]),
          ]);
        }),
    ]);
  }
}

class _TrendPreview extends StatelessWidget {
  final String label, unit;
  final List<ProgressPoint> points;
  final bool average;
  final String? contextLabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _TrendPreview(
      {required this.label,
      required this.unit,
      required this.points,
      required this.color,
      required this.icon,
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
        accent: color,
        padding: EdgeInsets.zero,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _IconChip(icon: icon, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(fitnessText(context, label),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: progressMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500))),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 12, color: progressMuted),
                      ]),
                      const SizedBox(height: 12),
                      ProgressValueText(
                          progressValue(context, value, unit: unit),
                          size: 24),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ProgressSparkline(
                              points: points, daily: average, color: color)),
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

/// A small tinted square holding an area's icon.
class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconChip({required this.icon, required this.color, this.size = 26});

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(size * .32)),
      child: Icon(icon, size: size * .52, color: color));
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
    const colors = {
      'training': progressTraining,
      'exercises': progressStrength,
      'muscles': progressMuscle,
      'body': progressBody,
      'nutrition': progressNutrition,
      'recovery': progressRecovery,
    };
    return Column(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        _TrendCard(
            kind: items[i].$1,
            title: items[i].$2,
            icon: items[i].$3,
            points: items[i].$4,
            summary: items[i].$5,
            color: colors[items[i].$1]!,
            onTap: () => onOpen(items[i].$1)),
      ],
    ]);
  }
}

/// One area of progress: its tinted icon, the current figure and, once there
/// are readings, a full-width chart of the period in that area's hue.
class _TrendCard extends StatelessWidget {
  final String kind, title, summary;
  final IconData icon;
  final List<ProgressPoint> points;
  final Color color;
  final VoidCallback onTap;
  const _TrendCard(
      {required this.kind,
      required this.title,
      required this.icon,
      required this.points,
      required this.summary,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recorded = points.isNotEmpty && summary.isNotEmpty;
    return ProgressSurface(
        accent: recorded ? color : null,
        padding: EdgeInsets.zero,
        child: InkWell(
            key: ValueKey('progress-trend-$kind'),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _IconChip(
                            icon: icon,
                            color: recorded ? color : progressMuted,
                            size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(fitnessText(context, title),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.2)),
                              const SizedBox(height: 3),
                              Text(
                                  recorded
                                      ? summary
                                      : fitnessText(context, 'Not recorded yet'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: recorded
                                          ? progressSilver
                                          : progressMuted)),
                            ])),
                        const SizedBox(width: 10),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 13, color: progressMuted),
                      ]),
                      if (points.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ExcludeSemantics(
                                child: ProgressSparkline(
                                    points: points,
                                    color: color,
                                    daily: ['nutrition', 'recovery']
                                        .contains(kind)))),
                      ],
                    ]))));
  }
}
