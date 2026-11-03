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

ProgressJson? _setMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

ProgressJson? _bestLoggedSet(List<ProgressJson> entries) {
  if (entries.isEmpty) return null;
  final sorted = [...entries]..sort((a, b) {
      final weight = (progressNumber(b['weight']) ?? 0)
          .compareTo(progressNumber(a['weight']) ?? 0);
      return weight != 0
          ? weight
          : (progressNumber(b['reps']) ?? 0)
              .compareTo(progressNumber(a['reps']) ?? 0);
    });
  return sorted.first;
}

class _ExerciseProgressContentState extends State<ExerciseProgressContent> {
  String? _metric;

  @override
  Widget build(BuildContext context) {
    final series = progressRows(widget.data['series'])
      ..sort((a, b) =>
          (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
    final history = progressRows(widget.data['history'])
      ..sort((a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''));
    final records = widget.data['records'] as Map? ?? {};
    final best = _setMap(records['bestLoad']) ??
        _bestLoggedSet(progressRows(records['repsAtLoad']));
    final lastDay = series.lastOrNull;
    final last = _setMap(lastDay?['bestSet']) ??
        (history.isEmpty
            ? null
            : _bestLoggedSet(progressRows(history.first['entries'])));
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
        ? 'reps'
        : _metric == 'volume'
            ? 'kg·reps'
            : 'kg';
    final points = ProgressPoint.parse(series, _metric!);
    final setCount =
        progressNumber((widget.data['exercise'] as Map?)?['loggedSets']);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ProgressSurface(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    key: const ValueKey('exercise-progress-metric'),
                    value: _metric,
                    isExpanded: true,
                    dropdownColor: DSColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(CupertinoIcons.chevron_down,
                        size: 12, color: progressMuted),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: progressSilver,
                        fontWeight: FontWeight.w500),
                    items: [
                      for (final entry in choices.entries)
                        DropdownMenuItem(
                            value: entry.key,
                            child: Text(fitnessText(context, entry.value))),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _metric = value);
                    })),
            const SizedBox(height: 8),
            if (points.isEmpty)
              const ProgressEmpty('No metric data in this period')
            else
              ProgressChart(
                  key: ValueKey(_metric),
                  points: points,
                  unit: unit,
                  digits: _metric == 'reps' ? 0 : 1,
                  headlineSize: 30,
                  color: progressStrength,
                  height: 122,
                  showChange: true,
                  bars: _metric == 'volume'),
            if (_metric == 'estimatedStrength') ...[
              const SizedBox(height: 12),
              const ProgressNote('Estimated from your logged weight and reps.'),
            ],
            if (series.isNotEmpty) ...[
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: DSColors.border)),
              Wrap(spacing: 18, runSpacing: 6, children: [
                Text(
                    fitnessText(
                        context,
                        series.length == 1
                            ? '{count} session'
                            : '{count} sessions',
                        values: {
                          'count':
                              progressValue(context, series.length, digits: 0)
                        }),
                    style: const TextStyle(color: progressMuted, fontSize: 11)),
                if (setCount != null)
                  Text(
                      fitnessText(context,
                          setCount == 1 ? '{count} set' : '{count} sets',
                          values: {
                            'count': progressValue(context, setCount, digits: 0)
                          }),
                      style:
                          const TextStyle(color: progressMuted, fontSize: 11)),
              ]),
            ],
          ])),
      if (best != null || last != null) ...[
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, box) {
          final stack = box.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 19;
          final width = stack ? box.maxWidth : (box.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            if (best != null)
              SizedBox(
                  width: width,
                  child: _SetSummary(
                      title: 'Best set',
                      value: progressSetValue(context, best),
                      caption: [
                        fitnessText(context, 'All time'),
                        if (best['date'] != null)
                          progressDate(best['date'] as String, locale),
                      ].join(' · '))),
            if (last != null && series.isNotEmpty)
              SizedBox(
                  width: width,
                  child: _SetSummary(
                      title: 'Last session',
                      value: progressSetValue(context, last),
                      caption: progressDate(
                          (lastDay?['date'] ?? history.firstOrNull?['date'])
                              as String?,
                          locale))),
          ]);
        }),
      ],
      const ProgressHeading('Set history', topPadding: 18),
      if (history.isEmpty)
        const ProgressSurface(
            padding: EdgeInsets.all(14),
            child: ProgressEmpty('No sets logged in this period'))
      else
        ProgressSurface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              for (var i = 0; i < history.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: DSColors.border),
                ProgressSetHistory(row: history[i]),
              ],
            ])),
      if (widget.loadingMore)
        const Padding(
            padding: EdgeInsets.all(16),
            child: CupertinoActivityIndicator(color: progressSilver))
      else if (widget.onMore != null)
        Center(
            child: TextButton(
                key: const ValueKey('exercise-history-more'),
                onPressed: widget.onMore,
                child: Text(
                    fitnessText(
                        context, widget.moreFailed ? 'Retry' : 'Load more'),
                    style:
                        const TextStyle(color: progressSilver, fontSize: 12)))),
    ]);
  }
}

class _SetSummary extends StatelessWidget {
  final String title, value, caption;
  const _SetSummary(
      {required this.title, required this.value, required this.caption});
  @override
  Widget build(BuildContext context) => ProgressSurface(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fitnessText(context, title),
            style: const TextStyle(color: progressMuted, fontSize: 11)),
        const SizedBox(height: 9),
        Text(value,
            style: const TextStyle(
                color: progressSilver,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: -.3,
                fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 6),
        Text(caption,
            style: const TextStyle(
                color: progressMuted, fontSize: 10, height: 1.4)),
      ]));
}

class ProgressSetHistory extends StatelessWidget {
  const ProgressSetHistory({super.key, required this.row});
  final ProgressJson row;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entries = progressRows(row['entries']);
    final best = _setMap(row['bestSet']) ?? _bestLoggedSet(entries);
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
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: progressSilver)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                [
                  fitnessText(context,
                      entries.length == 1 ? '{count} set' : '{count} sets',
                      values: {
                        'count':
                            progressValue(context, entries.length, digits: 0)
                      }),
                  if (best != null) progressSetValue(context, best),
                ].join(' · '),
                style: const TextStyle(
                    color: progressMuted, fontSize: 10, height: 1.5))),
        children: [ProgressSetTable(entries: entries)]);
  }
}
