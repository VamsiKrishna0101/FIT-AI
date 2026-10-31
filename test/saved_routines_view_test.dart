import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/train/views/saved_routines_view.dart';
import 'package:setcraft/features/train/views/train_view.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'training_session_test.dart' as training;

class RoutineAdapter extends training.Adapter {
  final targets = {
    'weightBasis': 'estimated_start',
    'weightUnit': 'per_hand',
    'sets': [
      {
        'setNumber': 1,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 2,
        'targetRpe': 6
      },
      {
        'setNumber': 2,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 3,
        'targetRpe': 6
      },
      {
        'setNumber': 3,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 3,
        'targetRpe': 6
      },
    ],
  };
  final writes = <Map>[];
  bool bodyweight = false, missingLoad = false, failSave = false;
  Completer<void>? holdSave;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    final uri = Uri.parse(options.path);
    if (!uri.path.contains('/training') || uri.path.contains('/previous')) {
      return super.fetch(options, stream, cancel);
    }
    final date = uri.queryParameters['date'] ?? '2026-10-13';
    final day = training.fixture(date)..['session'] = null;
    day['routines'] = List.generate(
        5,
        (index) => {
              'id': 'routine-$index',
              'name': 'Saved workout $index',
              'count': 1
            });
    dynamic data = day;
    if (options.method == 'GET' && uri.path.contains('/routines/')) {
      final storedTargets = jsonDecode(jsonEncode(targets)) as Map;
      if (missingLoad || bodyweight) {
        for (final set in storedTargets['sets']) {
          set['weightKg'] = bodyweight ? 0 : null;
        }
      }
      if (bodyweight) {
        storedTargets['weightBasis'] = 'bodyweight';
        storedTargets['weightUnit'] = 'bodyweight';
      }
      final item = jsonDecode(jsonEncode((day['items'] as List).first)) as Map;
      if (bodyweight) {
        item['workout']['equipment'] = 'body weight';
        item['workout']['exerciseType'] = 'bodyweight_reps';
        item['workout']['name'] = 'Push-up';
      }
      data = {
        'id': 'routine-0',
        'name': 'Saved workout 0',
        'items': [
          {...item, 'setTargets': storedTargets},
        ]
      };
    } else if (options.method != 'GET') {
      writes.add(
          {'path': uri.path, 'method': options.method, 'data': options.data});
      if (options.method == 'PUT') {
        if (holdSave != null) await holdSave!.future;
        if (failSave) {
          return ResponseBody.fromString(
              '{"error":"Could not save routine."}', 400,
              headers: {
                Headers.contentTypeHeader: ['application/json']
              });
        }
      }
    }
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }
}

void main() {
  late RoutineAdapter adapter;
  var owner = 0;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: training.token('routine-ui-test-${owner++}'),
        refreshToken: 'test');
    adapter = RoutineAdapter();
    final client = ApiClient.shared.client;
    final original = client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
  });
  testWidgets(
      'My workouts opens the collection and preserves targets when renamed',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(training.app(const TrainView(initialDate: '2026-10-13')));
    await tester.pumpAndSettle();
    expect(find.text('Saved workout 0'), findsNothing);
    await tester.scrollUntilVisible(find.text('My workouts'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('My workouts'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedRoutinesView), findsOneWidget);
    expect(find.text('Saved workout 4'), findsOneWidget);
    await tester.tap(find.text('Saved workout 0'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailView), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    for (var set = 1; set <= 3; set++) {
      expect(find.byKey(ValueKey('routine-set-item-$set')), findsOneWidget);
    }
    expect(find.textContaining('Rest: 60 sec'), findsOneWidget);
    expect(find.text('Target (kg)'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Renamed routine');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(adapter.writes.length, 1);
    final data = adapter.writes.single['data'] as Map;
    expect(data['name'], 'Renamed routine');
    expect((data['items'] as List).first['setTargets'], adapter.targets);
    await tester.tap(find.text('Use workout'));
    await tester.pumpAndSettle();
    expect(find.text('Replace this workout?'), findsOneWidget);
    expect(adapter.writes.length, 1,
        reason: 'Preview and confirmation must precede replacing a workout');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.writes.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  TrainingDay day() =>
      TrainingDay(training.fixture('2026-10-13')..['session'] = null);
  Widget detail({String locale = 'en', double scale = 1}) => training.app(
      Builder(
          builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RoutineDetailView(day: day(), routine: const {
                'id': 'routine-0',
                'name': 'Saved workout 0',
                'count': 1
              }))),
      locale: locale);
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Editing set targets preserves individual reps, load and effort',
      (tester) async {
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit targets'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('target-reps-1')), '12');
    await tester.enterText(find.byKey(const ValueKey('target-weight-1')), '4');
    await tester.scrollUntilVisible(find.text('Save'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    final sets = adapter.writes.single['data']['items'].first['setTargets']
        ['sets'] as List;
    expect(sets[0], (adapter.targets['sets'] as List)[0]);
    expect(sets[1]['weightKg'], 4);
    expect(sets[1]['repsMin'], 12);
    expect(sets[1]['repsMax'], 12);
    expect(sets[1]['targetRpe'], 6);
    expect(sets[2]['weightKg'], 3);
    expect(find.byType(TextField), findsNothing);
    await close(tester);
  });

  testWidgets(
      'Missing loads use dashes and one instruction; bodyweight uses reps',
      (tester) async {
    adapter.missingLoad = true;
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('Choose your working weight when you start.'),
        findsOneWidget);
    expect(find.textContaining('Choose a comfortable load'), findsNothing);
    expect(adapter.writes, isEmpty);
    await close(tester);
  });

  testWidgets('Bodyweight routines do not repeat bodyweight or show zero kg',
      (tester) async {
    adapter.bodyweight = true;
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    expect(find.text('Target (kg)'), findsNothing);
    expect(find.textContaining('Bodyweight'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(
        find.text('Choose your working weight when you start.'), findsNothing);
    for (var set = 1; set <= 3; set++) {
      expect(find.byKey(ValueKey('routine-set-item-$set')), findsOneWidget);
    }
    await close(tester);
  });

  testWidgets('Cancel restores the saved routine without writing',
      (tester) async {
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('routine-name')), 'Draft');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Saved workout 0'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(adapter.writes, isEmpty);
    await close(tester);
  });

  testWidgets('Back asks before discarding unsaved edits', (tester) async {
    await tester.pumpWidget(training.app(Builder(
        builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => RoutineDetailView(
                                day: day(),
                                routine: const {
                                  'id': 'routine-0',
                                  'name': 'Saved workout 0',
                                  'count': 1
                                }))),
                child: const Text('Open routine'))))));
    await tester.tap(find.text('Open routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('routine-name')), 'Draft');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailView), findsNothing);
    expect(adapter.writes, isEmpty);
    await close(tester);
  });

  testWidgets('Save blocks duplicate taps and keeps a failed draft editable',
      (tester) async {
    adapter.holdSave = Completer<void>();
    adapter.failSave = true;
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('routine-name')), 'Draft');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('routine-primary-action')))
            .onPressed,
        isNull);
    expect(find.text('Saving'), findsOneWidget);
    adapter.holdSave!.complete();
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Could not save routine.'), findsOneWidget);
    expect(find.text('Changes saved'), findsNothing);
    await close(tester);
  });

  for (final locale in ['en', 'de']) {
    testWidgets('All sets fit a narrow screen with large $locale text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(detail(locale: locale, scale: 1.8));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('routine-set-item-3')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }

  testWidgets('Managing My workouts requires confirmation before deleting',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(training.app(const TrainView(initialDate: '2026-10-13')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('My workouts'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('My workouts'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete workout'), findsNothing);
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete workout').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete workout?'), findsOneWidget);
    expect(adapter.writes, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.writes, isEmpty);
    await close(tester);
  });
}
