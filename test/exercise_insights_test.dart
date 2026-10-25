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
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/progress/repositories/progress_repository.dart';
import 'package:fitai_mobile/features/train/components/graphite_anatomy.dart';
import 'package:fitai_mobile/features/progress/components/progress_chart.dart';
import 'package:fitai_mobile/features/progress/components/exercise_progress_content.dart';
import 'package:fitai_mobile/features/train/components/exercise_insights.dart';
import 'package:fitai_mobile/features/train/components/exercise_muscle_map.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';
import 'package:fitai_mobile/features/train/views/exercise_detail_view.dart';

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

Map<String, dynamic> _rank({bool empty = false}) => {
      'kind': 'PERSONAL_TRAINING',
      'tier': empty ? 0 : 2,
      'title': empty ? 'Getting started' : 'Building momentum',
      'trainingDays': empty ? 0 : 6,
      'nextMilestone': {
        'trainingDays': empty ? 5 : 12,
        'progress': empty ? 0 : .5
      },
      'strengthRank': {
        'tier': empty ? 0 : 3,
        'title': empty ? 'Not ranked yet' : 'Intermediate',
        'estimatedMaxKg': empty ? null : 40,
        'bodyWeightKg': 70,
        'weightUnit': 'per_hand',
        'progress': empty ? 0 : .4,
        'nextLevel': empty ? null : {'title': 'Advanced', 'estimatedMaxKg': 50},
        'reason':
            'Log this exercise on two different days with confirmed load units to estimate your level.',
        'sourceUrl':
            'https://strengthlevel.com/strength-standards/dumbbell-bench-press/kg',
      },
      'strengthBadges': [
        for (var index = 0; index < 5; index++)
          {
            'id': 'STRENGTH_${index + 1}',
            'title': const [
              'Beginner',
              'Novice',
              'Intermediate',
              'Advanced',
              'Elite'
            ][index],
            'tier': index + 1,
            'earned': !empty && index < 3,
            'description':
                'An estimated exercise level from repeated logged performance and a matching bodyweight reference.'
          },
      ],
      'badges': [
        {
          'title': 'First log',
          'description': 'Log a set of this exercise.',
          'tier': 1,
          'earned': !empty
        },
        {
          'title': 'Five training days',
          'description': 'Train this exercise on five different days.',
          'tier': 2,
          'earned': !empty
        },
        {
          'title': 'Personal best',
          'description': 'Improve a previous load, rep or volume record.',
          'tier': 3,
          'earned': !empty
        },
      ],
    };

Map<String, dynamic> _history({int days = 6, String? cursor}) => {
      'rank': _rank(),
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
    final status = rankRoute || logged ? 200 : 404;
    final body = rankRoute
        ? {'data': _rank(empty: true)}
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
      'Info, Progress and Rank share history and preserve the add action',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    var loads = 0, adds = 0;
    await tester.pumpWidget(_app(ExerciseDetailView(
      exercise: _exercise,
      loadDetail: false,
      historyLoader: ({cursor, refresh = false}) async {
        loads++;
        return _history(cursor: cursor);
      },
      onAddToPlan: () async {
        adds++;
        return false;
      },
    )));
    await tester.pumpAndSettle();
    expect(loads, 0);
    await _capture(tester, 'exercise-info');
    expect(find.text('Info'), findsOneWidget);
    expect(
        find.descendant(of: find.byType(TabBar), matching: find.byType(Icon)),
        findsNothing);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(loads, 1);
    await _capture(tester, 'exercise-progress');
    await tester.tap(find.text('Rank'));
    await tester.pumpAndSettle();
    expect(find.text('Intermediate'), findsNWidgets(2));
    expect(find.text('Building momentum'), findsNothing);
    expect(loads, 1);
    await _capture(tester, 'exercise-rank');
    await tester.drag(find.byType(ListView).last, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-badge-STRENGTH_2')));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'An estimated exercise level from repeated logged performance and a matching bodyweight reference.'),
        findsOneWidget);
    Navigator.of(tester.element(find.text(
            'An estimated exercise level from repeated logged performance and a matching bodyweight reference.')))
        .pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    expect(adds, 1);
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('exercise-anatomy-map')), 250,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-muscles');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exercise tabs remain readable on a small phone with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
        ExerciseDetailView(
          exercise: _exercise,
          loadDetail: false,
          historyLoader: ({cursor, refresh = false}) async => _history(),
        ),
        scale: 1.6));
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('exercise-demo-stage'));
    expect(tester.getTopLeft(stage).dx, 0);
    expect(tester.getSize(stage).width, 320);
    expect(tester.getSize(stage).height, closeTo(180, .1));
    expect(
        tester
            .getSize(find.byKey(const ValueKey('exercise-demo-stage')))
            .height,
        lessThanOrEqualTo(280));
    await tester.tap(find.text('Rank'));
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-rank-large-text');
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('exercise-badge-STRENGTH_5')), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-badge-STRENGTH_5')));
    await tester.pumpAndSettle();
    expect(find.text('Elite'), findsWidgets);
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

  testWidgets('square MP4 uses its verified dimensions without side padding',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    final square = WorkoutExerciseModel.fromJson(
        {..._exercise.toJson(), 'mediaAspectRatio': 1});
    expect(WorkoutExerciseModel.fromJson(square.toJson()).demoAspectRatio, 1);
    await tester.pumpWidget(
        _app(ExerciseDetailView(exercise: square, loadDetail: false)));
    await tester.pumpAndSettle();
    final stage = find.byKey(const ValueKey('exercise-demo-stage'));
    expect(tester.getTopLeft(stage).dx, 0);
    expect(tester.getSize(stage), const Size(320, 320));
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
    await tester.tap(find.text('Set history'));
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
      'new exercises load backend locked badges and new sets refresh ranks',
      (tester) async {
    final adapter = _HistoryAdapter();
    final client = ApiClient.shared.client;
    final original = client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
    await tester.pumpWidget(_app(const Scaffold(
        body: ExerciseInsights(
            exerciseId: 'rank-contract-exercise', rank: true))));
    await tester.pumpAndSettle();
    expect(adapter.paths.last,
        '/api/progress/exercises/rank-contract-exercise/rank');
    expect(find.text('Not ranked yet'), findsOneWidget);
    adapter.logged = true;
    await ProgressRepository.shared.invalidate();
    await tester.pumpAndSettle();
    expect(find.text('Intermediate'), findsNWidgets(2));
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

  testWidgets(
      'strength badges stay locked without evidence and fit enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
        Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child:
                    ExerciseRankContent(data: {'rank': _rank(empty: true)}))),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(find.text('Not ranked yet'), findsOneWidget);
    expect(
        tester
            .widgetList<ExerciseRankBadge>(find.byType(ExerciseRankBadge))
            .every((badge) => !badge.earned),
        isTrue);
    expect(tester.takeException(), isNull);
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
