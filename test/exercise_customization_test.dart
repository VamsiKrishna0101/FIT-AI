import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/train/components/training_targets.dart';
import 'package:fitai_mobile/features/train/models/training_session.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';
import 'package:fitai_mobile/features/train/repositories/training_repository.dart';
import 'package:fitai_mobile/features/train/views/exercise_library_view.dart';
import 'package:fitai_mobile/features/train/views/train_dashboard_view.dart';
import 'package:fitai_mobile/features/planner/views/widgets/weekly_plan_schedule.dart';

Map<String, dynamic> exercise(String id, String name) => {
      'id': id,
      'name': name,
      'target': 'pectorals',
      'bodyPart': 'Chest',
      'equipment': 'dumbbell',
      'instructions': <String>[],
    };

Map<String, dynamic> day(String date) => {
      'date': date,
      'name': 'Chest and triceps',
      'restDay': false,
      'session': null,
      'week': [],
      'routines': [],
      'items': <Map<String, dynamic>>[
        {
          'id': 'item',
          'dayOfWeek': 'SUNDAY',
          'targetSets': 2,
          'targetReps': '10',
          'targetWeight': 12.0,
          'restSeconds': 90,
          'setLogs': [],
          'setTargets': {
            'weightBasis': 'as_logged',
            'weightUnit': 'per_hand',
            'sets': [
              {'setNumber': 1, 'repsMin': 10, 'repsMax': 10, 'weightKg': 12.0},
              {
                'setNumber': 2,
                'repsMin': 8,
                'repsMax': 8,
                'weightKg': 14.0,
                'targetRpe': 7.0
              },
            ]
          },
          'workout': exercise('press', 'Dumbbell press'),
        }
      ],
    };

class Adapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final days = <String, Map<String, dynamic>>{};
  bool failSave = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    calls.add(options);
    dynamic result;
    var status = 200;
    if (options.path.contains('/training')) {
      final date = Uri.parse(options.path).queryParameters['date']!;
      final current = days.putIfAbsent(date, () => day(date));
      if (options.method == 'POST' && options.path.contains('/items')) {
        if (failSave) {
          status = 503;
        } else {
          (current['items'] as List).add({
            ...Map<String, dynamic>.from(options.data as Map),
            'id': 'added',
            'dayOfWeek': 'SUNDAY',
            'setLogs': [],
            'workout': exercise('fly', 'Dumbbell fly'),
          });
        }
      }
      result = current;
    } else if (options.path == '/api/workout/exercises') {
      result = null;
      return ResponseBody.fromString(
          jsonEncode({
            'data': [exercise('fly', 'Dumbbell fly')],
            'pagination': {
              'page': 1,
              'pageSize': 24,
              'total': 1,
              'totalPages': 1
            },
            'filters': {'bodyParts': [], 'equipment': []},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    } else if (options.path == '/api/home') {
      status = 503;
    }
    return ResponseBody.fromString(
        jsonEncode(status == 200
            ? {'data': result}
            : {'error': 'Could not save. Please try again.'}),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Widget app(Widget child, {double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: FitnessTheme(child: child),
    );

void main() {
  var owner = 0;
  late Adapter adapter;
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'userId': 'editor-${owner++}'})));
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'e30.$payload.synthetic', refreshToken: 'test');
    adapter = Adapter();
    final previous = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = previous);
  });

  testWidgets('Editing a set preserves the other set and per-hand convention',
      (tester) async {
    Map<String, dynamic>? saved;
    final item =
        TodayPlanItemModel.fromJson((day('2026-10-18')['items'] as List).first);
    await tester.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                onPressed: () async =>
                    saved = await editTrainingTargets(context, item),
                child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('target-weight-1')), '15');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!['targetSets'], 2);
    final targets = saved!['setTargets'] as Map;
    expect(targets['weightUnit'], 'per_hand');
    expect(targets['sets'][0]['weightKg'], 12);
    expect(targets['sets'][1]['weightKg'], 15);
    expect(targets['sets'][1]['repsMax'], 8);
    expect(targets['sets'][1]['targetRpe'], 7);
    expect(saved!['restSeconds'], 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Adding from a weekly workout saves to its selected date with explicit targets',
      (tester) async {
    const date = '2026-10-18';
    await tester.pumpWidget(app(
        const TrainView(standalone: true, editOnly: true, initialDate: date)));
    await tester.pumpAndSettle();
    expect(find.text('Saved routines'), findsNothing);
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-exercise-fly')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('target-weight-0')), '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saves = adapter.calls
        .where((call) => call.method == 'POST' && call.path.contains('/items'))
        .toList();
    expect(saves, hasLength(1));
    expect(Uri.parse(saves.single.path).queryParameters['date'], date);
    expect(saves.single.data['workoutId'], 'fly');
    expect(saves.single.data['setTargets']['sets'][0]['weightKg'], 4);
    await tester.scrollUntilVisible(find.text('Dumbbell fly'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Dumbbell fly'), findsOneWidget);
    expect((await TrainingRepository.shared.cached(date))!.items.length, 2);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Weekly overview shows saved exercise changes rather than the generated snapshot',
      (tester) async {
    final dates = <String>[];
    await tester.pumpWidget(app(Scaffold(
        body: SingleChildScrollView(
            child: WeeklyPlanSchedule(
      active: true,
      payload: const {
        'workouts': [
          {
            'date': '2026-10-18',
            'name': 'Old recommendation',
            'restDay': false,
            'exercises': []
          },
          {
            'date': '2026-10-19',
            'name': 'Rest',
            'restDay': true,
            'exercises': []
          },
        ]
      },
      loadDay: (date) async {
        dates.add(date);
        final data = day(date);
        data['name'] =
            date == '2026-10-18' ? 'Edited workout' : 'Another workout';
        return TrainingDay(data);
      },
    )))));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell press'), findsOneWidget);
    expect(find.text('10 reps · 12.0 kg per hand'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('edit-plan-day-2026-10-18')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-19')));
    await tester.pumpAndSettle();
    expect(dates, ['2026-10-18', '2026-10-19']);
    expect(find.text('Another workout'), findsOneWidget);
    expect(find.text('Edited workout'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Library fits a small phone with enlarged text and blocks duplicate adds',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saving = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(app(
        ExerciseLibraryView(
          onExerciseAdded: () {},
          initialExercises: [
            WorkoutExerciseModel.fromJson(exercise('fly', 'Dumbbell fly'))
          ],
          addToWorkout: (_) {
            calls++;
            return saving.future;
          },
        ),
        scale: 1.8));
    await tester.pumpAndSettle();
    final add = find.byKey(const ValueKey('add-exercise-fly'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();
    await tester.tap(add);
    expect(calls, 1);
    saving.complete(false);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Capture compact exercise browser', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const capture = ValueKey('exercise-preview');
    await tester.pumpWidget(app(RepaintBoundary(
        key: capture,
        child: ExerciseLibraryView(
          onExerciseAdded: () {},
          initialExercises: [
            WorkoutExerciseModel.fromJson(
                exercise('press', 'Dumbbell bench press')),
            WorkoutExerciseModel.fromJson(exercise('fly', 'Dumbbell fly')),
            WorkoutExerciseModel.fromJson({
              ...exercise('row', 'Seated cable row'),
              'target': 'Back',
              'equipment': 'cable'
            }),
            WorkoutExerciseModel.fromJson({
              ...exercise('squat', 'Barbell squat'),
              'target': 'Quads',
              'equipment': 'barbell'
            }),
          ],
        ))));
    await tester.pumpAndSettle();
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/compact-exercise-library.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
