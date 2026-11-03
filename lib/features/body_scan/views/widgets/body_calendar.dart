import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_map_models.dart';

String bodyDateRangeLabel(BuildContext context, DateTime start, DateTime end) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final showYear = start.year != DateTime.now().year || end.year != start.year;
  final format = showYear ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale);
  return '${format.format(start)} – ${format.format(end)}';
}

String bodySelectionLabel(BuildContext context, BodyDateSelection selection) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final today = DateUtils.dateOnly(DateTime.now());
  String date(DateTime d) => (d.year == today.year
          ? DateFormat.MMMd(locale)
          : DateFormat.yMMMd(locale))
      .format(d);
  if (selection.mode == BodyDateMode.all) {
    return fitnessText(context, 'All time');
  }
  if (selection.mode == BodyDateMode.days && selection.dates.length > 1) {
    return fitnessText(context, '{count} days',
        values: {'count': selection.dates.length});
  }
  if (selection.mode == BodyDateMode.range &&
      selection.start != selection.end) {
    if (selection.start == bodyMapWeek(today) && selection.end == today) {
      return fitnessText(context, 'This week');
    }
    return bodyDateRangeLabel(context, selection.start!, selection.end);
  }
  return selection.end == today
      ? fitnessText(context, 'Today')
      : date(selection.end);
}

class BodyCalendar extends StatefulWidget {
  final BodyDateSelection selection;
  final bool planned;
  final DateTime? today;
  final String? title;
  const BodyCalendar(
      {super.key,
      required this.selection,
      this.planned = false,
      this.today,
      this.title});
  @override
  State<BodyCalendar> createState() => _BodyCalendarState();
}

class _BodyCalendarState extends State<BodyCalendar> {
  late DateTime _month;
  late BodyDateMode _mode;
  late Set<DateTime> _days;
  DateTime? _start, _end;
  DateTime get _today => DateUtils.dateOnly(widget.today ?? DateTime.now());
  DateTime get _lastMonth =>
      widget.planned ? DateTime(2100, 12) : DateTime(_today.year, _today.month);
  @override
  void initState() {
    super.initState();
    final s = widget.selection;
    _mode = s.mode;
    _month = DateTime(s.end.year, s.end.month);
    _days = {...s.dates};
    if (_days.isEmpty && s.mode == BodyDateMode.day) _days.add(s.end);
    _start = s.start;
    _end = s.end;
    if (widget.planned) {
      _mode = BodyDateMode.range;
      _start = bodyMapWeek(s.start ?? s.end);
      _end = DateTime(_start!.year, _start!.month, _start!.day + 6);
      _month = DateTime(_start!.year, _start!.month);
    }
  }

  void _changeMonth(int year, int month) => setState(() {
        final requested = DateTime(year, month);
        _month = requested.isAfter(_lastMonth) ? _lastMonth : requested;
      });

  BodyDateSelection? get _selection {
    if (_mode == BodyDateMode.all) {
      return BodyDateSelection(mode: _mode, end: _today);
    }
    if (_mode == BodyDateMode.range) {
      return _start == null
          ? null
          : BodyDateSelection(mode: _mode, start: _start, end: _end ?? _start!);
    }
    final days = _days.toList()..sort();
    return days.isEmpty
        ? null
        : BodyDateSelection(mode: _mode, end: days.last, dates: days);
  }

  void _tap(DateTime date) => setState(() {
        if (widget.planned) {
          _start = bodyMapWeek(date);
          _end = DateTime(_start!.year, _start!.month, _start!.day + 6);
          return;
        }
        if (_mode == BodyDateMode.all) _mode = BodyDateMode.day;
        if (_mode == BodyDateMode.day) {
          _days = {date};
        } else if (_mode == BodyDateMode.days) {
          if (!_days.remove(date) && _days.length < 366) _days.add(date);
        } else if (_start == null || _end != null) {
          _start = date;
          _end = null;
        } else {
          _end = date.isBefore(_start!) ? _start : date;
          if (date.isBefore(_start!)) _start = date;
        }
      });

  bool _selected(DateTime d) => _mode == BodyDateMode.all
      ? false
      : _mode == BodyDateMode.range
          ? _start != null &&
              !d.isBefore(_start!) &&
              !d.isAfter(_end ?? _start!)
          : _days.contains(d);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = DateTime(_month.year, _month.month);
    final offset = first.weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + count) / 7).ceil();
    return FitnessTheme(
        child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: FitnessText(
                                    widget.title ??
                                        (widget.planned
                                            ? 'Choose a week'
                                            : 'Training dates'),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.4))),
                            IconButton(
                                tooltip: fitnessText(context, 'Close'),
                                onPressed: () => Navigator.pop(context),
                                icon:
                                    const Icon(CupertinoIcons.xmark, size: 17)),
                          ]),
                          if (!widget.planned) ...[
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              for (final preset in [
                                'This week',
                                'Today',
                                'All time'
                              ])
                                ActionChip(
                                    backgroundColor: const Color(0xFF2A2A2A),
                                    side: BorderSide.none,
                                    label: FitnessText(preset,
                                        style: const TextStyle(fontSize: 12)),
                                    onPressed: () => setState(() {
                                          _month = DateTime(
                                              _today.year, _today.month);
                                          if (preset == 'Today') {
                                            _mode = BodyDateMode.day;
                                            _days = {_today};
                                          }
                                          if (preset == 'This week') {
                                            _mode = BodyDateMode.range;
                                            _start = bodyMapWeek(_today);
                                            _end = _today;
                                          }
                                          if (preset == 'All time') {
                                            _mode = BodyDateMode.all;
                                          }
                                        })),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              for (final pair in [
                                (BodyDateMode.day, 'Single day'),
                                (BodyDateMode.days, 'Multiple days'),
                                (BodyDateMode.range, 'Date range')
                              ])
                                ChoiceChip(
                                    showCheckmark: false,
                                    selectedColor: const Color(0xFF44484D),
                                    backgroundColor: const Color(0xFF292B2E),
                                    side: BorderSide.none,
                                    label: FitnessText(pair.$2,
                                        style: const TextStyle(fontSize: 11)),
                                    selected: _mode == pair.$1,
                                    onSelected: (_) {
                                      if (_mode == pair.$1) return;
                                      setState(() {
                                        _mode = pair.$1;
                                        _days = {};
                                        _start = null;
                                        _end = null;
                                      });
                                    }),
                            ]),
                          ],
                          if (widget.planned)
                            const Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 12),
                                child: FitnessText(
                                    'Select a day to choose its week.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))),
                          const SizedBox(height: 8),
                          _BodyCalendarMonthPicker(
                              month: _month,
                              lastMonth: _lastMonth,
                              onChanged: _changeMonth),
                          const SizedBox(height: 18),
                          Row(children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                  child: Text(
                                      DateFormat.E(locale)
                                          .format(DateTime(2026, 10, 26 + i)),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: FitnessTheme.muted)))
                          ]),
                          const SizedBox(height: 6),
                          for (var row = 0; row < rows; row++)
                            Row(children: [
                              for (var col = 0; col < 7; col++)
                                Expanded(child: Builder(builder: (context) {
                                  final day = DateTime(_month.year,
                                      _month.month, row * 7 + col - offset + 1);
                                  final selected = _selected(day);
                                  final available =
                                      !day.isBefore(DateTime(2000)) &&
                                          (widget.planned ||
                                              !day.isAfter(_today)) &&
                                          day.year <= _lastMonth.year;
                                  return Semantics(
                                    selected: selected,
                                    label: DateFormat.yMMMMEEEEd(locale)
                                        .format(day),
                                    child: TextButton(
                                        key: ValueKey(
                                            'body-calendar-${day.toIso8601String().substring(0, 10)}'),
                                        onPressed:
                                            available ? () => _tap(day) : null,
                                        style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(44, 44),
                                            backgroundColor: selected
                                                ? FitnessTheme.silver
                                                : Colors.transparent,
                                            foregroundColor: selected
                                                ? Colors.black
                                                : day.month == _month.month
                                                    ? Colors.white
                                                    : FitnessTheme.muted,
                                            shape: const CircleBorder()),
                                        child: Text('${day.day}',
                                            style:
                                                const TextStyle(fontSize: 13))),
                                  );
                                })),
                            ]),
                          const SizedBox(height: 12),
                          if (_selection case final selection?)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                    widget.planned
                                        ? bodyDateRangeLabel(context,
                                            selection.start!, selection.end)
                                        : bodySelectionLabel(
                                            context, selection),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))),
                        ]),
                  )),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                    key: const ValueKey('body-calendar-apply'),
                    onPressed: _selection == null
                        ? null
                        : () => Navigator.pop(context, _selection),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: FitnessTheme.silver,
                        foregroundColor: Colors.black),
                    child: const FitnessText('Apply')),
              ),
            ])));
  }
}

class _BodyCalendarMonthPicker extends StatelessWidget {
  final DateTime month, lastMonth;
  final void Function(int year, int month) onChanged;
  const _BodyCalendarMonthPicker(
      {required this.month, required this.lastMonth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget picker(String label, String key, int value,
            List<DropdownMenuItem<int>> items, ValueChanged<int> onSelected) =>
        InputDecorator(
            decoration: InputDecoration(
                labelText: fitnessText(context, label),
                labelStyle: const TextStyle(color: FitnessTheme.muted),
                fillColor: const Color(0xFF24272B),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                    key: ValueKey(key),
                    value: value,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    dropdownColor: const Color(0xFF24272B),
                    borderRadius: BorderRadius.circular(14),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                    items: items,
                    onChanged: (value) {
                      if (value != null) onSelected(value);
                    })));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          flex: 3,
          child: picker(
              'Month',
              'body-calendar-month-picker',
              month.month,
              [
                for (var number = 1; number <= 12; number++)
                  DropdownMenuItem(
                      value: number,
                      enabled: !DateTime(month.year, number).isAfter(lastMonth),
                      child: Text(
                          DateFormat.MMMM(locale)
                              .format(DateTime(2000, number)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
              ],
              (number) => onChanged(month.year, number))),
      const SizedBox(width: 12),
      Expanded(
          flex: 2,
          child: picker(
              'Year',
              'body-calendar-year-picker',
              month.year,
              [
                for (var year = lastMonth.year;
                    year >= (month.year < 2000 ? month.year : 2000);
                    year--)
                  DropdownMenuItem(
                      value: year,
                      child: Text(DateFormat.y(locale).format(DateTime(year)),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              (year) => onChanged(year, month.month))),
    ]);
  }
}
