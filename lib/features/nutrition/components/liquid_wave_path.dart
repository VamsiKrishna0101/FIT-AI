import 'package:flutter/material.dart';

/// Continuous tangents keep the meniscus smooth even in small nutrient meters.
Path liquidCurve(List<Offset> points) {
  final path = Path();
  appendLiquidCurve(path, points);
  return path;
}

void appendLiquidCurve(Path path, List<Offset> points, {bool move = true}) {
  if (points.isEmpty) return;
  if (move) {
    path.moveTo(points.first.dx, points.first.dy);
  } else {
    path.lineTo(points.first.dx, points.first.dy);
  }
  for (var i = 0; i < points.length - 1; i++) {
    final before = points[i == 0 ? 0 : i - 1];
    final start = points[i], end = points[i + 1];
    final after = points[i + 2 < points.length ? i + 2 : i + 1];
    final a = start + (end - before) / 6;
    final b = end - (after - start) / 6;
    path.cubicTo(a.dx, a.dy, b.dx, b.dy, end.dx, end.dy);
  }
}
