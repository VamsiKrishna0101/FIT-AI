import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

/// The Summary scoreboard: a large workout count that counts up, its change
/// against the previous period, the weekly rhythm and two supporting stats.
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
    // Stats sit beside the headline so the card stays one compact block;
    // larger text gives them their own row instead.
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 17;
    final stats = [
      _Stat(
          icon: CupertinoIcons.square_stack_3d_up_fill,
          color: progressStrength,
          value: progressNumber(summary['sets']) ?? 0,
          label: 'Logged sets'),
      _Stat(
          icon: CupertinoIcons.rosette,
          color: progressRecord,
          value: progressNumber(summary['records']) ?? 0,
          label: 'New records'),
    ];
    final headline = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                MotionValue(
                    value: workouts.toDouble(),
                    builder: (context, value) => Text(
                        progressValue(context, value.roundToDouble(),
                            digits: 0),
                        style: const TextStyle(
                            fontSize: 48,
                            height: 1,
                            letterSpacing: -1.8,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [ui.FontFeature.tabularFigures()]))),
                Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(fitnessText(context, 'Workouts'),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: progressMuted))),
              ]),
          const SizedBox(height: 9),
          if (change != null && change.isFinite)
            _ChangePill(change: change)
          else if (rangeLabel != null)
            Text(rangeLabel!,
                style: const TextStyle(color: progressMuted, fontSize: 12)),
        ]);
    return ProgressSurface(
        accent: progressTraining,
        radius: 28,
        padding: EdgeInsets.zero,
        child: InkWell(
            key: const ValueKey('progress-open-activity'),
            onTap: onOpen,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: headline),
                        if (!stacked) ...[
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                stats[0],
                                const SizedBox(height: 10),
                                stats[1],
                              ]),
                        ],
                        if (weeks.any((week) => week['partial'] == true))
                          Tooltip(
                              message: fitnessText(context,
                                  'Edge weeks include only the selected dates.'),
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(CupertinoIcons.info_circle,
                                      size: 14, color: progressMuted))),
                        const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(CupertinoIcons.chevron_right,
                                size: 13, color: progressMuted)),
                      ]),
                      if (stacked) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 16, runSpacing: 10, children: stats),
                      ],
                      if (points.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        LayoutBuilder(builder: (context, box) {
                          final labelWidth =
                              MediaQuery.textScalerOf(context).scale(12) * 4;
                          if (points.length <= 6 &&
                              box.maxWidth / points.length >= labelWidth) {
                            return ProgressWeeklyBars(
                                points: points,
                                metric: 'Workouts',
                                color: progressTraining,
                                compact: true);
                          }
                          return SizedBox(
                              height: 64,
                              width: double.infinity,
                              child: ProgressSparkline(
                                  points: points,
                                  bars: true,
                                  color: progressTraining));
                        }),
                      ],
                    ]))));
  }
}

/// The period-over-period workout change as a direction-tinted chip.
class _ChangePill extends StatelessWidget {
  final num change;
  const _ChangePill({required this.change});

  @override
  Widget build(BuildContext context) => ProgressChangeChip(
      change: change,
      label: fitnessText(
          context,
          change.abs() == 1
              ? '{change} workout vs previous period'
              : '{change} workouts vs previous period',
          values: {
            'change':
                '${change > 0 ? '+' : ''}${progressValue(context, change, digits: 0)}'
          }));
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final num value;
  final String label;
  const _Stat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 8),
        Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(progressValue(context, value, digits: 0),
                  style: const TextStyle(
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.3,
                      fontFeatures: [ui.FontFeature.tabularFigures()])),
              Text(fitnessText(context, label),
                  style: const TextStyle(
                      fontSize: 10.5, height: 1.25, color: progressMuted)),
            ]),
      ]);
}
