import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/train/components/planned_exercise_row.dart';
import 'package:setcraft/features/train/components/training_widgets.dart';
import 'package:setcraft/features/train/components/workout_warmup.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_detail_view.dart';
import 'exercise_thumbnail_test.dart' show LocalPosterCache;
import 'training_session_test.dart' show token;

WorkoutExerciseModel catalogue(String id) => WorkoutExerciseModel.fromJson({
      'id': id,
      'name': id == 'press' ? 'Dumbbell floor press' : 'Seated cable row',
      'thumbnailUrl': 'https://catalogue.test/$id.png',
      'bodyPart': id == 'press' ? 'Chest' : 'Back',
      'target': id == 'press' ? 'pectorals' : 'lats',
      'equipment': 'dumbbell',
      'instructions': ['Move with control.'],
    });

class _Adapter implements HttpClientAdapter {
  final writes = <String>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    if (options.method != 'GET') writes.add(options.path);
    final id = options.uri.pathSegments.last;
    final data = options.path.contains('/exercises/')
        ? catalogue(id).toJson()
        : {'gender': 'MALE'};
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Widget app(Widget child, {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: FitnessTheme(child: child!)),
      home: Scaffold(
          body: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18), child: child))),
    );

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await tester.pumpAndSettle();
}

void main() {
  late _Adapter adapter;
  var owner = 0;
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() async {
    final directory = Directory('build/test-planned-posters/cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => directory.absolute.path);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('planned-photo-${owner++}'), refreshToken: 'test');
    adapter = _Adapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  testWidgets(
      'Each catalogue photo opens its own exercise with the saved prescription',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
          await File('test/fixtures/exercise-white-demo.gif').readAsBytes());
      final frame = await codec.getNextFrame();
      final bytes =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/test-planned-posters/poster.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      frame.image.dispose();
      codec.dispose();
      final original = CachedNetworkImageProvider.defaultCacheManager;
      CachedNetworkImageProvider.defaultCacheManager = LocalPosterCache({
        for (final id in ['press', 'row'])
          'https://catalogue.test/$id.png': file.absolute.path,
      });
      addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = original);
    });
    final prescription = {
      'sets': 3,
      'repsMin': 8,
      'repsMax': 12,
      'setPrescriptions': [
        {'setNumber': 1, 'repsMin': 10, 'repsMax': 10, 'weightKg': 12},
        {'setNumber': 2, 'repsMin': 8, 'repsMax': 12, 'weightKg': 14},
      ],
      'reason': 'Retain the prescription saved with this plan.',
    };
    await tester.pumpWidget(app(TrainingSurface(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final id in ['press', 'row'])
            PlannedExerciseRow(
                key: ValueKey('catalogue-$id'),
                exercise: {
                  ...prescription,
                  'exerciseId': id,
                  'name': catalogue(id).name
                },
                loadExercise: (value) async => catalogue(value)),
        ]))));
    await settle(tester);
    final images = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((e) => e.imageUrl)
        .toSet();
    expect(images,
        {'https://catalogue.test/press.png', 'https://catalogue.test/row.png'});
    for (final id in ['press', 'row']) {
      await tester.tap(find.byKey(ValueKey('catalogue-$id')));
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 300));
      final detail =
          tester.widget<ExerciseDetailView>(find.byType(ExerciseDetailView));
      expect(detail.exercise.id, id);
      expect(detail.recommendation!['setPrescriptions'],
          prescription['setPrescriptions']);
      await tester.pageBack();
      await settle(tester);
    }
    expect(adapter.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final large in [false, true]) {
    testWidgets(
        'Warm-up keeps instructions on demand and opens real exercises (${large ? 'large text' : 'phone'})',
        (tester) async {
      tester.view.physicalSize =
          large ? const Size(320, 720) : const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const movement =
          'Walk gently for two minutes, using the space available.';
      const practice =
          'Practise eight controlled repetitions with a light load.';
      final data = {
        'durationMinutes': 5,
        'note':
            'Preparation only. These sets do not count towards working sets.',
        'steps': [
          {'name': 'Easy movement', 'seconds': 120, 'instruction': movement},
          {
            'name': 'Dumbbell floor press',
            'exerciseId': 'press',
            'seconds': 90,
            'reps': 8,
            'weightKg': 2,
            'instruction': practice
          },
        ],
      };
      final original = jsonEncode(data);
      await tester.pumpWidget(app(
          WorkoutWarmup(
              warmup: data,
              compact: true,
              loadExercise: (id) async => catalogue(id)),
          scale: large ? 1.8 : 1,
          locale: large ? 'de' : 'en'));
      await settle(tester);
      expect(find.text(movement), findsNothing);
      expect(find.text(practice), findsNothing);
      await tester.tap(find.byType(WorkoutWarmup));
      await settle(tester);
      expect(find.text(movement), findsNothing);
      await tester.tap(find.byKey(const ValueKey('warmup-instructions-0')));
      await settle(tester);
      expect(find.text(movement), findsOneWidget);
      expect(find.text(practice), findsNothing);
      final exercise = find.byKey(const ValueKey('warmup-exercise-1'));
      await tester.ensureVisible(exercise);
      await settle(tester);
      await tester.tap(exercise);
      await settle(tester);
      final detail =
          tester.widget<ExerciseDetailView>(find.byType(ExerciseDetailView));
      expect(detail.exercise.id, 'press');
      expect(detail.recommendation, isNull,
          reason: 'Preparation must not be presented as working sets');
      expect(jsonEncode(data), original);
      expect(adapter.writes, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
