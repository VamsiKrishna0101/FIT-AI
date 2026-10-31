import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

/// A week-by-day grid of the loaded sessions: each column is a week, each
/// cell a day, brighter mint for days with more workouts.
class ProgressTrainingHeatmap extends StatelessWidget {
  final List<ProgressJson> sessions;
  const ProgressTrainingHeatmap({super.key, required this.sessions});

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Calendar-day offset; adding a Duration would drift across DST changes.
  static DateTime _shift(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  @override
  Widget build(BuildContext context) {
    final counts = <DateTime, int>{};
    for (final session in sessions) {
      final date = DateTime.tryParse(session['date']?.toString() ?? '');
      if (date != null) counts.update(_day(date), (n) => n + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final latest = counts.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    final today = _day(DateTime.now());
    final end = latest.isAfter(today) ? latest : today;
    // Columns end on the week containing [end]; weeks start on Monday.
    final lastMonday = _shift(end, 1 - end.weekday);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final peak = counts.values.reduce(math.max);
    return ProgressSurface(
        accent: progressTraining,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: LayoutBuilder(builder: (context, box) {
          const gap = 4.0;
          final weeks =
              ((box.maxWidth + gap) / 18).floor().clamp(4, 26).toInt();
          final cell = (box.maxWidth - gap * (weeks - 1)) / weeks;
          final first = _shift(lastMonday, -7 * (weeks - 1));
          final shown = counts.entries
              .where((entry) => !entry.key.isBefore(first))
              .fold<int>(0, (sum, entry) => sum + entry.value);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(progressValue(context, shown, digits: 0),
                      style: const TextStyle(
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(fitnessText(context, 'Workouts'),
                          style: const TextStyle(
                              fontSize: 12, color: progressMuted))),
                  Text(
                      '${DateFormat.MMMd(locale).format(first)} – ${DateFormat.MMMd(locale).format(end)}',
                      style:
                          const TextStyle(fontSize: 11, color: progressMuted)),
                ]),
                const SizedBox(height: 12),
                ExcludeSemantics(
                    child: Row(children: [
                  for (var w = 0; w < weeks; w++) ...[
                    if (w > 0) const SizedBox(width: gap),
                    Column(children: [
                      for (var d = 0; d < 7; d++) ...[
                        if (d > 0) const SizedBox(height: gap),
                        _Cell(
                            size: cell,
                            date: _shift(first, w * 7 + d),
                            end: end,
                            count: counts[_shift(first, w * 7 + d)] ?? 0,
                            peak: peak),
                      ],
                    ]),
                  ],
                ])),
              ]);
        }));
  }
}

class _Cell extends StatelessWidget {
  final double size;
  final DateTime date, end;
  final int count, peak;
  const _Cell(
      {required this.size,
      required this.date,
      required this.end,
      required this.count,
      required this.peak});

  @override
  Widget build(BuildContext context) {
    final future = date.isAfter(end);
    final level = count == 0 ? 0.0 : .45 + .55 * count / peak;
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .28),
            color: future
                ? Colors.transparent
                : count == 0
                    ? const Color(0x0FFFFFFF)
                    : progressTraining.withValues(alpha: level),
            boxShadow: [
              if (count > 0)
                BoxShadow(
                    color: progressTraining.withValues(alpha: .25 * level),
                    blurRadius: 6),
            ]));
  }
}
