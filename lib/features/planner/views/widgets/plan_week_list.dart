import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';

/// A week can be understood without opening every date or exercise.
class PlanWeekList extends StatelessWidget {
  final List<Map> days;
  final Map<String, String> statuses;
  final String? selectedDate;
  final ValueChanged<String>? onSelected;
  final bool locked;
  final bool compact;
  final String keyPrefix;
  const PlanWeekList(
      {super.key,
      required this.days,
      this.statuses = const {},
      this.selectedDate,
      this.onSelected,
      this.locked = false,
      this.compact = false,
      this.keyPrefix = 'plan-day'});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final valid =
        days.where((d) => DateTime.tryParse('${d['date']}') != null).toList();
    return FitnessCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var n = 0; n < valid.length; n++) ...[
            if (n > 0)
              const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: FitnessTheme.line),
            Builder(builder: (context) {
              final day = valid[n];
              final date = DateTime.parse('${day['date']}');
              final rest = day['restDay'] == true;
              final complete = statuses[day['date']] == 'COMPLETED';
              final count =
                  day['exerciseCount'] ?? (day['exercises'] as List?)?.length;
              final minutes = day['estimatedMinutes'] as num? ?? 0;
              final selected = selectedDate == day['date'];
              return Material(
                  color:
                      selected ? const Color(0xFF2D2D2D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: ValueKey('$keyPrefix-${day['date']}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: onSelected == null
                        ? null
                        : () => onSelected!('${day['date']}'),
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: compact ? 11 : 13),
                        child: Row(children: [
                          SizedBox(
                              width: 76,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat.EEEE(locale).format(date),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                    if (!compact) ...[
                                      const SizedBox(height: 4),
                                      Text(DateFormat.MMMd(locale).format(date),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: FitnessTheme.muted)),
                                    ],
                                  ])),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                FitnessText(
                                    rest
                                        ? 'Rest day'
                                        : '${day['name'] ?? 'Workout'}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                        color: rest
                                            ? FitnessTheme.muted
                                            : Colors.white)),
                                if (!compact &&
                                    !rest &&
                                    (count != null || minutes > 0)) ...[
                                  const SizedBox(height: 4),
                                  Wrap(spacing: 8, runSpacing: 3, children: [
                                    if (count != null)
                                      FitnessText(
                                          count == 1
                                              ? '{count} exercise'
                                              : '{count} exercises',
                                          values: {'count': count},
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: FitnessTheme.muted)),
                                    if (minutes > 0)
                                      FitnessText('{minutes} min',
                                          values: {'minutes': minutes.round()},
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: FitnessTheme.muted)),
                                  ]),
                                ],
                                if (complete)
                                  const FitnessText('Completed',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: FitnessTheme.silver)),
                              ])),
                          const SizedBox(width: 8),
                          Icon(
                              complete
                                  ? Icons.check_circle_outline
                                  : rest
                                      ? Icons.nights_stay_outlined
                                      : locked
                                          ? Icons.lock_outline
                                          : onSelected != null
                                              ? Icons.chevron_right
                                              : Icons.fitness_center,
                              size: 17,
                              color: FitnessTheme.muted),
                        ])),
                  ));
            }),
          ],
        ]));
  }
}
