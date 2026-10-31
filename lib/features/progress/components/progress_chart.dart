import '../../../core/components/motion.dart';
import '../../../core/theme/ds_motion.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressChart extends StatefulWidget {
  final List<ProgressPoint> points;
  final String unit;
  final int digits;
  final bool bars,
      daily,
      average,
      showReference,
      compactHeader,
      showReadings,
      showChange;
  final Color color;
  final double height, headlineSize;
  final double? maximum, reference;
  final String referenceLabel;
  final String? summaryLabel;
  const ProgressChart({
    super.key,
    required this.points,
    this.unit = '',
    this.digits = 1,
    this.bars = false,
    this.daily = false,
    this.average = false,
    this.showReference = false,
    this.compactHeader = false,
    this.showReadings = false,
    this.showChange = false,
    this.color = progressBlue,
    this.height = 150,
    this.headlineSize = 31,
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
  int _readingCount = 7;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _selectIndex(int index) {
    final next = index.clamp(0, widget.points.length - 1);
    if (_selected == next) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = next);
  }

  @override
  void didUpdateWidget(ProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_chartKey(oldWidget.points) != _chartKey(widget.points)) {
      _selected = null;
      _readingCount = 7;
    }
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
    final scale = _ChartScale(points,
        zero: widget.bars || widget.maximum != null,
        maximum: widget.maximum,
        reference: reference,
        integer: widget.digits == 0);
    final min = scale.min, max = scale.max;
    String axisValue(double value) => value.abs() >= 10000
        ? NumberFormat.compact(locale: locale).format(value)
        : progressValue(context, value, digits: scale.step % 1 == 0 ? 0 : 1);
    final axisWidth = math.max(
        40.0,
        MediaQuery.textScalerOf(context).scale(12) *
            scale.ticks.map((v) => axisValue(v).length).reduce(math.max) *
            .62);
    final headline =
        widget.average && _selected == null ? average : selected.value;
    final headlineLabel = _selected != null
        ? 'Selected reading'
        : widget.average
            ? 'Recorded-day average'
            : widget.summaryLabel ?? 'Latest reading';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.compactHeader)
        Text(
            '${fitnessText(context, headlineLabel)} · ${progressValue(context, headline, unit: widget.unit, digits: widget.digits)}',
            style: const TextStyle(fontSize: 12, color: progressMuted))
      else ...[
        Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: progressValue(context, headline,
                            digits: widget.digits)),
                    if (widget.unit.isNotEmpty)
                      TextSpan(
                          text: ' ${fitnessText(context, widget.unit)}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: progressMuted,
                              letterSpacing: 0)),
                  ]),
                  style: TextStyle(
                      color: progressSilver,
                      fontSize: widget.headlineSize,
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.1)),
              if (widget.showChange && points.length > 1 && _selected == null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                        '${points.last.value - points.first.value > 0 ? '+' : ''}${progressValue(context, points.last.value - points.first.value, unit: widget.unit, digits: widget.digits)}',
                        style: const TextStyle(
                            fontSize: 14, color: progressMuted))),
            ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(fitnessText(context, headlineLabel),
                  style: const TextStyle(fontSize: 12, color: progressMuted))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(
                  widget.average && _selected == null
                      ? fitnessText(context, '{count} recorded days',
                          values: {'count': points.length})
                      : DateFormat.MMMd(locale).format(selected.date),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: progressMuted))),
        ]),
      ],
      SizedBox(height: widget.compactHeader ? 12 : 16),
      if (points.length > 1) ...[
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
                  _selectIndex(candidate);
                }

                return Focus(
                    focusNode: _focus,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                        return KeyEventResult.ignored;
                      }
                      final key = event.logicalKey;
                      if (key == LogicalKeyboardKey.arrowLeft ||
                          key == LogicalKeyboardKey.arrowRight) {
                        _selectIndex(index +
                            (key == LogicalKeyboardKey.arrowRight ? 1 : -1));
                      } else if (key == LogicalKeyboardKey.home) {
                        _selectIndex(0);
                      } else if (key == LogicalKeyboardKey.end) {
                        _selectIndex(points.length - 1);
                      } else {
                        return KeyEventResult.ignored;
                      }
                      return KeyEventResult.handled;
                    },
                    child: Semantics(
                        label:
                            '${progressValue(context, headline, unit: widget.unit)}, ${DateFormat.yMMMd(locale).format(selected.date)}',
                        onIncrease: index < points.length - 1
                            ? () => _selectIndex(index + 1)
                            : null,
                        onDecrease:
                            index > 0 ? () => _selectIndex(index - 1) : null,
                        child: GestureDetector(
                            key: const ValueKey('progress-chart-plot'),
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              _focus.requestFocus();
                              select(details.localPosition);
                            },
                            onHorizontalDragUpdate: (details) =>
                                select(details.localPosition),
                            child: RepaintBoundary(
                                child: MotionProgress(
                                    dataKey:
                                        '${widget.bars}:${widget.unit}:${_chartKey(points)}',
                                    builder: (context, progress) => CustomPaint(
                                        size: Size(constraints.maxWidth,
                                            widget.height),
                                        painter: _ChartPainter(
                                            points: points,
                                            progress: progress,
                                            min: min,
                                            max: max,
                                            color: widget.color,
                                            bars: widget.bars,
                                            daily: widget.daily,
                                            selected: _selected,
                                            reference: reference,
                                            ticks: scale.ticks)))))));
              })),
              const SizedBox(width: 10),
              SizedBox(
                  width: axisWidth,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: scale.ticks
                          .map((value) => Text(axisValue(value),
                              style: const TextStyle(
                                  fontSize: 12, color: progressMuted)))
                          .toList())),
            ])),
        const SizedBox(height: 10),
        Padding(
            padding: EdgeInsets.only(right: axisWidth + 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(
                          DateFormat.MMMd(locale).format(points.first.date),
                          style: const TextStyle(
                              fontSize: 12, color: progressMuted))),
                  if (points.length > 2 &&
                      MediaQuery.sizeOf(context).width >= 380 &&
                      MediaQuery.textScalerOf(context).scale(12) <= 16)
                    Expanded(
                        child: Text(
                            DateFormat.MMMd(locale)
                                .format(points[points.length ~/ 2].date),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: progressMuted))),
                  if (points.length > 1)
                    Expanded(
                        child: Text(
                            DateFormat.MMMd(locale).format(points.last.date),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 12, color: progressMuted))),
                ])),
      ],
      if (reference != null)
        Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Row(children: [
              Text('– –', style: TextStyle(color: widget.color, fontSize: 12)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(fitnessText(context, widget.referenceLabel),
                      style:
                          const TextStyle(fontSize: 12, color: progressMuted))),
              Text(progressValue(context, reference, unit: widget.unit),
                  style: const TextStyle(fontSize: 12, color: progressSilver)),
            ])),
      if (points.length == 1)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                fitnessText(context, 'More readings will reveal your trend.'),
                style: const TextStyle(fontSize: 12, color: progressMuted))),
      if (widget.showReadings) ...[
        const SizedBox(height: 12),
        Text(fitnessText(context, 'Tap the chart to explore readings.'),
            style: const TextStyle(fontSize: 12, color: progressMuted)),
        const SizedBox(height: 8),
        ExpansionTile(
            key: ValueKey('readings-${widget.unit}-${_chartKey(points)}'),
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(fitnessText(context, 'Recorded readings'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            children: [
              for (final point in points.reversed.take(_readingCount))
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              DateFormat.yMMMd(locale).format(point.date),
                              style: const TextStyle(
                                  fontSize: 13, color: progressMuted))),
                      const SizedBox(width: 10),
                      Flexible(
                          child: Text(
                              progressValue(context, point.value,
                                  unit: widget.unit, digits: widget.digits),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600))),
                    ])),
              if (_readingCount < points.length)
                TextButton(
                    onPressed: () => setState(() => _readingCount += 7),
                    child: Text(fitnessText(context, 'Load more'))),
            ]),
      ],
    ]);
  }
}

class ProgressSparkline extends StatelessWidget {
  final List<ProgressPoint> points;
  final Color color;
  final bool daily, bars;
  const ProgressSparkline(
      {super.key,
      required this.points,
      this.color = progressCyan,
      this.daily = false,
      this.bars = false});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final low = points.map((point) => point.value).reduce(math.min);
    final high = points.map((point) => point.value).reduce(math.max);
    final padding = math.max(1.0, (high - low) * .2);
    return RepaintBoundary(
        child: MotionProgress(
            dataKey: _chartKey(points),
            builder: (context, progress) => CustomPaint(
                size: const Size(70, 28),
                painter: _ChartPainter(
                    points: points,
                    progress: progress,
                    min: bars ? 0 : low - padding,
                    max: high + padding,
                    color: color,
                    daily: daily,
                    bars: bars,
                    compact: true))));
  }
}

class _ChartGeometry {
  final List<ProgressPoint> points;
  final Size size;
  final double min, max;
  final double inset;
  const _ChartGeometry(this.points, this.size, this.min, this.max,
      {this.inset = 12});

  double y(double value) =>
      size.height -
      4 -
      ((value - min) / (max - min)).clamp(0, 1) * (size.height - 8);

  Offset position(int index) {
    final duration = math.max(
        1, points.last.date.difference(points.first.date).inMilliseconds);
    final x = points.length == 1
        ? size.width / 2
        : inset +
            (size.width - inset * 2) *
                points[index]
                    .date
                    .difference(points.first.date)
                    .inMilliseconds /
                duration;
    return Offset(x, y(points[index].value));
  }
}

/// Rounded, evenly spaced ticks keep the scale readable without changing data.
class _ChartScale {
  late final double min, max, step;
  late final List<double> ticks;
  _ChartScale(List<ProgressPoint> points,
      {required bool zero,
      bool integer = false,
      double? maximum,
      double? reference}) {
    final low = zero ? 0.0 : points.map((p) => p.value).reduce(math.min);
    final high =
        math.max(points.map((p) => p.value).reduce(math.max), reference ?? low);
    final span = math.max(high - low, integer ? 1.0 : .1);
    final padding = zero ? span * .06 : span * .12;
    final lower = zero ? 0.0 : low - padding;
    final upper = maximum ?? high + padding;
    final rough = math.max((upper - lower) / 3, .001);
    final power =
        math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final fraction = rough / power;
    final nice = fraction <= 1
        ? 1.0
        : fraction <= 2
            ? 2.0
            : fraction <= 2.5
                ? 2.5
                : fraction <= 5
                    ? 5.0
                    : 10.0;
    step = math.max(integer ? 1.0 : .001, nice * power);
    final lowerTick = zero ? 0.0 : (lower / step).floor() * step;
    min = low >= 0 ? math.max(0, lowerTick).toDouble() : lowerTick;
    max = maximum ?? math.max(min + step, (upper / step).ceil() * step);
    // A fixed bound (for example a score out of 100) stays exact.
    ticks = maximum != null
        ? [max, (max + min) / 2, min]
        : [
            for (var value = max; value >= min - step * .01; value -= step)
              value.abs() < step * .001 ? 0 : value
          ];
  }
}

/// Monotone cubic interpolation softens corners while preserving each reading
/// and keeping the curve within the adjacent points' values.
Path _trendPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) return path;
  final widths = <double>[], slopes = <double>[];
  for (var i = 0; i < points.length - 1; i++) {
    final dx = points[i + 1].dx - points[i].dx;
    if (dx <= 0) {
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path;
    }
    widths.add(dx);
    slopes.add((points[i + 1].dy - points[i].dy) / dx);
  }
  final tangents = List<double>.filled(points.length, 0);
  tangents[0] = slopes.first;
  tangents[points.length - 1] = slopes.last;
  for (var i = 1; i < points.length - 1; i++) {
    final a = slopes[i - 1], b = slopes[i];
    if (a * b > 0) {
      final w1 = 2 * widths[i] + widths[i - 1];
      final w2 = widths[i] + 2 * widths[i - 1];
      tangents[i] = (w1 + w2) / (w1 / a + w2 / b);
    }
  }
  for (var i = 0; i < slopes.length; i++) {
    final slope = slopes[i];
    if (slope == 0) {
      tangents[i] = tangents[i + 1] = 0;
    } else {
      final a = tangents[i] / slope, b = tangents[i + 1] / slope;
      final magnitude = math.sqrt(a * a + b * b);
      if (magnitude > 3) {
        tangents[i] = 3 / magnitude * a * slope;
        tangents[i + 1] = 3 / magnitude * b * slope;
      }
    }
  }
  for (var i = 0; i < slopes.length; i++) {
    final p = points[i], q = points[i + 1], dx = widths[i] / 3;
    path.cubicTo(p.dx + dx, p.dy + tangents[i] * dx, q.dx - dx,
        q.dy - tangents[i + 1] * dx, q.dx, q.dy);
  }
  return path;
}

class _ChartPainter extends CustomPainter {
  final List<ProgressPoint> points;
  final double min, max, progress;
  final Color color;
  final bool bars, daily, compact;
  final int? selected;
  final double? reference;
  final List<double>? ticks;
  const _ChartPainter({
    required this.points,
    required this.min,
    required this.max,
    required this.color,
    this.progress = 1,
    this.bars = false,
    this.daily = false,
    this.compact = false,
    this.selected,
    this.reference,
    this.ticks,
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
    final geometry = _ChartGeometry(points, size, min, max,
        inset: compact
            ? bars
                ? math.min(14, size.width / points.length * .4 + 2)
                : 2
            : 12);
    if (!compact) {
      final grid = Paint()
        ..color = const Color(0x12FFFFFF)
        ..strokeWidth = .7;
      for (final value in ticks ?? [max, (max + min) / 2, min]) {
        final y = geometry.y(value);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = compact ? 1.8 : 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (bars) {
      final slots = daily
          ? math.max(
              1, points.last.date.difference(points.first.date).inDays + 1)
          : points.length;
      final width =
          math.min(24.0, (size.width - geometry.inset * 2) / slots * .65);
      for (var i = 0; i < points.length; i++) {
        if (points[i].value == 0) continue;
        final p = geometry.position(i);
        final rect = Rect.fromLTRB(
            p.dx - width / 2,
            size.height -
                4 -
                (size.height - 4 - p.dy) *
                    DSMotion.barProgress(progress, i, points.length),
            p.dx + width / 2,
            size.height - 4);
        final bar = Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: .72)]).createShader(rect);
        if (selected != null && selected != i) {
          bar.shader = null;
          bar.color = color.withValues(alpha: .3);
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)), bar);
      }
    } else {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0,
          size.width * DSMotion.effects.transform(progress), size.height));
      var start = 0;
      for (var i = 1; i <= points.length; i++) {
        final gap = i < points.length &&
            daily &&
            points[i].date.difference(points[i - 1].date).inDays > 1;
        if (i == points.length || gap) {
          final line = _trendPath([
            for (var j = start; j < i; j++) geometry.position(j),
          ]);
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
                        color.withValues(alpha: compact ? .07 : .12),
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
        if (points.length <= 12) {
          for (var i = 0; i < points.length; i++) {
            canvas.drawCircle(geometry.position(i), 1.8,
                Paint()..color = color.withValues(alpha: .8));
          }
        }
        final last = geometry.position(selected ?? points.length - 1);
        canvas.drawCircle(last, 5, Paint()..color = const Color(0xFF1D1E20));
        canvas.drawCircle(last, 3.5, Paint()..color = color);
      }
    }
    if (!bars) canvas.restore();
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
      canvas.drawLine(
          Offset(p.dx, 0),
          Offset(p.dx, size.height),
          Paint()
            ..color = progressSilver.withValues(alpha: .24)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.selected != selected ||
      old.color != color ||
      old.bars != bars ||
      old.daily != daily ||
      old.compact != compact ||
      old.reference != reference ||
      old.ticks != ticks ||
      old.min != min ||
      old.max != max;
}

String _chartKey(List<ProgressPoint> points) => points
    .map((point) => '${point.date.microsecondsSinceEpoch}:${point.value}')
    .join('|');
