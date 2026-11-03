import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

/// Clean Apple-style weekly bars with soft pastel tones, flat solid fills,
/// and zero blurry drop-shadow halos.
class ProgressWeeklyBars extends StatelessWidget {
  final List<ProgressPoint> points;
  final String metric;
  final Color color;
  final bool compact;

  const ProgressWeeklyBars({
    super.key,
    required this.points,
    required this.metric,
    this.color = progressTraining,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maximum =
        points.fold<double>(1, (max, point) => math.max(max, point.value));
    final barHeight = compact ? 44.0 : 70.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(fitnessText(context, 'Weekly total'),
              style: const TextStyle(fontSize: 12, color: progressMuted)),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.asMap().entries.map((entry) {
            final i = entry.key;
            final point = entry.value;
            final isLatest = i == points.length - 1;
            final hasValue = point.value > 0;
            final barColor = isLatest
                ? (hasValue ? color : const Color(0xFF38383A))
                : (hasValue
                    ? const Color(0xFF555558)
                    : const Color(0xFF2C2C2E));

            return Expanded(
              child: Semantics(
                label: '${DateFormat.yMMMd(locale).format(point.date)}: '
                    '${progressValue(context, point.value, digits: 0)} '
                    '${fitnessText(context, metric)}',
                child: Tooltip(
                  message: '${DateFormat.yMMMd(locale).format(point.date)} · '
                      '${progressValue(context, point.value, digits: 0)} '
                      '${fitnessText(context, metric)}',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          hasValue
                              ? (point.value >= 10000
                                  ? '${(point.value / 1000).toStringAsFixed(1)}k'
                                  : progressValue(context, point.value,
                                      digits: 0))
                              : '0',
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight: isLatest && hasValue
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isLatest && hasValue
                                ? DSColors.silver
                                : DSColors.muted,
                          ),
                        ),
                        SizedBox(height: compact ? 6 : 8),
                        SizedBox(
                          height: barHeight,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: !hasValue
                                ? Container(
                                    width: 12,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38383A),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  )
                                : MotionValue(
                                    value: point.value / maximum,
                                    builder: (context, value) => Container(
                                      width: compact ? 16 : 20,
                                      height: math.max(3, value * barHeight),
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: compact ? 7 : 10),
                        Text(
                          DateFormat.Md(locale).format(point.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                isLatest ? FontWeight.w600 : FontWeight.w400,
                            color: isLatest ? DSColors.silver : DSColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (!compact) const SizedBox(height: 12),
      ],
    );
  }
}
