import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressTrendSummary extends StatelessWidget {
  final List<ProgressPoint> points;
  final String unit;
  final Color color;
  final bool extrema;
  const ProgressTrendSummary({
    super.key,
    required this.points,
    required this.unit,
    this.color = progressSilver,
    this.extrema = false,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final change =
        points.length > 1 ? points.last.value - points.first.value : null;
    final items = extrema
        ? [
            (
              'Lowest',
              progressValue(
                  context, points.map((point) => point.value).reduce(math.min),
                  unit: unit)
            ),
            (
              'Highest',
              progressValue(
                  context, points.map((point) => point.value).reduce(math.max),
                  unit: unit)
            ),
            (
              'Latest reading',
              progressValue(context, points.last.value, unit: unit)
            ),
          ]
        : [
            (
              'First reading',
              progressValue(context, points.first.value, unit: unit)
            ),
            (
              'Latest reading',
              progressValue(context, points.last.value, unit: unit)
            ),
            (
              'Change',
              change == null
                  ? '—'
                  : '${change > 0 ? '+' : ''}${progressValue(context, change, unit: unit)}'
            ),
          ];
    return Padding(
        padding: const EdgeInsets.only(top: 15),
        child: ProgressFactGrid(facts: items, color: color));
  }
}
