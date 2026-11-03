import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';

String planWorkoutTitle(Map day) {
  if (day['restDay'] == true) return 'Recovery';
  final name = '${day['name'] ?? 'Workout'}';
  if (name.split('+').length < 3) return name.replaceAll(' + ', ' & ');
  final lower = name.toLowerCase();
  final upper =
      RegExp(r'chest|shoulder|bicep|tricep|forearm|upper|push|pull|back')
          .hasMatch(lower);
  final legs =
      RegExp(r'legs|quads|hamstring|glute|calves|lower').hasMatch(lower);
  return upper && legs
      ? 'Full body'
      : legs
          ? 'Lower body'
          : upper
              ? 'Upper body'
              : name;
}

String? planWorkoutFocus(Map day) {
  final name = '${day['name'] ?? ''}';
  return name.split('+').length >= 3
      ? name.replaceAll(' + ', ' \u00b7 ')
      : null;
}

class PlanWeekList extends StatelessWidget {
  final List<Map> days;
  final Map<String, String> statuses;
  final String? selectedDate;
  final ValueChanged<String>? onSelected;
  final bool locked, compact;
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
    return Column(children: [
      for (final day in valid)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (context) {
              final date = DateTime.parse('${day['date']}');
              final rest = day['restDay'] == true;
              final complete = statuses[day['date']] == 'COMPLETED';
              final inProgress = statuses[day['date']] == 'IN_PROGRESS';
              final today = day['date'] == CacheScope.todayKey();
              final selected = selectedDate == day['date'];
              final count =
                  day['exerciseCount'] ?? (day['exercises'] as List?)?.length;
              final minutes = (day['estimatedMinutes'] as num? ?? 0).round();
              return Semantics(
                  selected: selected,
                  child: Material(
                    color: selected
                        ? const Color(0xFF282B2F)
                        : rest
                            ? Colors.transparent
                            : FitnessTheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color:
                                rest ? Colors.transparent : FitnessTheme.line,
                            width: .7)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('$keyPrefix-${day['date']}'),
                      onTap: onSelected == null
                          ? null
                          : () => onSelected!('${day['date']}'),
                      child: Padding(
                          padding: EdgeInsets.all(compact ? 12 : 15),
                          child: Row(children: [
                            Container(
                                width: compact ? 42 : 46,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: today
                                      ? FitnessTheme.silver
                                      : const Color(0xFF23262A),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Column(children: [
                                  Text(DateFormat.E(locale).format(date),
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: today
                                              ? FitnessTheme.canvas
                                              : FitnessTheme.muted)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat.d(locale).format(date),
                                      style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          color: today
                                              ? FitnessTheme.canvas
                                              : FitnessTheme.silver)),
                                ])),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  FitnessText(planWorkoutTitle(day),
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                          color: rest
                                              ? FitnessTheme.muted
                                              : Colors.white)),
                                  const SizedBox(height: 5),
                                  if (rest)
                                    const FitnessText('Rest day',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: FitnessTheme.muted))
                                  else if (!compact)
                                    Wrap(spacing: 10, runSpacing: 4, children: [
                                      if (count != null)
                                        FitnessText('{count} exercises',
                                            values: {'count': count},
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: FitnessTheme.muted)),
                                      if (minutes > 0)
                                        FitnessText('{minutes} min',
                                            values: {'minutes': minutes},
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: FitnessTheme.muted)),
                                    ]),
                                  if (inProgress) ...[
                                    const SizedBox(height: 5),
                                    const FitnessText('In progress',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: FitnessTheme.silver)),
                                  ],
                                ])),
                            const SizedBox(width: 10),
                            Icon(
                                complete
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : rest
                                        ? CupertinoIcons.moon
                                        : locked
                                            ? CupertinoIcons.lock
                                            : CupertinoIcons.chevron_right,
                                size: complete ? 21 : 15,
                                color: complete
                                    ? const Color(0xFF80B69E)
                                    : FitnessTheme.muted),
                          ])),
                    ),
                  ));
            })),
    ]);
  }
}
