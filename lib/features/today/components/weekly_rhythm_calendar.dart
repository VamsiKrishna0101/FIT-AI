import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/app_date_filter.dart';
import '../../wellness/models/sleep_edit_window.dart';

String rhythmWeekRange(DateTime date, String locale) {
  final monday = sleepWeekStart(date);
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final showYear =
      monday.year != DateTime.now().year || monday.year != sunday.year;
  final format = showYear ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale);
  return '${format.format(monday)} – ${format.format(sunday)}';
}

class WeeklyRhythmCalendarButton extends StatefulWidget {
  final DateTime selectedDate, today;
  final bool allowFuture;
  final ValueChanged<DateTime>? onSelected;
  const WeeklyRhythmCalendarButton({
    super.key,
    required this.selectedDate,
    required this.today,
    this.allowFuture = false,
    this.onSelected,
  });
  @override
  State<WeeklyRhythmCalendarButton> createState() =>
      _WeeklyRhythmCalendarButtonState();
}

class _WeeklyRhythmCalendarButtonState
    extends State<WeeklyRhythmCalendarButton> {
  bool _open = false;
  Future<void> _show() async {
    if (_open || widget.onSelected == null) return;
    setState(() => _open = true);
    try {
      final selected = await showAppCalendarSheet<DateTime>(
          context,
          (_) => WeeklyRhythmCalendar(
              selectedDate: widget.selectedDate,
              today: widget.today,
              allowFuture: widget.allowFuture));
      if (selected != null && mounted) widget.onSelected?.call(selected);
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppDateFilterButton(
      key: const ValueKey('weekly-rhythm-calendar'),
      onPressed: _open || widget.onSelected == null ? null : _show);
}

/// Today and Train share a picker, while retaining their recorded/planned policy.
class WeeklyRhythmCalendar extends StatefulWidget {
  final DateTime selectedDate, today;
  final bool allowFuture;
  const WeeklyRhythmCalendar({
    super.key,
    required this.selectedDate,
    required this.today,
    this.allowFuture = false,
  });
  @override
  State<WeeklyRhythmCalendar> createState() => _WeeklyRhythmCalendarState();
}

class _WeeklyRhythmCalendarState extends State<WeeklyRhythmCalendar> {
  @override
  Widget build(BuildContext context) => AppCalendar(
      selection: AppCalendarSelection(
          mode: AppCalendarMode.week, end: widget.selectedDate),
      today: widget.today,
      allowFuture: widget.allowFuture,
      modes: const {AppCalendarMode.day, AppCalendarMode.week},
      keyPrefix: 'week-calendar',
      dayKeyPrefix: 'week-calendar-day-',
      applyKey: 'week-calendar-view-week',
      closeKey: 'week-calendar-close',
      onApply: (selection) {
        final currentWeek = calendarWeekStart(widget.today);
        final selectedWeek = calendarWeekStart(selection.anchor);
        final date = selection.mode == AppCalendarMode.day
            ? selection.end
            : selectedWeek == currentWeek
                ? calendarDay(widget.today)
                : selectedWeek;
        Navigator.pop(context, date);
      });
}
