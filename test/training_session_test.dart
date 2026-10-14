import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/localization/fitness_copy_data.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/train/components/workout_set_entry.dart';
import 'package:fitai_mobile/features/train/models/training_session.dart';
import 'package:fitai_mobile/features/train/repositories/training_repository.dart';
import 'package:fitai_mobile/features/train/views/workout_session_view.dart';
import 'package:fitai_mobile/features/train/views/train_view.dart';

String token(String owner) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.synthetic';

Map<String, dynamic> fixture(String date,
        {bool finished = false, int sets = 0}) =>
    {
      'date': date,
      'name': 'Workout',
      'restDay': false,
      'session': {
        'id': 'session',
        'status': finished ? 'COMPLETED' : 'IN_PROGRESS',
        'startedAt': DateTime.now().toIso8601String(),
        'durationSeconds': finished ? 620 : null
      },
      'items': [
        {
          'id': 'item',
          'dayOfWeek': 'THURSDAY',
          'orderIndex': 0,
          'targetSets': 3,
          'targetReps': '8-12',
          'restSeconds': 60,
          'status': finished ? 'COMPLETED' : 'NOT_STARTED',
          'setLogs': List.generate(
              sets, (i) => {'setNumber': i + 1, 'reps': 10, 'weight': 20}),
          'workout': {
            'id': 'exercise',
            'name': 'Dumbbell press',
            'target': 'pectorals',
            'equipment': 'dumbbells'
          }
        }
      ],
      'summary': {'sets': sets, 'volume': sets * 200, 'skipped': 0},
      'week': [],
      'routines': [],
    };

class Adapter implements HttpClientAdapter {
  int savedSets = 0;
  bool rejectCompletion = false;
  Completer<void>? slowRead;
  final readStarted = Completer<void>();
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (options.path == '/api/home') {
      return ResponseBody.fromString('{"error":"Home sync unavailable"}', 503,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    Map<String, dynamic> data;
    final date =
        Uri.parse(options.path).queryParameters['date'] ?? '2026-10-08';
    if (options.path.contains('/previous/')) {
      data = {'date': null, 'sets': []};
    } else if (options.method == 'GET' && options.path.contains('/training')) {
      if (!readStarted.isCompleted) readStarted.complete();
      if (slowRead != null) await slowRead!.future;
      data = fixture(date, sets: savedSets);
    } else if (options.method == 'PUT') {
      savedSets = 1;
      data = fixture(date, sets: 1);
    } else if (options.method == 'POST' && options.path.contains('/complete')) {
      final sets = options.data['sets'] as List;
      if (rejectCompletion) {
        return ResponseBody.fromString(
            '{"error":"Could not save. Please try again."}', 503,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
      savedSets = sets.isEmpty ? savedSets : sets.length;
      data = fixture(date, sets: savedSets);
      (data['items'] as List).first['status'] = 'COMPLETED';
    } else if (options.method == 'PATCH' && options.path.contains('/status')) {
      if (rejectCompletion ||
          (savedSets == 0 && options.data['status'] == 'COMPLETED')) {
        return ResponseBody.fromString(
            jsonEncode({
              'error': 'Log at least one set before marking this exercise done.'
            }),
            400,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
      data = fixture(date, sets: savedSets);
      (data['items'] as List).first['status'] = options.data['status'];
    } else if (options.method == 'POST' && options.path.contains('/finish')) {
      data = fixture(date, sets: savedSets, finished: true);
    } else {
      data = fixture(date);
    }
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Widget app(Widget child, {String locale = 'en'}) => MaterialApp(
    theme: ThemeData.dark(),
    locale: Locale(locale),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child);

void main() {
  late Adapter adapter;
  var accountNumber = 0;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('train-test-${accountNumber++}'),
        refreshToken: 'synthetic');
    adapter = Adapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  test('a stale read cannot overwrite a newly saved set', () async {
    final repo = TrainingRepository.shared;
    adapter.slowRead = Completer<void>();
    final read = repo.load('2026-10-09', refresh: true);
    await adapter.readStarted.future;
    final saved = await repo.mutate('2026-10-09', 'PUT', '/items/item/sets',
        data: {'setNumber': 1, 'reps': 10, 'weight': 20});
    expect(saved.loggedSets, 1);
    adapter.slowRead!.complete();
    expect((await read).loggedSets, 1);
    expect((await repo.cached('2026-10-09'))!.loggedSets, 1);
  });

  test('a delayed response cannot populate another account cache', () async {
    adapter.slowRead = Completer<void>();
    final read = TrainingRepository.shared.load('2026-10-10', refresh: true);
    await adapter.readStarted.future;
    final expectation = expectLater(
        read, throwsA(anyOf(isA<StateError>(), isA<DioException>())));
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('another-train-test'), refreshToken: 'synthetic');
    adapter.slowRead!.complete();
    await expectation;
    expect(await TrainingRepository.shared.cached('2026-10-10'), isNull);
  });

  testWidgets('set table requires actual reps and never confirms an empty set',
      (tester) async {
    int saves = 0;
    await tester.pumpWidget(app(Scaffold(
        body: WorkoutSetEntry(
            date: '2026-10-11',
            itemId: 'actual-item',
            number: 1,
            targetLabel: '10 reps · 2 kg per hand',
            disabled: false,
            onSave: (reps, weight, effort) async {
              saves++;
              expect(reps, 10);
              expect(weight, 20);
            },
            onDelete: () async {}))));
    await tester.pumpAndSettle();
    expect(find.text('Target · 10 reps · 2 kg per hand'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty);
    await tester.tap(find.byTooltip('Save set'));
    await tester.pump();
    expect(saves, 0);
    expect(find.text('Enter valid reps and load.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.tap(find.byTooltip('Save set'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'finished summary shows recorded totals and no set-entry controls',
      (tester) async {
    await tester.pumpWidget(app(
        WorkoutSessionView(
            initial:
                TrainingDay(fixture('2026-10-12', finished: true, sets: 4))),
        locale: 'de'));
    await tester.pumpAndSettle();
    expect(find.text('Training abgeschlossen'), findsOneWidget);
    expect(find.text('Erfasste Sätze'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('800 kg'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'Done saves entered sets before completing and totals survive finish',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        app(WorkoutSessionView(initial: TrainingDay(fixture('2026-10-10')))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.drag(
        find
            .byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down)
            .last,
        const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final writes = adapter.requests
        .where((r) => r.path.contains('/items/item') && r.method != 'GET')
        .toList();
    expect(writes.map((r) => r.method), ['POST']);
    expect(writes.first.data['sets'].first['reps'], 10);
    expect(writes.first.data['sets'].first['weight'], 20);
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('200 kg'), findsOneWidget);
    expect(find.text('No sets were logged. Your body map is unchanged.'),
        findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'A completed workout can reopen its real set entries for correction',
      (tester) async {
    await tester.pumpWidget(app(WorkoutSessionView(
        initial: TrainingDay(fixture('2026-10-10', finished: true)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit logged sets'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Your sets'), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('workout-session-scroll')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.byType(WorkoutSetEntry), findsWidgets);
    expect(find.text('Save changes'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Train fits a small phone and opens the active exercise logger',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(
        Builder(
            builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: const TrainView(),
                )),
        locale: 'de'));
    await tester.pumpAndSettle();
    expect(find.text('Trainieren'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Dumbbell press'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Dumbbell press'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutSessionView), findsOneWidget);
    expect(find.byType(WorkoutSetEntry), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'Train opens logging instead of completing an exercise with no sets',
      (tester) async {
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Log sets'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Log sets'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutSessionView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Your sets'), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('workout-session-scroll')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.byType(WorkoutSetEntry), findsNWidgets(3));
    expect(
        adapter.requests.where((request) => request.path.contains('/status')),
        isEmpty);
    expect(find.text('Could not save. Please try again.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Train Done completes an exercise that already has saved sets',
      (tester) async {
    adapter.savedSets = 1;
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Done'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Could not save. Please try again.'), findsNothing);
    expect(
        adapter.requests.where((request) => request.path.contains('/status')),
        hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Train preserves backend validation instead of hiding its reason',
      (tester) async {
    adapter.savedSets = 1;
    adapter.rejectCompletion = true;
    await tester.pumpWidget(app(const TrainView()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Done'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Done'));
    // Dio delivers rejection on the event loop while the busy indicator loops.
    final message =
        find.text('Log at least one set before marking this exercise done.');
    for (var attempt = 0;
        attempt < 100 && message.evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.text('Log at least one set before marking this exercise done.'),
        findsOneWidget);
    expect(find.text('Completed'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.ancestor(
                of: find.text('Done'), matching: find.byType(FilledButton)))
            .onPressed,
        isNotNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  test(
      'new training copy exists in every supported locale with matching placeholders',
      () {
    const keys = [
      'Start workout',
      'Resume workout',
      'Saved routines',
      'Personalized weekly AI plan',
      'Coming soon',
      'Save set',
      'Workout complete',
      '{sets} sets · {minutes} min · {skipped} skipped',
      'Body part',
      'Page {page} of {total}',
      'Previous page',
      'Next page',
      'Reset filters',
      'Finding exercises…',
      'Find your next movement. Make it part of your plan.',
      'Clear search',
      'Loading…',
      'Check your connection and try again.',
      'Added',
      'Select'
    ];
    for (final locale in [
      'en',
      'de',
      'fr',
      'sv',
      'no',
      'da',
      'nl',
      'es',
      'it'
    ]) {
      for (final key in keys) {
        final value = fitnessCopyData[locale]?[key];
        expect(value, isNotNull, reason: '$locale: $key');
        expect(RegExp(r'\{\w+\}').allMatches(value!).map((m) => m[0]).toSet(),
            RegExp(r'\{\w+\}').allMatches(key).map((m) => m[0]).toSet());
      }
    }
  });
}
