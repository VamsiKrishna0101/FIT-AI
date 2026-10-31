import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/components/liquid_surface_simulation.dart';

double peak(LiquidSurfaceSimulation surface) =>
    surface.heights.map((height) => height.abs()).reduce(math.max);

void run(LiquidSurfaceSimulation surface, double seconds,
    {double fill = .5, bool ambient = false, int fps = 120}) {
  for (var frame = 0; frame < (seconds * fps).round(); frame++) {
    surface.advance(1 / fps, fill: fill, ambient: ambient);
  }
}

void main() {
  test('A disturbance adds momentum without teleporting the surface', () {
    final surface = LiquidSurfaceSimulation();
    surface.disturb(position: .5, velocity: .18);
    expect(peak(surface), 0);
    run(surface, .15);
    expect(peak(surface), greaterThan(.001));
    final heights = surface.heights;
    for (var i = 0; i < heights.length; i++) {
      expect(heights[i], closeTo(heights[heights.length - 1 - i], .000001));
    }
    expect(
        heights.reduce((a, b) => a + b) / heights.length, closeTo(0, .000001));
  });

  test('Unforced ripples lose energy and settle', () {
    final surface = LiquidSurfaceSimulation();
    surface.disturb(position: .18, velocity: .2);
    run(surface, .25);
    final moving = peak(surface);
    run(surface, 6);
    expect(moving, greaterThan(.001));
    expect(peak(surface), lessThan(.00003));
  });

  test('Fixed substeps produce the same motion at different frame rates', () {
    final slow = LiquidSurfaceSimulation(seed: .7);
    final fast = LiquidSurfaceSimulation(seed: .7);
    slow.disturb(position: .3, velocity: .15);
    fast.disturb(position: .3, velocity: .15);
    run(slow, 2, ambient: true, fps: 30);
    run(fast, 2, ambient: true);
    for (var i = 0; i < slow.heights.length; i++) {
      expect(slow.heights[i], closeTo(fast.heights[i], .000001));
    }
  });

  test('Independent meters have visible, different rolling waves', () {
    final protein = LiquidSurfaceSimulation(seed: .7);
    final carbs = LiquidSurfaceSimulation(seed: 2.9);
    run(protein, 3, ambient: true);
    run(carbs, 3, ambient: true);
    expect(peak(protein), greaterThan(.008));
    expect(peak(protein), lessThan(.055));
    expect(protein.heights, isNot(orderedEquals(carbs.heights)));
  });

  test('Repeated disturbances stay bounded at shallow and nearly full levels',
      () {
    for (final fill in [.02, .5, .98]) {
      final surface = LiquidSurfaceSimulation();
      for (var frame = 0; frame < 600; frame++) {
        if (frame % 3 == 0) {
          surface.disturb(position: frame.isEven ? .1 : .9, velocity: .25);
        }
        surface.advance(1 / 60, fill: fill, ambient: true);
      }
      expect(surface.heights.every((height) => height.isFinite), isTrue);
      expect(peak(surface), lessThan(.09));
      surface.advance(1 / 60, fill: 0);
      expect(peak(surface), 0);
      surface.disturb();
      surface.advance(1 / 60, fill: 1);
      expect(peak(surface), 0);
    }
  });
}
