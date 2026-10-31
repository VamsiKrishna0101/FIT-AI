import 'dart:math' as math;

/// A damped, one-dimensional free surface. Heights are fractions of the
/// container's short side; rendering and the volume solver remain independent.
class LiquidSurfaceSimulation {
  LiquidSurfaceSimulation({this.seed = 0});

  static const sampleCount = 41;
  static const _step = 1 / 120;
  final double seed;
  final _heights = List<double>.filled(sampleCount, 0);
  final _velocities = List<double>.filled(sampleCount, 0);
  final _accelerations = List<double>.filled(sampleCount, 0);
  double _time = 0, _remainder = 0;

  List<double> get heights => List<double>.unmodifiable(_heights);

  void reset() {
    _heights.fillRange(0, sampleCount, 0);
    _velocities.fillRange(0, sampleCount, 0);
    _remainder = 0;
  }

  /// Add velocity, not height: a new disturbance never teleports the surface.
  void disturb({double position = .5, double velocity = .1}) {
    if (!position.isFinite || !velocity.isFinite) return;
    final center = position.clamp(0.0, 1.0);
    for (var i = 0; i < sampleCount; i++) {
      final distance = (i / (sampleCount - 1) - center) / .12;
      _velocities[i] = (_velocities[i] +
              velocity.clamp(-.25, .25) * math.exp(-distance * distance / 2))
          .clamp(-.6, .6);
    }
    _removeMean(_velocities);
  }

  void advance(double elapsed, {required double fill, bool ambient = false}) {
    if (!elapsed.isFinite || elapsed <= 0 || !fill.isFinite) return;
    if (fill <= 0 || fill >= 1) {
      reset();
      return;
    }
    // A paused page must not integrate its entire time away on the first frame.
    _remainder += elapsed.clamp(0.0, 1 / 15);
    final depth = math.sqrt(fill.clamp(0.0, 1.0));
    final speed = .45 + depth * .45;
    final coupling = speed * speed * (sampleCount - 1) * (sampleCount - 1);
    final limit = .08 * math.sqrt(math.min(fill, 1 - fill) * 2);
    while (_remainder >= _step) {
      _remainder -= _step;
      _time += _step;
      for (var i = 0; i < sampleCount; i++) {
        // Mirrored neighbours give closed, reflecting walls, not wraparound.
        final left = _heights[i == 0 ? 1 : i - 1];
        final right = _heights[i == sampleCount - 1 ? i - 1 : i + 1];
        final x = i / (sampleCount - 1);
        final clock = _time * (1 + .08 * math.sin(seed));
        final breeze = ambient
            ? .25 * math.sin(math.pi * 2 * x - clock * 1.4 + seed) +
                .1 * math.sin(math.pi * 4 * x + clock * 1.05 + seed * 1.7) +
                .04 * math.cos(math.pi * x) * math.sin(clock * .6 + seed * .4)
            : 0.0;
        _accelerations[i] = coupling * (left + right - 2 * _heights[i]) -
            2.5 * _heights[i] -
            2.8 * _velocities[i] +
            breeze;
      }
      for (var i = 0; i < sampleCount; i++) {
        _velocities[i] += _accelerations[i] * _step;
        final next = _heights[i] + _velocities[i] * _step;
        _heights[i] = next.clamp(-limit, limit);
        if (next.abs() > limit) _velocities[i] *= -.15;
      }
      _removeMean(_heights);
      _removeMean(_velocities);
    }
  }

  static void _removeMean(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    for (var i = 0; i < values.length; i++) {
      values[i] -= mean;
      if (values[i].abs() < .000001) values[i] = 0;
    }
  }
}
