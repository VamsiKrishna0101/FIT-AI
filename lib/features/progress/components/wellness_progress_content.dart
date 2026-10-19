import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'nutrition_progress_content.dart';
import 'progress_surface.dart';
import 'progress_trend_summary.dart';

class WellnessProgressContent extends StatefulWidget {
  final ProgressJson data;
  final bool nutrition, compact;
  const WellnessProgressContent(
      {super.key,
      required this.data,
      this.nutrition = false,
      this.compact = false});
  @override
  State<WellnessProgressContent> createState() =>
      _WellnessProgressContentState();
}

class _WellnessProgressContentState extends State<WellnessProgressContent> {
  String _metric = 'recovery';
  static const choices = {
    'recovery': 'Recovery',
    'sleep': 'Sleep',
    'hrv': 'HRV',
    'rhr': 'Resting heart rate',
    'steps': 'Steps',
    'activeCalories': 'Active calories'
  };
  static const units = {
    'recovery': '/100',
    'sleep': 'h',
    'hrv': 'ms',
    'rhr': 'bpm',
    'steps': 'steps',
    'activeCalories': 'kcal'
  };
  @override
  Widget build(BuildContext context) {
    if (widget.nutrition) {
      return NutritionProgressContent(
          data: widget.data, compact: widget.compact);
    }
    var rows = progressRows(widget.data['recovery']);
    String? method;
    if (_metric == 'hrv') {
      method = rows
          .where((row) => row['hrv'] != null && row['hrvMethod'] != null)
          .lastOrNull?['hrvMethod'] as String?;
      rows = rows.where((row) => row['hrvMethod'] == method).toList();
    }
    final points = ProgressPoint.parse(rows, _metric);
    final color =
        _metric == 'hrv' || _metric == 'rhr' ? progressCyan : progressViolet;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressMetricPicker(
          choices: choices,
          selected: _metric,
          color: color,
          onChanged: (value) => setState(() => _metric = value)),
      const SizedBox(height: 16),
      ProgressSurface(
          accent: color,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(
                  _metric == 'sleep'
                      ? Icons.bedtime_outlined
                      : Icons.monitor_heart_outlined,
                  color: color,
                  size: 21),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(fitnessText(context, choices[_metric]!),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
              if (method != null)
                Text(method,
                    style: const TextStyle(fontSize: 12, color: progressMuted)),
            ]),
            const SizedBox(height: 20),
            ProgressChart(
                key: ValueKey('wellness-$_metric-$method'),
                points: points,
                unit: units[_metric]!,
                bars: ['recovery', 'steps', 'activeCalories'].contains(_metric),
                average: true,
                showReference: true,
                daily: true,
                maximum: _metric == 'recovery' ? 100 : null,
                color: color,
                height: widget.compact ? 120 : 160,
                showReadings: !widget.compact),
          ])),
      if (points.isNotEmpty) ...[
        const SizedBox(height: 14),
        ProgressTrendSummary(
            points: points, unit: units[_metric]!, color: color, extrema: true),
      ],
      if (!widget.compact)
        const ProgressNote(
            'Missing readings stay empty. Recovery is a recorded score, not a diagnosis.'),
    ]);
  }
}
