import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            color: DSColors.bgCard,
            borderRadius: BorderRadius.circular(14),
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
                                  borderRadius: BorderRadius.circular(14),
                                  color: DSColors.bgRaised,
                                  /*
// e
// c
// c1
// c2
                                  */
                                  border: Border.all(
                                      color: DSColors.borderHi, width: .7)))))),
              /* boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 3)),
                                  ]))))), */
              Row(children: [
                for (final section in ProgressSection.values)
                  Expanded(
                      child: Semantics(
                          selected: section == selected,
                          button: true,
                          child: InkWell(
                              key: ValueKey('progress-section-${section.name}'),
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (section != selected) {
                                  HapticFeedback.selectionClick();
                                  onChanged(section);
                                }
                              },
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
    ('protein', 'g', 'Protein'),
    ('calories', 'kcal', 'Calories'),
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
    final available = exercises
        .where((row) =>
            row['latest'] is Map &&
            (progressNumber((row['latest'] as Map)['reps']) ?? 0) > 0)
        .toList();
    final byId = {for (final row in available) row['id']: row};
    final chosen = <ProgressJson>[
      for (final id in pins)
        if (byId[id] != null) byId[id]!,
      ...available.where((row) => !pins.contains(row['id'])),
    ].take(3).toList();
    if (chosen.isEmpty) {
      return const ProgressSurface(
          child: ProgressEmpty('Log sets to see how your exercises improve.'));
    }
    return ProgressSurface(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < chosen.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1, indent: 16, endIndent: 16, color: DSColors.border),
            _ExerciseComparisonRow(
                exercise: chosen[i], onTap: () => onOpen(chosen[i])),
          ],
        ]));
  }
}

class _ExerciseComparisonRow extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const _ExerciseComparisonRow({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = exercise['latest'] as Map;
    final first = exercise['first'] as Map?;
    final firstDate = exercise['firstDate'] as String?;
    final latestDate = exercise['latestDate'] as String?;
    // Older cached responses have no first set. Never infer its reps from a
    // truncated load sparkline, or present that as a comparable set.
    final compare = first != null &&
        (progressNumber(first['reps']) ?? 0) > 0 &&
        firstDate != null &&
        latestDate != null &&
        firstDate != latestDate;
    final loaded = (progressNumber(latest['weight']) ?? 0) > 0 ||
        (progressNumber(first?['weight']) ?? 0) > 0;
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget reading(String label, Map set, String? date, {bool muted = false}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fitnessText(context, label),
              style: const TextStyle(
                  color: progressMuted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 5),
          Text(progressSetValue(context, set),
              style: TextStyle(
                  color: muted ? progressMuted : progressSilver,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.3,
                  height: 1.3)),
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(progressDate(date, locale),
                style: const TextStyle(
                    color: progressMuted, fontSize: 11, height: 1.4)),
          ],
        ]);
    return InkWell(
        key: ValueKey('progress-exercise-${exercise['id']}'),
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(
                        progressTitle(exercise['name'] as String? ?? ''),
                        style: const TextStyle(
                            color: progressSilver,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4))),
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: progressMuted),
              ]),
              const SizedBox(height: 4),
              Text(
                  fitnessText(
                      context,
                      loaded
                          ? 'Heaviest set per session'
                          : 'Most reps per session'),
                  style: const TextStyle(
                      color: progressMuted, fontSize: 11, height: 1.4)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, box) {
                final latestReading =
                    reading('Latest session', latest, latestDate);
                if (!compare) return latestReading;
                final firstReading =
                    reading('First session', first, firstDate, muted: true);
                if (box.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        firstReading,
                        const SizedBox(height: 14),
                        latestReading,
                      ]);
                }
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: firstReading),
                      const Padding(
                          padding: EdgeInsets.fromLTRB(8, 22, 16, 0),
                          child: Icon(CupertinoIcons.arrow_right,
                              size: 14, color: progressMuted)),
                      Expanded(child: latestReading),
                    ]);
              }),
              if (!compare) ...[
                const SizedBox(height: 12),
                Text(
                    fitnessText(
                        context,
                        (progressNumber(exercise['sessions']) ?? 1) <= 1
                            ? 'Log another session to compare.'
                            : 'Open exercise for earlier sessions.'),
                    style: const TextStyle(
                        color: progressMuted, fontSize: 12, height: 1.4)),
              ],
            ])));
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
    final habits = [
      if (recovery.points.isNotEmpty)
        _TrendPreview(
            label: recovery.label,
            unit: recovery.unit,
            points: recovery.points,
            average: true,
            dayCount: data.dayCount,
            onTap: onRecovery),
      if (nutrition.points.isNotEmpty)
        _TrendPreview(
            label: nutrition.label,
            unit: nutrition.unit,
            points: nutrition.points,
            average: true,
            dayCount: data.dayCount,
            onTap: onNutrition),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (body.points.isNotEmpty) ...[
        const ProgressHeading('Body changes'),
        _TrendPreview(
            label: body.label,
            unit: body.unit,
            points: body.points,
            contextLabel: _bodySourceLabel(body.source),
            onTap: onBody),
      ],
      if (habits.isNotEmpty) ...[
        const ProgressHeading('Supporting habits'),
        LayoutBuilder(builder: (context, box) {
          if (habits.length == 1 ||
              box.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(children: [
              for (var i = 0; i < habits.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                habits[i],
              ],
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: habits[0]),
            const SizedBox(width: 12),
            Expanded(child: habits[1]),
          ]);
        }),
      ],
    ]);
  }
}

class _TrendPreview extends StatelessWidget {
  final String label, unit;
  final List<ProgressPoint> points;
  final bool average;
  final int? dayCount;
  final String? contextLabel;
  final VoidCallback onTap;
  const _TrendPreview(
      {required this.label,
      required this.unit,
      required this.points,
      required this.onTap,
      this.contextLabel,
      this.average = false,
      this.dayCount});

  @override
  Widget build(BuildContext context) {
    final value = average
        ? points.fold<double>(0, (sum, row) => sum + row.value) / points.length
        : points.last.value;
    final count = points.map((point) => point.date).toSet().length;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final change = points.last.value - points.first.value;
    final coverage = dayCount != null && dayCount! >= count
        ? fitnessText(context, '{count} of {days} days logged', values: {
            'count': progressValue(context, count, digits: 0),
            'days': progressValue(context, dayCount, digits: 0),
          })
        : fitnessText(
            context, count == 1 ? '{count} day logged' : '{count} days logged',
            values: {'count': progressValue(context, count, digits: 0)});
    final minutes = (value * 60).round();
    final display = unit == 'h'
        ? '${progressValue(context, minutes ~/ 60, unit: 'h', digits: 0)} ${progressValue(context, minutes % 60, unit: 'min', digits: 0)}'
        : progressValue(context, value, unit: unit);
    return ProgressSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(fitnessText(context, label),
                    style: const TextStyle(
                        color: progressSilver,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right,
                size: 12, color: progressMuted),
          ]),
          const SizedBox(height: 12),
          Text(display,
              style: const TextStyle(
                  color: progressSilver,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.4)),
          const SizedBox(height: 6),
          Text(
              fitnessText(
                  context, average ? 'Recorded-day average' : 'Latest reading'),
              style: const TextStyle(
                  color: progressMuted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 4),
          Text(
              average
                  ? coverage
                  : progressDate(
                      points.last.date.toIso8601String().substring(0, 10),
                      locale),
              style: const TextStyle(
                  color: progressMuted, fontSize: 11, height: 1.4)),
          if (contextLabel != null) ...[
            const SizedBox(height: 4),
            Text(fitnessText(context, contextLabel!),
                style: const TextStyle(
                    color: progressMuted, fontSize: 11, height: 1.4)),
          ],
          if (points.length >= 2) ...[
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 30,
                child: ExcludeSemantics(
                    child: ProgressSparkline(
                        points: points, daily: average, color: progressMuted))),
            const SizedBox(height: 8),
            if (!average)
              Text(
                  fitnessText(context, '{change} since {date}', values: {
                    'change':
                        '${change > 0 ? '+' : ''}${progressValue(context, change, unit: unit)}',
                    'date': progressDate(
                        points.first.date.toIso8601String().substring(0, 10),
                        locale),
                  }),
                  style: const TextStyle(
                      color: progressMuted, fontSize: 12, height: 1.4))
            else
              Text(
                  '${progressDate(points.first.date.toIso8601String().substring(0, 10), locale)} – ${progressDate(points.last.date.toIso8601String().substring(0, 10), locale)}',
                  style: const TextStyle(
                      color: progressMuted, fontSize: 10, height: 1.4)),
          ],
        ]));
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
                                      : fitnessText(
                                          context, 'Not recorded yet'),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      letterSpacing: .6,
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
                        if (points.length >= 2)
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
