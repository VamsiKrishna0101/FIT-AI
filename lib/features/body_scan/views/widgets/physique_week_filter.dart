import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';

// Calendar arithmetic keeps Mondays at local midnight across European DST.
DateTime physiqueWeekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);
DateTime physiqueWeekShift(DateTime monday, int weeks) =>
    DateTime(monday.year, monday.month, monday.day + weeks * 7);

String physiqueWeekLabel(BuildContext context, DateTime week) {
  final end = DateTime(week.year, week.month, week.day + 6);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return '${DateFormat.MMMd(locale).format(week)} – ${DateFormat.yMMMd(locale).format(end)}';
}

Future<DateTime?> showPhysiqueWeekPicker(BuildContext context,
    {required DateTime selected, DateTime? now}) {
  final current = physiqueWeekStart(now ?? DateTime.now());
  // Future scheduled weeks and two years of history; every row is a full week.
  final weeks = [
    for (var offset = 12; offset >= -104; offset--)
      physiqueWeekShift(current, offset)
  ];
  final index = weeks.indexWhere((week) => week == physiqueWeekStart(selected));
  return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: FitnessTheme.surface,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _PhysiqueWeekPicker(
          weeks: weeks,
          selected: physiqueWeekStart(selected),
          initialIndex: index < 0 ? 12 : index));
}

class _PhysiqueWeekPicker extends StatefulWidget {
  final List<DateTime> weeks;
  final DateTime selected;
  final int initialIndex;
  const _PhysiqueWeekPicker(
      {required this.weeks,
      required this.selected,
      required this.initialIndex});
  @override
  State<_PhysiqueWeekPicker> createState() => _PhysiqueWeekPickerState();
}

class _PhysiqueWeekPickerState extends State<_PhysiqueWeekPicker> {
  late final ScrollController _controller =
      ScrollController(initialScrollOffset: widget.initialIndex * 72.0);
  final _search = TextEditingController();
  String _query = '';

  bool _matches(DateTime week, String locale) {
    if (_query.trim().isEmpty) return true;
    final thursday = DateTime.utc(week.year, week.month, week.day + 3);
    final number =
        thursday.difference(DateTime.utc(thursday.year)).inDays ~/ 7 + 1;
    final terms = <String>['week $number week$number w$number'];
    for (var day = 0; day < 7; day++) {
      final date = DateTime(week.year, week.month, week.day + day);
      terms.add(
          DateFormat('yyyy-MM-dd dd/MM/yyyy d MMMM yyyy', locale).format(date));
      terms.add(DateFormat('d MMMM MMM yyyy', 'en').format(date));
    }
    final searchable = terms.join(' ').toLowerCase();
    return _query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(searchable.contains);
  }

  void _filter(String value) {
    setState(() => _query = value);
    if (_controller.hasClients) _controller.jumpTo(0);
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weeks = widget.weeks.where((week) => _matches(week, locale)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: FitnessText('Choose a week',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
            const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: FitnessText('Monday to Sunday · Select a whole week',
                    style: TextStyle(fontSize: 12, color: FitnessTheme.muted))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: CupertinoSearchTextField(
                key: const ValueKey('physique-week-search'),
                controller: _search,
                placeholder: 'Month, year, date or week number',
                placeholderStyle:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted),
                style:
                    const TextStyle(fontSize: 14, color: FitnessTheme.silver),
                backgroundColor: Colors.white.withValues(alpha: .06),
                onChanged: _filter,
              ),
            ),
            Expanded(
                child: weeks.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const FitnessText('No matching weeks',
                            style: TextStyle(color: FitnessTheme.muted)),
                        TextButton(
                            onPressed: () {
                              _search.clear();
                              _filter('');
                            },
                            child: const FitnessText('Clear search')),
                      ]))
                    : ListView.builder(
                        controller: _controller,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemExtent: 72,
                        itemCount: weeks.length,
                        itemBuilder: (context, index) {
                          final week = weeks[index];
                          final active = week == widget.selected;
                          return ListTile(
                            key: ValueKey(
                                'physique-week-${CacheScope.todayKey(week)}'),
                            selected: active,
                            selectedTileColor:
                                Colors.white.withValues(alpha: .05),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            leading: const Icon(CupertinoIcons.calendar,
                                size: 20, color: FitnessTheme.muted),
                            title: FitnessText(physiqueWeekLabel(context, week),
                                style: const TextStyle(
                                    fontSize: 13, color: FitnessTheme.silver)),
                            trailing: active
                                ? const Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    size: 20,
                                    color: FitnessTheme.silver)
                                : null,
                            onTap: () => Navigator.pop(context, week),
                          );
                        })),
          ])),
    );
  }
}

class PhysiqueWeekFilter extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final DateTime? now;
  const PhysiqueWeekFilter(
      {super.key, required this.selected, required this.onChanged, this.now});
  @override
  Widget build(BuildContext context) {
    final current = physiqueWeekStart(now ?? DateTime.now());
    final week = physiqueWeekStart(selected);
    final last = physiqueWeekShift(current, -1);
    final custom = week != current && week != last;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (final item in [
          ('This week', week == current),
          ('Last week', week == last),
          ('Custom', custom)
        ])
          ChoiceChip(
            key: ValueKey('physique-filter-${item.$1}'),
            label: FitnessText(item.$1, style: const TextStyle(fontSize: 12)),
            selected: item.$2,
            showCheckmark: false,
            selectedColor: FitnessTheme.silver,
            backgroundColor: FitnessTheme.surface,
            side: const BorderSide(color: FitnessTheme.line),
            labelStyle: TextStyle(
                color: item.$2 ? FitnessTheme.canvas : FitnessTheme.silver),
            onSelected: (_) async {
              if (item.$1 == 'Custom') {
                final chosen = await showPhysiqueWeekPicker(context,
                    selected: week, now: now);
                if (chosen != null && context.mounted) onChanged(chosen);
              } else {
                onChanged(item.$1 == 'This week' ? current : last);
              }
            },
          ),
      ]),
      const SizedBox(height: 10),
      FitnessText(physiqueWeekLabel(context, week),
          style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
    ]);
  }
}
