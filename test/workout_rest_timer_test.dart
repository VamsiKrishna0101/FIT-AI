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
import 'package:setcraft/core/cache/cache_scope.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/train/components/workout_rest_timer.dart';
import 'package:setcraft/features/train/components/workout_set_entry.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/repositories/training_repository.dart';
import 'package:setcraft/features/train/views/workout_session_view.dart';
import 'training_session_test.dart' as session;

class _Adapter implements HttpClientAdapter {
  bool reject = false;
  int saved = 0;
  Map<String, dynamic> day() {
    final data = session.fixture(CacheScope.todayKey(), sets: saved);
    (data['items'] as List).first['restSeconds'] = 135;
    return data;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions request, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    final status = request.path == '/api/home'
        ? 503
        : reject && request.method == 'PUT'
            ? 400
            : 200;
    if (request.method == 'PUT' && status == 200) saved = 1;
    final Object data = status != 200
        ? {'error': 'Not saved yet. Tap save to retry.'}
        : {
            'data': request.path.contains('/previous/') ? {'sets': []} : day()
          };
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _deliver(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

const _capture = ValueKey('rest-preview');
Widget _app(TrainingDay day, {double scale = 1, DateTime Function()? clock}) =>
    RepaintBoundary(
        key: _capture,
        child: MaterialApp(
            theme: ThemeData.dark().copyWith(
                textTheme:
                    ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: WorkoutSessionView(initial: day, clock: clock)));

Future<void> _preview(WidgetTester tester, String name) async {
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

void main() {
  var account = 0;
  late _Adapter adapter;
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
    await SecureSessionStore.shared.saveTokens(
        accessToken: session.token('rest-test-${account++}'),
        refreshToken: 'test');
    adapter = _Adapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  test('Elapsed time, pause/restore and extension use the actual deadline', () {
    final now = DateTime(2026, 10, 16, 10);
    final rest = WorkoutRest(
        end: now.add(const Duration(seconds: 135)),
        duration: 135,
        exercise: 'Squat',
        setNumber: 2);
    expect(rest.remaining(now.add(const Duration(milliseconds: 250))), 135);
    expect(rest.remaining(now.add(const Duration(seconds: 40))), 95);
    final paused = rest.togglePause(now.add(const Duration(seconds: 40)));
    final later = now.add(const Duration(hours: 3));
    final restored = WorkoutRest.fromJson(paused.toJson(), later)!;
    expect(restored.remaining(later), 95);
    expect(restored.isPaused, isTrue);
    expect(restored.extend(later).remaining(later), 125);
    expect(restored.extend(later).isPaused, isTrue);
    final resumed = restored.togglePause(later);
    expect(resumed.isPaused, isFalse);
    expect(resumed.remaining(later.add(const Duration(seconds: 20))), 75);
    expect(resumed.extend(later).end.difference(resumed.end),
        const Duration(seconds: 30));
    expect(WorkoutRest.fromJson(rest.toJson(), later), isNull);
  });

  testWidgets(
      'Saving a new set starts compact rest; expanding, pausing and skipping persist',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(TrainingDay(adapter.day())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.tap(find.byKey(const ValueKey('workout-primary-action')));
    await _deliver(tester);
    expect(adapter.saved, 1);
    expect(find.byKey(const ValueKey('rest-countdown')), findsNothing);
    expect(find.byKey(const ValueKey('minimized-rest-timer')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expand-rest-timer')));
    await _deliver(tester);
    expect(find.byKey(const ValueKey('rest-countdown')), findsOneWidget);
    final timer = tester
        .widgetList<WorkoutRestTimer>(find.byType(WorkoutRestTimer))
        .firstWhere((timer) => !timer.compact);
    expect(timer.rest.duration, 135);
    expect(timer.rest.setNumber, 1);
    await _preview(tester, 'rest-timer');
    await tester.tap(find.byKey(const ValueKey('rest-pause')));
    await _deliver(tester);
    expect(find.text('Resume timer'), findsOneWidget);
    final paused =
        await TrainingRepository.shared.restData(CacheScope.todayKey());
    expect(paused!['pausedSeconds'], greaterThan(0));
    await tester.tap(find.byTooltip('Minimize timer'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('minimized-rest-timer')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(TrainingDay(adapter.day())));
    await _deliver(tester);
    final bar = find.byKey(const ValueKey('minimized-rest-timer'));
    expect(bar, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expand-rest-timer')));
    await _deliver(tester);
    expect(find.text('Resume timer'), findsOneWidget);
    await tester.tap(find.text('Resume timer'));
    await _deliver(tester);
    expect(find.text('Pause timer'), findsOneWidget);
    final before =
        await TrainingRepository.shared.restData(CacheScope.todayKey());
    await tester.tap(find.text('30 s'));
    await _deliver(tester);
    final after =
        await TrainingRepository.shared.restData(CacheScope.todayKey());
    expect((after!['end'] as int) - (before!['end'] as int), 30000);
    final skip = tester
        .widgetList<WorkoutRestTimer>(find.byType(WorkoutRestTimer))
        .firstWhere((timer) => !timer.compact)
        .onSkip;
    skip();
    skip();
    await tester.pump();
    expect(find.byKey(const ValueKey('rest-countdown')), findsOneWidget,
        reason: 'Keep the sheet content during its exit transition');
    await _deliver(tester);
    expect(find.byType(WorkoutSessionView), findsOneWidget);
    expect(find.byKey(const ValueKey('rest-countdown')), findsNothing);
    expect(await TrainingRepository.shared.restData(CacheScope.todayKey()),
        isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Rejected set saves and corrections do not start rest',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(TrainingDay(adapter.day())));
    await tester.pumpAndSettle();
    final entry =
        tester.state<WorkoutSetEntryState>(find.byType(WorkoutSetEntry).first);
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '10');
    adapter.reject = true;
    await tester.runAsync(() async {
      await expectLater(entry.savePending(confirmSuggestion: true),
          throwsA(isA<DioException>()));
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('rest-countdown')), findsNothing);
    expect(await TrainingRepository.shared.restData(CacheScope.todayKey()),
        isNull);
    await tester.pumpWidget(const SizedBox());
    adapter.reject = false;
    adapter.saved = 1;
    await tester.pumpWidget(_app(TrainingDay(adapter.day())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(WorkoutSetEntry).first);
    await tester.tap(find.byType(WorkoutSetEntry).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '22');
    final correction =
        tester.state<WorkoutSetEntryState>(find.byType(WorkoutSetEntry).first);
    await tester
        .runAsync(() => correction.savePending(confirmSuggestion: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('minimized-rest-timer')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('A finished rest updates on resume and vibrates once',
      (tester) async {
    var vibrations = 0;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate' &&
          call.arguments == 'HapticFeedbackType.lightImpact') {
        vibrations++;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    var now = DateTime.now();
    final start = now;
    await tester.runAsync(() => TrainingRepository.shared.saveRest(
        CacheScope.todayKey(),
        WorkoutRest(end: start.add(const Duration(seconds: 60)), duration: 60)
            .toJson()));
    await tester.pumpWidget(_app(TrainingDay(adapter.day()), clock: () => now));
    await _deliver(tester);
    expect(find.byKey(const ValueKey('minimized-rest-timer')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    now = start.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Ready for your next set'), findsOneWidget);
    expect(vibrations, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(vibrations, 1);
    expect(adapter.saved, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Small screens and large text keep timer controls scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rest = WorkoutRest(
        end: DateTime.now().add(const Duration(seconds: 90)),
        duration: 90,
        exercise: 'Dumbbell shoulder press',
        setNumber: 3);
    await tester.runAsync(() => TrainingRepository.shared
        .saveRest(CacheScope.todayKey(), rest.toJson()));
    await tester.pumpWidget(_app(TrainingDay(adapter.day()), scale: 1.7));
    await _deliver(tester);
    await tester.tap(find.byKey(const ValueKey('expand-rest-timer')));
    await _deliver(tester);
    expect(find.byKey(const ValueKey('rest-countdown')), findsOneWidget);
    await tester.ensureVisible(find.text('Skip rest').last);
    await tester.pump(const Duration(milliseconds: 200));
    await _preview(tester, 'rest-timer-large-text');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Skip rest').last);
    await _deliver(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
