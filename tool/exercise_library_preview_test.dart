// Manual production-list preview using actual locally decoded source posters.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_library_view.dart';
import '../test/exercise_thumbnail_test.dart' show LocalPosterCache;

void main() {
  testWidgets('render chest search with full source posters', (tester) async {
    // This tool runs as a Flutter test and must not read real device preferences.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final directory = Directory('build/previews/cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => directory.absolute.path);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    // Match production text for controls that omit an explicit font family.
    await (FontLoader('Ahem')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final fixture =
        jsonDecode(File('build/previews/chest-library.json').readAsStringSync())
            as Map;
    final rows = (fixture['exercises'] as List)
        .map((r) => WorkoutExerciseModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    final original = CachedNetworkImageProvider.defaultCacheManager;
    CachedNetworkImageProvider.defaultCacheManager =
        LocalPosterCache(Map<String, String>.from(fixture['posters']));
    addTearDown(
        () => CachedNetworkImageProvider.defaultCacheManager = original);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() => Future.wait(rows.take(24).map((row) =>
        precacheImage(
            ResizeImage.resizeIfNeeded(
                72, null, CachedNetworkImageProvider(row.thumbnailUrl!)),
            context))));
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark().copyWith(
                textTheme:
                    ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
            home: ExerciseLibraryView(
                initialExercises: rows, onExerciseAdded: () {}))));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'chest');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('${rows.length} exercises'), findsNothing);
    expect(find.byType(Image), findsWidgets);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/previews/chest-search-fixed.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-filter-male')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/previews/exercise-filters-premium.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
