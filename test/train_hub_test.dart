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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/repositories/training_repository.dart';
import 'package:setcraft/features/train/components/workout_completion_summary.dart';
import 'package:setcraft/features/train/views/train_view.dart';
import 'package:setcraft/features/train/views/create_workout_view.dart';
import 'package:setcraft/features/train/views/saved_routines_view.dart';
import 'package:setcraft/features/today/components/weekly_rhythm_calendar.dart';
import 'package:setcraft/core/components/session_overview_card.dart';
import 'package:setcraft/features/today/views/today_home_view.dart';
import 'today_date_filter_test.dart' show DateAdapter;
import 'training_session_test.dart' as training;
import 'saved_routines_view_test.dart' show RoutineAdapter;

class HubAdapter extends RoutineAdapter {
  Completer<void>? holdCreate;
  bool failCreate = false, completed = false, rest = false, started = false;
  bool todayHome = false;
  int completedSets = 0;
  final home = DateAdapter()..recordedReadiness = true;
  final savedWorkouts = <Map<String, dynamic>>[];
  String workoutName = 'Push day';
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (todayHome &&
        (options.path == '/api/home' ||
            options.path == '/api/history/recovery')) {
      return home.fetch(options, stream, cancel);
    }
    if (options.method == 'GET' &&
        Uri.parse(options.path).path.endsWith('/training')) {
      final date = Uri.parse(options.path).queryParameters['date']!;
      final day =
          training.fixture(date, finished: completed, sets: completedSets)
            ..['session'] = completed
                ? {'status': 'COMPLETED', 'durationSeconds': 1200}
                : started
                    ? {'status': 'IN_PROGRESS'}
                    : null
            ..['restDay'] = rest
            ..['name'] = workoutName;
      (day['items'] as List).first['setTargets'] = targets;
      day['routines'] = [
        ...List.generate(
            5,
            (i) =>
                {'id': 'routine-$i', 'name': 'Saved workout $i', 'count': 1}),
        ...savedWorkouts,
      ];
      return ResponseBody.fromString(jsonEncode({'data': day}), 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (options.method == 'PATCH' &&
        Uri.parse(options.path).path.endsWith('/day')) {
      writes.add({
        'path': Uri.parse(options.path).path,
        'method': 'PATCH',
        'data': options.data
      });
      workoutName = options.data['name'] as String? ?? workoutName;
      rest = options.data['restDay'] as bool? ?? rest;
      final date = Uri.parse(options.path).queryParameters['date']!;
      final day = training.fixture(date)
        ..['session'] = null
        ..['name'] = workoutName
        ..['restDay'] = rest;
      return ResponseBody.fromString(jsonEncode({'data': day}), 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (options.path == '/api/workout/exercises') {
      return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 'pushup',
                'name': 'Push-up',
                'equipment': 'body weight',
                'target': 'pectorals',
                'bodyPart': 'Chest',
                'instructions': <String>[],
              }
            ],
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
    }
    if (options.method == 'POST' &&
        Uri.parse(options.path).path.endsWith('/routines')) {
      writes.add({
        'path': Uri.parse(options.path).path,
        'method': 'POST',
        'date': options.uri.queryParameters['date'],
        'data': options.data
      });
      if (holdCreate != null) await holdCreate!.future;
      if (failCreate) {
        return ResponseBody.fromString(
            '{"error":"Could not save routine."}', 400,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
    }
    // Super handles ordinary GETs and tracks other mutations.
    if (options.method == 'POST' &&
        Uri.parse(options.path).path.endsWith('/routines')) {
      final date = Uri.parse(options.path).queryParameters['date']!;
      final day = training.fixture(date)
        ..['session'] = null
        ..['name'] = workoutName;
      (day['items'] as List).first['setTargets'] = targets;
      savedWorkouts.add({
        'id': 'new-routine-${savedWorkouts.length}',
        'name': options.data['name'],
        'count': (options.data['items'] as List).length
      });
      day['routines'] = [...savedWorkouts];
      return ResponseBody.fromString(jsonEncode({'data': day}), 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    return super.fetch(options, stream, cancel);
  }
}

void main() {
  late HubAdapter adapter;
  var owner = 0;
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: training.token('hub-test-${owner++}'),
        refreshToken: 'test');
    adapter = HubAdapter();
    final client = ApiClient.shared.client,
        original = ApiClient.shared.client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
  });
  void phone(WidgetTester tester, {double width = 393}) {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child,
          {String locale = 'en', double scale = 1}) =>
      MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
              data:
                  MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(
                  key: const ValueKey('hub-preview'), child: child!)),
          home: child);

  Future<void> openCreator(WidgetTester tester) async {
    await tester.pumpWidget(app(SavedRoutinesView(initial: trainingDay())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create workout'));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('hub-preview')))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
      'Library stays first; Train previews have no competing row actions',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.text('Exercise library')).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('train-session-card')))
            .dy));
    expect(find.byType(WeeklyRhythmCalendarButton), findsOneWidget);
    expect(find.byTooltip('Edit exercise'), findsNothing);
    expect(find.byTooltip('Workout options'), findsNothing);
    expect(find.text('Done'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    await capture(tester, 'train-premium-preview');
    await tester.scrollUntilVisible(find.text('Edit'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit exercise'), findsOneWidget);
    expect(find.text('Rename workout'), findsOneWidget);
    expect(find.text('Save to My workouts'), findsOneWidget);
    await capture(tester, 'edit-workout-actions-preview');
    await close(tester);
  });

  testWidgets(
      'Calendar supports future training weeks without enabling future Today history',
      (tester) async {
    phone(tester);
    final now = DateTime.now();
    final future = DateTime(now.year, now.month + 1, 10);
    await tester.pumpWidget(app(WeeklyRhythmCalendar(
        selectedDate: future, today: now, allowFuture: true)));
    await tester.pumpAndSettle();
    final day = find.byKey(ValueKey(
        'week-calendar-day-${future.toIso8601String().substring(0, 10)}'));
    expect(tester.widget<TextButton>(day).onPressed, isNotNull);
    await close(tester);
  });

  testWidgets(
      'An unstarted past workout saves its exact prescription once and opens My workouts',
      (tester) async {
    phone(tester);
    const date = '2026-10-19';
    adapter.holdCreate = Completer<void>();
    await tester.pumpWidget(app(const TrainView(initialDate: date)));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('train-session-card'));
    final action =
        find.descendant(of: card, matching: find.byType(FilledButton));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(
        tester.widget<SessionOverviewCard>(card).actionLabel, 'Save workout');
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();
    for (var i = 0; i < 50 && adapter.writes.isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(adapter.writes, hasLength(1));
    expect(adapter.writes.single['path'], endsWith('/routines'));
    expect(adapter.writes.single['date'], date);
    final data = adapter.writes.single['data'];
    expect(data['name'], 'Push day');
    expect(data['items'].single, {
      'workoutId': 'exercise',
      'targetSets': 3,
      'targetReps': '8-12',
      'targetWeight': 0.0,
      'restSeconds': 60,
      'setTargets': adapter.targets,
    });
    adapter.holdCreate!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<SessionOverviewCard>(card).actionLabel, 'My workouts');
    expect(find.text('Saved to My workouts'), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final library =
        tester.widget<SavedRoutinesView>(find.byType(SavedRoutinesView));
    expect(library.initial.routines.last['name'], 'Push day');
    expect(library.initial.session, isNull);
    expect(library.initial.date, date);
    expect(library.initial.items.single.status, 'NOT_STARTED');
    expect(library.initial.loggedEntries, isEmpty);
    expect(adapter.writes, hasLength(1));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('A failed past-workout save can retry without starting a session',
      (tester) async {
    phone(tester);
    adapter.failCreate = true;
    await tester.pumpWidget(app(const TrainView(initialDate: '2026-10-19')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('train-session-card'));
    final action =
        find.descendant(of: card, matching: find.byType(FilledButton));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Could not save routine.'), findsOneWidget);
    expect(
        tester.widget<SessionOverviewCard>(card).actionLabel, 'Save workout');
    adapter.failCreate = false;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tester.widget<SessionOverviewCard>(card).actionLabel, 'My workouts');
    expect(adapter.writes, hasLength(2));
    expect(
        adapter.writes.every((row) => '${row['path']}'.endsWith('/routines')),
        isTrue);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Only unstarted past sessions change their primary action',
      (tester) async {
    phone(tester);
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final future = DateTime(now.year, now.month, now.day + 7)
        .toIso8601String()
        .substring(0, 10);
    for (final (date, started, completed, rest, label, enabled) in [
      (today, false, false, false, 'Start workout', true),
      (future, false, false, false, 'Start workout', false),
      ('2026-10-19', true, false, false, 'Resume workout', true),
      ('2026-10-20', false, true, false, 'View summary', true),
      ('2026-10-21', false, false, true, 'Build a workout', true),
    ]) {
      adapter.started = started;
      adapter.completed = completed;
      adapter.rest = rest;
      await tester.pumpWidget(app(TrainView(initialDate: date)));
      await tester.pumpAndSettle();
      final card = tester.widget<SessionOverviewCard>(
          find.byKey(const ValueKey('train-session-card')));
      expect(card.actionLabel, label);
      expect(card.onAction != null, enabled);
      expect(adapter.writes, isEmpty);
      await close(tester);
    }
  });

  testWidgets('Today saves the workout from the selected historical week',
      (tester) async {
    phone(tester);
    adapter.todayHome = true;
    await tester.pumpWidget(app(TodayHomeView(
        clock: () => DateTime(2026, 10, 28),
        onSelectTab: (_) {},
        onOpenProfile: () {})));
    await tester.pumpAndSettle();
    final calendar = find.byKey(const ValueKey('weekly-rhythm-calendar'));
    await tester.scrollUntilVisible(calendar, -180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(calendar);
    await tester.pumpAndSettle();
    await tester.tap(calendar);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('week-calendar-day-2026-10-19')));
    await tester.tap(find.byKey(const ValueKey('week-calendar-view-week')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('today-session-card'));
    final action =
        find.descendant(of: card, matching: find.byType(FilledButton));
    await tester.scrollUntilVisible(action, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(find.descendant(of: card, matching: find.text('Save workout')),
        findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    expect(adapter.writes.single['date'], '2026-10-19');
    expect(adapter.writes.single['path'], endsWith('/routines'));
    expect(adapter.writes.single['data']['items'].single['setTargets'],
        adapter.targets);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final library =
        tester.widget<SavedRoutinesView>(find.byType(SavedRoutinesView));
    expect(library.initial.date, '2026-10-19');
    expect(library.initial.routines.single['name'], 'Push day');
    expect(library.initial.session, isNull);
    expect(adapter.writes, hasLength(1));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
      'View summary opens the completed workout and Done returns to Train',
      (tester) async {
    phone(tester);
    adapter.completed = true;
    adapter.completedSets = 3;
    await tester.pumpWidget(app(const TrainView(initialDate: '2026-10-20')));
    await tester.pumpAndSettle();
    final action = find.descendant(
        of: find.byKey(const ValueKey('train-session-card')),
        matching: find.byType(FilledButton));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutCompletionSummary), findsOneWidget);
    expect(find.text('Workout summary'), findsOneWidget);
    expect(find.text('600 kg'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final exercise = find.byType(ExpansionTile);
    await tester.ensureVisible(exercise);
    await tester.pumpAndSettle();
    await tester.tap(exercise);
    await tester.pumpAndSettle();
    expect(find.text('20 kg'), findsNWidgets(3));
    expect(adapter.writes, isEmpty);
    await capture(tester, 'train-completed-summary-preview');
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutCompletionSummary), findsNothing);
    expect(find.byKey(const ValueKey('train-session-card')), findsOneWidget);
    expect(adapter.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
      'Create workout adds an exercise and saves a template without changing the scheduled workout',
      (tester) async {
    phone(tester);
    await openCreator(tester);
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();
    expect(adapter.writes, isEmpty);
    expect(find.text('Enter a workout name.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('workout-name')), 'My push day');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-exercise-pushup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-selection')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('Push-up'), findsOneWidget);
    await capture(tester, 'create-workout-preview');
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    expect(adapter.writes.single['path'], endsWith('/routines'));
    expect(adapter.writes.single['data']['name'], 'My push day');
    expect(find.byType(SavedRoutinesView), findsOneWidget);
    expect(find.text('My push day'), findsOneWidget);
    await capture(tester, 'my-workouts-preview');
    expect(
        adapter.writes.single['data']['items'].single['workoutId'], 'pushup');
    await close(tester);
  });

  testWidgets('My workouts refreshes saves made from another cached week',
      (tester) async {
    phone(tester);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await close(tester);
    adapter.workoutName = 'Saved from October';
    final repo = TrainingRepository.shared;
    await tester.runAsync(() => repo.saveWorkout('2026-10-19'));
    expect(
        (await repo.cached(today))!
            .routines
            .any((r) => r['name'] == 'Saved from October'),
        isFalse,
        reason: 'The other date still has its earlier 30-second cache entry');
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    final libraryButton = find.byKey(const ValueKey('train-my-workouts'));
    await tester.scrollUntilVisible(libraryButton, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(libraryButton);
    await tester.pumpAndSettle();
    await tester.tap(libraryButton);
    await tester.pumpAndSettle();
    final library =
        tester.widget<SavedRoutinesView>(find.byType(SavedRoutinesView));
    expect(library.initial.date, today);
    expect(library.initial.routines.last['name'], 'Saved from October');
    expect(adapter.writes, hasLength(1));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
      'Saving a copy preserves targets, blocks duplicate taps, and keeps a failed draft',
      (tester) async {
    phone(tester);
    adapter.holdCreate = Completer<void>();
    adapter.failCreate = true;
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Edit'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('train-manage-save')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateWorkoutView), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-workout-action')));
    await tester.tap(find.byKey(const ValueKey('save-workout-action')));
    await tester.pump();
    for (var i = 0; i < 50 && adapter.writes.isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(adapter.writes, hasLength(1));
    expect(adapter.writes.single['data']['items'].single['setTargets'],
        adapter.targets);
    adapter.holdCreate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Could not save routine.'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('workout-name')))
            .controller!
            .text,
        'Push day');
    expect(find.text('Dumbbell press'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
      'Rename and rest actions stay in Edit workout and update the selected day',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Workout options'), findsNothing);
    await tester.scrollUntilVisible(find.text('Edit'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('train-manage-rename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Upper body');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Upper body'), findsOneWidget);
    expect(adapter.writes.single['data']['name'], 'Upper body');
    await tester.tap(find.byKey(const ValueKey('train-manage-rest')));
    await tester.pumpAndSettle();
    expect(adapter.writes.last['data']['restDay'], true);
    expect(find.byKey(const ValueKey('train-manage-rest')), findsNothing);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
      'Completed workouts can still be saved without offering edits or rest changes',
      (tester) async {
    phone(tester);
    adapter.completed = true;
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Details'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('train-manage-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('train-manage-rename')), findsNothing);
    expect(find.byKey(const ValueKey('train-manage-rest')), findsNothing);
    expect(find.byTooltip('Edit exercise'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('train-manage-save')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateWorkoutView), findsOneWidget);
    expect(adapter.writes, isEmpty);
    await close(tester);
  });

  testWidgets('Edit workout actions fit narrow enlarged German text',
      (tester) async {
    phone(tester, width: 320);
    await tester.pumpWidget(app(
        const TrainView(standalone: true, editOnly: true),
        locale: 'de',
        scale: 1.6));
    await tester.pumpAndSettle();
    await capture(tester, 'edit-workout-actions-large-preview');
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Leaving a new workout asks before discarding the draft',
      (tester) async {
    phone(tester);
    await openCreator(tester);
    await tester.enterText(
        find.byKey(const ValueKey('workout-name')), 'Draft workout');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateWorkoutView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateWorkoutView), findsNothing);
    expect(adapter.writes, isEmpty);
    await close(tester);
  });

  testWidgets('My workouts fits narrow enlarged German text', (tester) async {
    phone(tester, width: 320);
    await tester.pumpWidget(app(SavedRoutinesView(initial: trainingDay()),
        locale: 'de', scale: 1.5));
    await tester.pumpAndSettle();
    await capture(tester, 'my-workouts-large-preview');
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}

// Reuse the same confirmed day shape as the logging tests.
TrainingDay trainingDay() => TrainingDay(training.fixture('2026-10-13')
  ..['session'] = null
  ..['routines'] = List.generate(
      5, (i) => {'id': 'routine-$i', 'name': 'Saved workout $i', 'count': 3}));
