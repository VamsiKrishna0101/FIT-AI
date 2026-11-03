import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/app_date_filter.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../models/body_map_models.dart';

String bodyDateRangeLabel(BuildContext context, DateTime start, DateTime end) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final showYear = start.year != DateTime.now().year || end.year != start.year;
  final format = showYear ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale);
  return '${format.format(start)} – ${format.format(end)}';
}

String bodySelectionLabel(BuildContext context, BodyDateSelection selection) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final today = calendarDay(DateTime.now());
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
    return bodyDateRangeLabel(
        context, selection.start ?? selection.end, selection.end);
  }
  return selection.end == today
      ? fitnessText(context, 'Today')
      : date(selection.end);
}

Future<BodyDateSelection?> showBodyDateFilter(
  BuildContext context, {
  required BodyDateSelection selection,
  bool planned = false,
  bool rangeOnly = false,
  DateTime? today,
  String? title,
}) =>
    showAppCalendarSheet<BodyDateSelection>(
        context,
        (_) => BodyCalendar(
            selection: selection,
            planned: planned,
            rangeOnly: rangeOnly,
            today: today,
            title: title));

class BodyCalendar extends StatefulWidget {
  final BodyDateSelection selection;
  final bool planned, rangeOnly;
  final DateTime? today;
  final String? title;
  const BodyCalendar({
    super.key,
    required this.selection,
    this.planned = false,
    this.rangeOnly = false,
    this.today,
    this.title,
  });
  @override
  State<BodyCalendar> createState() => _BodyCalendarState();
}

class _BodyCalendarState extends State<BodyCalendar> {
  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final mode = widget.planned
        ? AppCalendarMode.week
        : switch (selection.mode) {
            BodyDateMode.day => AppCalendarMode.day,
            BodyDateMode.days => AppCalendarMode.days,
            BodyDateMode.range => AppCalendarMode.range,
            BodyDateMode.all => AppCalendarMode.all,
          };
    return AppCalendar(
      selection: AppCalendarSelection(
          mode: mode,
          start: selection.start,
          end: selection.end,
          dates: selection.dates,
          anchor: widget.planned
              ? selection.start ?? selection.end
              : selection.end),
      today: widget.today ?? DateTime.now(),
      allowFuture: widget.planned,
      modes: widget.planned
          ? const {AppCalendarMode.week}
          : widget.rangeOnly
              ? const {AppCalendarMode.range}
              : const {
                  AppCalendarMode.day,
                  AppCalendarMode.week,
                  AppCalendarMode.days,
                  AppCalendarMode.range,
                  AppCalendarMode.all
                },
      title: widget.title ?? 'Calendar',
      keyPrefix: 'body-calendar',
      dayKeyPrefix: 'body-calendar-',
      applyKey: 'body-calendar-apply',
      closeKey: 'body-calendar-close',
      onApply: (result) => Navigator.pop(
          context,
          BodyDateSelection(
            mode: switch (result.mode) {
              AppCalendarMode.day => BodyDateMode.day,
              AppCalendarMode.days => BodyDateMode.days,
              AppCalendarMode.all => BodyDateMode.all,
              _ => BodyDateMode.range,
            },
            start: result.start,
            end: result.end,
            dates: result.dates,
          )),
    );
  }
}
