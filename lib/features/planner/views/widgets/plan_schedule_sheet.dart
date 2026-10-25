import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/components/fitness_form.dart';
import '../../../../core/components/neutral_schedule_chips.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';

class PlanScheduleSelection {
  final DateTime start;
  final List<DateTime> dates;
  const PlanScheduleSelection(this.start, this.dates);
}

// Calendar constructors keep dates correct across daylight-saving changes.
List<DateTime> remainingWeekDates(DateTime start) => [
      for (var offset = 0; offset <= DateTime.sunday - start.weekday; offset++)
        DateTime(start.year, start.month, start.day + offset),
    ];

class PlanScheduleSheet extends StatefulWidget {
  final DateTime initialStart;
  final List<String> preferredDays;
  final int usualCount;
  final DateTime? now;
  const PlanScheduleSheet(
      {super.key,
      required this.initialStart,
      this.preferredDays = const [],
      this.usualCount = 3,
      this.now});
  @override
  State<PlanScheduleSheet> createState() => _PlanScheduleSheetState();
}

class _PlanScheduleSheetState extends State<PlanScheduleSheet> {
  late DateTime _start;
  final _selected = <String>{};
  DateTime get _today {
    final now = widget.now ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static const _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
  @override
  void initState() {
    super.initState();
    _start =
        widget.initialStart.isBefore(_today) ? _today : widget.initialStart;
    _defaults();
  }

  void _defaults() {
    final dates = remainingWeekDates(_start);
    final preferred = dates
        .where((date) =>
            widget.preferredDays.contains(_weekdays[date.weekday - 1]))
        .toList();
    final count = (preferred.isEmpty ? widget.usualCount : preferred.length)
        .clamp(1, dates.length.clamp(1, 6));
    _selectCount(count, preferred.isEmpty ? null : preferred);
  }

  void _selectCount(int count, [List<DateTime>? preferred]) {
    final dates = remainingWeekDates(_start);
    _selected.clear();
    final source =
        preferred != null && preferred.length >= count ? preferred : dates;
    for (var i = 0; i < count; i++) {
      final index =
          count == 1 ? 0 : (i * (source.length - 1) / (count - 1)).round();
      _selected.add(CacheScope.todayKey(source[index]));
    }
  }

  void _setStart(DateTime date) => setState(() {
        _start = date;
        _defaults();
      });
  @override
  Widget build(BuildContext context) {
    final dates = remainingWeekDates(_start);
    final tomorrow = DateTime(_today.year, _today.month, _today.day + 1);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return NeutralScheduleChips(
        child: SafeArea(
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Row(children: [
                        const Expanded(
                            child: FitnessText('When do you want to start?',
                                style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 20))
                      ]),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        ChoiceChip(
                            label: const FitnessText('Today'),
                            selected: _start == _today,
                            onSelected: (_) => _setStart(_today)),
                        ChoiceChip(
                            label: const FitnessText('Tomorrow'),
                            selected: _start == tomorrow,
                            onSelected: (_) => _setStart(tomorrow)),
                        ActionChip(
                            label: const FitnessText('Choose date'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: _start,
                                  firstDate: _today,
                                  lastDate: DateTime(_today.year, _today.month,
                                      _today.day + 28));
                              if (date != null && mounted) _setStart(date);
                            }),
                      ]),
                      const SizedBox(height: 16),
                      Text(
                          '${DateFormat.yMMMEd(locale).format(_start)} – ${DateFormat.yMMMEd(locale).format(dates.last)}',
                          style: const TextStyle(color: FitnessTheme.muted)),
                      const SizedBox(height: 24),
                      const FitnessText('How many workouts this week?',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        for (var count = 1;
                            count <= dates.length && count <= 6;
                            count++)
                          ChoiceChip(
                              key: ValueKey('session-count-$count'),
                              label: Text('$count'),
                              selected: _selected.length == count,
                              onSelected: (_) =>
                                  setState(() => _selectCount(count)))
                      ]),
                      const SizedBox(height: 18),
                      const FitnessText('Choose your training dates',
                          style: TextStyle(color: FitnessTheme.muted)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        for (final date in dates)
                          FilterChip(
                              key: ValueKey(
                                  'training-date-${CacheScope.todayKey(date)}'),
                              label:
                                  Text(DateFormat.MMMEd(locale).format(date)),
                              selected:
                                  _selected.contains(CacheScope.todayKey(date)),
                              onSelected: (selected) => setState(() {
                                    final key = CacheScope.todayKey(date);
                                    if (selected && _selected.length < 6) {
                                      _selected.add(key);
                                    } else if (!selected) {
                                      _selected.remove(key);
                                    }
                                  }))
                      ]),
                      const SizedBox(height: 16),
                      const FitnessText(
                          'Only these dates get workouts. Your usual weekly preferences stay the same.',
                          style: TextStyle(
                              fontSize: 12,
                              color: FitnessTheme.muted,
                              height: 1.5)),
                      const SizedBox(height: 24),
                      FitnessSubmit(
                          label: 'Use these dates',
                          onPressed: _selected.isEmpty
                              ? null
                              : () {
                                  final values = _selected.toList()..sort();
                                  Navigator.pop(
                                      context,
                                      PlanScheduleSelection(_start,
                                          values.map(DateTime.parse).toList()));
                                }),
                    ])))));
  }
}
