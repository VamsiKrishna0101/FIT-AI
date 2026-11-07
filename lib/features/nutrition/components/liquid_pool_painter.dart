import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'liquid_wave_path.dart';

/// Vessel capacity includes a small air gap above the recorded daily goal.
double liquidVesselFill(double fraction, {required bool perspective}) =>
    fraction.clamp(0.0, 1.0) * (perspective ? .92 : .94);

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
      final lower = index.floor();
      final t = index - lower;
      double at(int i) => samples[i.clamp(0, samples.length - 1)];
      final a = at(lower - 1),
          b = at(lower),
          c = at(lower + 1),
          d = at(lower + 2);
      final height = b +
          t *
              (.5 * (c - a) +
                  t *
                      (a -
                          2.5 * b +
                          2 * c -
                          .5 * d +
                          t * (.5 * (d - a) + 1.5 * (b - c))));
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
    ui.FragmentShader? optics,
    bool perspective = true}) {
  if (size.isEmpty) return;
  final tank = GravityWaterSurface(
      size: size,
      // Leave air for the surface to move even at the daily goal.
      fill: liquidVesselFill(fraction, perspective: perspective),
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
    final waterPaint = Paint();
    if (optics != null) {
      // Keep uniform order in sync with shaders/water_optics.frag.
      final uniforms = [
        size.width,
        size.height,
        tank.minU,
        tank.maxU,
        deepest,
        phase,
        pitch,
        energy,
        tint.r,
        tint.g,
        tint.b,
        perspective ? 1.0 : 0.0,
        for (var i = 0; i <= 64; i++)
          tank.surfaceAt(tank.minU + (tank.maxU - tank.minU) * i / 64),
      ];
      for (var i = 0; i < uniforms.length; i++) {
        optics.setFloat(i, uniforms[i]);
      }
      waterPaint.shader = optics;
    } else {
      waterPaint.shader =
          ui.Gradient.linear(Offset(0, tank.level), Offset(0, deepest), [
        Color.lerp(tint, Colors.white, .18)!.withValues(alpha: .85),
        Color.lerp(tint, const Color(0xFF003875), perspective ? .5 : .25)!
            .withValues(alpha: .96)

      ]);
    }
    canvas.drawPath(body, waterPaint);
    if (optics == null) {
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
      canvas.restore();
    }
    // The meniscus follows the fluid and refracts light at its surface.
    final rimDepth = math.min(
        (deepest - tank.level).clamp(0.0, size.shortestSide) * .38,
        size.shortestSide * (.065 + .012 * math.sin(pitch)));
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
            Colors.white.withValues(alpha: optics == null ? .22 : .06),
            tint.withValues(alpha: 0)
          ]));
    canvas.restore();
    canvas.drawPath(
        liquidCurve(crest),
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(tank.minU, tank.level),
              Offset(tank.maxU, tank.level),
              const [Color(0x0CFFFFFF), Color(0x70FFFFFF), Color(0x14FFFFFF)],
              [0, .5 + .18 * math.sin(phase * .2), 1])
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65);
    canvas.restore();
  }
  canvas.restore();
  canvas.drawRRect(
      tank.vessel,
      Paint()
        ..color = const Color(0x30CFDCE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7);
}
