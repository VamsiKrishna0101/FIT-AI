import 'package:flutter/cupertino.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

class ExerciseProgressListRow extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const ExerciseProgressListRow(
      {super.key, required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = exercise['latest'] as Map?;
    final weight = progressNumber(latest?['weight']);
    final load = exercise['metric'] == 'load' ||
        (exercise['metric'] == null && (weight ?? 0) > 0);
    final points =
        ProgressPoint.parse(progressRows(exercise['sparkline']), 'value');
    final change =
        points.length > 1 ? points.last.value - points.first.value : null;
    final sessions = progressNumber(exercise['sessions']);
    final date = exercise['latestDate'] as String?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final trend = SizedBox(
        width: 66,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (change != null && change.isFinite)
            Text(
                '${change > 0 ? '+' : ''}${progressValue(context, change, unit: load ? 'kg' : 'reps', digits: load ? 1 : 0)}',
                style: const TextStyle(
                    fontSize: 11, color: progressSilver, height: 1.3)),
          const SizedBox(height: 6),
          SizedBox(
              height: 28,
              width: 66,
              child: ExcludeSemantics(
                  child: ProgressSparkline(
                      points: points, color: progressStrength))),
        ]));
    return ProgressSurface(
        key: ValueKey('exercise-progress-row-${exercise['id']}'),
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(exercise['name'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: progressSilver,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        letterSpacing: -.2))),
            const SizedBox(width: 10),
            const Icon(CupertinoIcons.chevron_right,
                size: 12, color: progressMuted),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      latest == null
                          ? fitnessText(
                              context, 'No sets logged in this period')
                          : progressSetValue(
                              context, Map<String, dynamic>.from(latest)),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: progressSilver,
                          letterSpacing: -.4,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  const SizedBox(height: 5),
                  Text(
                      date == null
                          ? fitnessText(context, 'Last session')
                          : progressDate(date, locale,
                              year: DateTime.tryParse(date)?.year !=
                                  DateTime.now().year),
                      style: const TextStyle(
                          fontSize: 11, color: progressMuted, height: 1.4)),
                ])),
            if (points.length > 1 && !large) ...[
              const SizedBox(width: 12),
              trend,
            ],
          ]),
          if (sessions != null && sessions > 0) ...[
            const SizedBox(height: 10),
            Text(
                fitnessText(context,
                    sessions == 1 ? '{count} session' : '{count} sessions',
                    values: {
                      'count': progressValue(context, sessions, digits: 0)
                    }),
                style: const TextStyle(
                    color: progressMuted, fontSize: 10, height: 1.4)),
          ],
        ]));
  }
}
