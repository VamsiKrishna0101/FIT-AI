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
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/repositories/workout_offline_store.dart';
import 'package:setcraft/features/train/views/workout_session_view.dart';
import 'package:setcraft/features/train/components/workout_form_guide.dart';
import 'training_session_test.dart' as fixture;

Map<String, dynamic> sample(
    {bool finished = false, bool bodyweight = false, bool two = false}) {
  final data = Map<String, dynamic>.from(jsonDecode(jsonEncode(fixture.fixture(
      '2026-10-27',
      finished: finished,
      sets: finished ? 3 : 0))) as Map);
  data['name'] = 'Chest & triceps';
  data['session']['startedAt'] = '2026-10-27T07:00:00Z';
  final item = (data['items'] as List).first as Map;
  item['workout']['name'] = bodyweight ? 'Push-up' : 'Dumbbell bench press';
  item['workout']['bodyPart'] = 'Chest';
  item['workout']['instructions'] = [
    'Set up with control.',
    'Keep the movement steady.',
    'Return to the starting position.'
  ];
  item['workout']['equipment'] = bodyweight ? 'body weight' : 'dumbbell';
  item['workout']['exerciseType'] =
      bodyweight ? 'bodyweight_reps' : 'weight_reps';
  item['setTargets'] = {
    'weightBasis': bodyweight ? 'bodyweight' : 'as_logged',
    'weightUnit': bodyweight ? 'bodyweight' : 'per_hand',
    'sets': List.generate(
        3,
        (i) => {
              'setNumber': i + 1,
              'repsMin': 10,
              'repsMax': 10,
              'weightKg': bodyweight ? null : 20
            })
  };
  if (bodyweight) {
    for (final log in item['setLogs']) {
      log['weight'] = null;
    }
  }
  if (two) {
    final second =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(item)) as Map);
    second['id'] = 'item-2';
    second['workout']['id'] = 'exercise-2';
    second['workout']['name'] = 'Cable triceps pushdown';
    second['workout']['equipment'] = 'cable';
    second['setLogs'] = [];
    (data['items'] as List).add(second);
  }
  data['summary']['volume'] =
      0; // A stale aggregate must not hide actual saved load.
  return data;
}

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic> day = sample(two: true);
  final writes = <RequestOptions>[];
  bool rejectSave = false, rejectDelete = false;
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    dynamic data = day;
    if (o.path.contains('/previous/')) {
      data = {'sets': []};
    } else if (o.path.contains('/api/home')) {
      return ResponseBody.fromString('{}', 503, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    } else if (o.method != 'GET') {
      writes.add(o);
      if ((rejectSave && o.method == 'PUT') ||
          (rejectDelete && o.method == 'DELETE')) {
        return ResponseBody.fromString(
            '{"error":"Not saved yet. Tap save to retry."}', 503,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
      final item = (day['items'] as List)
          .cast<Map>()
          .where((item) => o.path.contains('/items/${item['id']}/'))
          .firstOrNull;
      void upsert(Map set) {
        (item!['setLogs'] as List)
            .removeWhere((log) => log['setNumber'] == set['setNumber']);
        (item['setLogs'] as List).add(Map<String, dynamic>.from(set));
      }

      if (o.path.contains('/complete')) {
        for (final set in o.data['sets']) {
          upsert(set as Map);
        }
        item!['status'] = 'COMPLETED';
      } else if (o.method == 'PUT') {
        upsert(o.data as Map);
      } else if (o.method == 'DELETE' && o.path.contains('/sets/')) {
        final number = int.parse(o.path.split('/sets/').last.split('?').first);
        (item!['setLogs'] as List)
            .removeWhere((log) => log['setNumber'] == number);
      } else if (o.path.contains('/finish')) {
        day['session']['status'] = 'COMPLETED';
        day['session']['durationSeconds'] = 620;
      } else if (o.path.contains('/status')) {
        item!['status'] = o.data['status'];
      }
      final logs = (day['items'] as List)
          .expand((item) => item['setLogs'] as List)
          .toList();
      day['summary'] = {'sets': logs.length, 'volume': 0, 'skipped': 0};
    }
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

const _capture = ValueKey('session-design-capture');
Widget screen(Map<String, dynamic> day,
        {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child!),
        home: RepaintBoundary(
            key: _capture,
            child: WorkoutSessionView(
                initial: TrainingDay(day),
                clock: () => DateTime.parse('2026-10-27T07:12:20Z'))));

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_capture));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/previews').createSync(recursive: true);
    File('build/previews/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pumpAndSettle();
}

void main() {
  late _Adapter adapter;
  var owner = 0;
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: fixture.token('session-design-${owner++}'),
        refreshToken: 'test');
    adapter = _Adapter();
    final previous = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = previous);
  });
  testWidgets('Log each set explicitly before advancing to the next movement',
      (tester) async {
    await tester.pumpWidget(screen(adapter.day));
    await settle(tester);
    final scroll = find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .last;
    for (var number = 1; number <= 3; number++) {
      await tester.scrollUntilVisible(
          find.byKey(ValueKey('set-weight-$number')), 200,
          scrollable: scroll);
      await settle(tester);
      await tester.enterText(find.byKey(ValueKey('set-weight-$number')), '20');
      expect(find.text('Log set $number'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
      await settle(tester);
      expect(
          adapter.writes.where((request) => request.path.contains('/complete')),
          isEmpty);
    }
    expect(adapter.writes.where((request) => request.method == 'PUT'),
        hasLength(3));
    expect(find.byKey(const ValueKey('minimized-rest-timer')), findsNothing,
        reason: 'The final set clears the timer from the preceding set');
    expect(find.text('Next exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await settle(tester);
    expect(find.text('Cable triceps pushdown'), findsOneWidget);
    expect(find.text('Exercise 2 of 2'), findsOneWidget);
    expect(find.text('Log set 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Required load cannot be omitted when confirming suggested reps',
      (tester) async {
    await tester.pumpWidget(screen(sample()));
    await settle(tester);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('set-reps-1')), 200,
        scrollable: find
            .byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down)
            .last);
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await settle(tester);
    expect(adapter.writes, isEmpty);
    expect(find.text('Enter the weight you lifted before saving this set.'),
        findsWidgets);
    expect(find.byTooltip('Saved'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Set selection keeps equal input boxes without opening the keyboard',
      (tester) async {
    // Keep the guide in the viewport when checking that row selection does not
    // rebuild it. Phone-sized scrolling is covered by the layout tests below.
    tester.view.physicalSize = const Size(393, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen(sample()));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('set-select-2')));
    await settle(tester);
    final guide =
        tester.widget<WorkoutFormGuide>(find.byType(WorkoutFormGuide));
    final firstSize =
        tester.getSize(find.byKey(const ValueKey('set-weight-1')));
    final secondSize =
        tester.getSize(find.byKey(const ValueKey('set-weight-2')));
    expect(firstSize, secondSize);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byKey(const ValueKey('set-select-2')));
    await settle(tester);
    expect(find.text('Log set 2'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
        identical(
            tester.widget<WorkoutFormGuide>(find.byType(WorkoutFormGuide)),
            guide),
        isTrue);
    await tester.tap(find.byKey(const ValueKey('set-weight-2')));
    await settle(tester);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
        tester.getSize(find.byKey(const ValueKey('set-weight-2'))), secondSize);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'An unsaved extra row is removed locally and its draft stays deleted',
      (tester) async {
    await tester.pumpWidget(screen(sample()));
    await settle(tester);
    await tester.ensureVisible(find.text('Add set'));
    await settle(tester);
    await tester.tap(find.text('Add set'));
    await settle(tester);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.enterText(find.byKey(const ValueKey('set-weight-4')), '25');
    await tester.enterText(find.byKey(const ValueKey('set-reps-4')), '9');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    expect(find.byKey(const ValueKey('set-weight-4')), findsNothing);
    expect(adapter.writes, isEmpty);
    await tester.ensureVisible(find.text('Add set'));
    await settle(tester);
    await tester.tap(find.text('Add set'));
    await settle(tester);
    for (final id in ['set-weight-4', 'set-reps-4']) {
      expect(
          tester.widget<TextField>(find.byKey(ValueKey(id))).controller!.text,
          isEmpty);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Deleting a saved extra row preserves higher numbered saved sets',
      (tester) async {
    adapter.day = sample();
    (adapter.day['items'] as List).first['setLogs'] = [
      {'setNumber': 4, 'reps': 8, 'weight': 25},
      {'setNumber': 5, 'reps': 7, 'weight': 30},
    ];
    await tester.pumpWidget(screen(adapter.day));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    expect(find.byKey(const ValueKey('set-weight-4')), findsNothing);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('set-weight-5')))
            .controller!
            .text,
        '30');
    expect(adapter.writes.single.method, 'DELETE');
    expect(adapter.writes.single.path, contains('/sets/4'));
    expect((adapter.day['items'] as List).first['setLogs'], [
      {'setNumber': 5, 'reps': 7, 'weight': 30},
    ]);
    // Let the repository's coalesced dashboard refresh complete.
    await tester.pump(const Duration(milliseconds: 800));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('A failed extra-set deletion preserves the row and edited values',
      (tester) async {
    adapter.day = sample();
    adapter.rejectDelete = true;
    (adapter.day['items'] as List).first['setLogs'] = [
      {'setNumber': 4, 'reps': 8, 'weight': 25},
    ];
    await tester.pumpWidget(screen(adapter.day));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('set-weight-4')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('set-weight-4')), '26');
    await tester.ensureVisible(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('set-delete-4')));
    await settle(tester);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('set-weight-4')))
            .controller!
            .text,
        '26');
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Bodyweight uses reps-only entry and finishes without a load',
      (tester) async {
    adapter.day = sample(bodyweight: true);
    await tester.pumpWidget(screen(adapter.day));
    await settle(tester);
    expect(find.byKey(const ValueKey('set-weight-1')), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('set-reps-1')), 200,
        scrollable: find
            .byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down)
            .last);
    await tester.enterText(find.byKey(const ValueKey('set-reps-1')), '12');
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await settle(tester);
    expect(adapter.writes.single.data['weight'], isNull);
    for (var number = 2; number <= 3; number++) {
      final field = find.byKey(ValueKey('set-reps-$number'));
      await tester.scrollUntilVisible(field, 200,
          scrollable: find
              .byWidgetPredicate((widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down)
              .last);
      await tester.enterText(field, '12');
      await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
      await settle(tester);
    }
    expect(find.text('Finish workout'), findsOneWidget);
    await tester.tap(find.text('Finish workout'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 500));

    await settle(tester);
    expect(find.text('Bodyweight session'), findsOneWidget);
    expect(find.text('0 kg'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Form instructions expand in place and demo can be minimized',
      (tester) async {
    await tester.pumpWidget(screen(sample()));
    await settle(tester);
    final scroll = find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .last;
    await tester.scrollUntilVisible(find.text('Show all'), 160,
        scrollable: scroll);
    await settle(tester);
    expect(find.text('Set up with control.'), findsOneWidget);
    expect(find.text('Return to the starting position.'), findsNothing);
    await tester.scrollUntilVisible(find.text('Show all'), 160,
        scrollable: scroll);
    await settle(tester);
    await tester.tap(find.text('Show all'));
    await settle(tester);
    expect(find.text('Return to the starting position.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hide demo'), -200,
        scrollable: scroll);
    await settle(tester);
    await tester.tap(find.text('Hide demo'));
    await settle(tester);
    expect(find.byKey(const ValueKey('demo-item')), findsNothing);
    await tester.tap(find.text('Show demo'));
    await settle(tester);
    expect(tester.getSize(find.byKey(const ValueKey('demo-item'))).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio - 36);
    expect(find.byType(WorkoutFormGuide), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Ratings are optional details and persist only after the set is logged',
      (tester) async {
    await tester.pumpWidget(screen(sample()));
    await settle(tester);
    final scroll = find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .last;
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('set-weight-1')), 200,
        scrollable: scroll);
    await tester.enterText(find.byKey(const ValueKey('set-weight-1')), '20');
    expect(find.byType(DropdownButtonFormField<double>), findsNothing);
    expect(find.byTooltip('Set options'), findsNothing);
    await tester.ensureVisible(find.text('Set details'));
    await tester.tap(find.text('Set details'));
    await settle(tester);
    expect(find.text('Not rated'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<double>));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('7.5 / 10'), 160,
        scrollable: find.byType(Scrollable).last);
    await settle(tester);
    await tester.tap(find.text('7.5 / 10').last);
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(adapter.writes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await settle(tester);
    expect(adapter.writes.single.data['rpe'], 7.5);
    expect(find.byType(DropdownButtonFormField<double>), findsNothing);
    expect(find.text('Log set 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Failed logging retains the entry and the primary action clears the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    adapter.day = sample();
    adapter.rejectSave = true;
    await tester.pumpWidget(screen(adapter.day));
    await settle(tester);
    final scroll = find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .last;
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('set-weight-1')), 200,
        scrollable: scroll);
    await tester.enterText(find.byKey(const ValueKey('set-weight-1')), '20');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await settle(tester);
    final button = find.byKey(const ValueKey('workout-primary-action'));
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(852 - 280));
    await tester.tap(button);
    await settle(tester);
    expect(find.text('Not saved yet. Tap save to retry.'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('set-weight-1')))
            .controller!
            .text,
        '20');
    adapter.rejectSave = false;
    tester.view.viewInsets = FakeViewPadding.zero;
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
    expect(adapter.writes.where((request) => request.method == 'PUT'),
        hasLength(2));
    expect(find.text('Log set 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('Offline rules and recorded volume match online logging', () {
    final store = WorkoutOfflineStore();
    final day = sample();
    final action = {
      'method': 'PUT',
      'suffix': '/items/item/sets',
      'data': {'setNumber': 1, 'reps': 10, 'weight': null}
    };
    expect(() => store.project(day, [action]), throwsFormatException);
    action['data'] = {'setNumber': 1, 'reps': 10, 'weight': 20};
    expect(store.project(day, [action]).volume, 200);
    action['data'] = {'setNumber': 1, 'reps': 10, 'weight': null};
    expect(store.project(sample(bodyweight: true), [action]).loggedReps, 10);
  });
  testWidgets(
      'Summary expands actual sets, preserves missing loads, and separates skipped exercises',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final day = sample(finished: true, two: true);
    final items = day['items'] as List;
    items.first['setLogs'] = [
      {'setNumber': 3, 'reps': 6, 'weight': null},
      {'setNumber': 1, 'reps': 10, 'weight': 20},
      {'setNumber': 2, 'reps': 8, 'weight': 22.5},
    ];
    items.last['status'] = 'SKIPPED';
    await tester.pumpWidget(screen(day));
    await settle(tester);
    expect(find.text('380 kg'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(
        find.text(
            'Some sets have no recorded load. Edit your sets to complete the volume.'),
        findsOneWidget);
    final first = find.byType(ExpansionTile).first;
    await tester.ensureVisible(first);
    await tester.pumpAndSettle();
    await tester.tap(first);
    await settle(tester);
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('22.5 kg'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(tester.getTopLeft(find.text('10')).dy,
        lessThan(tester.getTopLeft(find.text('8')).dy));
    expect(tester.getTopLeft(find.text('8')).dy,
        lessThan(tester.getTopLeft(find.text('6')).dy));
    await capture(tester, 'workout-summary-set-details');
    final skipped = find.byType(ExpansionTile).last;
    await tester.ensureVisible(skipped);
    await tester.pumpAndSettle();
    await tester.tap(skipped);
    await settle(tester);
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('No sets logged'), findsOneWidget);
    expect(adapter.writes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final summary in [false, true]) {
    for (final large in [false, true]) {
      testWidgets(
          'Session ${summary ? 'summary' : 'logger'} fits ${large ? 'large German' : 'phone'} layout',
          (tester) async {
        tester.view.physicalSize =
            large ? const Size(320, 720) : const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final day = sample(finished: summary);
        if (!summary) {
          final items = day['items'] as List;
          final completed = (sample(finished: true)['items'] as List).first;
          for (var index = 1; index < 6; index++) {
            final item = Map<String, dynamic>.from(
                jsonDecode(jsonEncode(index >= 4 ? completed : items.first))
                    as Map);
            item['id'] = 'item-$index';
            item['workout']['id'] = 'exercise-$index';
            items.add(item);
          }
        }
        await tester.pumpWidget(
            screen(day, scale: large ? 1.8 : 1, locale: large ? 'de' : 'en'));
        await settle(tester);
        if (summary && !large) {
          expect(find.text('600 kg'), findsOneWidget);
        }
        if (!summary) {
          expect(tester.getSize(find.byKey(const ValueKey('demo-item'))).width,
              tester.view.physicalSize.width - 36,
              reason:
                  'The demo aligns with the cards and keeps the complete movement visible');
        }
        expect(tester.takeException(), isNull);
        await capture(tester,
            'workout-${summary ? 'summary' : 'logger'}-${large ? 'large-de' : 'premium'}');
        if (!summary && !large) {
          await tester.scrollUntilVisible(
              find.byKey(const ValueKey('set-reps-1')), 160,
              scrollable: find
                  .byWidgetPredicate((widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down)
                  .last);
          await settle(tester);
          await capture(tester, 'workout-set-table-premium');
        }
        if (large) {
          final target = summary
              ? find.byType(ExpansionTile)
              : find.byKey(const ValueKey('set-reps-1'));
          await tester.scrollUntilVisible(target, 160,
              scrollable: find
                  .byWidgetPredicate((widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down)
                  .last);
          await settle(tester);
          expect(tester.takeException(), isNull);
          await capture(tester,
              'workout-${summary ? 'summary' : 'logger'}-large-de-details');
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
