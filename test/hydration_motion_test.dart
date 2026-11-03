import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/motion/device_tilt.dart';
import 'package:setcraft/features/nutrition/components/liquid_water_visual.dart';
import 'package:setcraft/features/nutrition/components/liquid_pool_painter.dart';
import 'package:setcraft/features/nutrition/components/liquid_surface_simulation.dart';
import 'package:setcraft/features/nutrition/components/liquid_water_optics.dart';
import 'package:setcraft/features/nutrition/components/nutrition_summary_card.dart';
import 'package:setcraft/features/nutrition/components/water_intake_card.dart';

LiquidWaterPainter water(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('liquid-water-paint')))
    .painter! as LiquidWaterPainter;

Widget host(Stream<GravitySample> stream,
        {bool reduced = false, bool enabled = true, double fraction = .5}) =>
    MaterialApp(
        home: Builder(
            builder: (context) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(disableAnimations: reduced),
                child: TickerMode(
                    enabled: enabled,
                    child: Center(
                        child: LiquidWaterVisual(
                            fraction: fraction, motion: stream))))));

void main() {
  setUpAll(() async {
    expect(await LiquidWaterOptics.load(), isNotNull,
        reason: 'The production water shader must compile and load');
  });
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  test('Gravity follows the actual lowered edge, including upside down', () {
    expect(const GravitySample(0, -1).angle(), 0);
    expect(const GravitySample(1, 0).angle(), -math.pi / 2);
    expect(const GravitySample(-1, 0).angle(), math.pi / 2);
    expect(const GravitySample(0, 1).angle().abs(), math.pi);
    expect(const GravitySample(.1, -1).angle(), closeTo(-.0997, .001));
    expect(const GravitySample(-.1, 1).angle(), greaterThan(3));
    expect(const GravitySample(-1, -.1).angle(landscape: true), lessThan(0));
    expect(const GravitySample(1, .1).angle(landscape: true), lessThan(0));
    expect(const GravitySample(100, -.01).angle(), closeTo(-math.pi / 2, .001));
    expect(const GravitySample(0, 0).angle(), 0);
    expect(const GravitySample(double.nan, -1).angle(), 0);
    expect(const GravitySample(0, 0, 1).hasScreenGravity, isFalse);
    expect(const GravitySample(0, 0, 1).pitch(), -math.pi / 2);
  });

  test('The water surface and reflection loop have no seam', () {
    GravityWaterSurface surface(double phase) => GravityWaterSurface(
        size: const Size(320, 84),
        fill: 400 / 2800,
        angle: 2.7,
        phase: phase,
        amplitude: 4);
    final start = surface(0), end = surface(LiquidMotion.phaseSpan);
    for (final u in [-100.0, -50.0, 0.0, 50.0, 100.0]) {
      expect(start.surfaceAt(u), closeTo(end.surfaceAt(u), .000001));
    }
  });

  test('The liquid occupies the lower side of the glass in all four directions',
      () {
    GravityWaterSurface surface(double angle) => GravityWaterSurface(
        size: const Size(320, 84), fill: .2, angle: angle, amplitude: 0);
    final bottom = surface(0),
        left = surface(math.pi / 2),
        top = surface(math.pi),
        right = surface(-math.pi / 2);
    expect(bottom.containsWater(const Offset(160, 78)), isTrue);
    expect(bottom.containsWater(const Offset(160, 6)), isFalse);
    expect(top.containsWater(const Offset(160, 6)), isTrue);
    expect(top.containsWater(const Offset(160, 78)), isFalse);
    expect(left.containsWater(const Offset(6, 42)), isTrue);
    expect(left.containsWater(const Offset(314, 42)), isFalse);
    expect(right.containsWater(const Offset(314, 42)), isTrue);
    expect(right.containsWater(const Offset(6, 42)), isFalse);
  });

  testWidgets('Rendered liquid follows the bottom, ceiling and both side walls',
      (tester) async {
    await tester.runAsync(() async {
      const lower = Offset(160, 78),
          upper = Offset(160, 6),
          left = Offset(6, 42),
          right = Offset(314, 42);
      final poses = [
        (name: 'upright', angle: 0.0, wet: lower, dry: upper),
        (name: 'inverted', angle: math.pi, wet: upper, dry: lower),
        (name: 'left', angle: math.pi / 2, wet: left, dry: right),
        (name: 'right', angle: -math.pi / 2, wet: right, dry: left),
      ];
      for (final pose in poses) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        LiquidWaterPainter(fraction: .2, tilt: pose.angle, energy: 0)
            .paint(canvas, const Size(320, 84));
        final picture = recorder.endRecording();
        final image = await picture.toImage(320, 84);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        bool blue(Offset point) {
          final index = (point.dy.toInt() * 320 + point.dx.toInt()) * 4;
          return pixels!.getUint8(index + 2) - pixels.getUint8(index) > 28;
        }

        expect(blue(pose.wet), isTrue, reason: pose.name);
        expect(blue(pose.dry), isFalse, reason: pose.name);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/water-gravity-${pose.name}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    });
  });

  testWidgets('Water optics move smoothly inside the water and loop seamlessly',
      (tester) async {
    await tester.runAsync(() async {
      Future<List<int>> render(double phase) async {
        final shader = LiquidWaterOptics.create()!;
        final recorder = ui.PictureRecorder();
        LiquidWaterPainter(
                fraction: .62,
                wave: phase,
                energy: 0,
                surface: List.filled(LiquidSurfaceSimulation.sampleCount, 0),
                optics: shader)
            .paint(Canvas(recorder), const Size(160, 84));
        final picture = recorder.endRecording();
        final image = await picture.toImage(160, 84);
        try {
          final bytes =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          return bytes.buffer.asUint8List().toList();
        } finally {
          image.dispose();
          picture.dispose();
          shader.dispose();
        }
      }

      final first = await render(0);
      final next = await render(.016);
      final flowing = await render(.8);
      final loop = await render(LiquidMotion.phaseSpan);
      var changed = 0, frameDifference = 0, seamDifference = 0;
      for (var y = 0; y < 84; y++) {
        for (var x = 0; x < 160; x++) {
          final i = (y * 160 + x) * 4;
          for (var channel = 0; channel < 3; channel++) {
            final at = i + channel;
            frameDifference += (first[at] - next[at]).abs();
            seamDifference =
                math.max(seamDifference, (first[at] - loop[at]).abs());
            if (y < 20) {
              expect(flowing[at], first[at],
                  reason: 'Light flow must stay inside the water');
            } else if ((first[at] - flowing[at]).abs() > 2) {
              changed++;
            }
          }
        }
      }
      expect(changed, greaterThan(200),
          reason: 'Reflections must visibly flow through the fluid');
      expect(frameDifference / (160 * 84 * 3), lessThan(1.5),
          reason: 'Adjacent frames must change smoothly');
      expect(seamDifference, lessThanOrEqualTo(2),
          reason: 'The lighting loop must not flash when the clock wraps');
    });
  });

  test('Rounded tank conserves water through full rotations, even at 400 ml',
      () {
    for (final fill in [.02, 400 / 2800, .5, .9]) {
      for (final angle in [
        -math.pi,
        -2.4,
        -math.pi / 2,
        -.8,
        0.0,
        .8,
        math.pi / 2,
        2.4,
        math.pi
      ]) {
        final surface = GravityWaterSurface(
            size: const Size(320, 84),
            fill: fill,
            angle: angle,
            phase: 1.3,
            amplitude: 4.5);
        var inside = 0, wet = 0;
        for (var x = 0; x < 320; x++) {
          for (var y = 0; y < 84; y++) {
            final point = Offset(x + .5, y + .5);
            if (surface.vessel.contains(point)) {
              inside++;
              if (surface.containsWater(point)) wet++;
            }
          }
        }
        expect(wet / inside, closeTo(fill, .004),
            reason: 'fill $fill at angle $angle');
      }
    }
  });

  test('Simulated ripples conserve the amount through container rotations', () {
    final simulation = LiquidSurfaceSimulation();
    simulation.disturb(position: .15, velocity: .2);
    for (var frame = 0; frame < 48; frame++) {
      simulation.advance(1 / 120, fill: .5);
    }
    for (final fill in [.05, .5, .95]) {
      for (final angle in [0.0, .8, math.pi / 2, math.pi]) {
        final tank = GravityWaterSurface(
            size: const Size(160, 84),
            fill: fill,
            angle: angle,
            surface: simulation.heights);
        var inside = 0, wet = 0;
        for (var x = 0; x < 160; x++) {
          for (var y = 0; y < 84; y++) {
            final point = Offset(x + .5, y + .5);
            if (tank.vessel.contains(point)) {
              inside++;
              if (tank.containsWater(point)) wet++;
            }
          }
        }
        expect(wet / inside, closeTo(fill, .006));
      }
    }
  });

  testWidgets('Today nutrient meters have independent natural surfaces',
      (tester) async {
    LiquidMotion.ambientEnabled = true;
    addTearDown(() => LiquidMotion.ambientEnabled = false);
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    const preview = RepaintBoundary(
        key: ValueKey('nutrition-liquid-preview'),
        child: SizedBox(
            width: 361,
            child: NutritionSummaryCard(
                calories: 1480,
                calorieTarget: 2200,
                protein: 100,
                proteinTarget: 160,
                carbs: 160,
                carbTarget: 250,
                fat: 40,
                fatTarget: 65)));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: const Scaffold(
            body: Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min, children: [preview])))));
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final surfaces = tester
        .widgetList<CustomPaint>(
            find.byKey(const ValueKey('liquid-water-paint')))
        .map((widget) => widget.painter! as LiquidWaterPainter)
        .toList();
    expect(surfaces.length, 3);
    for (final label in ['Protein', 'Carbs', 'Fat']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(surfaces[0].surface, isNot(orderedEquals(surfaces[1].surface!)));
    expect(surfaces[1].surface, isNot(orderedEquals(surfaces[2].surface!)));
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('nutrition-liquid-preview')))
          .toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/nutrition-natural-liquid.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Water hot reload stays stable with accessibility semantics enabled',
      (tester) async {
    LiquidMotion.ambientEnabled = true;
    addTearDown(() => LiquidMotion.ambientEnabled = false);
    final semantics = tester.ensureSemantics();
    try {
      Widget preview(int protein) => MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
                      width: 361,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        NutritionSummaryCard(
                            calories: 1480,
                            calorieTarget: 2200,
                            protein: protein,
                            proteinTarget: 160,
                            carbs: 160,
                            carbTarget: 250,
                            fat: 40,
                            fatTarget: 65),
                        const SizedBox(height: 16),
                        const WaterIntakeCard(consumedMl: 400, targetMl: 2800),
                      ])))));
      await tester.pumpWidget(preview(100));
      for (var reload = 0; reload < 3; reload++) {
        await tester.pumpWidget(preview(100 + reload * 5));
        unawaited(tester.binding.reassembleApplication());
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
        }
        final painters = tester.widgetList<CustomPaint>(
            find.byKey(const ValueKey('liquid-water-paint')));
        expect(painters, hasLength(4));
        for (final paint in painters) {
          expect((paint.painter! as LiquidWaterPainter).surface,
              hasLength(LiquidSurfaceSimulation.sampleCount));
        }
        for (final label in ['Protein', 'Carbs', 'Fat']) {
          expect(find.text(label), findsOneWidget);
        }
      }
      expect(find.text('110 / 160 g'), findsOneWidget);
      expect(
          find.bySemanticsLabel(RegExp('Protein: 110 / 160 g')), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    }
  });

  testWidgets('A full phone rotation moves water around every wall',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream, fraction: 400 / 2800));
    const samples = [
      GravitySample(-1, 0),
      GravitySample(0, 1),
      GravitySample(1, 0),
      GravitySample(0, -1)
    ];
    for (var index = 0; index < samples.length; index++) {
      stream.add(samples[index]);
      await tester.pumpAndSettle();
      expect(water(tester).tilt, closeTo((index + 1) * math.pi / 2, .00001));
      expect(water(tester).fraction, 400 / 2800);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Crossing the upside-down seam never spins in reverse',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    stream.add(const GravitySample(-.01745, .99985));
    await tester.pumpAndSettle();
    final before = water(tester).tilt;
    stream.add(const GravitySample(.01745, .99985));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((water(tester).tilt - before).abs(), lessThan(.04));
    await tester.pumpAndSettle();
    expect(water(tester).tilt, greaterThan(math.pi));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Water has a soft slosh after tilting and settles to gravity',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream, fraction: 400 / 2800));
    const sample = GravitySample(-.2, -1, -.12);
    stream.add(sample);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(water(tester).tilt, greaterThan(sample.angle()));
    expect(water(tester).depthTilt, greaterThan(sample.pitch()));
    expect(water(tester).fraction, 400 / 2800);
    await tester.pumpAndSettle();
    expect(water(tester).tilt, sample.angle());
    expect(water(tester).depthTilt, sample.pitch());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Today water keeps flowing at 400 ml without changing the amount',
      (tester) async {
    LiquidMotion.ambientEnabled = true;
    addTearDown(() => LiquidMotion.ambientEnabled = false);
    tester.view.physicalSize = const Size(393, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      RepaintBoundary(
                          key: ValueKey('water-preview'),
                          child:
                              WaterIntakeCard(consumedMl: 400, targetMl: 2800))
                    ]))))));
    for (var frame = 0; frame < 90; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    Future<void> capture(String name) => tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('water-preview')))
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/previews/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
    await capture('today-water-tides-first');
    final heights = water(tester).surface!;
    final waveHeight =
        (heights.reduce(math.max) - heights.reduce(math.min)) * 84;
    expect(waveHeight, greaterThan(1.5));
    final phase = water(tester).wave;
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(water(tester).wave, greaterThan(phase));
    expect(water(tester).fraction, 400 / 2800);
    expect(find.text('0.4 L'), findsOneWidget);
    await capture('today-water-tides-second');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Completed water and nutrient goals retain moving sea waves',
      (tester) async {
    LiquidMotion.ambientEnabled = true;
    addTearDown(() => LiquidMotion.ambientEnabled = false);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    for (final perspective in [true, false]) {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: LiquidWaterVisual(
                  fraction: 1,
                  motion: stream.stream,
                  perspective: perspective,
                  size:
                      perspective ? const Size(80, 96) : const Size(32, 46)))));
      for (var frame = 0; frame < 120; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final first = water(tester).surface!;
      expect(first.map((height) => height.abs()).reduce(math.max),
          greaterThan(.002));
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(water(tester).surface, isNot(orderedEquals(first)));
      expect(water(tester).fraction, 1);
      await tester.pumpWidget(const SizedBox());
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Native depth samples produce forward and backward motion',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    stream.add(const GravitySample(0, -1, -.3));
    await tester.pumpAndSettle();
    expect(water(tester).depthTilt, greaterThan(.2));
    expect(water(tester).tilt, 0);
    stream.add(const GravitySample(0, -1, .3));
    await tester.pumpAndSettle();
    expect(water(tester).depthTilt, lessThan(-.2));
    expect(water(tester).fraction, .5);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Visible nutrient waves keep moving and pause when hidden or reduced',
      (tester) async {
    LiquidMotion.ambientEnabled = true;
    addTearDown(() => LiquidMotion.ambientEnabled = false);
    Widget capsule({bool enabled = true, bool reduced = false}) => MaterialApp(
        home: Builder(
            builder: (context) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(disableAnimations: reduced),
                child: TickerMode(
                    enabled: enabled,
                    child: const Center(
                        child: LiquidWaterVisual(
                            fraction: .6,
                            size: Size(32, 46),
                            reactToTilt: false,
                            perspective: false))))));
    await tester.pumpWidget(capsule());
    await tester.pump(const Duration(seconds: 2));
    final first = water(tester).wave;
    await tester.pump(const Duration(seconds: 1));
    expect(water(tester).wave, isNot(first));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(water(tester).fraction, .6);
    await tester.pumpWidget(capsule(enabled: false));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(capsule(reduced: true));
    await tester.pumpAndSettle();
    final still = water(tester).wave;
    await tester.pump(const Duration(seconds: 1));
    expect(water(tester).wave, still);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(capsule());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    LiquidMotion.ambientEnabled = false;
  });

  testWidgets(
      'Nutrient fill animates after logging without motion subscriptions',
      (tester) async {
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    Widget capsule(double fraction) => MaterialApp(
        home: Center(
            child: LiquidWaterVisual(
                fraction: fraction,
                motion: stream.stream,
                reactToTilt: false,
                perspective: false,
                size: const Size(40, 66))));
    await tester.pumpWidget(capsule(.2));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isFalse);
    await tester.pumpWidget(capsule(.8));
    await tester.pump(const Duration(milliseconds: 120));
    expect(water(tester).fraction, greaterThan(.2));
    expect(water(tester).fraction, lessThan(.8));
    await tester.pumpAndSettle();
    expect(water(tester).fraction, .8);
    expect(water(tester).perspective, isFalse);
    expect(stream.hasListener, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Rapid tilt updates preserve surface position and ripple continuity',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    stream.add(const GravitySample(.12, -1, .08));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final roll = water(tester).tilt,
        depth = water(tester).depthTilt,
        ripple = water(tester).energy;
    stream.add(const GravitySample(-.15, -1, -.08));
    await tester.pump();
    expect(water(tester).tilt, closeTo(roll, .000001));
    expect(water(tester).depthTilt, closeTo(depth, .000001));
    expect(water(tester).energy, closeTo(ripple, .000001));
    await tester.pump(const Duration(milliseconds: 16));
    expect((water(tester).tilt - roll).abs(), lessThan(.025));
    expect(water(tester).fraction, .5);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tilt changes surface and settles without changing logged fill',
      (tester) async {
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    stream.add(const GravitySample(.2, -1));
    await tester.pump(const Duration(milliseconds: 200));
    final phase = water(tester).wave;
    stream.add(const GravitySample(.3, -1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(water(tester).wave, greaterThan(phase));
    await tester.pumpAndSettle();
    expect(
        water(tester).tilt, const GravitySample(.3, -1).angle(landscape: true));
    expect(water(tester).fraction, .5);
    expect(water(tester).settle, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    stream.addError(StateError('Sensor unavailable'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(stream.hasListener, isFalse);
  });

  testWidgets('Reduced motion and hidden tabs stop listening and stay static',
      (tester) async {
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    expect(stream.hasListener, isTrue);
    await tester.pumpWidget(host(stream.stream, reduced: true, fraction: .75));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isFalse);
    expect(water(tester).tilt, 0);
    expect(water(tester).fraction, .75);
    expect(water(tester).surface, everyElement(0.0));
    await tester.pumpWidget(host(stream.stream, enabled: false));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isFalse);
    await tester.pumpWidget(host(stream.stream));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(stream.hasListener, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(stream.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('An outgoing page holds its liquid pose throughout the fade',
      (tester) async {
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
            body: Center(
                child:
                    LiquidWaterVisual(fraction: .5, motion: stream.stream)))));
    stream.add(const GravitySample(.2, -1, .12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final before = water(tester);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Next'))));
    await tester.pump();
    final paused = water(tester);
    expect(paused.tilt, closeTo(before.tilt, .000001));
    expect(paused.depthTilt, closeTo(before.depthTilt, .000001));
    expect(paused.energy, closeTo(before.energy, .000001));
    expect(stream.hasListener, isFalse);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Covered routes and offscreen liquid release the sensor',
      (tester) async {
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    final nav = GlobalKey<NavigatorState>();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: Scaffold(
            body: SingleChildScrollView(
                controller: scroll,
                child: Column(children: [
                  LiquidWaterVisual(fraction: .5, motion: stream.stream),
                  const SizedBox(height: 2000)
                ])))));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isTrue);
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other screen'))));
    await tester.pumpAndSettle();
    expect(stream.hasListener, isFalse);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(stream.hasListener, isTrue);
    scroll.jumpTo(1000);
    await tester.pumpAndSettle();
    expect(stream.hasListener, isFalse);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(stream.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Desktop drag previews water and zero intake stays empty',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final stream = StreamController<GravitySample>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(host(stream.stream));
    final start = tester.getCenter(find.byType(LiquidWaterVisual));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(35, 0));
    await tester.pumpAndSettle();
    expect(water(tester).tilt, lessThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(water(tester).tilt, 0);
    await tester.pumpWidget(host(stream.stream, fraction: 0));
    await tester.pumpAndSettle();
    expect(water(tester).fraction, 0);
    expect(stream.hasListener, isFalse);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
