import 'package:flutter/cupertino.dart';
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
    'water': 'Water',
  };
  static const colors = {
    'calories': progressSilver,
    'protein': progressBlue,
    'carbs': progressViolet,
    'fat': progressAmber,
    'water': progressCyan,
  };
  static const targets = {
    'calories': 'targetCalories',
    'protein': 'targetProtein',
    'carbs': 'targetCarbs',
    'fat': 'targetFat',
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressSurface(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.restaurant_outlined,
                size: 16, color: progressMuted),
            const SizedBox(width: 8),
            Expanded(
                child: Text(fitnessText(context, 'Daily nutrition'),
                    style:
                        const TextStyle(fontSize: 13, color: progressMuted))),
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
            height: widget.compact ? 112 : 180,
            showReference: target != null,
            reference: target,
            referenceLabel: 'Current target',
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final entry in labels.entries) _choice(entry.key, entry.value),
          ]),
          const SizedBox(height: 22),
          const Divider(height: 1, color: DSColors.border),
          const SizedBox(height: 18),
          Text(fitnessText(context, 'Average macros'),
              style: const TextStyle(fontSize: 12, color: progressMuted)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final stacked = constraints.maxWidth < 275 ||
                MediaQuery.textScalerOf(context).scale(12) > 18;
            final tiles = [
              for (final metric in ['protein', 'carbs', 'fat'])
                _MacroAverage(
                    label: labels[metric]!,
                    value: _average(metric),
                    target: _target(metric),
                    color: colors[metric]!,
                    stacked: stacked)
            ];
            return stacked
                ? Column(children: [
                    for (final tile in tiles)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: tile)
                  ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var index = 0; index < tiles.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: tiles[index]),
                    ],
                  ]);
          }),
          if (!widget.compact) ...[
            const SizedBox(height: 14),
            Text(
                fitnessText(context,
                    'Targets are estimated from your profile. Logged portions update your totals.'),
                style: const TextStyle(
                    fontSize: 11, height: 1.5, color: progressMuted)),
          ],
        ]),
      ),
      if (!widget.compact) ...[
        const SizedBox(height: 14),
        ProgressSurface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fitnessText(context, 'Your logging rhythm'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _stat(context, 'Days logged',
                    progressValue(context, loggedDays))),
            const SizedBox(width: 14),
            Expanded(
                child: _stat(
                    context, 'Meals logged', progressValue(context, meals))),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: DSColors.border),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(CupertinoIcons.drop, color: progressCyan, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(fitnessText(context, 'Average water'),
                    style:
                        const TextStyle(fontSize: 13, color: progressMuted))),
            Text(progressValue(context, _average('water'), unit: 'L'),
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 12),
          Text(
              fitnessText(context,
                  'Logs show what you recorded. Unlogged days are not zero intake.'),
              style: const TextStyle(
                  fontSize: 11, height: 1.5, color: progressMuted)),
        ])),
      ],
    ]);
  }

  Widget _choice(String metric, String label) {
    final selected = _metric == metric;
    return Semantics(
        button: true,
        selected: selected,
        child: MotionPress(
          child: Material(
            color: selected ? DSColors.bgRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _metric = metric),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(fitnessText(context, label),
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? colors[metric] : progressMuted,
                          fontWeight:
                              selected ? FontWeight.w500 : FontWeight.w400))),
            ),
          ),
        ));
  }

  Widget _stat(BuildContext context, String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: -.8)),
        const SizedBox(height: 4),
        Text(fitnessText(context, label),
            style: const TextStyle(fontSize: 12, color: progressMuted)),
      ]);
}

class _MacroAverage extends StatelessWidget {
  final String label;
  final double? value, target;
  final Color color;
  final bool stacked;

  const _MacroAverage(
      {required this.label,
      required this.value,
      required this.target,
      required this.color,
      required this.stacked});

  @override
  Widget build(BuildContext context) {
    final progress = value != null && target != null
        ? (value! / target!).clamp(0.0, 1.0)
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: DSColors.bgRaised, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(fitnessText(context, label),
                  style: const TextStyle(fontSize: 11, color: progressMuted))),
          if (stacked)
            Text(progressValue(context, value, unit: 'g', digits: 0),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        if (!stacked) ...[
          const SizedBox(height: 10),
          Text(progressValue(context, value, unit: 'g', digits: 0),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -.4)),
        ],
        const SizedBox(height: 7),
        Text(
            target == null
                ? '—'
                : "${fitnessText(context, 'Current target')} ${progressValue(context, target, unit: 'g', digits: 0)}",
            style: const TextStyle(
                fontSize: 9, color: progressMuted, height: 1.3)),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: MotionValue(
                value: progress ?? 0,
                builder: (context, value) => LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    color: color,
                    backgroundColor: DSColors.border))),
      ]),
    );
  }
}
