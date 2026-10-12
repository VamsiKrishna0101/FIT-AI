import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_trend_summary.dart';

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
      if (best != null)
        ProgressSurface(
            child: Row(children: [
          const Icon(Icons.emoji_events_outlined,
              color: progressAmber, size: 27),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(fitnessText(context, 'Best recorded load'),
                    style: const TextStyle(color: progressMuted, fontSize: 11)),
                const SizedBox(height: 5),
                Text(
                    '${progressValue(context, progressNumber(best['weight']), unit: 'kg')} × ${best['reps']}',
                    style: const TextStyle(
                        color: progressAmber,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.7)),
                const SizedBox(height: 5),
                Text(
                    '${fitnessText(context, 'All time')} · ${progressDate(best['date'] as String?, locale)}',
                    style: const TextStyle(color: progressMuted, fontSize: 12)),
              ])),
        ])),
      const SizedBox(height: 12),
      ProgressSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProgressChoices(
            choices: choices,
            color: progressCyan,
            selected: _metric!,
            onChanged: (value) => setState(() => _metric = value)),
        const SizedBox(height: 18),
        ProgressChart(
            points: points,
            unit: unit,
            color: progressCyan,
            height: 175,
            bars: _metric == 'volume'),
        ProgressTrendSummary(points: points, unit: unit, color: progressCyan),
        if (_metric == 'estimatedStrength')
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                  fitnessText(context,
                      'An estimate from eligible logged sets, not a tested maximum.'),
                  style: const TextStyle(
                      fontSize: 11, color: progressMuted, height: 1.4))),
      ])),
      const ProgressHeading('Last two training days'),
      ProgressSurface(
          child: Column(
              children:
                  progressRows(widget.data['previous']).reversed.map((row) {
        final set = row['bestSet'] as Map?;
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(
                  child: Text(progressDate(row['date'] as String?, locale),
                      style:
                          const TextStyle(color: progressMuted, fontSize: 12))),
              Text(
                  '${set?['weight'] != null && (set!['weight'] as num) > 0 ? '${progressValue(context, progressNumber(set['weight']), unit: 'kg')} × ' : ''}${set?['reps'] ?? '—'} ${fitnessText(context, 'reps')}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ]));
      }).toList())),
      const ProgressHeading('Rep records by load'),
      ProgressSurface(
          child: Column(
              children: progressRows(records['repsAtLoad'])
                  .map((row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                progressNumber(row['weight']) == null ||
                                        progressNumber(row['weight']) == 0
                                    ? fitnessText(context, 'No external load')
                                    : progressValue(
                                        context, progressNumber(row['weight']),
                                        unit: 'kg'),
                                style: const TextStyle(fontSize: 13))),
                        Text('${row['reps']} ${fitnessText(context, 'reps')}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Text(progressDate(row['date'] as String?, locale),
                            style: const TextStyle(
                                fontSize: 11, color: progressMuted)),
                      ])))
                  .toList())),
      const ProgressHeading('Set history'),
      if (history.isEmpty)
        const ProgressEmpty('No sets in this period')
      else
        ProgressSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
                children: history
                    .map((row) => ProgressSetHistory(row: row))
                    .toList())),
      if (widget.onMore != null)
        Center(
            child: TextButton(
                onPressed: widget.onMore,
                child: Text(fitnessText(context, 'Load more')))),
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
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(progressDate(row['date'] as String?, locale, year: true),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text('${entries.length} ${fitnessText(context, 'sets')}',
            style: const TextStyle(fontSize: 11, color: progressMuted)),
        children: entries
            .map((set) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  SizedBox(
                      width: 35,
                      child: Text('${set['setNumber']}',
                          style: const TextStyle(
                              color: progressMuted, fontSize: 12))),
                  Expanded(
                      child: Text(
                          '${set['weight'] != null && (set['weight'] as num) > 0 ? '${progressValue(context, progressNumber(set['weight']), unit: 'kg')} × ' : ''}${set['reps']} ${fitnessText(context, 'reps')}',
                          style: const TextStyle(fontSize: 13))),
                  if (set['rpe'] != null)
                    Text(
                        'RPE ${progressValue(context, progressNumber(set['rpe']))}',
                        style: const TextStyle(
                            color: progressMuted, fontSize: 11)),
                ])))
            .toList());
  }
}
