import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'nutrition_progress_content.dart';
import 'progress_surface.dart';
import 'progress_trend_summary.dart';

class WellnessProgressContent extends StatefulWidget {
  final ProgressJson data;
  final bool nutrition;
  final bool compact;
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
  String? _metric;
  @override
  Widget build(BuildContext context) {
    if (widget.nutrition) {
      return NutritionProgressContent(
          data: widget.data, compact: widget.compact);
    }
    _metric ??= widget.nutrition ? 'protein' : 'recovery';
    final choices = widget.nutrition
        ? const {
            'protein': 'Protein',
            'calories': 'Calories',
            'carbs': 'Carbs',
            'fat': 'Fat',
            'water': 'Water'
          }
        : const {
            'recovery': 'Recovery',
            'sleep': 'Sleep',
            'hrv': 'HRV',
            'rhr': 'Resting heart rate',
            'steps': 'Steps',
            'activeCalories': 'Active calories'
          };
    const units = {
      'protein': 'g',
      'carbs': 'g',
      'fat': 'g',
      'calories': 'kcal',
      'water': 'ml',
      'recovery': '/100',
      'sleep': 'h',
      'hrv': 'ms',
      'rhr': 'bpm',
      'steps': 'steps',
      'activeCalories': 'kcal'
    };
    var rows =
        progressRows(widget.data[widget.nutrition ? 'nutrition' : 'recovery']);
    String? hrvMethod;
    if (_metric == 'hrv') {
      // SDNN and RMSSD are different measurements; never join them into one trend.
      hrvMethod = rows
          .where((r) => r['hrv'] != null && r['hrvMethod'] != null)
          .lastOrNull?['hrvMethod'] as String?;
      rows = rows.where((r) => r['hrvMethod'] == hrvMethod).toList();
    }
    final points = ProgressPoint.parse(rows, _metric!);
    final color = widget.nutrition
        ? progressAmber
        : _metric == 'hrv' || _metric == 'rhr'
            ? progressCyan
            : progressViolet;
    final target = widget.nutrition && _metric != 'water'
        ? progressNumber((widget.data['currentTargets'] as Map?)?[{
            'protein': 'targetProtein',
            'calories': 'targetCalories',
            'carbs': 'targetCarbs',
            'fat': 'targetFat'
          }[_metric]])
        : null;
    return ProgressSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressChoices(
          choices: choices,
          color: color,
          selected: _metric!,
          onChanged: (value) => setState(() => _metric = value)),
      const SizedBox(height: 18),
      if (_metric == 'hrv' && hrvMethod != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('HRV · $hrvMethod',
                style: const TextStyle(color: progressMuted, fontSize: 12))),
      ProgressChart(
          points: points,
          unit: units[_metric!]!,
          bars: widget.nutrition ||
              _metric == 'recovery' ||
              _metric == 'sleep' ||
              _metric == 'steps' ||
              _metric == 'activeCalories',
          average: true,
          showReference: true,
          reference: target,
          referenceLabel:
              target != null ? 'Current target' : 'Recorded-day average',
          daily: true,
          maximum: _metric == 'recovery' ? 100 : null,
          color: color,
          height: widget.compact ? 120 : 190),
      ProgressTrendSummary(
          points: points, unit: units[_metric!]!, color: color, extrema: true),
      if (!widget.compact) ...[
        const SizedBox(height: 14),
        Text(
            fitnessText(
                context,
                widget.nutrition
                    ? 'Logs show what you recorded. Unlogged days are not zero intake.'
                    : 'Missing readings stay empty. Recovery is a recorded score, not a diagnosis.'),
            style: const TextStyle(
                color: progressMuted, fontSize: 11, height: 1.45)),
      ],
    ]));
  }
}
