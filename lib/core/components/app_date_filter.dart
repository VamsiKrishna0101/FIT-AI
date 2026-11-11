import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../localization/fitness_copy.dart';
import '../localization/fitness_text.dart';
import '../theme/ds_motion.dart';
import '../theme/fitness_theme.dart';

DateTime calendarDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime calendarWeekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - d.weekday + 1);
String calendarDateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

enum AppCalendarMode { day, week, days, range, all }

class AppCalendarSelection {
  final AppCalendarMode mode;
  final DateTime? start;
  final DateTime end, anchor;
  final List<DateTime> dates;
  AppCalendarSelection({
    required this.mode,
    required DateTime end,
    DateTime? start,
    DateTime? anchor,
    List<DateTime> dates = const [],
  })  : end = calendarDay(end),
        start = start == null ? null : calendarDay(start),
        anchor = calendarDay(anchor ?? end),
        dates =
            List.unmodifiable(dates.map(calendarDay).toSet().toList()..sort());
}

/// The same accessible, compact trigger on every dashboard tab.
class AppDateFilterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  const AppDateFilterButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Calendar',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        tooltip: fitnessText(context, tooltip),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(12),
          foregroundColor: FitnessTheme.silver,
          backgroundColor: const Color(0xFF17191C),
          side: const BorderSide(color: Color(0x24FFFFFF), width: .7),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        icon: const Icon(CupertinoIcons.calendar, size: 18));
  }
}

/// Shared dropdown finish for filter, month, year, and progress time ranges.
class AppFilterDropdown<T> extends StatelessWidget {
  final Key? dropdownKey;
  final T value;
  final String? label;
  final List<DropdownMenuItem<T>> items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final ValueChanged<T>? onChanged;
  const AppFilterDropdown({
    super.key,
    this.dropdownKey,
    required this.value,
    this.label,
    required this.items,
    this.selectedItemBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x24FFFFFF), width: .7));
    final decoration = InputDecoration(
      labelText: label == null ? null : fitnessText(context, label!),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(color: FitnessTheme.muted, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF222428),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0x70FFFFFF), width: .8)),
    );
    final selectedIndex = items.indexWhere((item) => item.value == value);
    final selected = selectedIndex < 0
        ? const SizedBox.shrink()
        : selectedItemBuilder?.call(context)[selectedIndex] ??
            items[selectedIndex].child;
    return LayoutBuilder(builder: (context, constraints) {
      return PopupMenuButton<T>(
        key: dropdownKey,
        tooltip: label == null ? null : fitnessText(context, label!),
        enabled: onChanged != null,
        // No initialValue: it would align the selected option over the field.
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
            maxHeight: 340),
        color: const Color(0xFF222428),
        surfaceTintColor: Colors.transparent,
        menuPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x24FFFFFF), width: .7)),
        onSelected: onChanged,
        itemBuilder: (_) => [
          _FilterOptionsEntry<T>(
              width: constraints.maxWidth, items: items, selected: value),
        ],
        child: InputDecorator(
            decoration: decoration,
            child: DefaultTextStyle.merge(
                style: TextStyle(
                    color: onChanged == null
                        ? FitnessTheme.muted
                        : FitnessTheme.silver,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                child: Row(children: [
                  Expanded(child: selected),
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.chevron_down,
                      size: 12, color: FitnessTheme.muted),
                ]))),
      );
    });
  }
}

/// The popup owns one scrollable list so its scrollbar and paging cue remain
/// visible while the options move. Short lists fit without a scroll cue.
class _FilterOptionsEntry<T> extends PopupMenuEntry<T> {
  final double width;
  final List<DropdownMenuItem<T>> items;
  final T selected;
  const _FilterOptionsEntry(
      {required this.width, required this.items, required this.selected});
  @override
  double get height => 340;
  @override
  bool represents(T? value) => false;
  @override
  State<_FilterOptionsEntry<T>> createState() => _FilterOptionsEntryState<T>();
}

class _FilterOptionsEntryState<T> extends State<_FilterOptionsEntry<T>> {
  final _scroll = ScrollController();
  bool _scrollable = false, _moreBelow = false, _metricsScheduled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_scheduleMetrics);
    _scheduleMetrics();
  }

  void _scheduleMetrics() {
    if (_metricsScheduled) return;
    _metricsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsScheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      final scrollable = _scroll.position.maxScrollExtent > 1;
      final moreBelow = _scroll.position.extentAfter > 1;
      if (scrollable != _scrollable || moreBelow != _moreBelow) {
        setState(() {
          _scrollable = scrollable;
          _moreBelow = moreBelow;
        });
      }
    });
  }

  void _more() {
    final position = _scroll.position;
    final next = (position.pixels +
            position.viewportDimension * (_moreBelow ? .75 : -.75))
        .clamp(0.0, position.maxScrollExtent);
    _scroll.animateTo(next,
        duration: DSMotion.duration(context, DSMotion.fast),
        curve: DSMotion.effects);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: widget.width,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
                fit: FlexFit.loose,
                child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      _scheduleMetrics();
                      return false;
                    },
                    child: RawScrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        thickness: 4,
                        radius: const Radius.circular(3),
                        crossAxisMargin: 4,
                        thumbColor: FitnessTheme.muted,
                        trackColor: const Color(0x18FFFFFF),
                        trackBorderColor: Colors.transparent,
                        child: ListView(
                            controller: _scroll,
                            primary: false,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            children: [
                              for (final item in widget.items)
                                CheckedPopupMenuItem<T>(
                                    value: item.value,
                                    enabled: item.enabled,
                                    checked: item.value == widget.selected,
                                    child: item.child),
                            ])))),
            if (_scrollable) ...[
              const Divider(height: 1, color: Color(0x24FFFFFF)),
              InkWell(
                  onTap: _more,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                    child: FitnessText('More options',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted))),
                                const SizedBox(width: 8),
                                Icon(
                                    _moreBelow
                                        ? CupertinoIcons.chevron_down
                                        : CupertinoIcons.chevron_up,
                                    size: 12,
                                    color: FitnessTheme.muted),
                              ])))),
            ],
          ])));
}

Future<T?> showAppCalendarSheet<T>(
        BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF181A1D),
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          side: BorderSide(color: Color(0x24FFFFFF), width: .7)),
      constraints: BoxConstraints(
          maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .92),
      builder: builder,
    );

/// One calendar layout and draft/apply lifecycle for all dashboard filters.
/// Feature adapters retain their existing API query types and date policies.
class AppCalendar extends StatefulWidget {
  final AppCalendarSelection selection;
  final DateTime today;
  final bool allowFuture;
  final Set<AppCalendarMode> modes;
  final String title, keyPrefix, dayKeyPrefix, applyKey, closeKey;
  final ValueChanged<AppCalendarSelection> onApply;
  const AppCalendar({
    super.key,
    required this.selection,
    required this.today,
    required this.onApply,
    this.allowFuture = false,
    this.modes = const {
      AppCalendarMode.day,
      AppCalendarMode.week,
      AppCalendarMode.days,
      AppCalendarMode.range,
      AppCalendarMode.all,
    },
    this.title = 'Calendar',
    this.keyPrefix = 'app-calendar',
    this.dayKeyPrefix = 'app-calendar-day-',
    this.applyKey = 'app-calendar-apply',
    this.closeKey = 'app-calendar-close',
  }) : assert(modes.length > 0);

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late AppCalendarMode _mode;
  late DateTime _month, _anchor;
  DateTime? _start, _end;
  late Set<DateTime> _days;
  DateTime get _today => calendarDay(widget.today);
  DateTime get _last => widget.allowFuture ? DateTime(2100, 12, 31) : _today;
  DateTime get _lastMonth => DateTime(_last.year, _last.month);
  DateTime _clamp(DateTime d) {
    final day = calendarDay(d);
    return day.isBefore(DateTime(2000))
        ? DateTime(2000)
        : day.isAfter(_last)
            ? _last
            : day;
  }

  @override
  void initState() {
    super.initState();
    final selection = widget.selection;
    _mode = widget.modes.contains(selection.mode)
        ? selection.mode
        : widget.modes.first;
    _anchor = _clamp(selection.anchor);
    _month = DateTime(_anchor.year, _anchor.month);
    _start = selection.start == null ? null : _clamp(selection.start!);
    _end = _clamp(selection.end);
    if (_start != null && _end!.isBefore(_start!)) {
      final previous = _start;
      _start = _end;
      _end = previous;
    }
    _days = selection.dates
        .where((d) => !d.isBefore(DateTime(2000)) && !d.isAfter(_last))
        .map(calendarDay)
        .toSet();
    if (_mode == AppCalendarMode.day && _days.isEmpty) _days.add(_anchor);
  }

  void _browse(int year, int month) => setState(() {
        final requested = DateTime(year, month);
        _month = requested.isAfter(_lastMonth)
            ? _lastMonth
            : requested.isBefore(DateTime(2000))
                ? DateTime(2000)
                : requested;
      });

  void _filter(String value) => setState(() {
        if (value == 'preset-all' || value == 'all') {
          _mode = AppCalendarMode.all;
          _days = {};
          _start = null;
          _end = null;
          return;
        }
        if (value.startsWith('preset-')) {
          _anchor = value == 'preset-last-week'
              ? DateTime(_today.year, _today.month, _today.day - 7)
              : _today;
          _month = DateTime(_anchor.year, _anchor.month);
          if (value == 'preset-today') {
            _mode = AppCalendarMode.day;
            _days = {_today};
          } else if (value == 'preset-this-month') {
            _mode = AppCalendarMode.range;
            _start = DateTime(_today.year, _today.month);
            _end = _today;
          } else if (widget.modes.contains(AppCalendarMode.week)) {
            _mode = AppCalendarMode.week;
          } else {
            _mode = AppCalendarMode.range;
            _start = calendarWeekStart(_anchor);
            final end = DateTime(_start!.year, _start!.month, _start!.day + 6);
            _end = end.isAfter(_today) ? _today : end;
          }
          return;
        }
        final mode = AppCalendarMode.values.byName(value);
        if (mode == _mode) return;
        _mode = mode;
        _days = {};
        _start = null;
        _end = null;
      });

  String? get _activePreset {
    if (_mode == AppCalendarMode.all) return 'preset-all';
    if (_mode == AppCalendarMode.day &&
        _days.length == 1 &&
        _days.contains(_today)) {
      return 'preset-today';
    }
    final currentWeekStart = calendarWeekStart(_today);
    final lastWeekAnchor = DateTime(_today.year, _today.month, _today.day - 7);
    final lastWeekStart = calendarWeekStart(lastWeekAnchor);
    if (_mode == AppCalendarMode.week) {
      final anchorWeek = calendarWeekStart(_anchor);
      if (anchorWeek == currentWeekStart) return 'preset-this-week';
      if (anchorWeek == lastWeekStart) return 'preset-last-week';
    }
    if (_mode == AppCalendarMode.range) {
      final currentWeekSunday = DateTime(currentWeekStart.year,
          currentWeekStart.month, currentWeekStart.day + 6);
      final currentWeekEnd = widget.allowFuture
          ? currentWeekSunday
          : (currentWeekSunday.isAfter(_today) ? _today : currentWeekSunday);
      if (_start == currentWeekStart && _end == currentWeekEnd) {
        return 'preset-this-week';
      }
      final lastWeekSunday = DateTime(
          lastWeekStart.year, lastWeekStart.month, lastWeekStart.day + 6);
      final lastWeekEnd =
          lastWeekSunday.isAfter(_today) ? _today : lastWeekSunday;
      if (_start == lastWeekStart && _end == lastWeekEnd) {
        return 'preset-last-week';
      }
      if (_start == DateTime(_today.year, _today.month) && _end == _today) {
        return 'preset-this-month';
      }
    }
    return null;
  }

  Widget _buildPresetPills(
      BuildContext context, Map<String, String> presets) {
    if (presets.isEmpty) return const SizedBox.shrink();
    final active = _activePreset;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in presets.entries) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                selected: active == entry.key,
                child: InkWell(
                  key: ValueKey('${widget.keyPrefix}-pill-${entry.key}'),
                  onTap: () => _filter(entry.key),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active == entry.key
                          ? FitnessTheme.silver
                          : const Color(0xFF222428),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active == entry.key
                            ? FitnessTheme.silver
                            : const Color(0x24FFFFFF),
                        width: .7,
                      ),
                    ),
                    child: FitnessText(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active == entry.key
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: active == entry.key
                            ? Colors.black
                            : FitnessTheme.silver,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _tap(DateTime date) {
    if (date.isBefore(DateTime(2000)) || date.isAfter(_last)) return;
    setState(() {
      _anchor = date;
      if (_mode == AppCalendarMode.all) _mode = AppCalendarMode.day;
      switch (_mode) {
        case AppCalendarMode.day:
          _days = {date};
        case AppCalendarMode.days:
          if (!_days.remove(date) && _days.length < 366) _days.add(date);
        case AppCalendarMode.range:
          if (_start == null || _end != null) {
            _start = date;
            _end = null;
          } else {
            _end = date.isBefore(_start!) ? _start : date;
            if (date.isBefore(_start!)) _start = date;
          }
        case AppCalendarMode.week:
          break;
        case AppCalendarMode.all:
          break;
      }
    });
  }

  AppCalendarSelection? get _selection {
    if (_mode == AppCalendarMode.all) {
      return AppCalendarSelection(mode: _mode, end: _today);
    }
    if (_mode == AppCalendarMode.week) {
      final start = calendarWeekStart(_anchor);
      final end = DateTime(start.year, start.month, start.day + 6);
      return AppCalendarSelection(
          mode: _mode,
          start: start,
          end: end.isAfter(_last) ? _last : end,
          anchor: _anchor);
    }
    if (_mode == AppCalendarMode.range) {
      if (_start == null) return null;
      return AppCalendarSelection(
          mode: _mode, start: _start, end: _end ?? _start!);
    }
    final days = _days.toList()..sort();
    return days.isEmpty
        ? null
        : AppCalendarSelection(mode: _mode, end: days.last, dates: days);
  }

  bool _selected(DateTime date) {
    if (_mode == AppCalendarMode.day || _mode == AppCalendarMode.days) {
      return _days.contains(date);
    }
    final selection = _selection;
    return _mode != AppCalendarMode.all &&
        selection?.start != null &&
        !date.isBefore(selection!.start!) &&
        !date.isAfter(selection.end);
  }

  String _summary(BuildContext context) {
    final selection = _selection;
    if (selection == null) return fitnessText(context, 'Choose dates');
    if (_mode == AppCalendarMode.all) return fitnessText(context, 'All time');
    if (_mode == AppCalendarMode.days && selection.dates.length > 1) {
      return fitnessText(context, '{count} days',
          values: {'count': selection.dates.length});
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    String format(DateTime d) => (d.year != _today.year
            ? DateFormat.yMMMd(locale)
            : DateFormat.MMMd(locale))
        .format(d);
    if (selection.start != null && selection.start != selection.end) {
      return '${format(selection.start!)} – ${format(selection.end)}';
    }
    return selection.end == _today
        ? fitnessText(context, 'Today')
        : format(selection.end);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = calendarWeekStart(_month);
    final rows =
        ((DateTime(_month.year, _month.month + 1, 0).day + _month.weekday - 1) /
                7)
            .ceil();
    final height = (MediaQuery.textScalerOf(context).scale(13) + 24)
        .clamp(44.0, double.infinity);
    const labels = {
      AppCalendarMode.day: 'Single day',
      AppCalendarMode.week: 'Week',
      AppCalendarMode.days: 'Multiple days',
      AppCalendarMode.range: 'Date range',
      AppCalendarMode.all: 'All time',
    };
    final presets = <String, String>{
      if (widget.modes.length > 1) ...{
        if (widget.modes.contains(AppCalendarMode.day)) 'preset-today': 'Today',
        if (widget.modes.contains(AppCalendarMode.week) ||
            widget.modes.contains(AppCalendarMode.range))
          'preset-this-week': 'This week',
        if (!widget.allowFuture) ...{
          if (widget.modes.contains(AppCalendarMode.week) ||
              widget.modes.contains(AppCalendarMode.range))
            'preset-last-week': 'Last week',
          if (widget.modes.contains(AppCalendarMode.range))
            'preset-this-month': 'This month',
          if (widget.modes.contains(AppCalendarMode.all))
            'preset-all': 'All time',
        },
      },
    };
    final filters = <String, String>{
      for (final mode in widget.modes) mode.name: labels[mode]!,
    };
    DropdownMenuItem<String> option(
            String value, String label) =>
        DropdownMenuItem(
            value: value,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FitnessText(label,
                    maxLines: 2, overflow: TextOverflow.ellipsis)));
    return FitnessTheme(
        child: Material(
            color: const Color(0xFF181A1D),
            child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 34,
                            height: 4,
                            margin: const EdgeInsets.only(top: 10, bottom: 10),
                            decoration: BoxDecoration(
                                color: const Color(0x40FFFFFF),
                                borderRadius: BorderRadius.circular(3)))),
                    Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: FitnessText(widget.title,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -.4))),
                                  IconButton(
                                      key: ValueKey(widget.closeKey),
                                      tooltip: fitnessText(context, 'Close'),
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(CupertinoIcons.xmark,
                                          size: 17)),
                                ]),
                                if (presets.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _buildPresetPills(context, presets),
                                ],
                                const SizedBox(height: 14),
                                AppFilterDropdown<String>(
                                  dropdownKey:
                                      ValueKey('${widget.keyPrefix}-filter'),
                                  label: 'Selection mode',
                                  value: _mode.name,
                                  items: [
                                    for (final entry in filters.entries)
                                      option(entry.key, entry.value),
                                  ],
                                  selectedItemBuilder: (_) => [
                                    for (final label in filters.values)
                                      FitnessText(label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                  onChanged: _filter,
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(builder: (context, constraints) {
                                  final stacked = constraints.maxWidth < 350 &&
                                      MediaQuery.textScalerOf(context)
                                              .scale(14) >
                                          20;
                                  final width = constraints.maxWidth - 12;
                                  return Wrap(
                                      spacing: 12,
                                      runSpacing: 16,
                                      children: [
                                        SizedBox(
                                            width: stacked
                                                ? constraints.maxWidth
                                                : width * .58,
                                            child: AppFilterDropdown<int>(
                                                dropdownKey: ValueKey(
                                                    '${widget.keyPrefix}-month-picker'),
                                                label: 'Month',
                                                value: _month.month,
                                                items: [
                                                  for (var m = 1; m <= 12; m++)
                                                    DropdownMenuItem(
                                                        value: m,
                                                        enabled: !DateTime(
                                                                _month.year, m)
                                                            .isAfter(
                                                                _lastMonth),
                                                        child: Text(
                                                            DateFormat.MMMM(
                                                                    locale)
                                                                .format(
                                                                    DateTime(
                                                                        2000,
                                                                        m)),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis))
                                                ],
                                                onChanged: (month) => _browse(
                                                    _month.year, month))),
                                        SizedBox(
                                            width: stacked
                                                ? constraints.maxWidth
                                                : width * .42,
                                            child: AppFilterDropdown<int>(
                                                dropdownKey: ValueKey(
                                                    '${widget.keyPrefix}-year-picker'),
                                                label: 'Year',
                                                value: _month.year,
                                                items: [
                                                  for (var y = _last.year;
                                                      y >= 2000;
                                                      y--)
                                                    DropdownMenuItem(
                                                        value: y,
                                                        child: Text(
                                                            DateFormat.y(locale)
                                                                .format(
                                                                    DateTime(
                                                                        y)),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis))
                                                ],
                                                onChanged: (year) => _browse(
                                                    year, _month.month))),
                                      ]);
                                }),
                                const SizedBox(height: 20),
                                Row(children: [
                                  for (var i = 0; i < 7; i++)
                                    Expanded(
                                        child: Text(
                                            DateFormat.E(locale).format(
                                                DateTime(2024, 1, 1 + i)),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: FitnessTheme.muted)))
                                ]),
                                const SizedBox(height: 8),
                                for (var row = 0; row < rows; row++)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(children: [
                                      for (var col = 0; col < 7; col++)
                                        Expanded(
                                            child: Builder(builder: (context) {
                                          final day = DateTime(
                                              first.year,
                                              first.month,
                                              first.day + row * 7 + col);
                                          final available =
                                              !day.isBefore(DateTime(2000)) &&
                                                  !day.isAfter(_last);
                                          final selected = _selected(day);
                                          final foreground = selected
                                              ? Colors.black
                                              : day.month == _month.month
                                                  ? FitnessTheme.silver
                                                  : FitnessTheme.muted;
                                          return Semantics(
                                              button: true,
                                              enabled: available,
                                              selected: selected,
                                              onTap: available
                                                  ? () => _tap(day)
                                                  : null,
                                              label:
                                                  DateFormat.yMMMMEEEEd(locale)
                                                      .format(day),
                                              excludeSemantics: true,
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  child: TextButton(
                                                    key: ValueKey(
                                                        '${widget.dayKeyPrefix}${calendarDateKey(day)}'),
                                                    onPressed: available
                                                        ? () => _tap(day)
                                                        : null,
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize:
                                                          Size(0, height),
                                                      backgroundColor: selected
                                                          ? FitnessTheme.silver
                                                          : Colors.transparent,
                                                      foregroundColor:
                                                          foreground,
                                                      disabledForegroundColor:
                                                          const Color(
                                                              0xFF62666C),
                                                      shape:
                                                          const CircleBorder(),
                                                      side: day == _today &&
                                                              !selected
                                                          ? const BorderSide(
                                                              color: Color(
                                                                  0x60FFFFFF),
                                                              width: .7)
                                                          : BorderSide.none,
                                                    ),
                                                    child: Text('${day.day}',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                selected ||
                                                                        day ==
                                                                            _today
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .w400)),
                                                  )));
                                        }))
                                    ]),
                                  ),
                                const SizedBox(height: 18),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF121416),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: const Color(0x18FFFFFF),
                                            width: .7)),
                                    child: Text(_summary(context),
                                        key: ValueKey(
                                            '${widget.keyPrefix}-selected-range'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: FitnessTheme.silver))),
                              ]),
                        )),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                        child: FilledButton(
                          key: ValueKey(widget.applyKey),
                          onPressed: _selection == null
                              ? null
                              : () => widget.onApply(_selection!),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: FitnessTheme.silver,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: const FitnessText('Apply',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        )),
                  ],
                ))));
  }
}
