import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../models/body_progress_summary.dart';
import 'body_controls.dart';

class BodyChangesCard extends StatelessWidget {
  final BodyProgressSummary summary;
  final VoidCallback onMeasurements, onCompare;
  const BodyChangesCard(
      {super.key,
      required this.summary,
      required this.onMeasurements,
      required this.onCompare});

  @override
  Widget build(BuildContext context) {
    final changes = summary.changes.take(3).toList();
    return FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FitnessText('Your progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (changes.isEmpty)
        const FitnessText('Save readings on two different days to see changes.',
            style: TextStyle(
                fontSize: 13, height: 1.4, color: FitnessTheme.muted)),
      for (final change in changes)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: FitnessText(
                        bodyMetricSpecs[change.current.key]!.label,
                        style: const TextStyle(fontSize: 14))),
                Text(
                    '${change.delta > 0 ? '+' : ''}${change.delta.toStringAsFixed(1)} ${bodyMetricSpecs[change.current.key]!.unit}',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 5),
              Text(
                  '${change.previous.metric.display(bodyMetricSpecs[change.current.key]!.unit)} → ${change.current.metric.display(bodyMetricSpecs[change.current.key]!.unit)}',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              const SizedBox(height: 3),
              Text(
                  '${bodyDate(change.previous.date)} – ${bodyDate(change.current.date)} · ${fitnessText(context, change.current.sourceLabel)}',
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
            ])),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed:
              summary.comparisonEntry == null ? onMeasurements : onCompare,
          icon: Icon(
              summary.comparisonEntry == null
                  ? CupertinoIcons.add
                  : CupertinoIcons.rectangle_on_rectangle,
              size: 16),
          label: FitnessText(summary.comparisonEntry == null
              ? 'Add measurements'
              : 'Compare progress')),
    ]));
  }
}

class BodyBalanceCard extends StatelessWidget {
  final BodyProgressSummary summary;
  final VoidCallback onAdd;
  const BodyBalanceCard(
      {super.key, required this.summary, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final pairs = summary.pairs;
    return FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FitnessText('Left & right',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 7),
      const FitnessText('Compare your recorded measurements.',
          style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      if (pairs.isEmpty) ...[
        const SizedBox(height: 13),
        const FitnessText(
            'Add left and right readings together to see the difference.',
            style: TextStyle(
                fontSize: 13, height: 1.4, color: FitnessTheme.muted)),
        TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const FitnessText('Add measurements')),
      ],
      for (final pair in pairs)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitnessText(pair.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              FitnessText('Difference: {value} cm',
                  values: {'value': pair.difference.toStringAsFixed(1)},
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: FitnessText('Left: {value} cm',
                        values: {'value': pair.left.value.toStringAsFixed(1)},
                        style: const TextStyle(fontSize: 16))),
                Expanded(
                    child: FitnessText('Right: {value} cm',
                        values: {'value': pair.right.value.toStringAsFixed(1)},
                        style: const TextStyle(fontSize: 16))),
              ]),
              const SizedBox(height: 6),
              Text(
                  '${bodyDate(pair.entry.recordedDate)} · ${fitnessText(context, bodySourceLabel(pair.left.source))}',
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
            ])),
      if (pairs.isNotEmpty)
        const FitnessText(
            'A size difference does not measure strength. Small changes can come from measuring technique.',
            style: TextStyle(
                fontSize: 11, height: 1.4, color: FitnessTheme.muted)),
    ]));
  }
}

class BodyTrainingFocusCard extends StatelessWidget {
  final BodyAssessment? report;
  final List<String> chosenFocus;
  final VoidCallback onTrain;
  const BodyTrainingFocusCard(
      {super.key,
      this.report,
      required this.chosenFocus,
      required this.onTrain});

  @override
  Widget build(BuildContext context) {
    final focus = report?.observations.take(3).toList() ?? [];
    if (focus.isEmpty && chosenFocus.isEmpty) return const SizedBox.shrink();
    return FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FitnessText('Your training focus',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 9),
      for (final area in focus)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitnessText(
                  bodyRegionNames[area['region']] ?? area['region'].toString(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(area['observation']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
              const SizedBox(height: 4),
              FitnessText(
                  switch (area['basis']) {
                    'training_history' => 'From your logged workouts',
                    'measurements' => 'From saved measurements',
                    'visual_context' => 'From your photo review',
                    'profile_goal' => 'From your goal and preferences',
                    _ => 'Unavailable',
                  },
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
            ])),
      if (focus.isEmpty)
        FitnessText(
            chosenFocus
                .take(3)
                .map((id) => fitnessText(context, bodyRegionNames[id] ?? id))
                .join(' · '),
            style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: onTrain,
          icon: const Icon(CupertinoIcons.arrow_right, size: 16),
          label: const FitnessText('Open your workout')),
    ]));
  }
}
