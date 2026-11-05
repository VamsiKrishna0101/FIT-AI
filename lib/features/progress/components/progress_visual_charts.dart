import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_chart_data.dart';
import 'progress_surface.dart';

class ProgressVisualBar {
  final String label, tooltip;
  final double? value;
  const ProgressVisualBar(this.label, this.value, this.tooltip);
}

/// Null is an unlogged day; a recorded zero keeps its own numeric label.
class ProgressColumnChart extends StatelessWidget {
  final List<ProgressVisualBar> bars;
  final Color color;
  final double minBarWidth;
  final int? selected;
  final ValueChanged<int>? onSelected;
  const ProgressColumnChart(
      {super.key,
      required this.bars,
      this.color = progressStrength,
      this.minBarWidth = 44,
      this.selected,
      this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox(height: 72);
    final maxValue =
        bars.fold<double>(1, (v, bar) => math.max(v, bar.value ?? 0));
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return LayoutBuilder(builder: (context, box) {
      final width = math.max(
          box.maxWidth, bars.length * minBarWidth * scale.clamp(1, 1.5));
      // Build labels, hit targets and full-height bars once. Animation changes
      // only the plot's paint transform, so no bar is laid out on every frame.
      final plot = Row(children: [
        for (var i = 0; i < bars.length; i++)
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      width: bars[i].value == null ? 9 : 22,
                      height: math.max(2, (bars[i].value ?? 0) / maxValue * 68),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: bars[i].value == null
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                      color.withValues(
                                          alpha:
                                              selected == null || selected == i
                                                  ? 1
                                                  : .45),
                                      color.withValues(alpha: .18)
                                    ]),
                          color: bars[i].value == null
                              ? DSColors.borderHi
                              : null))))
      ]);
      final labels = RepaintBoundary(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < bars.length; i++)
          Expanded(
              child: Semantics(
                  label: bars[i].tooltip,
                  button: onSelected != null,
                  selected: selected == i,
                  child: Tooltip(
                      message: bars[i].tooltip,
                      child: InkWell(
                          key: ValueKey('progress-visual-bar-$i'),
                          borderRadius: BorderRadius.circular(10),
                          onTap:
                              onSelected == null ? null : () => onSelected!(i),
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: ExcludeSemantics(
                                  child: Column(children: [
                                SizedBox(
                                    height: 22 * scale,
                                    child: Text(
                                        progressShortValue(
                                            context, bars[i].value),
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: selected == i
                                                ? progressSilver
                                                : progressMuted,
                                            fontWeight: FontWeight.w500))),
                                const SizedBox(height: 78),
                                Text(bars[i].label,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        height: 1.3,
                                        color: selected == i
                                            ? progressSilver
                                            : progressMuted)),
                              ])))))))
      ]));
      final grid = Positioned(
          left: 0,
          right: 0,
          top: 22 * scale,
          height: 72,
          child: CustomPaint(painter: _GridPainter()));
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: width,
              child: MotionProgress(
                  dataKey: bars.map((b) => '${b.label}:${b.value}').join('|'),
                  builder: (context, progress) => Stack(children: [
                        grid,
                        Positioned(
                            left: 0,
                            right: 0,
                            top: 22 * scale,
                            height: 72,
                            child: RepaintBoundary(
                                child: Transform.scale(
                                    scaleX: 1,
                                    scaleY: progress,
                                    alignment: Alignment.bottomCenter,
                                    child: plot))),
                        labels,
                      ]))));
    });
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DSColors.border
      ..strokeWidth = .5;
    for (final fraction in [0.0, .5, 1.0]) {
      canvas.drawLine(Offset(0, size.height * fraction),
          Offset(size.width, size.height * fraction), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

const progressMacroColors = [
  Color(0xFF8CBCEB),
  Color(0xFFB4A0E6),
  Color(0xFFE6BC86)
];

class ProgressDonutPainter extends CustomPainter {
  final List<double> values;
  final double progress;
  final int? selected;
  ProgressDonutPainter(this.values, this.progress, this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = DSColors.bgRaised;
    canvas.drawCircle(centre, radius, track);
    canvas.drawCircle(
        centre,
        radius - 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = DSColors.border);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final gap = math.min(.045, sweep * .1);
      if (sweep > 0) {
        canvas.drawArc(
            rect,
            start + gap / 2,
            math.max(0, sweep - gap) * progress,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = selected == i ? 18 : 14
              ..strokeCap = StrokeCap.round
              ..color = progressMacroColors[i].withValues(
                  alpha: selected == null || selected == i ? 1 : .3));
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(ProgressDonutPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString() ||
      oldDelegate.progress != progress ||
      oldDelegate.selected != selected;
}
