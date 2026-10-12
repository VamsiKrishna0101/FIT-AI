import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/planner/repositories/weekly_plan_repository.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_history_view.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_view.dart';

Map<String, dynamic> _savedWeek(String id, String week, String status,
        {bool test = false, bool food = true, int trainingDays = 5}) =>
    {
      'id': id,
      'weekStart': week,
      'version': 1,
      'status': status,
      'synthetic': test,
      'trainingDays': trainingDays,
      'foodPlanIncluded': food,
      'payload': {
        'synthetic': test,
        'warnings': [],
        'workouts': List.generate(
            7,
            (day) => {
                  'date': DateTime.parse(week)
                      .add(Duration(days: day))
                      .toIso8601String()
                      .split('T')
                      .first,
                  'name': '$id session',
                  'restDay': day >= trainingDays,
                  'estimatedMinutes': day < trainingDays ? 40 : 0,
                  'exercises': day < trainingDays
                      ? [
                          {
                            'name': '$id press',
                            'sets': 2,
                            'repsMin': 8,
                            'repsMax': 12,
                            'weightKg': 10,
                            'weightBasis': 'as_logged',
                            'targetRpe': 7,
                            'restSeconds': 90,
                            'reason': 'A familiar movement.',
                          }
                        ]
                      : [],
                }),
        'nutrition': food
            ? {
                'status': 'RECOMMENDED',
                'reason': 'Simple meals.',
                'days': [
                  {
                    'date': week,
                    'totals': {'calories': 2000, 'protein': 120},
                    'meals': []
                  }
                ],
              }
            : {'status': 'NEEDS_INPUT', 'reason': 'Review food preferences.'},
      },
    };

class _HistoryRepository extends WeeklyPlanRepository {
  final recent = _savedWeek('current', '2026-10-12', 'ACTIVE');
  final previous = _savedWeek('previous', '2026-10-05', 'DRAFT',
      food: false, trainingDays: 3);
  final older = _savedWeek('older', '2025-09-29', 'DRAFT', test: true);
  bool empty = false;
  bool fail = false;
  bool failDetail = false;
  int generations = 0;
  int activations = 0;
  int detailCalls = 0;
  final List<String?> cursors = [];

  @override
  Future<Map<String, dynamic>> history({String? cursor}) async {
    cursors.add(cursor);
    if (fail) throw Exception('offline');
    return {
      'items': empty
          ? []
          : cursor == null
              ? [recent, previous]
              : [older],
      'nextCursor': empty || cursor != null ? null : 'previous'
    };
  }

  @override
  Future<Map<String, dynamic>> savedPlan(String id) async {
    detailCalls++;
    if (failDetail) throw Exception('offline');
    return [recent, previous, older].firstWhere((plan) => plan['id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> plans() async => [recent, previous];

  @override
  Future<Map<String, dynamic>> availability() async => {
        'canGenerate': false,
        'cooldownActive': true,
        'lastPlanId': 'current',
        'nextGenerationAt': DateTime.now()
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'pendingRun': null,
      };

  @override
  Future<Map<String, dynamic>> generate({required DateTime weekStart}) async {
    generations++;
    throw StateError('History must not generate a plan.');
  }

  @override
  Future<void> activate(String id) async {
    activations++;
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(rootBundle
          .load('packages/cupertino_icons/assets/CupertinoIcons.ttf'));
    await cupertino.load();
  });

  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'opaque',
        'fitai_user_id': 'history-test',
      }));

  testWidgets(
      'History shows database summaries and loads older weeks on demand',
      (tester) async {
    final repository = _HistoryRepository();
    await tester.pumpWidget(
        MaterialApp(home: WeeklyPlanHistoryView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('5 training days'), findsOneWidget);
    expect(find.text('Food plan included'), findsOneWidget);
    expect(find.text('Food plan not included'), findsOneWidget);
    expect(repository.detailCalls, 0);
    await tester.scrollUntilVisible(find.text('See older weeks'), 200);
    await tester.ensureVisible(find.text('See older weeks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See older weeks'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Test'), 200);
    expect(find.text('Test'), findsOneWidget);
    expect(repository.cursors, [null, 'previous']);
    expect(find.text('See older weeks'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Opening an older week reviews its plan and preserves the generation limit',
      (tester) async {
    final repository = _HistoryRepository();
    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Plan history'));
    await tester.tap(find.text('Plan history'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('See older weeks'), 200);
    await tester.ensureVisible(find.text('See older weeks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See older weeks'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Test'), 200);
    await tester.ensureVisible(find.text('Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyPlanHistoryView), findsNothing);
    expect(find.text('older press'), findsOneWidget);
    expect(find.text('Generate weekly plan'), findsNothing);
    expect(find.text('Use this weekly plan'), findsNothing);
    expect(repository.generations, 0);
    expect(repository.activations, 0);
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refresh;
    expect(find.text('older press'), findsOneWidget);
    expect(repository.detailCalls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Empty history and retryable network failure are clear',
      (tester) async {
    final repository = _HistoryRepository()..fail = true;
    await tester.pumpWidget(
        MaterialApp(home: WeeklyPlanHistoryView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    repository.fail = false;
    repository.empty = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No saved weeks yet'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('History cards fit small screens and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
      child: WeeklyPlanHistoryView(repository: _HistoryRepository()),
    )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('See older weeks'), 160);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Capture native history screen for visual review',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final captureKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
      key: captureKey,
      child: WeeklyPlanHistoryView(repository: _HistoryRepository()),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/weekly-plan-history.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
