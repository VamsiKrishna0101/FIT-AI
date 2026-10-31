import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

/// The overview has one training summary; full activity stays one tap away.
class ProgressTrainingSnapshot extends StatelessWidget {
  final ProgressJson summary;
  final List<ProgressJson> weeks;
  final String? rangeLabel;
  final VoidCallback onActivity;
  const ProgressTrainingSnapshot({
    super.key,
    required this.summary,
    required this.weeks,
    required this.onActivity,
    this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final workouts = progressNumber(summary['workouts']) ?? 0;
    final records = progressNumber(summary['records']) ?? 0;
    final change = progressNumber(summary['workoutChange']);
    final points = ProgressPoint.parse(weeks, 'workouts');
    return ProgressSurface(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(fitnessText(context, 'Your training'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            key: const ValueKey('progress-open-activity'),
            onPressed: onActivity,
            tooltip: fitnessText(context, 'Consistency'),
            icon: const Icon(CupertinoIcons.chevron_right,
                size: 14, color: progressMuted),
          ),
        ]),
        if (rangeLabel != null)
          Text(rangeLabel!,
              style: const TextStyle(fontSize: 12, color: progressMuted)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, box) {
          final total = Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(progressValue(context, workouts, digits: 0),
                    style: const TextStyle(
                        fontSize: 38,
                        height: 1.05,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w600,
                        color: progressSilver)),
                Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(fitnessText(context, 'Workouts'),
                        style: const TextStyle(
                            fontSize: 12, color: progressMuted))),
              ]);
          if (records <= 0) return total;
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(CupertinoIcons.rosette,
                  color: progressAmber, size: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    '${progressValue(context, records, digits: 0)} · '
                    '${fitnessText(context, 'New records')}',
                    style:
                        const TextStyle(fontSize: 12, color: progressSilver)),
              ),
            ]),
          );
          if (MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [total, const SizedBox(height: 12), badge]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: total),
            const SizedBox(width: 12),
            Flexible(child: badge),
          ]);
        }),
        if (change != null && change.isFinite) ...[
          const SizedBox(height: 10),
          Text(
              fitnessText(
                  context,
                  change.abs() == 1
                      ? '{change} workout vs previous period'
                      : '{change} workouts vs previous period',
                  values: {
                    'change':
                        '${change > 0 ? '+' : ''}${progressValue(context, change, digits: 0)}'
                  }),
              style: const TextStyle(
                  fontSize: 12, color: progressMuted, height: 1.4)),
        ],
        if (points.isNotEmpty) ...[
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, box) {
            final labelWidth = MediaQuery.textScalerOf(context).scale(12) * 4;
            if (points.length <= 6 &&
                box.maxWidth / points.length >= labelWidth) {
              return ProgressWeeklyBars(
                  points: points, metric: 'Workouts', compact: true);
            }
            return ProgressChart(
                points: points,
                bars: true,
                digits: 0,
                summaryLabel: 'Weekly total',
                compactHeader: true,
                height: MediaQuery.textScalerOf(context).scale(12) * 6);
          }),
          if (weeks.any((row) => row['partial'] == true)) ...[
            const SizedBox(height: 10),
            Text(
                fitnessText(
                    context, 'Edge weeks include only the selected dates.'),
                style: const TextStyle(
                    fontSize: 11, color: progressMuted, height: 1.4)),
          ],
        ],
      ]),
    );
  }
}
