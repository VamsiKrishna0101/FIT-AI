import 'dart:math' as math;

/// A damped, one-dimensional free surface. Heights are fractions of the
/// container's short side; rendering and the volume solver remain independent.
class LiquidSurfaceSimulation {
  LiquidSurfaceSimulation({this.seed = 0, int resolution = sampleCount})
      : assert(resolution >= 5 && resolution <= sampleCount),
        _heights = List<double>.filled(resolution, 0),
        _velocities = List<double>.filled(resolution, 0),
        _accelerations = List<double>.filled(resolution, 0);

  static const sampleCount = 65;
  static const _step = 1 / 120;
  final double seed;
  final List<double> _heights, _velocities, _accelerations;
  double _time = 0, _remainder = 0;
  double _seaExposure = 0, _fill = .5, _aspectRatio = 1;

  // Hot reload preserves old buffers even when the default resolution changes.
  // Every solver bound must use the live instance, not the new static default.
  int get resolution => _heights.length;

  List<double> get heights {
    if (_seaExposure < .000001) return List<double>.unmodifiable(_heights);
    final margin = math.min(_fill, 1 - _fill);
    final depthScale = math.sqrt(margin * 2);
    final amplitude = math.min(.062 * depthScale, margin * .55) * _seaExposure;
    final turns = 1.25 + math.log(_aspectRatio) * .25;
    final count = resolution;
    final values = List<double>.generate(count, (i) {
      final x = i / (count - 1);
      final swell = _gerstner(x, turns, seed - _time * 1.65, .48);
      final crossing =
          _gerstner(x, turns * 1.75, seed * 1.7 - _time * 2.2 + 2.1, .16);
      return _heights[i] + amplitude * (swell + crossing * .30);
    });
    _removeMean(values);
    final peak = values.fold<double>(0, (a, b) => math.max(a, b.abs()));
    final limit = .085 * depthScale;
    if (peak > limit) {
      for (var i = 0; i < values.length; i++) {
        values[i] *= limit / peak;
      }
    }
    return List<double>.unmodifiable(values);
  }

  /// Invert horizontal Gerstner displacement at a fixed sample position.
  /// Compression at the crest and wider troughs produce travelling swells.
  /// Steepness stays below 1 so the free surface never folds over itself.
  static double _gerstner(
      double x, double turns, double phase, double steepness) {
    final k = math.pi * 2 * turns;
    var q = x;
    for (var pass = 0; pass < 4; pass++) {
      final angle = k * q + phase;
      q -= (q + steepness / k * math.cos(angle) - x) /
          (1 - steepness * math.sin(angle));
    }
    return -math.sin(k * q + phase);
  }

  void reset() {
    _heights.fillRange(0, _heights.length, 0);
    _velocities.fillRange(0, _velocities.length, 0);
    _accelerations.fillRange(0, _accelerations.length, 0);
    _remainder = 0;
    _seaExposure = 0;
  }

  /// Add velocity, not height: a new disturbance never teleports the surface.
  void disturb({double position = .5, double velocity = .1}) {
    if (!position.isFinite || !velocity.isFinite) return;
    final center = position.clamp(0.0, 1.0);
    final count = resolution;
    for (var i = 0; i < count; i++) {
      final distance = (i / (count - 1) - center) / .12;
      _velocities[i] = (_velocities[i] +
              velocity.clamp(-.25, .25) * math.exp(-distance * distance / 2))
          .clamp(-.6, .6);
    }
    _removeMean(_velocities);
  }

  void advance(double elapsed,
      {required double fill, bool ambient = false, double aspectRatio = 1}) {
    if (!elapsed.isFinite || elapsed <= 0 || !fill.isFinite) return;
    if (fill <= 0 || fill >= 1) {
      reset();
      return;
    }
    _fill = fill;
    _aspectRatio = aspectRatio.isFinite ? aspectRatio.clamp(.5, 6.0) : 1;
    // A paused page must not integrate its entire time away on the first frame.
    _remainder += elapsed.clamp(0.0, 1 / 15);
    final depth = math.sqrt(fill.clamp(0.0, 1.0));
    final speed = .45 + depth * .45;
    final count = resolution;
    final intervals = count - 1;
    final coupling = speed * speed * intervals * intervals;
    // Surface tension disperses short ripples; viscosity removes their energy
    // faster than broad swells. The fixed step keeps this stable at 30–120 Hz.
    final tension = .000012 * intervals * intervals * intervals * intervals;
    final viscosity = .0012 * intervals * intervals;
    final limit = .08 * math.sqrt(math.min(fill, 1 - fill) * 2);
    while (_remainder >= _step) {
      _remainder -= _step;
      _time += _step;
      // Wind eases in and out without resetting phase or ripple momentum.
      _seaExposure +=
          ((ambient ? 1 : 0) - _seaExposure) * (1 - math.exp(-2.8 * _step));
      for (var i = 0; i < count; i++) {
        // Mirrored neighbours give closed, reflecting walls, not wraparound.
        final left = _heights[i == 0 ? 1 : i - 1];
        final right = _heights[i == count - 1 ? i - 1 : i + 1];
        final farLeft = _heights[_reflect(i - 2, count)];
        final farRight = _heights[_reflect(i + 2, count)];
        final curvature = left + right - 2 * _heights[i];
        final bending =
            farLeft - 4 * left + 6 * _heights[i] - 4 * right + farRight;
        final velocityCurve = _velocities[_reflect(i - 1, count)] +
            _velocities[_reflect(i + 1, count)] -
            2 * _velocities[i];
        final x = i / (count - 1);
        final clock = _time * (1 + .08 * math.sin(seed));
        final breeze = ambient
            ? .07 * math.sin(math.pi * 2 * x - clock * 1.4 + seed) +
                .04 * math.sin(math.pi * 4 * x + clock * 1.05 + seed * 1.7) +
                .025 *
                    math.cos(math.pi * x) *
                    math.sin(clock * .6 + seed * .4) +
                .014 * math.sin(math.pi * 8 * x - clock * 2.4 + seed * 2.3)
            : 0.0;
        _accelerations[i] = coupling * curvature -
            tension * bending +
            viscosity * velocityCurve -
            2.5 * _heights[i] -
            2.8 * _velocities[i] +
            breeze;
      }
      for (var i = 0; i < count; i++) {
        _velocities[i] += _accelerations[i] * _step;
        final next = _heights[i] + _velocities[i] * _step;
        _heights[i] = next.clamp(-limit, limit);
        if (next.abs() > limit) _velocities[i] *= -.15;
      }
      _removeMean(_heights);
      _removeMean(_velocities);
    }
  }

  static int _reflect(int index, int count) => index < 0
      ? -index
      : index >= count
          ? 2 * (count - 1) - index
          : index;

  static void _removeMean(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    for (var i = 0; i < values.length; i++) {
      values[i] -= mean;
      if (values[i].abs() < .000001) values[i] = 0;
    }
  }
}
