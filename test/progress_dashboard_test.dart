import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/progress_dashboard.dart';
import 'package:setcraft/features/progress/components/progress_training_hero.dart';
import 'package:setcraft/features/progress/components/progress_workout_history.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';
import 'package:setcraft/features/progress/views/progress_detail_view.dart';
import 'progress_overview_redesign_test.dart' as fixture;
import 'progress_detail_design_test.dart' as detail;

final populated = ProgressOverview({
  ...fixture.overview.json,
  'body': detail.body,
  'wellness': {...detail.wellness, ...detail.nutrition},
});

class _Repository extends ProgressRepository {
  final calls = <({String path, String period, Map<String, dynamic> query})>[];
  @override
  Future<List<String>> pins() async => [];
  @override
  Future<ProgressJson?> cached(String path, String period,
          {Map<String, dynamic> query = const {}}) async =>
      null;
  @override
  Future<ProgressJson> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    calls.add((path: path, period: period, query: Map.of(query)));
    if (path == '/sessions') {
      return {
        'items': [
          if (query['cursor'] != null)
            {
              'id': 'third',
              'name': 'Older workout',
              'date': '2026-10-20',
              'sets': 12,
              'status': 'COMPLETED'
            },
          {
            'id': 'one',
            'name': 'Upper body',
            'date': '2026-10-30',
            'sets': 18,
            'status': 'COMPLETED',
            'exercises': []
          },
          if (query['cursor'] == null)
            {
              'id': 'two',
              'name': 'Lower body',
              'date': '2026-10-28',
              'sets': 20,
              'status': 'COMPLETED'
            },
        ],
        'nextCursor': query['cursor'] == null ? 'older' : null,
      };
    }
    if (path.startsWith('/exercises/')) {
      return {
        ...detail.exercise,
        'exercise': {'id': 'bench', 'name': 'Bench press'},
        'range': populated.json['range'],
      };
    }
    if (path == '/body') {
      return {...detail.body, 'range': populated.json['range']};
    }
    if (path == '/wellness') {
      return {...populated.wellness, 'range': populated.json['range']};
    }
    if (path == '/exercises') return {'items': populated.exercises};
    return populated.json;
  }
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('Live loading and range changes use one period across sections',
      (tester) async {
    fixture.phone(tester);
    final repository = _Repository();
    await tester
        .pumpWidget(fixture.page(ProgressOverviewView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressExerciseTrends), findsOneWidget);
    expect(repository.calls.single.period, '4w');
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 months').last);
    await tester.pumpAndSettle();
    expect(repository.calls.last.period, '3m');
    await tester.tap(find.byKey(const ValueKey('progress-section-history')));
    await tester.pumpAndSettle();
    expect(repository.calls.last.path, '/sessions');
    expect(repository.calls.last.period, '3m');
    expect(repository.calls.last.query['dataset'], 'real');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Summary keeps exercise rows compact and opens the real chart',
      (tester) async {
    fixture.phone(tester);
    final repository = _Repository();
    await tester.pumpWidget(fixture.page(
        ProgressOverviewView(initial: populated, repository: repository),
        dock: true));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressExerciseTrends), findsOneWidget);
    expect(tester.getSize(find.byType(ProgressTrainingHero)).height,
        lessThan(240));
    expect(tester.getSize(find.byType(ProgressExerciseTrends)).height,
        lessThan(210));
    await fixture.capture(tester, 'progress-dashboard-summary');
    await tester
        .ensureVisible(find.byKey(const ValueKey('progress-exercise-bench')));
    await tester.tap(find.byKey(const ValueKey('progress-exercise-bench')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressChart), findsOneWidget);
    final chart = tester.widget<ProgressChart>(find.byType(ProgressChart));
    expect(chart.showChange, isTrue);
    expect(chart.points.map((p) => p.value), [55, 60, 62.5]);
    expect(repository.calls.last.path, '/exercises/bench');
    expect(repository.calls.last.period, '4w');
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find
          .ancestor(
              of: find.byType(ProgressDetailView),
              matching: find.byType(RepaintBoundary))
          .first);
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/previews/progress-exercise-chart-refined.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProgressExerciseTrends), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All six trend categories are discoverable and retain the period',
      (tester) async {
    fixture.phone(tester);
    final repository = _Repository();
    await tester.pumpWidget(fixture.page(
        ProgressOverviewView(initial: populated, repository: repository),
        dock: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-section-trends')));
    await tester.pumpAndSettle();
    for (final kind in [
      'training',
      'exercises',
      'muscles',
      'body',
      'nutrition',
      'recovery'
    ]) {
      expect(find.byKey(ValueKey('progress-trend-$kind')), findsOneWidget);
    }
    await fixture.capture(tester, 'progress-dashboard-trends');
    await tester
        .ensureVisible(find.byKey(const ValueKey('progress-trend-body')));
    await tester.tap(find.byKey(const ValueKey('progress-trend-body')));
    await tester.pumpAndSettle();
    expect(repository.calls.last.path, '/body');
    expect(repository.calls.last.period, '4w');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-trend-body')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'History loads once, paginates without duplicates and opens recaps',
      (tester) async {
    fixture.phone(tester);
    final repository = _Repository();
    await tester.pumpWidget(fixture.page(
        ProgressOverviewView(initial: populated, repository: repository),
        dock: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-section-history')));
    await tester.pumpAndSettle();
    expect(find.text('Upper body'), findsOneWidget);
    expect(find.text('Lower body'), findsOneWidget);
    await fixture.capture(tester, 'progress-dashboard-history');
    await tester.tap(find.byKey(const ValueKey('progress-section-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-section-history')));
    await tester.pumpAndSettle();
    expect(
        repository.calls.where((call) => call.path == '/sessions').length, 1);
    await tester
        .ensureVisible(find.byKey(const ValueKey('progress-history-more')));
    await tester.tap(find.byKey(const ValueKey('progress-history-more')));
    await tester.pumpAndSettle();
    expect(find.text('Upper body'), findsOneWidget);
    expect(find.text('Older workout'), findsOneWidget);
    expect(repository.calls.last.query['cursor'], 'older');
    await tester.ensureVisible(find.text('Older workout'));
    await tester.tap(find.text('Older workout'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressWorkoutRecap), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Older workout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Body preview keeps measured and estimated sources separate', () {
    final preview = progressBodyPreview({
      'metrics': [
        {
          'id': 'weightKg',
          'label': 'Weight',
          'unit': 'kg',
          'series': [
            {
              'source': 'photo_estimate',
              'points': [
                {'date': '2026-10-01', 'value': 65}
              ]
            },
            {
              'source': 'scale',
              'points': [
                {'date': '2026-10-02', 'value': 70},
                {'date': '2026-10-09', 'value': 69}
              ]
            },
          ]
        }
      ]
    });
    expect(preview.source, 'scale');
    expect(preview.points.map((point) => point.value), [70, 69]);
  });

  testWidgets(
      'Chart selection works by touch, keyboard and screen-reader actions',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(18),
            child: ProgressChart(points: [
              for (final entry in [
                (1, 45.0),
                (8, 50.0),
                (15, 50.0),
                (28, 60.0)
              ])
                ProgressPoint(DateTime(2026, 10, entry.$1), entry.$2)
            ], unit: 'kg', showChange: true)))));
    await tester.pumpAndSettle();
    final plot = find.byKey(const ValueKey('progress-chart-plot'));
    await tester.tapAt(tester.getTopLeft(plot) + const Offset(14, 40));
    await tester.pumpAndSettle();
    expect(find.text('Selected reading'), findsOneWidget);
    final locale =
        Localizations.localeOf(tester.element(find.byType(ProgressChart)))
            .toLanguageTag();
    expect(find.text(DateFormat.MMMd(locale).format(DateTime(2026, 10, 1))),
        findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(find.text(DateFormat.MMMd(locale).format(DateTime(2026, 10, 28))),
        findsNWidgets(2));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      final node = tester.getSemantics(plot);
      expect(node.getSemanticsData().label, contains('60 kg'));
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.decrease),
          isTrue);
      node.owner!.performAction(node.id, ui.SemanticsAction.decrease);
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.MMMd(locale).format(DateTime(2026, 10, 15))),
          findsNWidgets(2));
    } finally {
      semantics.dispose();
    }
    expect(tester.takeException(), isNull);
  });
}
