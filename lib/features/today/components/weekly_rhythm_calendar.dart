import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../wellness/models/sleep_edit_window.dart';

String rhythmWeekRange(DateTime date, String locale) {
  final monday = sleepWeekStart(date);
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final start = DateFormat.MMMd(locale).format(monday);
  final end = DateFormat.MMMd(locale).format(sunday);
  return '$start – $end';
}

class WeeklyRhythmCalendarButton extends StatefulWidget {
  final DateTime selectedDate, today;
  final bool allowFuture;
  final ValueChanged<DateTime>? onSelected;
  const WeeklyRhythmCalendarButton(
      {super.key,
      required this.selectedDate,
      required this.today,
      this.allowFuture = false,
      this.onSelected});

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
      final week = await showModalBottomSheet<DateTime>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: DSColors.bgElevated,
          sheetAnimationStyle: DSMotion.sheetStyle(context),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              side: BorderSide(color: DSColors.border)),
          builder: (_) => FitnessTheme(
              child: WeeklyRhythmCalendar(
                  selectedDate: widget.selectedDate,
                  today: widget.today,
                  allowFuture: widget.allowFuture)));
      if (week != null && mounted) widget.onSelected?.call(week);
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
      key: const ValueKey('weekly-rhythm-calendar'),
      onPressed: _open || widget.onSelected == null ? null : _show,
      tooltip: fitnessText(context, 'Calendar'),
      style: IconButton.styleFrom(
          backgroundColor: DSColors.bgElevated,
          foregroundColor: DSColors.silver,
          disabledForegroundColor: DSColors.muted,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.all(8),
          side: const BorderSide(color: DSColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      icon: const Icon(CupertinoIcons.calendar, size: 17));
}

/// Monday-first calendar. A selection always represents a complete week.
class WeeklyRhythmCalendar extends StatefulWidget {
  final DateTime selectedDate, today;
  final bool allowFuture;
  const WeeklyRhythmCalendar(
      {super.key,
      required this.selectedDate,
      required this.today,
      this.allowFuture = false});
  @override
  State<WeeklyRhythmCalendar> createState() => _WeeklyRhythmCalendarState();
}

class _WeeklyRhythmCalendarState extends State<WeeklyRhythmCalendar> {
  late DateTime _week, _month;
  DateTime get _today => DateUtils.dateOnly(widget.today);
  DateTime get _currentWeek => sleepWeekStart(_today);
  String copy(String text) => fitnessText(context, text);

  @override
  void initState() {
    super.initState();
    final selected = !widget.allowFuture && widget.selectedDate.isAfter(_today)
        ? _today
        : widget.selectedDate;
    _week = sleepWeekStart(selected);
    _month = DateTime(selected.year, selected.month);
  }

  void _moveMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Widget _day(DateTime date, bool selected, double height, String locale) {
    final available = (widget.allowFuture || !date.isAfter(_today)) &&
        !date.isBefore(DateTime(2000));
    final today = DateUtils.isSameDay(date, _today);
    final currentMonth = date.month == _month.month;
    final foreground = selected
        ? available
            ? DSColors.bg
            : const Color(0xFF999999)
        : available && currentMonth
            ? Colors.white
            : const Color(0xFF626262);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return Expanded(
        child: Semantics(
            button: true,
            enabled: available,
            selected: selected,
            label: DateFormat.yMMMMEEEEd(locale).format(date),
            excludeSemantics: true,
            child: InkWell(
                key: ValueKey('week-calendar-day-$dateKey'),
                onTap: !available
                    ? null
                    : () => setState(() => _week = sleepWeekStart(date)),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                    height: height,
                    child: Center(
                        child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            padding: const EdgeInsets.symmetric(
                                vertical: 3, horizontal: 2),
                            alignment: Alignment.center,
                            decoration: today
                                ? BoxDecoration(
                                    color: selected
                                        ? DSColors.bg
                                        : DSColors.bgRaised,
                                    borderRadius: BorderRadius.circular(10))
                                : null,
                            child: Text('${date.day}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected || today
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: today && selected
                                        ? Colors.white
                                        : foreground))))))));
  }

  Widget _grid(String locale) {
    final first = sleepWeekStart(_month);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final rows = ((last.day + _month.weekday - 1) / 7).ceil();
    final height = (MediaQuery.textScalerOf(context).scale(14) + 24)
        .clamp(44.0, double.infinity);
    return Column(children: [
      Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
              child: Center(
                  child: Text(
                      DateFormat.E(locale).format(DateTime(_currentWeek.year,
                          _currentWeek.month, _currentWeek.day + i)),
                      style: const TextStyle(
                          fontSize: 10, color: DSColors.muted))))
      ]),
      const SizedBox(height: 10),
      for (var row = 0; row < rows; row++)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Builder(builder: (context) {
              final start =
                  DateTime(first.year, first.month, first.day + row * 7);
              final selected = DateUtils.isSameDay(start, _week);
              return Material(
                  color: selected ? DSColors.silver : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    for (var day = 0; day < 7; day++)
                      _day(DateTime(start.year, start.month, start.day + day),
                          selected, height, locale)
                  ]));
            })),
    ]);
  }

  void _thisWeek() => setState(() {
        _week = _currentWeek;
        _month = DateTime(_today.year, _today.month);
      });

  Widget _header() {
    final title = Text(copy('Choose a week'),
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.5));
    final close = TextButton(
        key: const ValueKey('week-calendar-close'),
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: DSColors.muted),
        child: Text(copy('Close'), style: const TextStyle(fontSize: 12)));
    if (MediaQuery.textScalerOf(context).scale(12) > 18) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerRight, child: close),
        title,
      ]);
    }
    return Row(
        children: [Expanded(child: title), const SizedBox(width: 8), close]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final current = DateUtils.isSameDay(_week, _currentWeek);
    final currentMonth = DateTime(_today.year, _today.month);
    final canNext = widget.allowFuture || _month.isBefore(currentMonth);
    Widget navigation(String text, String key, VoidCallback? action,
            {bool highlighted = false}) =>
        Expanded(
            child: TextButton(
                key: ValueKey(key),
                onPressed: action,
                style: TextButton.styleFrom(
                    foregroundColor: DSColors.silver,
                    disabledForegroundColor: const Color(0xFF626262),
                    backgroundColor:
                        highlighted ? DSColors.bgRaised : Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(copy(text),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500))));
    return SafeArea(
        top: false,
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 12),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                              color: DSColors.bgRaised,
                              borderRadius: BorderRadius.circular(4)))),
                  Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(),
                                const SizedBox(height: 24),
                                Text(DateFormat.yMMMM(locale).format(_month),
                                    key: const ValueKey('week-calendar-month'),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -.3)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  navigation(
                                      'Previous',
                                      'week-calendar-previous-month',
                                      _month.isAfter(DateTime(2000))
                                          ? () => _moveMonth(-1)
                                          : null),
                                  const SizedBox(width: 6),
                                  navigation('This week',
                                      'week-calendar-this-week', _thisWeek,
                                      highlighted:
                                          current && _month == currentMonth),
                                  const SizedBox(width: 6),
                                  navigation('Next', 'week-calendar-next-month',
                                      canNext ? () => _moveMonth(1) : null),
                                ]),
                                const SizedBox(height: 22),
                                _grid(locale),
                                const SizedBox(height: 22),
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: DSColors.bgInset,
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            Border.all(color: DSColors.border)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(rhythmWeekRange(_week, locale),
                                              key: const ValueKey(
                                                  'week-calendar-selected-range'),
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4)),
                                          const SizedBox(height: 5),
                                          Text(
                                              copy(current
                                                  ? 'This week'
                                                  : 'Sleep · Read-only'),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  height: 1.4,
                                                  color: DSColors.muted)),
                                        ])),
                              ]))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: FilledButton(
                          key: const ValueKey('week-calendar-view-week'),
                          onPressed: () =>
                              Navigator.pop(context, current ? _today : _week),
                          style: FilledButton.styleFrom(
                              backgroundColor: DSColors.silver,
                              foregroundColor: DSColors.bg,
                              minimumSize: const Size(0, 54),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18))),
                          child: Text(copy('View week'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)))),
                ])));
  }
}
