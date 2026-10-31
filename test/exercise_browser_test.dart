import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:setcraft/features/train/models/exercise_catalog_page.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_library_screen.dart';
import 'exercise_thumbnail_test.dart' show LocalPosterCache;

WorkoutExerciseModel exercise(int i) => WorkoutExerciseModel.fromJson({
      'id': 'item-$i',
      'name': 'Exercise ${i.toString().padLeft(3, '0')}',
      'bodyPart': i.isEven ? 'Chest' : 'Back',
      'target': i.isEven ? 'pectorals' : 'lats',
      'equipment': i.isEven ? 'Dumbbell' : 'Bodyweight',
      'mediaVariants': {
        'male': {'url': 'https://example.test/male-$i.mp4'},
        if (i.isEven) 'female': {'url': 'https://example.test/female-$i.mp4'}
      },
    });

ExerciseCatalogPage page(List<WorkoutExerciseModel> all, int number) =>
    ExerciseCatalogPage(
        exercises: all.skip((number - 1) * 24).take(24).toList(),
        page: number,
        total: all.length,
        totalPages: (all.length / 24).ceil(),
        bodyParts: const [
          ExerciseFilterOption('Chest', 'Chest'),
          ExerciseFilterOption('Back', 'Back')
        ],
        equipment: const [
          ExerciseFilterOption('Dumbbell', 'Dumbbell'),
          ExerciseFilterOption('Bodyweight', 'Bodyweight')
        ]);

Widget app(Widget child, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
                key: const ValueKey('browser-preview'), child: child!)),
        home: child);

Future<void> capture(WidgetTester tester, String file) async =>
    tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('browser-preview')))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/$file.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  void phone(WidgetTester tester, {double width = 393, double height = 852}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  ScrollController controller(WidgetTester tester) => tester
      .widget<CustomScrollView>(find.byKey(const ValueKey('exercise-scroll')))
      .controller!;
  Future<void> bottom(WidgetTester tester, {bool settle = true}) async {
    controller(tester).jumpTo(controller(tester).position.maxScrollExtent);
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets(
      'All pages append without jumps, dates, row add buttons or pagination controls',
      (tester) async {
    phone(tester);
    final all = List.generate(70, exercise), calls = <int>[];
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () {},
        workoutDate: 'Sunday, October 18',
        pageLoader: (number, search, body, equipment, gender, refresh) async {
          calls.add(number);
          return page(all, number);
        })));
    await tester.pumpAndSettle();
    expect(calls, [1]);
    expect(find.text('Sunday, October 18'), findsNothing);
    expect(find.text('Find your next movement'), findsNothing);
    expect(find.byKey(const ValueKey('exercise-pagination')), findsNothing);
    expect(
        find.byKey(const ValueKey('confirm-exercise-selection')), findsNothing);
    expect(find.byKey(const ValueKey('add-exercise-item-0')), findsNothing);
    await capture(tester, 'exercise-browser-premium');
    final firstEnd = controller(tester).position.maxScrollExtent;
    await bottom(tester);
    expect(calls, [1, 2]);
    expect(controller(tester).offset, closeTo(firstEnd, 1));
    controller(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Exercise 000'), findsOneWidget);
    await bottom(tester);
    expect(calls, [1, 2, 3]);
    await bottom(tester);
    expect(find.text('Exercise 069'), findsOneWidget);
    expect(calls, [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'A failed next page retains results and retries only when requested',
      (tester) async {
    phone(tester);
    final all = List.generate(40, exercise), calls = <int>[];
    var fail = true;
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () {},
        pageLoader: (number, search, body, equipment, gender, refresh) async {
          calls.add(number);
          if (number == 2 && fail) throw Exception('offline');
          return page(all, number);
        })));
    await tester.pumpAndSettle();
    await bottom(tester);
    expect(find.text('Could not load more exercises.'), findsOneWidget);
    expect(calls, [1, 2]);
    controller(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Exercise 000'), findsOneWidget);
    await bottom(tester);
    expect(calls, [1, 2]);
    fail = false;
    await tester.tap(find.byKey(const ValueKey('retry-exercise-page')));
    await tester.pumpAndSettle();
    await bottom(tester);
    expect(calls, [1, 2, 2]);
    expect(find.text('Exercise 039'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A delayed page cannot enter a newer search', (tester) async {
    phone(tester);
    final delayed = Completer<ExerciseCatalogPage>();
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () {},
        pageLoader: (number, search, body, equipment, gender, refresh) async {
          if (search == 'new') return page([exercise(999)], 1);
          if (number == 2) return delayed.future;
          return page(List.generate(50, exercise), number);
        })));
    await tester.pumpAndSettle();
    await bottom(tester, settle: false);
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'new');
    await tester.pumpAndSettle();
    delayed.complete(page(List.generate(50, exercise), 2));
    await tester.pumpAndSettle();
    expect(find.text('Exercise 999'), findsOneWidget);
    expect(find.text('Exercise 024'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Selections survive pagination and searches and are handed off once',
      (tester) async {
    phone(tester);
    List<WorkoutExerciseModel>? selected;
    var submits = 0;
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () {},
        initialExercises: List.generate(70, exercise),
        onSelectMany: (items) {
          selected = items;
          submits++;
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-exercise-item-0')));
    await bottom(tester);
    await bottom(tester);
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'Exercise 060');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-exercise-item-60')));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 exercises'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-selection')));
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-selection')));
    await tester.pumpAndSettle();
    expect(submits, 1);
    expect(selected!.map((e) => e.id), ['item-0', 'item-60']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Partial additions retain failed selections and never replay confirmed saves',
      (tester) async {
    phone(tester);
    final calls = <String>[];
    var fail = true, notifications = 0;
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () => notifications++,
        initialExercises: List.generate(3, exercise),
        addToWorkout: (exercise) async {
          calls.add(exercise.id);
          return exercise.id != 'item-1' || !fail;
        })));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('add-exercise-item-$i')));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-selection')));
    await tester.pumpAndSettle();
    expect(calls, ['item-0', 'item-1']);
    expect(notifications, 1);
    await tester.pumpAndSettle();
    expect(find.text('Add 2 exercises'), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-selection')));
    await tester.pumpAndSettle();
    expect(calls, ['item-0', 'item-1', 'item-1', 'item-2']);
    expect(notifications, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Filters fit enlarged German text and stay usable with the keyboard',
      (tester) async {
    phone(tester, width: 320, height: 700);
    await tester.pumpWidget(app(
        ExerciseLibraryView(
            onExerciseAdded: () {},
            initialExercises: List.generate(8, exercise)),
        locale: 'de',
        scale: 1.8));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-filter-female')));
    await capture(tester, 'exercise-browser-filters-large');
    await tester.tap(find.text('Filter anwenden'));
    await tester.pumpAndSettle();
    expect(find.text('Exercise 001'), findsNothing);
    await capture(tester, 'exercise-browser-large');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('exercise-search')), findsOneWidget);
  });

  testWidgets(
      'One filter sheet applies muscle and equipment and preserves search',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(ExerciseLibraryView(
        onExerciseAdded: () {}, initialExercises: List.generate(8, exercise))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-muscle-filter')), findsNothing);
    expect(
        find.byKey(const ValueKey('exercise-equipment-filter')), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'Exercise');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-filters-active')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell').last);
    await tester.pumpAndSettle();
    await capture(tester, 'exercise-filters-consolidated');
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('exercise-filters-active')), findsOneWidget);
    expect(find.text('Exercise 001'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('exercise-search')))
            .controller!
            .text,
        'Exercise');
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset filters'));
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('exercise-filters-active')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-filters-active')), findsNothing);
    expect(find.text('Exercise 001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Image-led browse and selection previews use actual exercise posters',
      (tester) async {
    phone(tester);
    const sources = {
      'https://preview.test/bench.jpg':
          'test/fixtures/exercise-posters/dumbbell-bench-press.jpg',
      'https://preview.test/fly.jpg':
          'test/fixtures/exercise-posters/dumbbell-fly.jpg',
      'https://preview.test/shoulder.jpg':
          'test/fixtures/exercise-posters/dumbbell-shoulder-press.jpg',
    };
    final directory = Directory('build/browser-poster-cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => directory.absolute.path);
    final original = CachedNetworkImageProvider.defaultCacheManager;
    CachedNetworkImageProvider.defaultCacheManager = LocalPosterCache(
        sources.map((url, path) => MapEntry(url, File(path).absolute.path)));
    addTearDown(
        () => CachedNetworkImageProvider.defaultCacheManager = original);
    final names = [
      'Dumbbell bench press',
      'Dumbbell fly',
      'Seated shoulder press'
    ];
    final posters = sources.keys.toList();
    final exercises = List.generate(
        3,
        (i) => WorkoutExerciseModel.fromJson({
              'id': 'preview-$i',
              'name': names[i],
              'bodyPart': i == 2 ? 'Shoulders' : 'Chest',
              'equipment': 'Dumbbell',
              'target': i == 2 ? 'deltoids' : 'pectorals',
              'thumbnailUrl': posters[i],
            }));
    await tester.pumpWidget(app(ExerciseLibraryView(
        key: const ValueKey('browse'),
        onExerciseAdded: () {},
        initialExercises: exercises)));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ExerciseLibraryView));
      for (final url in posters) {
        await precacheImage(
            ResizeImage.resizeIfNeeded(
                78, null, CachedNetworkImageProvider(url)),
            context);
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(3));
    await capture(tester, 'exercise-browser-cards-premium');
    await tester.pumpWidget(app(ExerciseLibraryView(
        key: const ValueKey('picker'),
        onExerciseAdded: () {},
        initialExercises: exercises,
        onSelectMany: (_) {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-exercise-preview-0')));
    await tester.tap(find.byKey(const ValueKey('add-exercise-preview-1')));
    await tester.pumpAndSettle();
    await capture(tester, 'exercise-browser-selection-premium');
    expect(find.text('Add 2 exercises'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
