import '../../../core/components/motion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

class ProgressTrainingSummary extends StatelessWidget {
  final ProgressJson summary;
  final String? rangeLabel;
  const ProgressTrainingSummary(
      {super.key, required this.summary, this.rangeLabel});

  @override
  Widget build(BuildContext context) => ProgressSurface(
      accent: progressBlue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fitnessText(context, 'Your training'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        if (rangeLabel != null) ...[
          const SizedBox(height: 5),
          Text(rangeLabel!,
              style: const TextStyle(fontSize: 12, color: progressMuted)),
        ],
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final item in [
            ('workouts', 'Workouts', progressSilver),
            ('sets', 'Logged sets', progressSilver),
            ('records', 'New records', progressAmber),
          ])
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      progressValue(
                          context, progressNumber(summary[item.$1]) ?? 0,
                          digits: 0),
                      style: TextStyle(
                          fontSize: 34,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w600,
                          color: item.$1 == 'records' && summary['records'] == 0
                              ? progressSilver
                              : item.$3)),
                  const SizedBox(height: 4),
                  Text(fitnessText(context, item.$2),
                      style:
                          const TextStyle(fontSize: 12, color: progressMuted)),
                ])),
        ]),
        if (summary['setsChange'] is num) ...[
          const SizedBox(height: 14),
          Text(
              '${fitnessText(context, 'Logged sets')} · '
              '${(summary['setsChange'] as num) > 0 ? '+' : ''}'
              '${progressValue(context, summary['setsChange'] as num)}% · '
              '${fitnessText(context, 'Previous period')}',
              style: const TextStyle(fontSize: 12, color: progressMuted)),
        ],
      ]));
}

class ProgressActivity extends StatefulWidget {
  final List<ProgressJson> weeks;
  final List<ProgressJson> activity;
  final String? endDate;
  const ProgressActivity(
      {super.key, required this.weeks, required this.activity, this.endDate});
  @override
  State<ProgressActivity> createState() => _ProgressActivityState();
}

class _ProgressActivityState extends State<ProgressActivity> {
  String _metric = 'workouts';
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime.tryParse(widget.endDate ?? '') ??
        DateTime.parse(CacheScope.todayKey());
    final start = today.subtract(Duration(days: 28 + today.weekday - 1));
    final activity = {
      for (final row in widget.activity) row['date'] as String: row
    };
    final activeWeeks =
        widget.weeks.where((row) => (row[_metric] as num? ?? 0) > 0).length;
    return ProgressSurface(
        accent: progressBlue,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressChoices(
              choices: const {'workouts': 'Workouts', 'sets': 'Logged sets'},
              color: progressBlue,
              selected: _metric,
              onChanged: (value) => setState(() => _metric = value)),
          const SizedBox(height: 8),
          if (activeWeeks == 0)
            const ProgressEmpty(
                'Your training history starts with your first logged workout.')
          else if (widget.weeks.length <= 6)
            ProgressWeeklyBars(
                points: ProgressPoint.parse(widget.weeks, _metric),
                metric: _metric == 'sets' ? 'Logged sets' : 'Workouts')
          else
            ProgressChart(
                points: ProgressPoint.parse(widget.weeks, _metric),
                bars: true,
                summaryLabel: 'Weekly total',
                compactHeader: true,
                color: progressBlue,
                height: 88),
          if (activeWeeks > 0 &&
              widget.weeks.any((row) => row['partial'] == true))
            Text(
                fitnessText(
                    context, 'Edge weeks include only the selected dates.'),
                style: const TextStyle(color: progressMuted, fontSize: 12)),
          const SizedBox(height: 8),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          ExpansionTile(
              key: const PageStorageKey('progress-recent-activity'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 6),
              shape: const Border(),
              collapsedShape: const Border(),
              dense: true,
              title: Text(fitnessText(context, 'Recent activity'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              children: [
                Row(
                    children: List.generate(
                        7,
                        (i) => Expanded(
                            child: Center(
                                child: Text(
                                    DateFormat.EEEEE(locale)
                                        .format(start.add(Duration(days: i))),
                                    style: const TextStyle(
                                        color: progressMuted,
                                        fontSize: 12)))))),
                const SizedBox(height: 8),
                for (var week = 0; week < 5; week++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                          children: List.generate(7, (day) {
                        final date = start.add(Duration(days: week * 7 + day));
                        final key = CacheScope.todayKey(date);
                        final row = activity[key];
                        final completed = row?['completed'] == true;
                        final logged = (row?['sets'] as num? ?? 0) > 0;
                        return Expanded(
                            child: Center(
                                child: Tooltip(
                                    message:
                                        '${DateFormat.yMMMd(locale).format(date)} · ${fitnessText(context, completed ? 'Completed' : logged ? 'Logged sets' : 'No activity')}',
                                    child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                            color: date.isAfter(today)
                                                ? Colors.transparent
                                                : completed
                                                    ? progressBlue
                                                    : logged
                                                        ? const Color(
                                                            0xFF73849D)
                                                        : const Color(
                                                            0xFF303030),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: key == CacheScope.todayKey()
                                                ? Border.all(
                                                    color: progressMuted)
                                                : null)))));
                      }))),
                const SizedBox(height: 5),
                Text(
                    fitnessText(
                        context, 'Bright squares show completed workouts.'),
                    style: const TextStyle(
                        color: progressMuted, fontSize: 11, height: 1.4)),
              ]),
        ]));
  }
}

class ProgressMuscleBars extends StatelessWidget {
  final List<ProgressJson> muscles;
  final ValueChanged<ProgressJson> onTap;
  const ProgressMuscleBars(
      {super.key, required this.muscles, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final max = muscles.fold<num>(
        1,
        (max, row) => (row['directSets'] as num? ?? 0) > max
            ? row['directSets'] as num
            : max);
    return Column(
        children: muscles
            .map((row) => InkWell(
                onTap: () => onTap(row),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Expanded(
                              flex: 4,
                              child: Text(progressMuscleLabel(context, row),
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 12),
                          Expanded(
                              flex: 5,
                              child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF303236),
                                      borderRadius: BorderRadius.circular(3)),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: MotionValue(
                                          value: ((row['directSets'] as num? ?? 0) / max)
                                              .toDouble(),
                                          builder: (context, animatedValue) => FractionallySizedBox(
                                              widthFactor: animatedValue,
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                      gradient: const LinearGradient(
                                                          colors: [Color(0xFF427FA8), progressCyan])))))))),
                          const SizedBox(width: 12),
                          Text('${row['directSets'] ?? 0}',
                              style: const TextStyle(
                                  color: progressSilver,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ])))))
            .toList());
  }
}
