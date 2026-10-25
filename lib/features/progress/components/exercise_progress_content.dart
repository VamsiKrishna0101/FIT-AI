import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_trend_summary.dart';
import 'progress_workout_history.dart';

class ExerciseProgressContent extends StatefulWidget {
  final ProgressJson data;
  final VoidCallback? onMore;
  const ExerciseProgressContent({super.key, required this.data, this.onMore});
  @override
  State<ExerciseProgressContent> createState() =>
      _ExerciseProgressContentState();
}

class _ExerciseProgressContentState extends State<ExerciseProgressContent> {
  String? _metric;
  String _section = 'trends';
  @override
  Widget build(BuildContext context) {
    final series = progressRows(widget.data['series']);
    final history = progressRows(widget.data['history']);
    final records = widget.data['records'] as Map? ?? {};
    final best = records['bestLoad'] as Map?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final choices = <String, String>{
      if (series.any((row) => row['load'] != null)) 'load': 'Load',
      'reps': 'Reps',
      if (series.any((row) => row['volume'] != null)) 'volume': 'Volume',
      if (series.any((row) => row['estimatedStrength'] != null))
        'estimatedStrength': 'Estimated strength',
    };
    if (!choices.containsKey(_metric)) _metric = choices.keys.first;
    final unit = _metric == 'reps'
        ? fitnessText(context, 'reps')
        : _metric == 'volume'
            ? 'kg·reps'
            : 'kg';
    final points = ProgressPoint.parse(series, _metric!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressChoices(
          choices: const {'trends': 'Trends', 'history': 'Set history'},
          selected: _section,
          color: progressCyan,
          onChanged: (value) => setState(() => _section = value)),
      const SizedBox(height: 12),
      if (_section == 'trends') ...[
        ProgressMetricPicker(
            choices: choices,
            selected: _metric!,
            color: progressCyan,
            onChanged: (value) => setState(() => _metric = value)),
        const SizedBox(height: 12),
        ProgressSurface(
            accent: progressCyan,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fitnessText(context, choices[_metric]!),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ProgressChart(
                  points: points,
                  unit: unit,
                  color: progressCyan,
                  height: 160,
                  bars: _metric == 'volume'),
              ProgressTrendSummary(
                  points: points, unit: unit, color: progressCyan),
              if (_metric == 'estimatedStrength')
                const ProgressNote(
                    'An estimate from eligible logged sets, not a tested maximum.'),
            ])),
        if (best != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ProgressSurface(
                  accent: progressAmber,
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(fitnessText(context, 'Best recorded load'),
                              style: const TextStyle(
                                  fontSize: 11, color: progressMuted)),
                          const SizedBox(height: 4),
                          Text(
                              '${progressValue(context, progressNumber(best['weight']), unit: 'kg')} × ${best['reps']}',
                              style: const TextStyle(
                                  color: progressSilver,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              '${fitnessText(context, 'All time')} · ${progressDate(best['date'] as String?, locale)}',
                              style: const TextStyle(
                                  fontSize: 10, color: progressMuted)),
                        ])),
                  ]))),
        if (progressRows(widget.data['previous']).isNotEmpty) ...[
          const ProgressHeading('Last two training days'),
          ProgressSurface(
              child: Column(children: [
            for (final row in progressRows(widget.data['previous']).reversed)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            progressDate(row['date'] as String?, locale),
                            style: const TextStyle(
                                fontSize: 12, color: progressMuted))),
                    Flexible(
                        child: Text(
                            progressSetLabel(
                                context,
                                Map<String, dynamic>.from(
                                    row['bestSet'] as Map? ?? {})),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600))),
                  ])),
          ])),
        ],
      ] else ...[
        if (history.isEmpty)
          const ProgressEmpty('No sets in this period')
        else
          ProgressSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                for (var i = 0; i < history.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0x12FFFFFF)),
                  ProgressSetHistory(row: history[i]),
                ],
              ])),
        if (widget.onMore != null)
          Center(
              child: TextButton(
                  onPressed: widget.onMore,
                  child: Text(fitnessText(context, 'Load more')))),
        if (progressRows(records['repsAtLoad']).isNotEmpty) ...[
          const ProgressHeading('Rep records by load'),
          ProgressSurface(
              accent: progressAmber,
              child: Column(children: [
                for (final row in progressRows(records['repsAtLoad']))
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                progressNumber(row['weight']) == 0
                                    ? fitnessText(context, 'No external load')
                                    : progressNumber(row['weight']) == null
                                        ? fitnessText(
                                            context, 'Weight not recorded')
                                        : progressValue(context,
                                            progressNumber(row['weight']),
                                            unit: 'kg'),
                                style: const TextStyle(
                                    fontSize: 12, color: progressMuted))),
                        Text('${row['reps']} ${fitnessText(context, 'reps')}',
                            style: const TextStyle(
                                color: progressSilver,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ])),
              ])),
        ],
      ],
    ]);
  }
}

class ProgressSetHistory extends StatelessWidget {
  final ProgressJson row;
  const ProgressSetHistory({super.key, required this.row});
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
        title: Text(progressDate(row['date'] as String?, locale, year: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${entries.length} ${fitnessText(context, 'sets')}',
            style: const TextStyle(fontSize: 11, color: progressMuted)),
        children: [ProgressSetTable(entries: entries)]);
  }
}
