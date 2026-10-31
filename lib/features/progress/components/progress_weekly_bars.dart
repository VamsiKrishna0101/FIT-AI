import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

/// Short ranges show every weekly total directly, including real zeroes.
class ProgressWeeklyBars extends StatelessWidget {
  final List<ProgressPoint> points;
  final String metric;
  final Color color;
  final bool compact;
  const ProgressWeeklyBars(
      {super.key,
      required this.points,
      required this.metric,
      this.color = progressBlue,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maximum =
        points.fold<double>(1, (max, point) => math.max(max, point.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!compact) ...[
        Text(fitnessText(context, 'Weekly total'),
            style: const TextStyle(fontSize: 12, color: progressMuted)),
        const SizedBox(height: 14),
      ],
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final point in points)
          Expanded(
              child: Semantics(
                  label: '${DateFormat.yMMMd(locale).format(point.date)}: '
                      '${progressValue(context, point.value, digits: 0)} '
                      '${fitnessText(context, metric)}',
                  child: Tooltip(
                      message:
                          '${DateFormat.yMMMd(locale).format(point.date)} · '
                          '${progressValue(context, point.value, digits: 0)} '
                          '${fitnessText(context, metric)}',
                      child: ExcludeSemantics(
                          child: Column(children: [
                        Text(progressValue(context, point.value, digits: 0),
                            style: TextStyle(
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    point.value == 0 ? progressMuted : color)),
                        SizedBox(height: compact ? 6 : 8),
                        SizedBox(
                            height: compact ? 32 : 70,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: MotionValue(
                                    value: point.value / maximum,
                                    builder: (context, value) => Container(
                                        width: compact ? 20 : 24,
                                        height: math.max(
                                            2, value * (compact ? 32 : 70)),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: point.value == 0
                                                    ? [
                                                        progressMuted
                                                            .withValues(
                                                                alpha: .25),
                                                        progressMuted
                                                            .withValues(
                                                                alpha: .25)
                                                      ]
                                                    : [
                                                        color,
                                                        color.withValues(
                                                            alpha: .5)
                                                      ])))))),
                        SizedBox(height: compact ? 7 : 10),
                        Text(DateFormat.Md(locale).format(point.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: progressMuted)),
                      ]))))),
      ]),
      if (!compact) const SizedBox(height: 12),
    ]);
  }
}
