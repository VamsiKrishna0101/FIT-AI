import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
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
    if (points.isEmpty) return const SizedBox.shrink();
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
        child: Column(children: [
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 13),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fitnessText(context, items[i].$1),
                                style: const TextStyle(
                                    color: progressMuted, fontSize: 10)),
                            const SizedBox(height: 5),
                            Text(items[i].$2,
                                style: TextStyle(
                                    color: i == 2 ? color : progressSilver,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ]))),
          ]),
        ]));
  }
}
