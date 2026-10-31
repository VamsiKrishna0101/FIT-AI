import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_workout_history.dart';

class ExerciseProgressContent extends StatefulWidget {
  const ExerciseProgressContent(
      {super.key,
      required this.data,
      this.onMore,
      this.loadingMore = false,
      this.moreFailed = false});
  final ProgressJson data;
  final VoidCallback? onMore;
  final bool loadingMore, moreFailed;
  @override
  State<ExerciseProgressContent> createState() =>
      _ExerciseProgressContentState();
}

class _ExerciseProgressContentState extends State<ExerciseProgressContent> {
  String? _metric;

  Widget _fact(
          BuildContext context, String label, String value, String? date) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fitnessText(context, label),
            style: const TextStyle(fontSize: 11, color: progressMuted)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: progressSilver)),
        if (date != null) ...[
          const SizedBox(height: 4),
          Text(
              progressDate(
                  date, Localizations.localeOf(context).toLanguageTag()),
              style: const TextStyle(fontSize: 11, color: progressMuted)),
        ],
      ]);
  @override
  Widget build(BuildContext context) {
    final series = progressRows(widget.data['series']);
    final history = progressRows(widget.data['history'])
      ..sort((a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''));
    final records = widget.data['records'] as Map? ?? {};
    final best = records['bestLoad'] is Map
        ? Map<String, dynamic>.from(records['bestLoad'] as Map)
        : null;
    final recent = [
      ...series,
      ...progressRows(widget.data['previous']),
      ...history
    ]..sort((a, b) =>
        (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''));
    final last = recent.firstOrNull;
    final lastEntries = progressRows(last?['entries']);
    final lastSets = progressNumber(last?['sets'])?.toInt() ??
        (lastEntries.isEmpty ? null : lastEntries.length);
    final choices = <String, String>{
      if (series.any((row) => (progressNumber(row['load']) ?? 0) > 0))
        'load': 'Weight',
      if (series.any((row) => progressNumber(row['reps']) != null))
        'reps': 'Reps',
      if (series.any((row) => (progressNumber(row['volume']) ?? 0) > 0))
        'volume': 'Volume',
      if (series
          .any((row) => (progressNumber(row['estimatedStrength']) ?? 0) > 0))
        'estimatedStrength': 'Estimated strength',
    };
    if (choices.isEmpty) choices['reps'] = 'Reps';
    if (!choices.containsKey(_metric)) _metric = choices.keys.first;
    final unit = _metric == 'reps'
        ? fitnessText(context, 'reps')
        : _metric == 'volume'
            ? 'kg·reps'
            : 'kg';
    final points = ProgressPoint.parse(series, _metric!);
    final facts = <Widget>[
      if (best != null)
        _fact(context, 'Best set', progressSetLabel(context, best),
            best['date'] as String?),
      if (last != null)
        _fact(
            context,
            'Last session',
            last['bestSet'] is Map
                ? progressSetLabel(
                    context, Map<String, dynamic>.from(last['bestSet'] as Map))
                : lastSets == null
                    ? '—'
                    : '$lastSets ${fitnessText(context, lastSets == 1 ? 'set' : 'sets')}',
            last['date'] as String?),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (points.isNotEmpty)
        ProgressSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              SizedBox(
                  height: 44,
                  child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                    key: const ValueKey('exercise-progress-metric'),
                    value: _metric,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: DSColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(CupertinoIcons.chevron_down,
                        size: 12, color: progressMuted),
                    style: TextStyle(
                        fontSize: 13,
                        color: progressSilver,
                        fontFamily:
                            Theme.of(context).platform == TargetPlatform.iOS
                                ? 'CupertinoSystemText'
                                : 'Inter'),
                    items: choices.entries
                        .map((choice) => DropdownMenuItem(
                            value: choice.key,
                            child: Text(fitnessText(context, choice.value),
                                maxLines: 1, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (metric) {
                      if (metric != null) setState(() => _metric = metric);
                    },
                  ))),
              const SizedBox(height: 10),
              ProgressChart(
                  key: ValueKey(_metric),
                  points: points,
                  unit: unit,
                  digits: _metric == 'reps' ? 0 : 1,
                  headlineSize: 32,
                  color: progressBlue,
                  height: 144,
                  showChange: true,
                  bars: _metric == 'volume'),
              if (_metric == 'estimatedStrength')
                const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: ProgressNote(
                        'An estimate from eligible logged sets, not a tested maximum.')),
            ])),
      if (facts.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ProgressSurface(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(builder: (context, box) {
                  if (facts.length == 1 ||
                      box.maxWidth < 240 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < facts.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            facts[i],
                          ]
                        ]);
                  }
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < facts.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(child: facts[i]),
                        ]
                      ]);
                }))),
      const ProgressHeading('Set history'),
      if (history.isEmpty)
        const ProgressEmpty('No sets in this period')
      else
        ProgressSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              for (var i = 0; i < history.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: DSColors.border),
                ProgressSetHistory(row: history[i]),
              ],
            ])),
      if (widget.loadingMore)
        const Padding(
            padding: EdgeInsets.all(16), child: CupertinoActivityIndicator())
      else if (widget.onMore != null)
        Center(
            child: TextButton(
                key: const ValueKey('exercise-history-more'),
                onPressed: widget.onMore,
                child: Text(
                    fitnessText(
                        context, widget.moreFailed ? 'Retry' : 'Load more'),
                    style:
                        const TextStyle(fontSize: 13, color: progressSilver)))),
    ]);
  }
}

class ProgressSetHistory extends StatelessWidget {
  const ProgressSetHistory({super.key, required this.row});
  final ProgressJson row;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entries = progressRows(row['entries']);
    return ExpansionTile(
        key: PageStorageKey('exercise-history-${row['date']}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: progressMuted,
        collapsedIconColor: progressMuted,
        textColor: progressSilver,
        collapsedTextColor: progressSilver,
        title: Text(progressDate(row['date'] as String?, locale, year: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(
            fitnessText(
                context, entries.length == 1 ? '{count} set' : '{count} sets',
                values: {'count': entries.length}),
            style: const TextStyle(fontSize: 11, color: progressMuted)),
        children: [ProgressSetTable(entries: entries)]);
  }
}
