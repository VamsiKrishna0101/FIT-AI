import '../../../../core/components/content_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../body_scan/views/widgets/body_controls.dart';

class WeeklyPlanSchedule extends StatefulWidget {
  final Map<String, dynamic> payload;

  const WeeklyPlanSchedule({super.key, required this.payload});

  @override
  State<WeeklyPlanSchedule> createState() => _WeeklyPlanScheduleState();
}

class _WeeklyPlanScheduleState extends State<WeeklyPlanSchedule> {
  int _day = 0;
  int _section = 0;

  List<Map<String, dynamic>> get _days =>
      (widget.payload['workouts'] as List? ?? [])
          .whereType<Map>()
          .map((day) => Map<String, dynamic>.from(day))
          .toList();

  @override
  Widget build(BuildContext context) {
    final days = _days;
    if (days.isEmpty) {
      return const FitnessCard(
          child: FitnessText('No workouts in this saved week.'));
    }

    final selected = days[_day.clamp(0, days.length - 1)];
    final trainingDays = days.where((day) => day['restDay'] != true).length;
    final restDays = days.length - trainingDays;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText(
          '$trainingDays training ${trainingDays == 1 ? 'day' : 'days'} · $restDays rest ${restDays == 1 ? 'day' : 'days'}',
          style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      const SizedBox(height: 14),
      _weekStrip(days),
      const SizedBox(height: 16),
      BodySegment(
          labels: const ['Workout', 'Food'],
          selected: _section,
          onChanged: (section) => setState(() => _section = section)),
      const SizedBox(height: 20),
      FitnessText(
          DateFormat.MMMMEEEEd()
              .format(DateTime.parse(selected['date'] as String)),
          style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
      ContentTransition(
        child: KeyedSubtree(
          key: ValueKey('${selected['date']}:$_section'),
          child: _section == 0
              ? _workout(selected)
              : _food(selected['date'] as String),
        ),
      ),
    ]);
  }

  Widget _weekStrip(List<Map<String, dynamic>> days) => LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
          final width = !largeText && days.length >= 5
              ? (constraints.maxWidth - 12) / days.length
              : 58.0;

          return Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              gradient: const LinearGradient(
                  colors: [Color(0xFF252525), Color(0xFF171717)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var index = 0; index < days.length; index++)
                  SizedBox(width: width, child: _dayButton(days[index], index)),
              ]),
            ),
          );
        },
      );

  Widget _dayButton(Map<String, dynamic> day, int index) {
    final selected = index == _day;
    final date = DateTime.parse(day['date'] as String);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Semantics(
      selected: selected,
      button: true,
      label: '${DateFormat.yMMMMEEEEd(locale).format(date)} · ${day['name']}',
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('plan-day-${day['date']}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _day = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: .30)
                        : Colors.transparent),
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF505050), Color(0xFF303030)],
                      )
                    : null,
              ),
              child: Column(children: [
                Text(DateFormat.E(locale).format(date),
                    style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? FitnessTheme.silver
                            : FitnessTheme.muted)),
                const SizedBox(height: 5),
                Text(DateFormat.d(locale).format(date),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : FitnessTheme.silver)),
                const SizedBox(height: 6),
                Container(
                    width: day['restDay'] == true ? 9 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: selected
                            ? FitnessTheme.silver
                            : FitnessTheme.muted.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(3))),
              ]),
            ),
          )),
    );
  }

  Widget _workout(Map<String, dynamic> day) {
    final exercises =
        (day['exercises'] as List? ?? []).whereType<Map>().toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText('${day['name']}',
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.5)),
      const SizedBox(height: 8),
      if (day['restDay'] == true)
        const FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(CupertinoIcons.moon, color: FitnessTheme.silver, size: 26),
            SizedBox(height: 14),
            FitnessText('Recovery day', style: TextStyle(fontSize: 18)),
            SizedBox(height: 6),
            FitnessText('No workout scheduled. Give yourself time to recover.',
                style: TextStyle(
                    fontSize: 13, color: FitnessTheme.muted, height: 1.4)),
          ]),
        )
      else ...[
        FitnessText(
            '${exercises.length} ${exercises.length == 1 ? 'exercise' : 'exercises'} · ${day['estimatedMinutes']} min',
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 16),
        for (var index = 0; index < exercises.length; index++)
          _exercise(exercises[index], index + 1, day['date'] as String),
        const FitnessText(
            'Effort is out of 10. Weights follow your previous logging convention.',
            style: TextStyle(
                fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
      ],
    ]);
  }

  Widget _exercise(Map exercise, int number, String date) {
    final load = exercise['weightBasis'] == 'bodyweight'
        ? 'Bodyweight'
        : exercise['weightKg'] == null
            ? 'Choose starting load'
            : exercise['weightBasis'] == 'estimated_start'
                ? '~${exercise['weightKg']} kg · suggested start'
                : '${exercise['weightKg']} kg · as logged';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(number.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: FitnessText('${exercise['name']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 14),
          FitnessText(
              '${exercise['sets']} × ${exercise['repsMin']}–${exercise['repsMax']} · $load',
              style: const TextStyle(fontSize: 14, color: FitnessTheme.silver)),
          const SizedBox(height: 6),
          FitnessText(
              'Effort ${exercise['targetRpe']}/10 · ${exercise['restSeconds']} s rest',
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          if (exercise['reason'] is String &&
              (exercise['reason'] as String).isNotEmpty)
            Material(
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: ValueKey('plan-exercise-$date-$number'),
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: const FitnessText('Why this exercise',
                        style:
                            TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                    children: [
                      FitnessText(exercise['reason'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: FitnessTheme.muted,
                              height: 1.5)),
                    ],
                  ),
                )),
        ]),
      ),
    );
  }

  Widget _food(String date) {
    final nutrition = widget.payload['nutrition'] as Map?;
    final foodDay = (nutrition?['days'] as List? ?? [])
        .whereType<Map>()
        .where((day) => day['date'] == date)
        .firstOrNull;

    if (nutrition?['status'] != 'RECOMMENDED' || foodDay == null) {
      return FitnessCard(
          child: FitnessText(
              nutrition?['reason'] as String? ??
                  'No food suggestions for this day.',
              style: const TextStyle(
                  fontSize: 13, color: FitnessTheme.muted, height: 1.5)));
    }

    final totals = foodDay['totals'] as Map;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FitnessText('Food for the day',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      FitnessText(
          '${(totals['calories'] as num).round()} kcal · ${(totals['protein'] as num).round()} g protein',
          style: const TextStyle(fontSize: 13, color: FitnessTheme.muted)),
      const SizedBox(height: 16),
      for (final meal in (foodDay['meals'] as List).whereType<Map>())
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FitnessCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText('${meal['mealType']}'.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                for (final food in (meal['foods'] as List).whereType<Map>())
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FitnessText('${food['name']} · ${food['grams']} g',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.silver))),
              ])),
        ),
    ]);
  }
}
