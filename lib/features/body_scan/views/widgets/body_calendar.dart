import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_map_models.dart';

String bodySelectionLabel(BuildContext context, BodyDateSelection selection) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  String date(DateTime d) => DateFormat.MMMd(locale).format(d);
  final today = DateUtils.dateOnly(DateTime.now());
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
    return '${date(selection.start!)} – ${date(selection.end)}';
  }
  return selection.end == today
      ? fitnessText(context, 'Today')
      : date(selection.end);
}

class BodyCalendar extends StatefulWidget {
  final BodyDateSelection selection;
  const BodyCalendar({super.key, required this.selection});
  @override
  State<BodyCalendar> createState() => _BodyCalendarState();
}

class _BodyCalendarState extends State<BodyCalendar> {
  late DateTime _month;
  late BodyDateMode _mode;
  late Set<DateTime> _days;
  DateTime? _start, _end;
  DateTime get _today => DateUtils.dateOnly(DateTime.now());
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
  }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: FitnessText('Training dates',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.4))),
                      IconButton(
                          tooltip: fitnessText(context, 'Close'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(CupertinoIcons.xmark, size: 17)),
                    ]),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final preset in ['Today', 'This week', 'All time'])
                        ActionChip(
                            backgroundColor: const Color(0xFF2A2A2A),
                            side: BorderSide.none,
                            label: FitnessText(preset,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => setState(() {
                                  _month = DateTime(_today.year, _today.month);
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
                            onSelected: (_) => setState(() {
                                  _mode = pair.$1;
                                  _days = {};
                                  _start = null;
                                  _end = null;
                                })),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      IconButton(
                          tooltip: fitnessText(context, 'Previous month'),
                          onPressed: _month.year <= 2000 && _month.month == 1
                              ? null
                              : () => setState(() => _month =
                                  DateTime(_month.year, _month.month - 1)),
                          icon: const Icon(CupertinoIcons.chevron_left,
                              size: 17)),
                      Expanded(
                          child: Text(DateFormat.yMMMM(locale).format(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500))),
                      IconButton(
                          tooltip: fitnessText(context, 'Next month'),
                          onPressed: _month.year == _today.year &&
                                  _month.month == _today.month
                              ? null
                              : () => setState(() => _month =
                                  DateTime(_month.year, _month.month + 1)),
                          icon: const Icon(CupertinoIcons.chevron_right,
                              size: 17)),
                    ]),
                    Row(children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                            child: Text(
                                DateFormat.E(locale)
                                    .format(DateTime(2026, 10, 26 + i)),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10, color: FitnessTheme.muted)))
                    ]),
                    const SizedBox(height: 6),
                    for (var row = 0; row < rows; row++)
                      Row(children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(child: Builder(builder: (context) {
                            final number = row * 7 + col - offset + 1;
                            if (number < 1 || number > count) {
                              return const SizedBox(height: 44);
                            }
                            final day =
                                DateTime(_month.year, _month.month, number);
                            final selected = _selected(day);
                            return Semantics(
                              selected: selected,
                              label: DateFormat.yMMMMEEEEd(locale).format(day),
                              child: TextButton(
                                  key: ValueKey(
                                      'body-calendar-${day.toIso8601String().substring(0, 10)}'),
                                  onPressed: day.isAfter(_today)
                                      ? null
                                      : () => _tap(day),
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(44, 44),
                                      backgroundColor: selected
                                          ? FitnessTheme.silver
                                          : Colors.transparent,
                                      foregroundColor: selected
                                          ? Colors.black
                                          : Colors.white,
                                      shape: const CircleBorder()),
                                  child: Text('$number',
                                      style: const TextStyle(fontSize: 13))),
                            );
                          })),
                      ]),
                    const SizedBox(height: 12),
                    if (_selection case final selection?)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(bodySelectionLabel(context, selection),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                    FilledButton(
                        onPressed: _selection == null
                            ? null
                            : () => Navigator.pop(context, _selection),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: FitnessTheme.silver,
                            foregroundColor: Colors.black),
                        child: const FitnessText('Apply')),
                  ]),
            )));
  }
}
