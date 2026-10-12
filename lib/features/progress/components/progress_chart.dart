import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressChart extends StatefulWidget {
  final List<ProgressPoint> points;
  final String unit;
  final bool bars, daily, average, showReference, compactHeader;
  final Color color;
  final double height;
  final double? maximum, reference;
  final String referenceLabel;
  final String? summaryLabel;
  const ProgressChart({
    super.key,
    required this.points,
    this.unit = '',
    this.bars = false,
    this.daily = false,
    this.average = false,
    this.showReference = false,
    this.compactHeader = false,
    this.color = progressBlue,
    this.height = 150,
    this.maximum,
    this.reference,
    this.referenceLabel = 'Recorded-day average',
    this.summaryLabel,
  });

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  int? _selected;

  @override
  void didUpdateWidget(ProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return const ProgressEmpty('No readings in this period');
    }
    final index = (_selected ?? points.length - 1).clamp(0, points.length - 1);
    final selected = points[index];
    final locale = Localizations.localeOf(context).toLanguageTag();
    final average = points.fold<double>(0, (sum, point) => sum + point.value) /
        points.length;
    final reference = widget.showReference ? widget.reference ?? average : null;
    final low = widget.bars || widget.maximum != null
        ? 0.0
        : points.map((point) => point.value).reduce(math.min);
    final high = widget.maximum ??
        math.max(points.map((point) => point.value).reduce(math.max),
            reference ?? low);
    final pad = widget.bars || widget.maximum != null
        ? 0.0
        : math.max(.5, (high - low) * .18);
    final min = low - pad;
    final max = math.max(min + 1, high + pad).toDouble();
    final headline =
        widget.average && _selected == null ? average : selected.value;
    final headlineLabel = _selected != null
        ? 'Selected reading'
        : widget.average
            ? 'Recorded-day average'
            : widget.summaryLabel ?? 'Latest reading';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: widget.compactHeader
                ? Text(
                    '${fitnessText(context, headlineLabel)} · ${progressValue(context, headline, unit: widget.unit)}',
                    style: const TextStyle(fontSize: 11, color: progressMuted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(fitnessText(context, headlineLabel),
                            style: const TextStyle(
                                fontSize: 11, color: progressMuted)),
                        const SizedBox(height: 4),
                        Text.rich(
                            TextSpan(children: [
                              TextSpan(text: progressValue(context, headline)),
                              if (widget.unit.isNotEmpty)
                                TextSpan(
                                    text:
                                        ' ${fitnessText(context, widget.unit)}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: progressMuted,
                                        letterSpacing: 0)),
                            ]),
                            style: TextStyle(
                                color: widget.color,
                                fontSize: 33,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.1)),
                      ])),
        if (widget.average && _selected == null)
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                  fitnessText(context, '{count} recorded days',
                      values: {'count': points.length}),
                  style: const TextStyle(fontSize: 10, color: progressMuted)))
        else
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(DateFormat.MMMd(locale).format(selected.date),
                  style: const TextStyle(color: progressMuted, fontSize: 11))),
      ]),
      SizedBox(height: widget.compactHeader ? 12 : 18),
      SizedBox(
          height: widget.height,
          child: Row(children: [
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              void select(Offset position) {
                final geometry = _ChartGeometry(points,
                    Size(constraints.maxWidth, widget.height), min, max);
                var candidate = 0;
                var distance = double.infinity;
                for (var i = 0; i < points.length; i++) {
                  final next = (geometry.position(i).dx - position.dx).abs();
                  if (next < distance) {
                    candidate = i;
                    distance = next;
                  }
                }
                if (candidate != _selected) {
                  setState(() => _selected = candidate);
                }
              }

              return Semantics(
                  label:
                      '${progressValue(context, headline, unit: widget.unit)}, ${DateFormat.yMMMd(locale).format(selected.date)}',
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => select(details.localPosition),
                      onHorizontalDragUpdate: (details) =>
                          select(details.localPosition),
                      child: RepaintBoundary(
                          child: CustomPaint(
                              size: Size(constraints.maxWidth, widget.height),
                              painter: _ChartPainter(
                                  points: points,
                                  min: min,
                                  max: max,
                                  color: widget.color,
                                  bars: widget.bars,
                                  daily: widget.daily,
                                  selected: _selected,
                                  reference: reference)))));
            })),
            const SizedBox(width: 10),
            SizedBox(
                width: 32,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [max, (max + min) / 2, min]
                        .map((value) => Text(
                            progressValue(context, value,
                                digits: max - min < 3 ? 1 : 0),
                            style: const TextStyle(
                                fontSize: 10, color: progressMuted)))
                        .toList())),
          ])),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.only(right: 42),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat.MMMd(locale).format(points.first.date),
                style: const TextStyle(fontSize: 10, color: progressMuted)),
            if (points.length > 2)
              Text(
                  DateFormat.MMMd(locale)
                      .format(points[points.length ~/ 2].date),
                  style: const TextStyle(fontSize: 10, color: progressMuted)),
            if (points.length > 1)
              Text(DateFormat.MMMd(locale).format(points.last.date),
                  style: const TextStyle(fontSize: 10, color: progressMuted)),
          ])),
      if (reference != null)
        Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Row(children: [
              Text('– –', style: TextStyle(color: widget.color, fontSize: 12)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(fitnessText(context, widget.referenceLabel),
                      style:
                          const TextStyle(fontSize: 10, color: progressMuted))),
              Text(progressValue(context, reference, unit: widget.unit),
                  style: const TextStyle(fontSize: 11, color: progressSilver)),
            ])),
      if (points.length == 1)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(fitnessText(context, 'Your first data point'),
                style: const TextStyle(fontSize: 11, color: progressMuted))),
    ]);
  }
}

class ProgressSparkline extends StatelessWidget {
  final List<ProgressPoint> points;
  final Color color;
  final bool daily;
  const ProgressSparkline(
      {super.key,
      required this.points,
      this.color = progressCyan,
      this.daily = false});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final low = points.map((point) => point.value).reduce(math.min);
    final high = points.map((point) => point.value).reduce(math.max);
    final padding = math.max(1.0, (high - low) * .2);
    return RepaintBoundary(
        child: CustomPaint(
            size: const Size(70, 28),
            painter: _ChartPainter(
                points: points,
                min: low - padding,
                max: high + padding,
                color: color,
                daily: daily,
                compact: true)));
  }
}

class _ChartGeometry {
  final List<ProgressPoint> points;
  final Size size;
  final double min, max;
  const _ChartGeometry(this.points, this.size, this.min, this.max);

  double y(double value) =>
      size.height -
      4 -
      ((value - min) / (max - min)).clamp(0, 1) * (size.height - 8);

  Offset position(int index) {
    final duration = math.max(
        1, points.last.date.difference(points.first.date).inMilliseconds);
    final x = points.length == 1
        ? size.width / 2
        : 12 +
            (size.width - 24) *
                points[index]
                    .date
                    .difference(points.first.date)
                    .inMilliseconds /
                duration;
    return Offset(x, y(points[index].value));
  }
}

class _ChartPainter extends CustomPainter {
  final List<ProgressPoint> points;
  final double min, max;
  final Color color;
  final bool bars, daily, compact;
  final int? selected;
  final double? reference;
  const _ChartPainter({
    required this.points,
    required this.min,
    required this.max,
    required this.color,
    this.bars = false,
    this.daily = false,
    this.compact = false,
    this.selected,
    this.reference,
  });

  void _dash(Canvas canvas, Offset from, Offset to, Paint paint) {
    final vector = to - from;
    final length = vector.distance;
    if (length == 0) return;
    final unit = vector / length;
    for (var distance = 0.0; distance < length; distance += 7) {
      canvas.drawLine(from + unit * distance,
          from + unit * math.min(distance + 3, length), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width < 24) return;
    final geometry = _ChartGeometry(points, size, min, max);
    if (!compact) {
      final grid = Paint()
        ..color = const Color(0x1FFFFFFF)
        ..strokeWidth = .6;
      for (final y in [4.0, size.height / 2, size.height - 4]) {
        _dash(canvas, Offset(0, y), Offset(size.width, y), grid);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = compact ? 1.7 : 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (bars) {
      final slots = daily
          ? math.max(
              1, points.last.date.difference(points.first.date).inDays + 1)
          : points.length;
      final width = math.min(25.0, (size.width - 24) / slots * .65);
      for (var i = 0; i < points.length; i++) {
        if (points[i].value == 0) continue;
        final p = geometry.position(i);
        final rect = Rect.fromLTRB(
            p.dx - width / 2, p.dy, p.dx + width / 2, size.height - 4);
        final bar = Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: .4)]).createShader(rect);
        if (selected != null && selected != i) {
          bar.shader = null;
          bar.color = color.withValues(alpha: .3);
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)), bar);
      }
    } else {
      var start = 0;
      for (var i = 1; i <= points.length; i++) {
        final gap = i < points.length &&
            daily &&
            points[i].date.difference(points[i - 1].date).inDays > 1;
        if (i == points.length || gap) {
          final line = Path()
            ..moveTo(geometry.position(start).dx, geometry.position(start).dy);
          for (var j = start + 1; j < i; j++) {
            final p = geometry.position(j);
            line.lineTo(p.dx, p.dy);
          }
          if (i - start > 1) {
            final fill = Path.from(line)
              ..lineTo(geometry.position(i - 1).dx, size.height - 4)
              ..lineTo(geometry.position(start).dx, size.height - 4)
              ..close();
            canvas.drawPath(
                fill,
                Paint()
                  ..shader = LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: .18),
                        color.withValues(alpha: 0)
                      ]).createShader(Offset.zero & size));
            canvas.drawPath(line, paint);
          } else {
            canvas.drawCircle(
                geometry.position(start), 2.5, Paint()..color = color);
          }
          start = i;
        }
      }
      if (!compact) {
        final last = geometry.position(selected ?? points.length - 1);
        canvas.drawCircle(last, 5, Paint()..color = const Color(0xFF1D1E20));
        canvas.drawCircle(last, 3.5, Paint()..color = color);
      }
    }
    if (reference != null && !compact) {
      _dash(
          canvas,
          Offset(0, geometry.y(reference!)),
          Offset(size.width, geometry.y(reference!)),
          Paint()
            ..color = color.withValues(alpha: .65)
            ..strokeWidth = 1);
    }
    if (selected != null && !compact) {
      final p = geometry.position(selected!);
      _dash(
          canvas,
          Offset(p.dx, 0),
          Offset(p.dx, size.height),
          Paint()
            ..color = progressSilver.withValues(alpha: .5)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.color != color ||
      old.bars != bars ||
      old.daily != daily ||
      old.compact != compact ||
      old.reference != reference ||
      old.min != min ||
      old.max != max;
}
