import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'liquid_wave_path.dart';

/// A gravity-aligned free surface inside a sealed, rounded tank.
class GravityWaterSurface {
  GravityWaterSurface(
      {required this.size,
      required this.fill,
      this.angle = 0,
      this.phase = 0,
      this.amplitude = 3,
      this.surface});
  final Size size;
  final double fill, angle, phase, amplitude;
  final List<double>? surface;
  late final rect = (Offset.zero & size).deflate(1);
  late final vessel =
      RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide * .23));
  late final center = rect.center;
  late final _cos = math.cos(angle), _sin = math.sin(angle);
  late final _outline = _roundedOutline().map(toLocal).toList();
  late final minU = _outline.map((p) => p.dx).reduce(math.min);
  late final maxU = _outline.map((p) => p.dx).reduce(math.max);
  late final minV = _outline.map((p) => p.dy).reduce(math.min);
  late final maxV = _outline.map((p) => p.dy).reduce(math.max);
  static const _resolution = 96;
  late final _columns = List.generate(_resolution, (i) {
    final u = minU + (maxU - minU) * (i + .5) / _resolution;
    var low = double.infinity, high = double.negativeInfinity;
    for (var edge = 0; edge < _outline.length; edge++) {
      final a = _outline[edge], b = _outline[(edge + 1) % _outline.length];
      if ((a.dx <= u && b.dx > u) || (b.dx <= u && a.dx > u)) {
        final v = a.dy + (b.dy - a.dy) * (u - a.dx) / (b.dx - a.dx);
        low = math.min(low, v);
        high = math.max(high, v);
      }
    }
    return (low: low, high: high, wave: waveAt(u));
  });
  late final level = _solveLevel();

  List<Offset> _roundedOutline() {
    final radius = vessel.tlRadiusX;
    final centers = [
      Offset(rect.right - radius, rect.top + radius),
      Offset(rect.right - radius, rect.bottom - radius),
      Offset(rect.left + radius, rect.bottom - radius),
      Offset(rect.left + radius, rect.top + radius)
    ];
    return [
      for (var corner = 0; corner < 4; corner++)
        for (var step = 0; step <= 12; step++)
          centers[corner] +
              Offset(
                      math.cos(-math.pi / 2 +
                          corner * math.pi / 2 +
                          step * math.pi / 24),
                      math.sin(-math.pi / 2 +
                          corner * math.pi / 2 +
                          step * math.pi / 24)) *
                  radius
    ];
  }

  Offset toLocal(Offset point) {
    final p = point - center;
    return Offset(p.dx * _cos + p.dy * _sin, -p.dx * _sin + p.dy * _cos);
  }

  double waveAt(double u) {
    final samples = surface;
    if (samples != null && samples.length >= 2) {
      final position = ((u - minU) / (maxU - minU)).clamp(0.0, 1.0);
      final index = position * (samples.length - 1);
      final lower = index.floor(), upper = index.ceil();
      final height =
          ui.lerpDouble(samples[lower], samples[upper], index - lower)!;
      final meniscus =
          -.003 * (math.exp(-position * 24) + math.exp(-(1 - position) * 24));
      return size.shortestSide * (height + meniscus);
    }
    final x = u / math.max(size.width, size.height);
    return amplitude *
        (.64 * math.sin(x * math.pi * 1.7 - phase) +
            .28 * math.sin(x * math.pi - phase * .6 + 1.2) +
            .08 * math.sin(x * math.pi * 5.2 + phase * .7));
  }

  double get waveExtent => surface == null
      ? amplitude * 2
      : size.shortestSide *
          (surface!.fold<double>(
                  0, (value, height) => math.max(value, height.abs())) +
              .006);

  double _solveLevel() {
    var low = minV - waveExtent - 1, high = maxV + waveExtent + 1;
    if (fill <= 0) return high;
    if (fill >= 1) return low;
    final capacity =
        _columns.fold<double>(0, (sum, col) => sum + col.high - col.low);
    for (var pass = 0; pass < 22; pass++) {
      final mid = (low + high) / 2;
      var volume = 0.0;
      for (final col in _columns) {
        volume += (col.high - math.max(col.low, mid + col.wave))
            .clamp(0.0, col.high - col.low);
      }
      if (volume > capacity * fill) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  double surfaceAt(double u) => level + waveAt(u);
  bool containsWater(Offset point) {
    if (!vessel.contains(point) || fill <= 0) return false;
    final local = toLocal(point);
    return local.dy >= surfaceAt(local.dx);
  }

  List<Offset> get crest => List.generate(65, (i) {
        final u = minU - 1 + (maxU - minU + 2) * i / 64;
        return Offset(u, surfaceAt(u));
      });
  Path bodyPath(List<Offset> crest) => liquidCurve(crest)
    ..lineTo(maxU + 2, maxV + waveExtent + 2)
    ..lineTo(minU - 2, maxV + waveExtent + 2)
    ..close();
}

void paintLiquidPool(Canvas canvas, Size size,
    {required double fraction,
    required double roll,
    required double pitch,
    required double phase,
    required double settle,
    required double energy,
    required Color tint,
    List<double>? surface,
    bool perspective = true}) {
  if (size.isEmpty) return;
  final tank = GravityWaterSurface(
      size: size,
      // Leave air for the surface to move even at the daily goal.
      fill: fraction.clamp(0.0, 1.0) * (perspective ? .92 : 1),
      angle: roll,
      phase: phase,
      surface: surface,
      amplitude: size.shortestSide * (.035 + .13 * energy * (1 - settle)));
  final rect = tank.rect;
  canvas.save();
  canvas.clipRRect(tank.vessel);
  final glassPaint = Paint()..color = const Color(0xFF17191B);
  if (perspective) {
    glassPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF10171B), Color(0xFF151D22)]).createShader(rect);
  }
  canvas.drawRect(rect, glassPaint);
  if (fraction > 0) {
    final crest = tank.crest;
    final body = tank.bodyPath(crest);
    // Only fluid rotates: the glass, labels and touch target stay fixed.
    canvas.save();
    canvas.translate(tank.center.dx, tank.center.dy);
    canvas.rotate(roll);
    final deepest = math.max(tank.level + 1, tank.maxV);
    final bounds = Rect.fromLTRB(tank.minU, tank.level - tank.waveExtent,
        tank.maxU, deepest + tank.waveExtent);
    canvas.drawPath(
        body,
        Paint()
          ..shader =
              ui.Gradient.linear(Offset(0, tank.level), Offset(0, deepest), [
            Color.lerp(tint, Colors.white, .06)!.withValues(alpha: .72),
            Color.lerp(
                    tint,
                    perspective ? const Color(0xFF123847) : Colors.black,
                    perspective ? .6 : .28)!
                .withValues(alpha: .94)
          ]));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
        bounds,
        Paint()
          ..shader = RadialGradient(
              center: Alignment(.3 * math.sin(phase * .3), -.35),
              radius: .9,
              colors: [
                Colors.white.withValues(alpha: .045),
                Colors.transparent
              ]).createShader(bounds));
    for (var band = 0; band < (perspective ? 2 : 0); band++) {
      final points = crest
          .map((point) => Offset(
              point.dx,
              point.dy +
                  (deepest - point.dy) * (.2 + band * .23) +
                  math.sin(point.dx / size.width * 8 - phase * .6 + band) *
                      1.5))
          .toList();
      canvas.drawPath(
          liquidCurve(points),
          Paint()
            ..color = Colors.white.withValues(alpha: .018)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1);
    }
    canvas.restore();
    // The meniscus follows the fluid and refracts light at its surface.
    final rimDepth = math.min(
        2.0, size.shortestSide * (.015 + .012 * math.sin(pitch).abs()));
    final rim = liquidCurve(crest);
    appendLiquidCurve(
        rim, crest.reversed.map((p) => p + Offset(0, rimDepth)).toList(),
        move: false);
    rim.close();
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
        rim,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, tank.level), Offset(0, tank.level + rimDepth), [
            Colors.white.withValues(alpha: .16),
            tint.withValues(alpha: 0)
          ]));
    canvas.restore();
    canvas.drawPath(
        liquidCurve(crest),
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(tank.minU, tank.level),
              Offset(tank.maxU, tank.level),
              const [Color(0x12FFFFFF), Color(0x50FFFFFF), Color(0x20FFFFFF)],
              const [0, .5, 1])
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65);
    canvas.restore();
  }
  if (!perspective) {
    for (final step in [.25, .5, .75]) {
      canvas.drawLine(
          Offset(size.width - 11, size.height * step),
          Offset(size.width - 6, size.height * step),
          Paint()
            ..color = const Color(0x29FFFFFF)
            ..strokeWidth = 1);
    }
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(7, 8, 1.2, math.max(0, size.height - 16)),
          const Radius.circular(2)),
      Paint()..color = const Color(0x0CFFFFFF));
  canvas.restore();
  canvas.drawRRect(
      tank.vessel,
      Paint()
        ..color = const Color(0x30CFDCE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7);
}
