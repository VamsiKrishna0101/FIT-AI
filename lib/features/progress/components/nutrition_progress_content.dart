import 'package:flutter/material.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

class NutritionProgressContent extends StatefulWidget {
  final ProgressJson data;
  final bool compact;
  const NutritionProgressContent(
      {super.key, required this.data, this.compact = false});
  @override
  State<NutritionProgressContent> createState() =>
      _NutritionProgressContentState();
}

class _NutritionProgressContentState extends State<NutritionProgressContent> {
  String _metric = 'calories';
  static const labels = {
    'calories': 'Calories',
    'protein': 'Protein',
    'carbs': 'Carbs',
    'fat': 'Fat',
    'water': 'Water'
  };
  static const colors = {
    'calories': progressNutrition,
    'protein': progressBlue,
    'carbs': progressViolet,
    'fat': progressAmber,
    'water': progressCyan
  };
  static const targets = {
    'calories': 'targetCalories',
    'protein': 'targetProtein',
    'carbs': 'targetCarbs',
    'fat': 'targetFat'
  };

  List<ProgressPoint> _points(String metric) {
    final points =
        ProgressPoint.parse(progressRows(widget.data['nutrition']), metric);
    return metric == 'water'
        ? points
            .map((point) => ProgressPoint(point.date, point.value / 1000))
            .toList()
        : points;
  }

  double? _average(String metric) {
    final points = _points(metric);
    return points.isEmpty
        ? null
        : points.fold<double>(0, (sum, point) => sum + point.value) /
            points.length;
  }

  double? _target(String metric) {
    final value = progressNumber(
        (widget.data['currentTargets'] as Map?)?[targets[metric]]);
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final rows = progressRows(widget.data['nutrition']);
    final loggedDays =
        rows.where((row) => (progressNumber(row['mealLogs']) ?? 0) > 0).length;
    final meals = rows.fold<int>(
        0, (sum, row) => sum + (progressNumber(row['mealLogs']) ?? 0).toInt());
    final points = _points(_metric);
    final target = _target(_metric);
    final unit = _metric == 'calories'
        ? 'kcal'
        : _metric == 'water'
            ? 'L'
            : 'g';
    final macros = ['protein', 'carbs', 'fat']
        .where((metric) => _average(metric) != null)
        .toList();
    if (widget.compact) {
      final waterOnly =
          _points('calories').isEmpty && _points('protein').isEmpty;
      final overview = _points(waterOnly ? 'water' : 'calories');
      return ProgressSurface(
          accent: progressAmber,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fitnessText(context, 'Daily nutrition'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ProgressFactGrid(color: progressAmber, facts: [
              (
                waterOnly ? 'Average water' : 'Calories',
                progressValue(
                    context, _average(waterOnly ? 'water' : 'calories'),
                    unit: waterOnly ? 'L' : 'kcal', digits: waterOnly ? 1 : 0)
              ),
              (
                'Protein',
                progressValue(context, _average('protein'),
                    unit: 'g', digits: 0)
              ),
            ]),
            const SizedBox(height: 14),
            Text(fitnessText(context, 'Recorded-day average'),
                style: const TextStyle(fontSize: 12, color: progressMuted)),
            if (overview.length > 1) ...[
              const SizedBox(height: 14),
              SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: ProgressSparkline(
                      points: overview,
                      color: waterOnly ? progressCyan : progressAmber,
                      bars: true,
                      daily: true)),
            ],
          ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressMetricPicker(
          choices: labels,
          selected: _metric,
          color: colors[_metric]!,
          onChanged: (value) => setState(() => _metric = value)),
      const SizedBox(height: 16),
      ProgressSurface(
          accent: colors[_metric],
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(fitnessText(context, labels[_metric]!),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 16),
            ProgressChart(
                key: ValueKey('nutrition-chart-$_metric'),
                points: points,
                digits: _metric == 'water' ? 1 : 0,
                unit: unit,
                bars: true,
                daily: true,
                average: true,
                color: colors[_metric]!,
                height: 160,
                showReference: target != null,
                reference: target,
                referenceLabel: 'Current target',
                showReadings: true),
            if (points.isEmpty)
              const ProgressNote(
                  'Log meals in Today to see your nutrition trends here.'),
          ])),
      if (macros.isNotEmpty) ...[
        const ProgressHeading('Average macros'),
        ProgressSurface(
            child: Column(children: [
          for (var i = 0; i < macros.length; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: DSColors.border)),
            _MacroAverage(
                label: labels[macros[i]]!,
                value: _average(macros[i])!,
                target: _target(macros[i]),
                color: colors[macros[i]]!),
          ],
        ])),
        const ProgressNote(
            'Targets are estimated from your profile. Logged portions update your totals.'),
      ],
      const ProgressHeading('Your logging rhythm'),
      ProgressFactGrid(facts: [
        ('Days logged', progressValue(context, loggedDays, digits: 0)),
        ('Meals logged', progressValue(context, meals, digits: 0)),
        if (_average('water') != null)
          (
            'Average water',
            progressValue(context, _average('water'), unit: 'L')
          ),
      ], color: progressCyan),
      const ProgressNote(
          'Logs show what you recorded. Unlogged days are not zero intake.'),
    ]);
  }
}

class _MacroAverage extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  const _MacroAverage(
      {required this.label,
      required this.value,
      required this.target,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(fitnessText(context, label),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(progressValue(context, value, unit: 'g', digits: 0),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: progressSilver))),
        ]),
        if (target != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: MotionValue(
                  value: (value / target!).clamp(0.0, 1.0),
                  builder: (context, value) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: color,
                      backgroundColor: DSColors.bgRaised))),
          const SizedBox(height: 8),
          Text(
              '${fitnessText(context, 'Current target')} · ${progressValue(context, target, unit: 'g', digits: 0)}',
              style: const TextStyle(fontSize: 13, color: progressMuted)),
        ],
      ]);
}
