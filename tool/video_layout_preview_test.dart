// Manual preview: renders the production screen with a decoded source frame.
// This substitutes only the platform texture; it is not a device playback test.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:fitai_mobile/core/media/video_cache.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';
import 'package:fitai_mobile/features/train/views/exercise_detail_view.dart';

class _FramePlayer extends VideoPlayerPlatform {
  final Uint8List frame;
  _FramePlayer(this.frame);
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 6),
      size: const Size(960, 540)));
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => Image.memory(frame);
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('render production video layout with a decoded source frame',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cache = Directory('build/previews/cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => cache.absolute.path);
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    const gender = String.fromEnvironment('LIBRARY_PREVIEW_GENDER');
    late final Map<String, dynamic> source;
    late final Uint8List frame;
    late final String url;
    if (gender.isNotEmpty) {
      final fixture = jsonDecode(
          File('build/previews/library-$gender.json').readAsStringSync());
      source = Map<String, dynamic>.from(fixture['exercise'] as Map);
      frame = File(fixture['frameFile'] as String).readAsBytesSync();
      url = source['url'] as String;
    } else {
      final root = '../backend/build/lyfta-male-fill';
      source =
          (jsonDecode(File('$root/database-before.json').readAsStringSync())
                  as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((w) => w['exerciseCode'] == '0022');
      final upload = jsonDecode(File('$root/uploaded.json').readAsStringSync());
      final asset = (upload['assets'] as List)
          .firstWhere((a) => a['key'].contains('/0022-'));
      frame = File(
              '$root/previews/${(asset['filename'] as String).replaceAll('.mp4', '.jpg')}')
          .readAsBytesSync();
      url = asset['publicUrl'] as String;
    }
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FramePlayer(frame);
    final controller =
        await tester.runAsync(() => VideoControllerPool.shared.acquire(url));
    expect(controller!.value.isInitialized, true);
    final exercise = WorkoutExerciseModel.fromJson({...source, 'url': url});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RepaintBoundary(
                key: const ValueKey('preview'),
                child: ExerciseDetailView(
                    exercise: exercise, loadDetail: false)))));
    await tester.runAsync(() => precacheImage(
        MemoryImage(frame), tester.element(find.byType(ExerciseDetailView))));
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('exercise-demo-stage'));
    expect(tester.getTopLeft(stage).dx, 0);
    expect(tester.getSize(stage), const Size(393, 221.0625));
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview')));
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture(gender.isEmpty ? 'video-full-width' : 'library-$gender');
    await tester.drag(find.byType(ListView).first, const Offset(0, -310));
    await tester.pumpAndSettle();
    await capture(gender.isEmpty
        ? 'video-muscles-instructions'
        : 'library-$gender-instructions');
    await tester.pumpWidget(const SizedBox());
    VideoControllerPool.shared.release(url);
    await tester.runAsync(controller.dispose);
    VideoPlayerPlatform.instance = original;
    expect(tester.takeException(), isNull);
  });
}
