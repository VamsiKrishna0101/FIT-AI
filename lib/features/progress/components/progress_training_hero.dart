import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

class ProgressTrainingHero extends StatelessWidget {
  final ProgressJson summary;
  final List<ProgressJson> weeks;
  final String? rangeLabel;
  final VoidCallback onOpen;
  const ProgressTrainingHero(
      {super.key,
      required this.summary,
      required this.weeks,
      required this.onOpen,
      this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final workouts = progressNumber(summary['workouts']) ?? 0;
    final change = progressNumber(summary['workoutChange']);
    final points = ProgressPoint.parse(weeks, 'workouts');
    return ProgressSurface(
        padding: EdgeInsets.zero,
        child: InkWell(
            key: const ValueKey('progress-open-activity'),
            onTap: onOpen,
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Wrap(
                                spacing: 7,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                              Text(progressValue(context, workouts, digits: 0),
                                  style: const TextStyle(
                                      fontSize: 34,
                                      height: 1.05,
                                      letterSpacing: -1.1,
                                      fontWeight: FontWeight.w600)),
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(fitnessText(context, 'Workouts'),
                                      style: const TextStyle(
                                          fontSize: 12, color: progressMuted))),
                            ])),
                        if (weeks.any((week) => week['partial'] == true))
                          Tooltip(
                              message: fitnessText(context,
                                  'Edge weeks include only the selected dates.'),
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(CupertinoIcons.info_circle,
                                      size: 14, color: progressMuted))),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 12, color: progressMuted),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                          change != null && change.isFinite
                              ? fitnessText(
                                  context,
                                  change.abs() == 1
                                      ? '{change} workout vs previous period'
                                      : '{change} workouts vs previous period',
                                  values: {
                                      'change':
                                          '${change > 0 ? '+' : ''}${progressValue(context, change, digits: 0)}'
                                    })
                              : rangeLabel ?? '',
                          style: const TextStyle(
                              color: progressMuted, fontSize: 11, height: 1.4)),
                      if (points.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        LayoutBuilder(builder: (context, box) {
                          final labelWidth =
                              MediaQuery.textScalerOf(context).scale(12) * 4;
                          if (points.length <= 6 &&
                              box.maxWidth / points.length >= labelWidth) {
                            return ProgressWeeklyBars(
                                points: points,
                                metric: 'Workouts',
                                compact: true);
                          }
                          return SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: ProgressSparkline(
                                  points: points,
                                  bars: true,
                                  color: progressBlue));
                        }),
                      ],
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0x14FFFFFF)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 20, runSpacing: 6, children: [
                        _fact(context, progressNumber(summary['sets']) ?? 0,
                            'Logged sets'),
                        _fact(context, progressNumber(summary['records']) ?? 0,
                            'New records'),
                      ]),
                    ]))));
  }

  Widget _fact(BuildContext context, num value, String label) => Text.rich(
      TextSpan(children: [
        TextSpan(
            text: '${progressValue(context, value, digits: 0)} ',
            style: const TextStyle(
                color: progressSilver, fontWeight: FontWeight.w500)),
        TextSpan(text: fitnessText(context, label)),
      ]),
      style: const TextStyle(color: progressMuted, fontSize: 11));
}
