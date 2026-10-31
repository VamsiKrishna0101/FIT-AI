import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setcraft/core/cache/cache_scope.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/planner/views/widgets/weekly_plan_schedule.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/views/workout_session_view.dart';
import 'training_session_test.dart' as session;
import 'plan_reveal_flow_test.dart' show SessionAdapter;

final today = DateUtils.dateOnly(DateTime.now());
String date(int offset) =>
    CacheScope.todayKey(today.add(Duration(days: offset)));
Map<String, dynamic> plan() => {
      'workouts': [
        for (var offset = -2; offset <= 4; offset++)
          {
            'date': date(offset),
            'name': offset == -2
                ? 'Chest + Triceps'
                : offset == -1
                    ? 'Back + Biceps'
                    : offset == 1
                        ? 'Upper body'
                        : offset == 2
                            ? 'Legs + Glutes'
                            : 'Rest day',
            'restDay': offset == 0 || offset > 2,
            'estimatedMinutes': offset == 0 || offset > 2 ? 0 : 45,
            'exercises': offset == 0 || offset > 2
                ? []
                : [
                    {
                      'name': 'Hidden exercise',
                      'sets': 3,
                      'repsMin': 10,
                      'repsMax': 10,
                      'restSeconds': 90
                    }
                  ],
          }
      ]
    };
TrainingDay live(String value) {
  final offset = DateTime.parse(value).difference(today).inDays;
  final raw = session.fixture(value);
  raw['name'] = offset == 1
      ? 'Back + Biceps'
      : offset == 2
          ? 'Legs + Glutes'
          : offset < 0
              ? 'Completed workout'
              : 'Rest day';
  raw['restDay'] = offset == 0 || offset > 2;
  raw['session'] =
      offset < 0 ? {...raw['session'] as Map, 'status': 'COMPLETED'} : null;
  if (raw['restDay'] == true) raw['items'] = [];
  raw['week'] = [
    for (var n = -2; n <= 4; n++)
      {
        'date': date(n),
        'status': n < 0
            ? 'COMPLETED'
            : n == 0 || n > 2
                ? 'REST_DAY'
                : 'SCHEDULED'
      }
  ];
  return TrainingDay(raw);
}

Widget app(Widget child, {double scale = 1}) => MaterialApp(
    theme: ThemeData.dark(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(scale)),
        child: child!),
    home: RepaintBoundary(
        key: const ValueKey('overview-capture'),
        child: FitnessTheme(
            child: Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20), child: child)))));
void phone(WidgetTester tester, {double width = 393}) {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues(
      {'fitai_access_token': 'opaque', 'fitai_user_id': 'overview-test'}));
  testWidgets(
      'Overview shows the actual next workout, full week and confirmed completion',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(WeeklyPlanSchedule(
        payload: plan(), active: true, loadDay: (value) async => live(value))));
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('next-plan-workout'));
    expect(find.descendant(of: next, matching: find.text('Back + Biceps')),
        findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2 of 4 complete'), findsOneWidget);
    expect(find.text('Hidden exercise'), findsNothing);
    for (var n = -2; n <= 4; n++) {
      expect(find.byKey(ValueKey('plan-day-${date(n)}')), findsOneWidget);
    }
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('overview-capture')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/previews/weekly-plan-overview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
  testWidgets('Future workout opens its own details and cannot start',
      (tester) async {
    phone(tester);
    var starts = 0;
    await tester.pumpWidget(app(WeeklyPlanSchedule(
        payload: plan(),
        active: true,
        loadDay: (value) async => live(value),
        startDay: (value) async {
          starts++;
          return live(value);
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View workout'));
    // A second tap during the route push is deliberately blocked.
    await tester.tap(find.text('View workout'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byType(WeeklyPlanSchedule, skipOffstage: false), findsNWidgets(2));
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(starts, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A normal active plan starts today without the onboarding flag',
      (tester) async {
    phone(tester);
    final raw = session.fixture(date(0))..['session'] = null;
    raw['name'] = 'Chest + Triceps';
    var starts = 0;
    final old = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = SessionAdapter();
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = old);
    await tester.pumpWidget(app(WeeklyPlanSchedule(
        payload: {
          'workouts': [
            {
              'date': date(0),
              'name': 'Chest + Triceps',
              'restDay': false,
              'estimatedMinutes': 40,
              'exercises': const []
            }
          ]
        },
        active: true,
        loadDay: (_) async => TrainingDay(raw),
        startDay: (value) async {
          starts++;
          return TrainingDay(session.fixture(value));
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.byType(WorkoutSessionView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Overview fits narrow large text and opens a different day',
      (tester) async {
    phone(tester, width: 320);
    await tester.pumpWidget(app(
        WeeklyPlanSchedule(
            payload: plan(),
            active: true,
            loadDay: (value) async => live(value)),
        scale: 1.6));
    await tester.pumpAndSettle();
    final row = find.byKey(ValueKey('plan-day-${date(2)}'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Legs + Glutes'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Offline refresh retains the saved week without invented completion',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(WeeklyPlanSchedule(
        payload: plan(),
        active: true,
        loadDay: (_) async => throw Exception('offline'))));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsNothing);
    expect(find.byKey(ValueKey('plan-day-${date(1)}')), findsOneWidget);
    expect(find.text('Could not sync. Tap to retry.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Refreshing the same week refreshes the actual next workout',
      (tester) async {
    phone(tester);
    var title = 'Back + Biceps';
    Widget screen() => app(WeeklyPlanSchedule(
        payload: plan(),
        active: true,
        loadDay: (value) async {
          final day = live(value);
          if (value == date(1)) day.json['name'] = title;
          return day;
        }));
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('next-plan-workout'));
    expect(find.descendant(of: next, matching: find.text('Back + Biceps')),
        findsOneWidget);
    title = 'Rescheduled leg workout';
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(
        find.descendant(of: next, matching: find.text(title)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
