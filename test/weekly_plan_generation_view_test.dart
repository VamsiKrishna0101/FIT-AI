import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/planner/repositories/weekly_plan_repository.dart';
import 'package:setcraft/features/planner/views/weekly_plan_generation_view.dart';
import 'package:setcraft/features/planner/views/weekly_plan_view.dart';
import 'package:setcraft/features/planner/views/widgets/plan_particle_orb.dart';
import 'package:setcraft/features/planner/views/weekly_plan_card.dart';

// Loading feedback deliberately keeps ticking, including with system motion
// disabled. Advance finite frames instead of waiting for an idle loading view.
Future<void> _advance(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

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
  Future<Map<String, dynamic>> availability({bool refresh = false}) async => {
        'canGenerate': false,
        'cooldownActive': false,
        'pendingRun': ['QUEUED', 'RUNNING'].contains(current['status'])
            ? {
                'id': 'progress-run',
                'status': current['status'],
                'weekStart': '2026-10-12'
              }
            : null,
      };

  @override
  Future<List<Map<String, dynamic>>> plans() async =>
      current['plan'] is Map && (current['plan'] as Map)['payload'] is Map
          ? [Map<String, dynamic>.from(current['plan'] as Map)]
          : [];

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
            requestAiConsent: (_) async => true,
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
    await _advance(tester);
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
    await _advance(tester);
    expect(find.text('99%'), findsOneWidget);
    expect(find.text('View weekly plan'), findsNothing);

    repository.current = {
      ...repository.current,
      'plan': {'id': 'saved-plan'}
    };
    await tester.pump(const Duration(seconds: 3));
    await _advance(tester);
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
    await _advance(tester);
    await tester.scrollUntilVisible(find.text('Continue in background'), 150);
    await _advance(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Activity keeps moving with system animations disabled and pauses in background',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await _advance(tester);
    final paint = find.descendant(
        of: find.byType(PlanParticleOrb), matching: find.byType(CustomPaint));
    final painter = tester.widget<CustomPaint>(paint).painter!;
    var frames = 0;
    void repaint() => frames++;
    painter.addListener(repaint);
    await tester.pump(const Duration(seconds: 2));
    expect(frames, greaterThan(0));
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('Build workouts'), findsNothing);
    await tester.ensureVisible(find.text('Planning details'));
    await tester.tap(find.text('Planning details'));
    await _advance(tester);
    expect(find.text('Build workouts'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final paused = frames;
    await tester.pump(const Duration(seconds: 6));
    expect(frames, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _advance(tester);
    expect(frames, greaterThan(paused));
    painter.removeListener(repaint);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Confirmed progress counts smoothly while the server is unchanged',
      (tester) async {
    var percent = 41;
    late StateSetter update;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return PlanParticleOrb(percent: percent);
    })));
    await tester.pump(const Duration(milliseconds: 1100));
    update(() => percent = 75);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final text =
        tester.widget<Text>(find.byKey(const ValueKey('plan-progress-label')));
    final shown = int.parse(text.data!.replaceAll('%', ''));
    expect(shown, greaterThan(41));
    expect(shown, lessThan(75));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('75%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('75%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Stars visibly move while the confirmed percentage stays unchanged',
      (tester) async {
    final capture = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
                width: 260,
                height: 260,
                child: RepaintBoundary(
                    key: capture,
                    child: const PlanParticleOrb(percent: 41))))));
    await tester.pump(const Duration(milliseconds: 1100));
    Future<List<int>> pixels() => tester.runAsync(() async {
          final boundary = capture.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data =
              await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          image.dispose();
          return data!.buffer.asUint8List().toList();
        }).then((value) => value!);
    final before = await pixels();
    await tester.pump(const Duration(milliseconds: 700));
    final after = await pixels();
    expect(after, isNot(orderedEquals(before)));
    expect(find.text('41%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Automatic retry preserves progress and resumes without duplicate taps',
      (tester) async {
    final repository = _ProgressRepository();
    repository.current = {
      ...repository.current,
      'status': 'QUEUED',
      'stage': 'retrying',
      'attempts': 1,
      'canRetry': false
    };
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await _advance(tester);
    expect(
        find.text('Reconnecting and retrying automatically'), findsOneWidget);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('Retry planning'), findsNothing);
    repository.current = {
      ...repository.current,
      'status': 'RUNNING',
      'stage': 'nutrition',
      'progress': {
        'percent': 75,
        'completedSteps': ['history', 'workouts']
      }
    };
    await tester.pump(const Duration(seconds: 3));
    await _advance(tester);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Reconnecting and retrying automatically'), findsNothing);
    expect(repository.retries, 0);
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
    await _advance(tester);
    expect(find.text('Planning paused'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry planning'));
    await tester.tap(find.text('Retry planning'));
    await _advance(tester);
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
    await _advance(tester);
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
    await _advance(tester);
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
    await _advance(tester);
    expect(find.text('75%'), findsOneWidget);
    expect(find.textContaining('Reconnecting'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Background stops polling and foreground refreshes',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(_screen(repository, reducedMotion: true));
    await _advance(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 15));
    expect(repository.calls, calls);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _advance(tester);
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
    await _advance(tester);
    final calls = repository.calls;
    await tester.pump(const Duration(seconds: 15));
    expect(repository.calls, calls);
    expect(find.text('Back to planner'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Continue in background can reopen the same confirmed progress',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await _advance(tester);
    await tester.ensureVisible(find.text('View plan progress'));
    await tester.tap(find.text('View plan progress'));
    await _advance(tester);
    await _advance(tester);
    expect(find.text('41%'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue in background'));
    await tester.tap(find.text('Continue in background'));
    await _advance(tester);
    expect(find.text('View plan progress'), findsOneWidget);
    await tester.ensureVisible(find.text('View plan progress'));
    await tester.tap(find.text('View plan progress'));
    await _advance(tester);
    await _advance(tester);
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
  testWidgets(
      'Planner card opens running progress directly and then the completed week',
      (tester) async {
    final repository = _ProgressRepository();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: WeeklyPlanCard(repository: repository))));
    await _advance(tester);
    await tester.tap(find.text('View plan progress'));
    await _advance(tester);
    expect(find.byType(WeeklyPlanGenerationView), findsOneWidget);
    expect(find.byType(WeeklyPlanView), findsNothing);
    // Let the route transition and the per-point counter finish.
    await _advance(tester);
    expect(find.text('41%'), findsOneWidget);
    repository.current = {
      ...repository.current,
      'status': 'COMPLETED',
      'plan': {
        'id': 'finished-week',
        'status': 'ARCHIVED',
        'weekStart': '2026-10-12',
        'payload': {
          'workouts': [
            {
              'date': '2026-10-12',
              'name': 'Chest + Triceps',
              'restDay': false,
              'estimatedMinutes': 40,
              'exercises': []
            }
          ],
        }
      }
    };
    await tester.pump(const Duration(seconds: 3));
    await _advance(tester);
    await tester.tap(find.text('View weekly plan'));
    await _advance(tester);
    await _advance(tester);
    expect(find.byType(WeeklyPlanView), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-day-2026-10-12')), findsOneWidget);
    expect(find.text('Generate weekly plan'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
