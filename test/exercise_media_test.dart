import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/media/exercise_animation.dart';
import 'package:fitai_mobile/core/media/video_cache.dart';

final _gif = File('test/fixtures/exercise-demo.gif').readAsBytesSync();
final _still = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=');

Widget _surface(ExerciseAnimationController controller,
        {bool visible = true, bool reduced = false}) =>
    MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!),
        theme: ThemeData.dark(),
        home: Scaffold(
            body: TickerMode(
                enabled: visible,
                child: Center(
                    child: SizedBox(
                        width: 290,
                        height: 248,
                        child: RepaintBoundary(
                            key: const ValueKey('media-stage'),
                            child: ExerciseAnimationSurface(
                                url: 'https://media.example/demo.gif',
                                controller: controller,
                                controls: true,
                                compact: true)))))));

Future<void> _decode(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pump();
}

Future<void> _ready(
    WidgetTester tester, ExerciseAnimationController controller) async {
  for (var attempt = 0; attempt < 50 && controller.loading; attempt++) {
    await _decode(tester);
  }
  expect(controller.loading, isFalse);
  await tester.pump();
}

Future<int> _pixel(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(() => image.toByteData());
  return data!.getUint8(0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Contained GIF fills its stage with white instead of dark side bars',
      (tester) async {
    final bytes =
        File('test/fixtures/exercise-white-demo.gif').readAsBytesSync();
    final controller = ExerciseAnimationController(
        loader: (_, {refresh = false}) async => bytes);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_surface(controller));
    await _ready(tester, controller);
    expect(tester.getSize(find.byType(RawImage)).width, 290);
    expect(tester.widget<RawImage>(find.byType(RawImage)).fit, BoxFit.contain);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('media-stage')));
      final image = await boundary.toImage();
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      for (final x in [1, image.width - 2]) {
        final start = (80 * image.width + x) * 4;
        expect(pixels!.buffer.asUint8List().sublist(start, start + 4),
            [255, 255, 255, 255]);
      }
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });

  test('media detection handles signed video URLs and URL fragments', () {
    expect(
        VideoAssetCache.isVideo(
            'https://media.example/demo.MP4?token=sample#clip'),
        isTrue);
    expect(VideoAssetCache.isVideo('https://media.example/demo.webm?version=2'),
        isTrue);
    expect(VideoAssetCache.isGif('https://media.example/demo.GIF#preview'),
        isTrue);
    expect(
        VideoAssetCache.isGif('https://media.example/poster.jpg?name=demo.gif'),
        isFalse);
    expect(VideoAssetCache.isVideo('/relative/demo.mp4'), isFalse);
  });

  testWidgets(
      'original GIF frames animate, loop, pause and stop on a hidden tab',
      (tester) async {
    final controller = ExerciseAnimationController(
        loader: (_, {refresh = false}) async => _gif);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_surface(controller, reduced: true));
    await _ready(tester, controller);
    expect(controller.frameCount, 2);
    expect(controller.width, 16);
    expect(controller.playing, isTrue);
    final first = await _pixel(tester, controller.frame.value!);
    await tester.pump(const Duration(milliseconds: 120));
    await _decode(tester);
    final second = await _pixel(tester, controller.frame.value!);
    expect(second, isNot(first));
    await tester.pump(const Duration(milliseconds: 240));
    await _decode(tester);
    expect(await _pixel(tester, controller.frame.value!), first);
    await tester.tap(find.byKey(const ValueKey('exercise-demo-play')));
    await tester.pump();
    expect(controller.playing, isFalse);
    final paused = controller.frame.value;
    await tester.pump(const Duration(seconds: 2));
    await _decode(tester);
    expect(controller.frame.value, same(paused));
    await tester.tap(find.byKey(const ValueKey('exercise-demo-play')));
    await tester.pump();
    expect(controller.playing, isTrue);
    await tester.pumpWidget(_surface(controller, visible: false));
    final hidden = controller.frame.value;
    await tester.pump(const Duration(seconds: 2));
    await _decode(tester);
    expect(controller.frame.value, same(hidden));
    await tester.pumpWidget(_surface(controller));
    expect(controller.playing, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a flattened demo is rejected, refetched once, and has visible retry',
      (tester) async {
    final downloads = <bool>[];
    final controller =
        ExerciseAnimationController(loader: (_, {refresh = false}) async {
      downloads.add(refresh);
      return downloads.length <= 2 ? _still : _gif;
    });
    addTearDown(controller.dispose);
    await tester.pumpWidget(_surface(controller));
    await _ready(tester, controller);
    expect(downloads, [false, true]);
    expect(controller.failed, isTrue);
    expect(find.text('Demo unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await _ready(tester, controller);
    expect(downloads, [false, true, true]);
    expect(controller.failed, isFalse);
    expect(controller.frameCount, 2);
    expect(find.text('Demo unavailable'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an old download cannot overwrite the current exercise',
      (tester) async {
    final old = Completer<List<int>>();
    final controller =
        ExerciseAnimationController(loader: (url, {refresh = false}) async {
      if (url.endsWith('old.gif')) return Uint8List.fromList(await old.future);
      return _gif;
    });
    addTearDown(controller.dispose);
    final pending = controller.load('https://media.example/old.gif');
    await tester
        .runAsync(() => controller.load('https://media.example/new.gif'));
    old.complete(_still);
    await pending;
    expect(controller.failed, isFalse);
    expect(controller.frameCount, 2);
    controller.setPlaying(false);
    await tester.pump();
  });

  testWidgets(
      'original white GIF background stays consistent across disposal frames',
      (tester) async {
    final bytes =
        File('test/fixtures/exercise-white-demo.gif').readAsBytesSync();
    final controller = ExerciseAnimationController(
        loader: (_, {refresh = false}) async => bytes);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_surface(controller, reduced: true));
    await _ready(tester, controller);
    for (var index = 0; index < 6; index++) {
      final pixels =
          await tester.runAsync(() => controller.frame.value!.toByteData());
      expect(pixels!.buffer.asUint8List().sublist(0, 4), [255, 255, 255, 255],
          reason: 'Background at frame $index');
      final current = controller.frame.value;
      await tester.pump(const Duration(milliseconds: 400));
      for (var attempt = 0;
          attempt < 50 && identical(current, controller.frame.value);
          attempt++) {
        await _decode(tester);
      }
      expect(controller.frame.value, isNot(same(current)));
    }
    await tester.pumpWidget(const SizedBox());
  });

  final real = File('build/media-fixtures/exercise-1512.gif');
  testWidgets(
      'the actual Cloudflare GIF retains its original 12-frame animation',
      (tester) async {
    final controller = ExerciseAnimationController(
        loader: (_, {refresh = false}) async => real.readAsBytesSync());
    addTearDown(controller.dispose);
    controller.setPlaying(false);
    await tester
        .runAsync(() => controller.load('https://media.example/1512.gif'));
    expect(controller.failed, isFalse);
    expect(controller.frameCount, 12);
    expect(controller.width, 180);
    expect(controller.height, 180);
    await tester.pump();
  }, skip: !real.existsSync());
}
