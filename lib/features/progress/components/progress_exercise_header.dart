import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../body_scan/models/body_map_models.dart';
import '../../body_scan/views/widgets/body_calendar.dart';
import '../models/progress_chart_data.dart';

BodyDateSelection progressExerciseSelection(
    String period, Map<String, dynamic> query) {
  final end = DateTime.tryParse('${query['end'] ?? query['date'] ?? ''}') ??
      DateUtils.dateOnly(DateTime.now());
  final dates = (query['dates']?.toString().split(',') ?? <String>[])
      .map(DateTime.tryParse)
      .whereType<DateTime>()
      .toSet()
      .toList()
    ..sort();
  if (dates.isNotEmpty) {
    return BodyDateSelection(
        mode: dates.length == 1 ? BodyDateMode.day : BodyDateMode.days,
        end: dates.last,
        dates: dates);
  }
  if (period == 'all') {
    return BodyDateSelection(mode: BodyDateMode.all, end: end);
  }
  final days = {'4w': 28, '3m': 90, '1y': 365}[period] ?? 1;
  return BodyDateSelection(
      mode: BodyDateMode.range,
      start: DateTime.tryParse('${query['start'] ?? ''}') ??
          DateTime(end.year, end.month, end.day - days + 1),
      end: end);
}

Map<String, dynamic> progressExerciseQuery(
        BodyDateSelection selection, Map<String, dynamic> base) =>
    {
      ...(Map<String, dynamic>.from(base)
        ..remove('start')
        ..remove('end')
        ..remove('dates')
        ..remove('date')),
      ...progressSelectionQuery(selection),
      'dataset': base['dataset'] ?? 'real',
    };

Future<BodyDateSelection?> showProgressExerciseCalendar(
        BuildContext context, BodyDateSelection selection) =>
    showModalBottomSheet<BodyDateSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            BodyCalendar(selection: selection, title: 'Progress dates'));

/// The same quiet header and calendar used by the Progress overview.
class ProgressExerciseHeader extends StatelessWidget {
  final String title, rangeLabel;
  final VoidCallback onCalendar;
  const ProgressExerciseHeader(
      {super.key,
      required this.title,
      required this.rangeLabel,
      required this.onCalendar});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
      child: Row(children: [
        IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(CupertinoIcons.chevron_left,
                size: 20, color: DSColors.silver)),
        const SizedBox(width: 6),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  letterSpacing: -.4)),
          const SizedBox(height: 5),
          Text(rangeLabel,
              style: const TextStyle(
                  color: DSColors.muted, fontSize: 11, height: 1.4)),
        ])),
        const SizedBox(width: 12),
        IconButton(
            key: const ValueKey('exercise-progress-calendar'),
            tooltip: fitnessText(context, 'Calendar'),
            onPressed: onCalendar,
            style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: const Color(0xFF17191C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13))),
            icon: const Icon(CupertinoIcons.calendar,
                size: 19, color: DSColors.silver)),
      ]));
}
