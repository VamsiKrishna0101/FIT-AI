import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/train/components/exercise_thumbnail.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';

class LocalPosterCache implements BaseCacheManager {
  final Map<String, String> paths;
  LocalPosterCache(this.paths);
  @override
  Stream<FileResponse> getFileStream(String url,
          {String? key,
          Map<String, String>? headers,
          bool withProgress = false}) =>
      Stream.value(FileInfo(const LocalFileSystem().file(paths[url]!),
          FileSource.Cache, DateTime(2099), url));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final directory = Directory('build/test-thumbnails/cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => directory.absolute.path);
  });
  for (final dimensions in [const Size(160, 90), const Size(90, 90)]) {
    testWidgets(
        'poster preserves ${dimensions.width}:${dimensions.height} source without dark bars',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final file = File('build/test-thumbnails/${dimensions.width}.png');
      await tester.runAsync(() async {
        await file.parent.create(recursive: true);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        // Edge markers must both remain visible: covering/cropping is a failure.
        canvas.drawRect(Rect.fromLTWH(0, 30, 20, 30),
            Paint()..color = const Color(0xFFFF0000));
        canvas.drawRect(Rect.fromLTWH(dimensions.width - 20, 30, 20, 30),
            Paint()..color = const Color(0xFF0000FF));
        final picture = recorder.endRecording();
        final source = await picture.toImage(
            dimensions.width.toInt(), dimensions.height.toInt());
        final bytes = await source.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        source.dispose();
        picture.dispose();
      });
      final original = CachedNetworkImageProvider.defaultCacheManager;
      final url = 'https://test.invalid/${dimensions.width}.png';
      CachedNetworkImageProvider.defaultCacheManager =
          LocalPosterCache({url: file.absolute.path});
      addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = original);
      final exercise = WorkoutExerciseModel.fromJson(
          {'id': 'poster', 'name': 'Press', 'thumbnailUrl': url});
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.runAsync(() => precacheImage(
          ResizeImage.resizeIfNeeded(80, null, CachedNetworkImageProvider(url)),
          tester.element(find.byType(SizedBox))));
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: RepaintBoundary(
                  key: const ValueKey('poster'),
                  child: ExerciseThumbnail(exercise: exercise, size: 80)))));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('poster')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        List<int> pixel(int x, int y) =>
            List.generate(3, (c) => pixels!.getUint8((y * 80 + x) * 4 + c));
        expect(pixel(40, 4), [255, 255, 255]);
        expect(pixel(40, 75), [255, 255, 255]);
        expect(pixel(4, 40), [255, 0, 0],
            reason: 'The left source edge remains visible');
        expect(pixel(75, 40), [0, 0, 255],
            reason: 'The right source edge remains visible');
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
}
