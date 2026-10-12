import '../../../../core/localization/fitness_copy.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_drawing/path_drawing.dart';
import 'anatomy_path_data.dart';

const _groups = <String, String>{
  'chest': 'chest',
  'deltoids': 'shoulders',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'forearm': 'forearms',
  'trapezius': 'upper_back',
  'upper-back': 'lats',
  'lower-back': 'lower_back',
  'abs': 'core',
  'obliques': 'core',
  'gluteal': 'glutes',
  'quadriceps': 'quads',
  'hamstring': 'hamstrings',
  'calves': 'calves'
};
final _cache = <String, Map<String, List<Path>>>{};

Map<String, List<Path>> _geometry(bool back, bool female) {
  final key = '${female ? 'female' : 'male'}_${back ? 'back' : 'front'}';
  return _cache.putIfAbsent(key, () {
    final source = {
      for (final entry in anatomyPathData[key]!.entries)
        entry.key: [for (final path in entry.value) parseSvgPathData(path)]
    };
    final box = source.values
        .expand((paths) => paths)
        .map((path) => path.getBounds())
        .reduce((a, b) => a.expandToInclude(b));
    final scale = math.min(200 / box.width, 420 / box.height);
    final matrix = Float64List.fromList([
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      110 - box.center.dx * scale,
      220 - box.center.dy * scale,
      0,
      1
    ]);
    return {
      for (final entry in source.entries)
        entry.key: [for (final path in entry.value) path.transform(matrix)]
    };
  });
}

/// Painting and touch selection share the same licensed anatomical paths.
Map<String, List<Path>> musclePaths({required bool back, bool female = false}) {
  final result = <String, List<Path>>{};
  for (final entry in _geometry(back, female).entries) {
    final id = _groups[entry.key];
    if (id != null) result.putIfAbsent(id, () => []).addAll(entry.value);
  }
  return result;
}

class AnatomicalTrainingMap extends StatelessWidget {
  final bool back, female;
  final Map<String, Color> colors;
  final String? selected;
  final ValueChanged<String> onSelected;
  const AnatomicalTrainingMap(
      {super.key,
      this.back = false,
      this.female = false,
      this.colors = const {},
      this.selected,
      required this.onSelected});
  @override
  Widget build(BuildContext context) => AspectRatio(
      aspectRatio: 220 / 440,
      child: LayoutBuilder(
          builder: (context, constraints) => Semantics(
                label: fitnessText(
                    context, back ? 'Back muscle map' : 'Front muscle map'),
                child: GestureDetector(
                    onTapUp: (details) {
                      final point = Offset(
                          details.localPosition.dx * 220 / constraints.maxWidth,
                          details.localPosition.dy *
                              440 /
                              constraints.maxHeight);
                      for (final entry
                          in musclePaths(back: back, female: female).entries) {
                        if (entry.value.any((path) => path.contains(point))) {
                          onSelected(entry.key);
                          return;
                        }
                      }
                    },
                    child: RepaintBoundary(
                        child: CustomPaint(
                            isComplex: true,
                            painter: _AnatomyPainter(_geometry(back, female),
                                colors, selected, back)))),
              )));
}

class _AnatomyPainter extends CustomPainter {
  final Map<String, List<Path>> geometry;
  final Map<String, Color> colors;
  final String? selected;
  final bool back;
  _AnatomyPainter(this.geometry, this.colors, this.selected, this.back);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220, size.height / 440);
    final fill = Paint();
    final outline = Paint()..style = PaintingStyle.stroke;
    for (final entry in geometry.entries) {
      final id = _groups[entry.key];
      final color = id == null
          ? const Color(0xFF414141)
          : colors[id] ?? const Color(0xFF717171);
      for (final path in entry.value) {
        // Front-facing anatomical left is the viewer's right; the back reverses it.
        final center = path.getBounds().center.dx;
        final left = back ? center < 110 : center > 110;
        final sideColor = colors['${id}_${left ? 'left' : 'right'}'];
        canvas.drawPath(path, fill..color = sideColor ?? color);
        canvas.drawPath(
            path,
            outline
              ..strokeWidth = selected == id && id != null ? 1.8 : .5
              ..color = selected == id && id != null
                  ? const Color(0xFFF2F2F2)
                  : const Color(0xFFB2B2B2).withValues(alpha: .4));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnatomyPainter old) =>
      old.geometry != geometry ||
      !mapEquals(old.colors, colors) ||
      old.selected != selected;
}
