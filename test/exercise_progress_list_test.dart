import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/progress/components/exercise_progress_content.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/views/progress_detail_view.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_calendar.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/progress/views/progress_exercises_view.dart';

class _Repository extends ProgressRepository {
  final queries = <Map<String, dynamic>>[];
  final paths = <String>[];
  final periods = <String>[];
  var failMore = false;
  var pinReads = 0;
  @override
  Future<Map<String, dynamic>> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    queries.add({...query});
    paths.add(path);
    periods.add(period);
    if (path.startsWith('/exercises/')) {
      const days = [
        ('2026-10-01', 10),
        ('2026-10-12', 11),
        ('2026-10-21', 12),
      ];
      return {
        'exercise': {
          'id': 'row',
          'name': 'Dumbbell bent over row',
          'loggedSets': 9,
        },
        'range': {'start': '2026-09-25', 'end': '2026-10-22'},
        'series': [
          for (final (date, weight) in days)
            {
              'date': date,
              'load': weight,
              'reps': 10,
              'volume': weight * 30,
              'estimatedStrength': weight * 4 / 3,
              'bestSet': {'weight': weight, 'reps': 10},
            }
        ],
        'records': {
          'bestLoad': {'weight': 12, 'reps': 10, 'date': '2026-10-21'}
        },
        'history': [
          for (final (date, weight) in days.reversed)
            {
              'date': date,
              'entries': [
                for (var i = 1; i <= 3; i++)
                  {'setNumber': i, 'weight': weight, 'reps': 10}
              ],
            }
        ],
      };
    }
    final more = query['cursor'] != null;
    if (more && failMore) throw StateError('Offline');
    final search = query['search'] as String? ?? '';
    return {
      'range': {'start': '2026-09-25', 'end': '2026-10-22'},
      'nextCursor': more ? null : 'next',
      'items': [
        {
          'id': more ? 'squat' : 'row',
          'name': more
              ? 'Barbell squat'
              : search.isEmpty
                  ? 'Dumbbell bent over row'
                  : 'Cable row',
          'latest': {'weight': more ? 40 : 12, 'reps': 10},
          'latestDate': '2026-10-21',
          'sessions': 3,
          'metric': 'load',
          'change': 20,
          'sparkline': [
            {'date': '2026-10-01', 'value': 10},
            {'date': '2026-10-21', 'value': 12}
          ]
        },
        if (!more && search.isEmpty)
          {
            'id': 'bench',
            'name': 'Barbell bench press',
            'latest': {'weight': null, 'reps': 10},
            'latestDate': '2026-10-20',
            'sessions': 1,
            'metric': 'reps',
            'sparkline': [
              {'date': '2026-10-20', 'value': 10}
            ]
          },
      ],
    };
  }

  @override
  Future<List<String>> pins() async {
    pinReads++;
    return [];
  }
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  testWidgets(
      'Search, muscle selection and pagination retain their query context',
      (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: ProgressExercisesView(
            period: 'custom',
            muscles: const [
              {'id': 'lats', 'label': 'Lats'}
            ],
            query: const {'start': '2026-09-25', 'end': '2026-10-22'},
            repository: repo)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pin exercise'), findsNothing);
    expect(find.text('10 reps'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'row');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All muscles'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<String> && w.value == 'lats'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more exercises'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more exercises'));
    await tester.pumpAndSettle();
    expect(repo.queries.last, containsPair('search', 'row'));
    expect(repo.queries.last, containsPair('muscle', 'lats'));
    expect(repo.queries.last, containsPair('start', '2026-09-25'));
    expect(repo.queries.last, containsPair('cursor', 'next'));
    expect(find.text('Cable row'), findsOneWidget);
    expect(find.text('Barbell squat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Opening an exercise retains sparse dates and has no overview action',
      (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: ProgressExercisesView(
            period: 'custom',
            muscles: const [],
            query: const {
              'start': '2026-09-25',
              'end': '2026-10-22',
              'dates': '2026-09-25,2026-10-22',
              'dataset': 'real',
            },
            repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell bent over row'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressDetailView), findsOneWidget);
    expect(find.byType(ProgressChart), findsOneWidget);
    expect(repo.paths.last, '/exercises/row');
    expect(repo.queries.last['dates'], '2026-09-25,2026-10-22');
    expect(repo.pinReads, 0);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Show on overview'), findsNothing);
    expect(find.text('Remove from overview'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('The shared calendar retains search and muscle filters',
      (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: ProgressExercisesView(
            period: 'custom',
            muscles: const [
              {'id': 'lats', 'label': 'Lats'}
            ],
            query: const {'start': '2026-09-25', 'end': '2026-10-22'},
            repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'row');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All muscles'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<String> && w.value == 'lats'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-progress-calendar')));
    await tester.pumpAndSettle();
    expect(find.byType(BodyCalendar), findsOneWidget);
    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-calendar-apply')));
    await tester.pumpAndSettle();
    final today = DateUtils.dateOnly(DateTime.now());
    String key(DateTime day) => day.toIso8601String().substring(0, 10);
    expect(repo.queries.last['search'], 'row');
    expect(repo.queries.last['muscle'], 'lats');
    expect(repo.queries.last['start'], key(bodyMapWeek(today)));
    expect(repo.queries.last['end'], key(today));
    expect(repo.periods.last, 'custom');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Older-page failure preserves rows and retries the same cursor',
      (tester) async {
    final repo = _Repository()..failMore = true;
    await tester.pumpWidget(MaterialApp(
        home: ProgressExercisesView(
            period: '4w', muscles: const [], repository: repo)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Load more exercises'));
    await tester.tap(find.text('Load more exercises'));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell bent over row'), findsOneWidget);
    expect(find.text('Barbell bench press'), findsOneWidget);
    expect(repo.queries.last['cursor'], 'next');
    repo.failMore = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repo.queries.last['cursor'], 'next');
    expect(find.text('Barbell squat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'List remains readable at larger text sizes and renders the native preview',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final capture = GlobalKey();
    Widget app(double scale) => MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
                key: capture,
                child: ProgressExercisesView(
                    period: '4w',
                    muscles: const [],
                    repository: _Repository()))));
    await tester.pumpWidget(app(1.8));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    final boundary =
        capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/exercise-progress-list.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.text('Dumbbell bent over row'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseProgressContent), findsOneWidget);
    final detailBoundary = tester.renderObject<RenderRepaintBoundary>(find
        .ancestor(
            of: find.byType(ProgressDetailView),
            matching: find.byType(RepaintBoundary))
        .first);
    await tester.runAsync(() async {
      final image = await detailBoundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/previews/exercise-progress-detail.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
