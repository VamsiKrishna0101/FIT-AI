import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_chart_data.dart';
import '../models/progress_models.dart';
import 'body_progress_content.dart' show progressSourceLabels;
import 'progress_chart.dart';
import 'progress_dashboard.dart' show progressBodyPreview;
import 'progress_surface.dart';
import 'progress_visual_charts.dart';

class ProgressAttendanceCard extends StatelessWidget {
  final ProgressOverview data;
  final List<DateTime> days;
  final VoidCallback onOpen;
  const ProgressAttendanceCard(
      {super.key,
      required this.data,
      required this.days,
      required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = {for (final row in data.activity) row['date']: row};
    final last = DateTime.tryParse(
        (data.json['range'] as Map?)?['end'] as String? ?? '');
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    return ProgressSurface(
        hero: true,
        onTap: onOpen,
        padding: const EdgeInsets.all(12),
        key: const ValueKey('progress-open-activity'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      progressValue(
                          context,
                          progressNumber(data.summary['trainingDays']) ??
                              data.activity.length,
                          digits: 0),
                      style: const TextStyle(
                          color: progressSilver,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          letterSpacing: -.8)),
                  const SizedBox(height: 4),
                  Text(fitnessText(context, 'Days trained'),
                      style:
                          const TextStyle(color: progressMuted, fontSize: 11)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  progressValue(
                      context, progressNumber(data.summary['workouts']) ?? 0,
                      digits: 0),
                  style: const TextStyle(
                      color: progressSilver,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 1.1)),
              const SizedBox(height: 4),
              Text(fitnessText(context, 'Workouts'),
                  style: const TextStyle(color: progressMuted, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(
              height: 44 + 16 * scale,
              child: LayoutBuilder(
                  builder: (context, box) => ListView.builder(
                      key: ValueKey(
                          'progress-attendance-days-${days.firstOrNull}-${days.lastOrNull}'),
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      itemExtent: math.max(42,
                          box.maxWidth / math.max(1, math.min(7, days.length))),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[days.length - 1 - index];
                        final row = rows[CacheScope.todayKey(day)];
                        final active = row != null &&
                            ((progressNumber(row['sets']) ?? 0) > 0 ||
                                row['completed'] == true);
                        final future = last != null && day.isAfter(last);
                        final label =
                            '${DateFormat('EEE d MMM', locale).format(day)} · ${fitnessText(context, future ? 'Upcoming' : active ? 'Trained' : 'No activity')}';
                        return Semantics(
                            label: label,
                            child: Tooltip(
                                message: label,
                                child: ExcludeSemantics(
                                    child: Column(children: [
                                  Text(DateFormat.EEEEE(locale).format(day),
                                      style: const TextStyle(
                                          color: progressMuted, fontSize: 10)),
                                  const SizedBox(height: 8),
                                  Container(
                                      width: 27,
                                      height: 27,
                                      key: ValueKey(
                                          'progress-attendance-${CacheScope.todayKey(day)}'),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: active
                                              ? Colors.white
                                              : DSColors.bgRaised,
                                          border: future
                                              ? Border.all(
                                                  color: DSColors.border)
                                              : null),
                                      child: Center(
                                          child: active
                                              ? const Icon(
                                                  CupertinoIcons.check_mark,
                                                  color: DSColors.bg,
                                                  size: 13)
                                              : Text('${day.day}',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: future
                                                          ? DSColors.muted
                                                              .withValues(
                                                                  alpha: .45)
                                                          : progressMuted)))),
                                ]))));
                      }))),
        ]));
  }
}

class ProgressMuscleChartCard extends StatelessWidget {
  final List<ProgressJson> muscles;
  final ValueChanged<ProgressJson> onMuscle;
  const ProgressMuscleChartCard(
      {super.key, required this.muscles, required this.onMuscle});
  @override
  Widget build(BuildContext context) {
    final ordered = [...muscles]..sort((a, b) =>
        (progressNumber(b['directSets']) ?? 0)
            .compareTo(progressNumber(a['directSets']) ?? 0));
    return ProgressSurface(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fitnessText(context, 'Logged sets'),
              style: const TextStyle(fontSize: 12, color: progressMuted)),
          const SizedBox(height: 16),
          if (ordered.isEmpty)
            const ProgressEmpty('No sets in this period')
          else
            ProgressColumnChart(
                color: progressMuscle,
                minBarWidth: 80,
                bars: [
                  for (final muscle in ordered)
                    ProgressVisualBar(
                        progressMuscleLabel(context, muscle),
                        progressNumber(muscle['directSets']),
                        '${progressMuscleLabel(context, muscle)} · ${progressValue(context, progressNumber(muscle['directSets']), unit: 'sets', digits: 0)}')
                ],
                onSelected: (i) => onMuscle(ordered[i])),
        ]));
  }
}

class ProgressExerciseChartShelf extends StatelessWidget {
  final List<ProgressJson> exercises;
  final List<String> pins;
  final ValueChanged<ProgressJson> onOpen;
  const ProgressExerciseChartShelf(
      {super.key,
      required this.exercises,
      required this.onOpen,
      this.pins = const []});
  @override
  Widget build(BuildContext context) {
    final available = exercises.where((row) => row['latest'] is Map).toList();
    final byId = {for (final row in available) row['id']: row};
    final rows = [
      for (final id in pins)
        if (byId[id] != null) byId[id]!,
      ...available.where((row) => !pins.contains(row['id']))
    ].take(6).toList();
    if (rows.isEmpty) {
      return const ProgressSurface(
          padding: EdgeInsets.all(12),
          child: ProgressEmpty('No exercises in this period'));
    }
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    Widget card(ProgressJson row) {
      final latest = row['latest'] as Map;
      final points =
          ProgressPoint.parse(progressRows(row['sparkline']), 'value');
      final loaded = row['metric'] == 'load' ||
          (progressNumber(latest['weight']) ?? 0) > 0;
      final value = points.lastOrNull?.value ??
          progressNumber(latest[loaded ? 'weight' : 'reps']);
      final stats = [
        ('Sets', progressNumber(row['loggedSets'])),
        ('Reps', progressNumber(row['totalReps'])),
        ('Volume', progressNumber(row['volume'])),
      ];
      return ProgressSurface(
          padding: const EdgeInsets.all(12),
          key: ValueKey('progress-exercise-${row['id']}'),
          onTap: () => onOpen(row),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row['name'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: progressSilver,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                    progressValue(context, value, unit: loaded ? 'kg' : 'reps'),
                    style: const TextStyle(
                        color: progressSilver,
                        fontSize: 22,
                        height: 1.15,
                        letterSpacing: -.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: points.isEmpty
                        ? const SizedBox.shrink()
                        : ExcludeSemantics(
                            child: ProgressSparkline(
                                points: points, color: progressStrength))),
                const SizedBox(height: 10),
                if (large) ...[
                  for (final item in stats)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(
                              child: Text(fitnessText(context, item.$1),
                                  style: const TextStyle(
                                      fontSize: 11, color: progressMuted))),
                          Text(progressShortValue(context, item.$2),
                              style: const TextStyle(
                                  fontSize: 13, color: progressSilver)),
                        ])),
                ] else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final item in stats)
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(progressShortValue(context, item.$2),
                                style: const TextStyle(
                                    color: progressSilver,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(fitnessText(context, item.$1),
                                style: const TextStyle(
                                    color: progressMuted, fontSize: 9)),
                          ])),
                  ]),
                if (row['volume'] != null)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Text('kg·reps',
                          style: TextStyle(fontSize: 9, color: progressMuted))),
              ]));
    }

    if (large) {
      return Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          card(rows[i]),
        ],
      ]);
    }
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            SizedBox(width: 200, child: card(rows[i])),
          ]
        ])));
  }
}

class ProgressBodyChartCard extends StatefulWidget {
  final ProgressJson body;
  final VoidCallback onOpen;
  const ProgressBodyChartCard(
      {super.key, required this.body, required this.onOpen});
  @override
  State<ProgressBodyChartCard> createState() => _ProgressBodyChartCardState();
}

class _ProgressBodyChartCardState extends State<ProgressBodyChartCard> {
  String _group = 'weightKg';
  String? _measurement;
  @override
  Widget build(BuildContext context) {
    final metrics = progressRows(widget.body['metrics']);
    final measurements = metrics
        .where((m) => !['weightKg', 'heightCm'].contains(m['id']))
        .toList();
    if (!measurements.any((m) => m['id'] == _measurement)) {
      _measurement = measurements.firstOrNull?['id'] as String?;
    }
    final id = _group == 'measurements' ? _measurement : _group;
    final metric = metrics.where((m) => m['id'] == id).firstOrNull;
    final preview = progressBodyPreview({
      'metrics': [if (metric != null) metric]
    });
    final baseline = _group == 'heightCm'
        ? progressNumber(widget.body['profileHeight'])
        : _group == 'weightKg'
            ? progressNumber(widget.body['profileBaseline'])
            : null;
    return ProgressSurface(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressMetricPicker(
              choices: const {
                'weightKg': 'Weight',
                'heightCm': 'Height',
                'measurements': 'Measurements'
              },
              selected: _group,
              onChanged: (value) => setState(() => _group = value)),
          if (_group == 'measurements' && measurements.isNotEmpty)
            DropdownButton<String>(
                value: _measurement,
                isExpanded: true,
                itemHeight: null,
                dropdownColor: DSColors.bgRaised,
                underline: const SizedBox.shrink(),
                items: [
                  for (final m in measurements)
                    DropdownMenuItem(
                        value: m['id'] as String,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                                fitnessText(
                                    context, m['label'] as String? ?? ''),
                                style: const TextStyle(fontSize: 12))))
                ],
                onChanged: (value) => setState(() => _measurement = value)),
          const SizedBox(height: 12),
          if (preview.points.isNotEmpty) ...[
            if (preview.source != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                      fitnessText(
                          context,
                          progressSourceLabels[preview.source] ??
                              preview.source!),
                      style:
                          const TextStyle(fontSize: 10, color: progressMuted))),
            ProgressChart(
                points: preview.points,
                unit: preview.unit,
                color: progressBody,
                compactHeader: true,
                height: 76,
                headlineSize: 24),
          ] else if (baseline != null) ...[
            Text(
                progressValue(context, baseline,
                    unit: _group == 'heightCm' ? 'cm' : 'kg'),
                style: const TextStyle(
                    color: progressSilver,
                    fontSize: 28,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(fitnessText(context, 'Profile baseline'),
                style: const TextStyle(color: progressMuted, fontSize: 11)),
          ] else ...[
            const ProgressEmpty('No readings in this period'),
            TextButton(
                onPressed: widget.onOpen,
                child: Text(fitnessText(context, 'Add a reading'))),
          ],
        ]));
  }
}

class ProgressNutritionDonutCard extends StatefulWidget {
  final ProgressJson wellness;
  const ProgressNutritionDonutCard({super.key, required this.wellness});
  @override
  State<ProgressNutritionDonutCard> createState() =>
      _ProgressNutritionDonutCardState();
}

class _ProgressNutritionDonutCardState
    extends State<ProgressNutritionDonutCard> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final macros =
        ProgressMacros.fromRows(progressRows(widget.wellness['nutrition']));
    const names = ['Protein', 'Carbs', 'Fat'];
    final selected = _selected;
    final centreValue = selected == null
        ? progressShortValue(context, macros.days == 0 ? null : macros.total)
        : macros.total > 0
            ? '${progressValue(context, macros.calories[selected] / macros.total * 100, digits: 0)}%'
            : '0%';
    final centreLabel =
        fitnessText(context, selected == null ? 'Macro kcal' : names[selected]);
    final ring = SizedBox(
        width: 148,
        height: 148,
        child: GestureDetector(
            key: const ValueKey('progress-macro-donut'),
            onTapUp: (details) {
              if (macros.total <= 0) return;
              final point = details.localPosition - const Offset(74, 74);
              if (point.distance < 47 || point.distance > 74) return;
              final angle = (math.atan2(point.dy, point.dx) + math.pi / 2) %
                  (2 * math.pi);
              var cumulative = 0.0;
              for (var i = 0; i < 3; i++) {
                cumulative += macros.calories[i] / macros.total * math.pi * 2;
                if (angle <= cumulative) {
                  setState(() => _selected = i);
                  break;
                }
              }
            },
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                  child: MotionProgress(
                      dataKey: macros.grams.join(','),
                      builder: (context, progress) => CustomPaint(
                          painter: ProgressDonutPainter(
                              macros.calories, progress, selected)))),
              SizedBox(
                  width: 88,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(centreValue,
                            key: const ValueKey('progress-macro-centre-value'),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                                color: progressSilver,
                                fontSize: 24,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.5))),
                    const SizedBox(height: 5),
                    Text(centreLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: progressMuted, fontSize: 9, height: 1.25)),
                  ])),
            ])));
    final legend = Column(children: [
      for (var i = 0; i < 3; i++)
        Semantics(
            button: true,
            selected: selected == i,
            label:
                '${fitnessText(context, names[i])} · ${progressValue(context, macros.grams[i], unit: 'g')}',
            child: InkWell(
                key: ValueKey('progress-macro-${names[i]}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _selected = selected == i ? null : i),
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(children: [
                      Container(
                          width: 4,
                          height: 26,
                          decoration: BoxDecoration(
                              color: progressMacroColors[i],
                              borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(fitnessText(context, names[i]),
                                style: const TextStyle(
                                    color: progressSilver,
                                    fontSize: 11,
                                    height: 1.3)),
                            Text(
                                progressValue(context,
                                    macros.days == 0 ? null : macros.grams[i],
                                    unit: 'g'),
                                style: const TextStyle(
                                    color: progressMuted,
                                    fontSize: 10,
                                    height: 1.3)),
                          ])),
                      if (macros.total > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                            '${progressValue(context, macros.calories[i] / macros.total * 100, digits: 0)}%',
                            style: TextStyle(
                                color: progressMacroColors[i],
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ]))))
    ]);
    return ProgressSurface(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (selected != null)
              IconButton(
                  key: const ValueKey('progress-macro-reset'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => setState(() => _selected = null),
                  icon: const Icon(CupertinoIcons.chevron_left,
                      size: 18, color: progressSilver)),
            Expanded(
                child: Text(fitnessText(context, 'Macro split'),
                    style:
                        const TextStyle(fontSize: 11, color: progressMuted))),
            Text(
                fitnessText(context, '{count} days',
                    values: {'count': macros.days}),
                style: const TextStyle(fontSize: 10, color: progressMuted)),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, box) {
            if (box.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(children: [Center(child: ring), legend]);
            }
            return Row(children: [
              ring,
              const SizedBox(width: 12),
              Expanded(child: legend)
            ]);
          }),
        ]));
  }
}

class ProgressDailyTrendsCard extends StatefulWidget {
  final ProgressOverview data;
  final List<DateTime> days;
  const ProgressDailyTrendsCard(
      {super.key, required this.data, required this.days});
  @override
  State<ProgressDailyTrendsCard> createState() =>
      _ProgressDailyTrendsCardState();
}

class _ProgressDailyTrendsCardState extends State<ProgressDailyTrendsCard> {
  String _metric = 'calories';
  int? _selected;
  @override
  void didUpdateWidget(ProgressDailyTrendsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.json['range'] != widget.data.json['range']) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = progressRows(
        widget.data.wellness[_metric == 'sleep' ? 'sleep' : 'nutrition']);
    final bars = progressDailyBars(widget.days, rows, _metric);
    final latest = bars.lastIndexWhere((bar) => bar.value != null);
    final selected = bars.isEmpty
        ? null
        : (_selected ?? math.max(0, latest)).clamp(0, bars.length - 1);
    final value = selected == null ? null : bars[selected].value;
    final unit = _metric == 'sleep'
        ? 'h'
        : _metric == 'protein'
            ? 'g'
            : 'kcal';
    String display(double? v) {
      if (v == null) return '—';
      if (_metric != 'sleep') return progressValue(context, v, unit: unit);
      final minutes = (v * 60).round();
      return '${progressValue(context, minutes ~/ 60, unit: 'h', digits: 0)} ${progressValue(context, minutes % 60, unit: 'min', digits: 0)}';
    }

    return ProgressSurface(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressMetricPicker(
              choices: const {
                'calories': 'Calories',
                'protein': 'Protein',
                'sleep': 'Sleep'
              },
              selected: _metric,
              onChanged: (value) => setState(() {
                    _metric = value;
                    _selected = null;
                  })),
          const SizedBox(height: 8),
          Text(display(value),
              key: const ValueKey('progress-daily-selected-value'),
              style: const TextStyle(
                  color: progressSilver,
                  fontSize: 22,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          if (selected != null)
            Text(
                '${widget.days.length > 14 ? '${fitnessText(context, 'Weekly average')} · ' : ''}${DateFormat('EEE d MMM', locale).format(bars[selected].date)}',
                style: const TextStyle(
                    color: progressMuted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 10),
          ProgressColumnChart(
              color: _metric == 'sleep' ? progressMuscle : progressNutrition,
              selected: selected,
              onSelected: (index) => setState(() => _selected = index),
              bars: [
                for (final bar in bars)
                  ProgressVisualBar(
                      widget.days.length <= 7
                          ? DateFormat.EEEEE(locale).format(bar.date)
                          : DateFormat.MMMd(locale).format(bar.date),
                      bar.value,
                      '${DateFormat.yMMMd(locale).format(bar.date)} · ${display(bar.value)}')
              ]),
        ]));
  }
}
