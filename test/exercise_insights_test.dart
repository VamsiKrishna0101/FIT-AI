import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/train/components/graphite_anatomy.dart';
import 'package:setcraft/core/media/fit_video_surface.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/exercise_progress_content.dart';
import 'package:setcraft/features/train/components/exercise_insights.dart';
import 'package:setcraft/features/train/components/exercise_muscle_map.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_detail_view.dart';

final _exercise = WorkoutExerciseModel.fromJson({
  'id': 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
  'name': 'Dumbbell press',
  'bodyPart': 'Chest',
  'target': 'Pectorals',
  'equipment': 'Dumbbell',
  'secondaryMuscles': ['Triceps', 'Delts'],
  'instructions': ['Press with control.'],
});

Map<String, dynamic> _day(int day) => {
      'date': '2026-10-${day.toString().padLeft(2, '0')}',
      'load': 10.0 + day,
      'reps': 10,
      'totalReps': 20,
      'sets': 2,
      'volume': (10.0 + day) * 20,
      'estimatedStrength': 15.0 + day,
      'bestSet': {'weight': 10.0 + day, 'reps': 10},
      'entries': [
        {
          'id': 'set-$day',
          'setNumber': 1,
          'weight': 10.0 + day,
          'reps': 10,
          'rpe': 7
        },
      ],
    };

Map<String, dynamic> _history({int days = 6, String? cursor}) => {
      'series': [for (var day = 1; day <= days; day++) _day(day)],
      'previous': [_day(5), _day(6)],
      'records': {
        'bestLoad': {'weight': 16, 'reps': 10, 'date': '2026-10-06'},
        'events': 2,
        'repsAtLoad': [
          {'weight': 16, 'reps': 10, 'date': '2026-10-06'}
        ]
      },
      'history': cursor == null ? [_day(6), _day(5)] : [_day(5), _day(4)],
      'nextCursor': cursor == null ? '2026-10-05' : null,
    };

class _HistoryAdapter implements HttpClientAdapter {
  bool logged = false;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add(options.path);
    final rankRoute = options.path.endsWith('/rank');
    final status = rankRoute
        ? 503
        : logged
            ? 200
            : 404;
    final body = rankRoute
        ? {'error': 'Rank service unavailable'}
        : logged
            ? {'data': _history()}
            : {'error': 'Exercise history not found'};
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Widget _app(Widget page, {double scale = 1, String language = 'en'}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      home: MediaQuery(
          data: MediaQueryData(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: RepaintBoundary(key: const ValueKey('preview'), child: page)),
    );

Future<void> _capture(WidgetTester tester, String name) async {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
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
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('fitai/sleep_estimate'), (_) async => null);
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'userId': 'rank-contract-test'})));
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'header.$claims.signature',
        refreshToken: 'fixture',
        userId: 'rank-contract-test');
    await LanguageManager.shared.restoreAccountLanguage('en');
  });

  test('canonical muscle tags select finite regions in each graphite figure',
      () {
    expect(exerciseMuscleIds(['Pectorals']), {'chest'});
    expect(exerciseMuscleIds(['Triceps', 'Delts']), {'triceps', 'shoulders'});
    expect(exerciseMuscleIds(['adductors']), isEmpty);
    for (final female in [false, true]) {
      for (final back in [false, true]) {
        final geometry = graphiteMusclePaths(back: back, female: female);
        final viewport = GraphiteAnatomyPainter(
            image: null,
            female: female,
            back: back,
            primary: const {},
            secondary: const {}).viewport;
        for (final paths in geometry.values) {
          for (final path in paths) {
            expect(path.getBounds().isFinite, isTrue);
            expect(viewport.overlaps(path.getBounds()), isTrue);
          }
        }
      }
    }
  });

  testWidgets(
      'Info and Progress preserve history and scope the add action to Info',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    var loads = 0, adds = 0;
    await tester.pumpWidget(_app(ExerciseDetailView(
      exercise: _exercise,
      loadDetail: false,
      female: false,
      historyLoader: ({cursor, refresh = false}) async {
        loads++;
        return _history(cursor: cursor);
      },
      onAddToPlan: () async {
        adds++;
        return false;
      },
    )));
    await tester.runAsync(() => precacheImage(
        const AssetImage(graphiteAnatomyAsset),
        tester.element(find.byType(ExerciseDetailView))));
    await tester.pumpAndSettle();
    expect(loads, 0);
    await _capture(tester, 'exercise-info');
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Rank'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byKey(const ValueKey('exercise-anatomy-map')), findsOneWidget);
    final anatomy = tester.widget<CustomPaint>(find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is GraphiteAnatomyPainter));
    expect((anatomy.painter as GraphiteAnatomyPainter).image, isNotNull);
    final infoScroll = find
        .descendant(
            of: find.byKey(PageStorageKey('exercise-info-${_exercise.id}')),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Press with control.'), 200,
        scrollable: infoScroll);
    await tester.pumpAndSettle();
    expect(find.text('Press with control.'), findsOneWidget);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(loads, 1);
    expect(find.text('Add to today'), findsNothing);
    expect(find.text('Trends'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(
        TickerMode.valuesOf(tester.element(find.byType(FitVideoSurface)))
            .enabled,
        false);
    await _capture(tester, 'exercise-progress');
    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    expect(adds, 1);
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(loads, 1);
    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    final info = find.byKey(PageStorageKey('exercise-info-${_exercise.id}'));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('exercise-anatomy-map')), 200,
        scrollable:
            find.descendant(of: info, matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-muscles');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exercise tabs remain readable on a small phone with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    final demo = WorkoutExerciseModel.fromJson({
      ..._exercise.toJson(),
      'mediaVariants': {
        'male': {'url': 'https://example.test/demo.mp4', 'aspectRatio': 16 / 9}
      }
    });
    await tester.pumpWidget(_app(
        TickerMode(
            enabled: false,
            child: ExerciseDetailView(
                exercise: demo,
                mediaGender: 'male',
                loadDetail: false,
                historyLoader: ({cursor, refresh = false}) async =>
                    _history())),
        scale: 1.6));
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('exercise-demo-stage'));
    expect(tester.getTopLeft(stage).dx, 18);
    final demoWidth = tester.getSize(stage).width;
    expect(demoWidth, 284);
    expect(tester.getSize(stage).height, closeTo(284 * 9 / 16, .1));
    expect(tester.getSize(stage).height, lessThanOrEqualTo(280));
    final muscles = find.byKey(PageStorageKey('exercise-muscles-${demo.id}'));
    final guide = find.byKey(const ValueKey('exercise-instructions'));
    expect(tester.widget<ExpansionTile>(muscles).initiallyExpanded, true);
    expect(tester.getRect(muscles).left, tester.getRect(stage).left);
    expect(tester.getRect(muscles).width, demoWidth);
    expect(
        tester.getRect(muscles).top, greaterThan(tester.getRect(stage).bottom));
    await tester.scrollUntilVisible(guide, 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(tester.getRect(guide).width, demoWidth);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-progress-large-text');
    expect(find.text('Rank'), findsNothing);
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed demonstrations do not offer rep-based workout logging',
      (tester) async {
    final timed = WorkoutExerciseModel.fromJson(
        {..._exercise.toJson(), 'exerciseType': 'duration'});
    expect(timed.supportsRepLogging, false);
    expect(WorkoutExerciseModel.fromJson(_exercise.toJson()).supportsRepLogging,
        true);
    await tester.pumpWidget(_app(ExerciseDetailView(
        exercise: timed, loadDetail: false, onAddToPlan: () async => true)));
    await tester.pumpAndSettle();
    expect(find.text('Add to today'), findsNothing);
    expect(find.byKey(const ValueKey('exercise-demo-stage')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'square MP4 preserves its proportions and shares the card margins',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    final square = WorkoutExerciseModel.fromJson({
      ..._exercise.toJson(),
      'mediaVariants': {
        'male': {'url': 'https://example.test/square.mp4', 'aspectRatio': 1}
      }
    });
    expect(
        WorkoutExerciseModel.fromJson(square.toJson())
            .withDemo('male')
            .demoAspectRatio,
        1);
    await tester.pumpWidget(_app(TickerMode(
        enabled: false,
        child: ExerciseDetailView(
            exercise: square, mediaGender: 'male', loadDetail: false))));
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('exercise-demo-stage'));
    expect(tester.getTopLeft(stage).dx, 18);
    expect(tester.getSize(stage), const Size(284, 284));
    expect(tester.takeException(), isNull);
  });

  testWidgets('history appends older days without duplicate entries',
      (tester) async {
    final cursors = <String?>[];
    await tester.pumpWidget(_app(Scaffold(
        body: ExerciseInsights(
            exerciseId: 'one',
            loader: ({cursor, refresh = false}) async {
              cursors.add(cursor);
              return _history(cursor: cursor);
            }))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(cursors, [null, '2026-10-05']);
    expect(find.byType(ProgressSetHistory), findsNWidgets(3));
    expect(find.text('Load more'), findsNothing);
    await tester.ensureVisible(find.byType(ProgressSetHistory).first);
    await tester.tap(find.byType(ProgressSetHistory).first);
    await tester.pumpAndSettle();
    final firstDay = find.byType(ProgressSetHistory).first;
    expect(find.descendant(of: firstDay, matching: find.text('16')),
        findsOneWidget);
    expect(find.descendant(of: firstDay, matching: find.text('10')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Empty and populated history never depend on the unavailable rank endpoint',
      (tester) async {
    final adapter = _HistoryAdapter();
    final client = ApiClient.shared.client;
    final original = client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
    await tester.pumpWidget(_app(const Scaffold(
        body: ExerciseInsights(exerciseId: 'history-only-contract'))));
    await tester.pumpAndSettle();
    expect(find.text('Your progress starts here'), findsOneWidget);
    expect(adapter.paths.any((path) => path.endsWith('/rank')), false);
    adapter.logged = true;
    await ProgressRepository.shared.invalidate();
    await tester.pumpAndSettle();
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(find.text('Could not load exercise history.'), findsNothing);
    expect(adapter.paths.any((path) => path.endsWith('/rank')), false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bodyweight progress starts with reps and never invents a load',
      (tester) async {
    final history = _history();
    history['series'] = [
      for (var day = 1; day <= 3; day++)
        {..._day(day), 'load': 0, 'volume': 0, 'estimatedStrength': null},
    ];
    history['records'] = {
      'bestLoad': {'weight': 0, 'reps': 10, 'date': '2026-10-03'}
    };
    await tester.pumpWidget(_app(Scaffold(
        body: SingleChildScrollView(
            child: ExerciseProgressContent(data: history)))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<String>>(
                find.byKey(const ValueKey('exercise-progress-metric')))
            .value,
        'reps');
    expect(
        tester.widget<ProgressChart>(find.byType(ProgressChart)).unit, 'reps');
    expect(find.text('0 kg'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed older page keeps history and retries the same cursor',
      (tester) async {
    final cursors = <String?>[], refreshes = <bool>[];
    var fail = true;
    await tester.pumpWidget(_app(Scaffold(
        body: ExerciseInsights(
            exerciseId: 'retry-page',
            loader: ({cursor, refresh = false}) async {
              cursors.add(cursor);
              refreshes.add(refresh);
              if (cursor != null && fail) throw StateError('Offline');
              return _history(cursor: cursor);
            }))));
    await tester.pumpAndSettle();
    final scroll = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Load more'), 250,
        scrollable: scroll);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressSetHistory), findsNWidgets(2));
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(find.text('Could not load exercise history.'), findsNothing);
    fail = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(cursors, [null, '2026-10-05', '2026-10-05']);
    expect(refreshes, [false, false, true]);
    expect(find.byType(ProgressSetHistory), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing history is empty while server failures offer retry',
      (tester) async {
    var status = 404;
    Future<Map<String, dynamic>> loader(
        {String? cursor, bool refresh = false}) async {
      final request = RequestOptions(path: '/exercise');
      throw DioException(
          requestOptions: request,
          response:
              Response(requestOptions: request, statusCode: status, data: {
            'error':
                status == 404 ? 'Exercise history not found' : 'Server error'
          }));
    }

    await tester.pumpWidget(_app(
        Scaffold(body: ExerciseInsights(exerciseId: 'one', loader: loader))));
    await tester.pumpAndSettle();
    expect(find.text('Your progress starts here'), findsOneWidget);
    expect(find.byType(ProgressChart), findsNothing);
    status = 503;
    await tester.pumpWidget(_app(Scaffold(
        body: ExerciseInsights(
            key: const ValueKey('new'), exerciseId: 'two', loader: loader))));
    await tester.pumpAndSettle();
    expect(find.text('Could not load exercise history.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Your progress starts here'), findsNothing);
  });

  testWidgets('a late response cannot overwrite a newly selected exercise',
      (tester) async {
    final old = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(_app(Scaffold(
        body: ExerciseInsights(
            exerciseId: 'old',
            loader: ({cursor, refresh = false}) => old.future))));
    await tester.pump();
    await tester.pumpWidget(_app(Scaffold(
        body: ExerciseInsights(
            exerciseId: 'new',
            loader: ({cursor, refresh = false}) async =>
                {'series': [], 'history': [], 'records': {}}))));
    await tester.pumpAndSettle();
    old.complete(_history());
    await tester.pumpAndSettle();
    expect(find.text('Your progress starts here'), findsOneWidget);
    expect(find.byType(ProgressChart), findsNothing);
  });

  testWidgets('Muscle maps remain readable with enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
        Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ExerciseMuscleMap(exercise: _exercise))),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
