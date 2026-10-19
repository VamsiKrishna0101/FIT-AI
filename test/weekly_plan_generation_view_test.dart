import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/planner/repositories/weekly_plan_repository.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_generation_view.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_view.dart';

class _ProgressRepository extends WeeklyPlanRepository {
  int calls = 0;
  int retries = 0;
  Object? error;
  Map<String, dynamic> current = {
    'id': 'progress-run',
    'status': 'RUNNING',
    'stage': 'specialists',
    'weekStart': '2026-10-12',
    'progress': {
      'percent': 41,
      'completedSteps': ['history', 'chest', 'back', 'legs', 'core'],
    },
  };

  @override
  Future<Map<String, dynamic>> availability() async => {
        'canGenerate': false,
        'cooldownActive': false,
        'pendingRun': {
          'id': 'progress-run',
          'status': current['status'],
          'weekStart': '2026-10-12'
        },
      };

  @override
  Future<List<Map<String, dynamic>>> plans() async => [];

  @override
  Future<Map<String, dynamic>> run(String id) async {
    calls++;
    if (error != null) throw error!;
    return Map.of(current);
  }

  @override
  Future<Map<String, dynamic>> retry(String id) async {
    retries++;
    current = {...current, 'status': 'QUEUED', 'stage': 'queued'};
    return current;
  }
}

Widget _screen(_ProgressRepository repository,
        {bool reducedMotion = false,
        double textScale = 1,
        GlobalKey? captureKey}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
            disableAnimations: reducedMotion,
            textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(
          key: captureKey,
          child: WeeklyPlanGenerationView(
            repository: repository,
            initialRun: Map.of(repository.current),
            weekStart: DateTime(2026, 10, 12),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'opaque',
        'fitai_user_id': 'progress-test',
      }));

  testWidgets(
      'Percentage holds until confirmed and completes only with a saved plan',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(_screen(repository));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('41%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();
    expect(find.text('41%'), findsOneWidget);

    repository.current = {
      ...repository.current,
      'status': 'COMPLETED',
      'progress': {'percent': 100, 'completedSteps': []}
    };
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('99%'), findsOneWidget);
    expect(find.text('View weekly plan'), findsNothing);

    repository.current = {
      ...repository.current,
      'plan': {'id': 'saved-plan'}
    };
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Your week is ready'), findsOneWidget);
    expect(find.text('View weekly plan'), findsOneWidget);
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 9));
    expect(repository.calls, calls);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Small screen and large text supports reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _ProgressRepository();
    await tester
        .pumpWidget(_screen(repository, reducedMotion: true, textScale: 1.8));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue in background'), 150);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed run retries without losing confirmed progress',
      (tester) async {
    final repository = _ProgressRepository();
    repository.current = {
      ...repository.current,
      'status': 'FAILED',
      'canRetry': true
    };
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await tester.pumpAndSettle();
    expect(find.text('Planning paused'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry planning'));
    await tester.tap(find.text('Retry planning'));
    await tester.pumpAndSettle();
    expect(repository.retries, 1);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('Building your week'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Final-save failure explains changed data and does not offer stale retry',
      (tester) async {
    final repository = _ProgressRepository();
    repository.current = {
      ...repository.current,
      'status': 'FAILED',
      'stage': 'failed',
      'errorCode': 'STALE_PLAN',
      'canRetry': false,
      'progress': {
        'percent': 91,
        'completedSteps': [
          'history',
          'workouts',
          'nutrition',
          'validation',
        ]
      },
    };
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await tester.pumpAndSettle();
    expect(find.text('91%'), findsOneWidget);
    expect(
        find.text(
            'Your history or preferences changed. Generate an updated plan.'),
        findsOneWidget);
    expect(find.text('Retry planning'), findsNothing);
    expect(find.text('View weekly plan'), findsNothing);
    expect(find.text('Back to planner'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Network interruption keeps progress and resumes polling',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await tester.pumpAndSettle();
    repository.error = Exception('offline');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('Reconnecting'), findsOneWidget);
    expect(find.text('41%'), findsOneWidget);
    repository.error = null;
    repository.current = {
      ...repository.current,
      'stage': 'nutrition',
      'progress': {
        'percent': 75,
        'completedSteps': ['history', 'workouts']
      }
    };
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    expect(find.textContaining('Reconnecting'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Background stops polling and foreground refreshes',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 15));
    expect(repository.calls, calls);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.calls, greaterThan(calls));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Unavailable plan stops polling', (tester) async {
    final repository = _ProgressRepository();
    repository.error = DioException(
        requestOptions: RequestOptions(path: '/run'),
        response: Response(
            requestOptions: RequestOptions(path: '/run'), statusCode: 404));
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await tester.pumpAndSettle();
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 15));
    expect(repository.calls, calls);
    expect(find.text('Back to planner'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Continue in background can reopen the same confirmed progress',
      (tester) async {
    final repository = _ProgressRepository();
    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View plan progress'));
    await tester.tap(find.text('View plan progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('41%'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue in background'));
    await tester.tap(find.text('Continue in background'));
    await tester.pumpAndSettle();
    expect(find.text('View plan progress'), findsOneWidget);
    await tester.ensureVisible(find.text('View plan progress'));
    await tester.tap(find.text('View plan progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('41%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Capture native progress screen for visual review',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _ProgressRepository();
    final captureKey = GlobalKey();
    await tester.pumpWidget(_screen(repository, captureKey: captureKey));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/weekly-plan-progress.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
