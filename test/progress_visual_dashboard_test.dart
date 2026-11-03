import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setcraft/features/planner/repositories/weekly_plan_repository.dart';
import 'package:setcraft/features/planner/views/weekly_plan_history_view.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_calendar.dart';
import 'package:setcraft/features/progress/components/progress_surface.dart';
import 'package:setcraft/features/progress/components/progress_visual_cards.dart';
import 'package:setcraft/features/progress/components/progress_visual_charts.dart';
import 'package:setcraft/features/progress/models/progress_chart_data.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/progress/views/progress_detail_view.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';
import 'progress_overview_redesign_test.dart' as fixture;
import 'progress_detail_design_test.dart' as detail;

final visualData = ProgressOverview({
  'range': {'start': '2026-10-26', 'end': '2026-10-30'},
  'summary': {'workouts': 3, 'sets': 36, 'trainingDays': 3},
  'activity': [
    {'date': '2026-10-26', 'sets': 12, 'completed': true},
    {'date': '2026-10-28', 'sets': 12, 'completed': true},
    {'date': '2026-10-30', 'sets': 12, 'completed': true},
  ],
  'weeks': [
    {'date': '2026-10-26', 'workouts': 3, 'sets': 36}
  ],
  'muscles': [
    for (final m in [
      ('chest', 12),
      ('lats', 9),
      ('shoulders', 6),
      ('quads', 5),
      ('biceps', 3),
      ('core', 1)
    ])
      {'id': m.$1, 'label': m.$1, 'directSets': m.$2},
  ],
  'exercises': [
    {
      ...fixture.bench,
      'loggedSets': 9,
      'totalReps': 72,
      'volume': 4140,
      'sparkline': [
        {'date': '2026-10-26', 'value': 55},
        {'date': '2026-10-28', 'value': 57.5},
        {'date': '2026-10-30', 'value': 60},
      ]
    },
    {...fixture.pullUp, 'loggedSets': 6, 'totalReps': 42, 'volume': null},
  ],
  'body': {
    'profileHeight': 178,
    'profileBaseline': 75,
    'metrics': [
      {
        'id': 'weightKg',
        'label': 'Weight',
        'unit': 'kg',
        'series': [
          {
            'source': 'scale',
            'points': [
              {'date': '2026-10-26', 'value': 75},
              {'date': '2026-10-28', 'value': 74.6},
              {'date': '2026-10-30', 'value': 74.8},
            ]
          },
        ]
      },
      {
        'id': 'waistCm',
        'label': 'Waist',
        'unit': 'cm',
        'series': [
          {
            'source': 'tape',
            'points': [
              {'date': '2026-10-30', 'value': 82}
            ]
          },
        ]
      },
    ],
  },
  'wellness': {
    'nutrition': [
      {
        'date': '2026-10-26',
        'protein': 120,
        'carbs': 240,
        'fat': 60,
        'calories': 2100
      },
      {
        'date': '2026-10-28',
        'protein': 140,
        'carbs': 200,
        'fat': 65,
        'calories': 2000
      },
      {'date': '2026-10-29', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
    ],
    'sleep': [
      {'date': '2026-10-26', 'sleep': 7.5},
      {'date': '2026-10-28', 'sleep': 6.5},
    ],
    'recovery': [
      {'date': '2026-10-30', 'hrv': 75, 'rhr': 60, 'recovery': 90}
    ],
  },
  'planHistory': [
    {'id': 'saved-week', 'weekStart': '2026-10-26', 'status': 'ACTIVE'},
  ],
});

class _Repository extends ProgressRepository {
  final calls = <({String path, String period, Map<String, dynamic> query})>[];
  @override
  Future<List<String>> pins() async => ['bench'];
  @override
  Future<ProgressJson?> cached(String path, String period,
          {Map<String, dynamic> query = const {}}) async =>
      null;
  @override
  Future<ProgressJson> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    calls.add((path: path, period: period, query: Map.of(query)));
    if (path.startsWith('/exercises/')) return detail.exercise;
    if (path == '/body') return visualData.body;
    if (path == '/sessions') return {'items': [], 'nextCursor': null};
    if (path == '/wellness') return visualData.wellness;
    return {
      ...visualData.json,
      'range': {
        'start': query['start'] ?? '2026-10-26',
        'end': query['end'] ?? '2026-10-30',
        if (query['dates'] is String)
          'selectedDates': (query['dates'] as String).split(','),
      }
    };
  }
}

class _Plans extends WeeklyPlanRepository {
  Map<String, dynamic>? filter;
  @override
  Future<Map<String, dynamic>> filteredHistory(
      {String? cursor, required Map<String, dynamic> query}) async {
    filter = Map.of(query);
    return {'items': [], 'nextCursor': null};
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 30 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsWidgets);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues(
      {'fitai_access_token': 'test', 'fitai_user_id': 'visual-progress-test'}));
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

  testWidgets(
      'One right-hand calendar filters the current week and non-consecutive days',
      (tester) async {
    fixture.phone(tester);
    final repo = _Repository();
    await tester.pumpWidget(fixture.page(ProgressOverviewView(
        repository: repo, clock: () => DateTime(2026, 10, 30))));
    await tester.pumpAndSettle();
    expect(repo.calls.first.period, 'custom');
    expect(repo.calls.first.query, containsPair('start', '2026-10-26'));
    expect(repo.calls.first.query, containsPair('end', '2026-10-30'));
    expect(find.byIcon(CupertinoIcons.calendar), findsOneWidget);
    expect(
        tester
            .getCenter(find.byKey(const ValueKey('progress-calendar-button')))
            .dx,
        greaterThan(330));
    await tester.tap(find.byKey(const ValueKey('progress-calendar-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BodyCalendar), findsOneWidget);
    await tester.tap(find.text('Multiple days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-calendar-2026-10-26')));
    await tester.tap(find.byKey(const ValueKey('body-calendar-2026-10-30')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-calendar-apply')));
    await tester.pumpAndSettle();
    expect(repo.calls.last.query['dates'], '2026-10-26,2026-10-30');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chart cards open the selected exercise using the same dates',
      (tester) async {
    fixture.phone(tester);
    final repo = _Repository();
    await tester.pumpWidget(fixture.page(ProgressOverviewView(
        initial: visualData,
        repository: repo,
        clock: () => DateTime(2026, 10, 30))));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('progress-exercise-bench')));
    expect(find.text('Recovery'), findsNothing);
    expect(find.text('HRV'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-exercise-bench')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressDetailView), findsOneWidget);
    expect(repo.calls.last.path, '/exercises/bench');
    expect(repo.calls.last.query['start'], '2026-10-26');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Macro donut uses calorie shares and exposes tapped percentages',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(const Scaffold(
        body: ProgressNutritionDonutCard(wellness: {
      'nutrition': [
        {'date': '2026-10-26', 'protein': 25, 'carbs': 25, 'fat': 0},
      ]
    }))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-macro-Protein')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('progress-macro-centre-value')))
            .data,
        '50%');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Daily bars distinguish missing days, recorded zeroes and manual sleep',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressDailyTrendsCard(
            data: visualData,
            days: List.generate(7, (i) => DateTime(2026, 10, 26 + i))))));
    await tester.pumpAndSettle();
    final chart =
        tester.widget<ProgressColumnChart>(find.byType(ProgressColumnChart));
    expect(chart.bars.map((bar) => bar.value),
        [2100, null, 2000, 0, null, null, null]);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(find.text('6 h 30 min'), findsOneWidget);
    expect(find.text('90'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in AppLanguage.values) {
    testWidgets(
        'Visual weekly dashboard fits narrow ${language.code} at large text',
        (tester) async {
      fixture.phone(tester, width: 320);
      await tester.pumpWidget(fixture.page(
          ProgressOverviewView(
              initial: visualData, clock: () => DateTime(2026, 10, 30)),
          locale: language.locale,
          scale: 1.6,
          dock: true));
      await tester.pumpAndSettle();
      for (var i = 0; i < 18; i++) {
        await tester.drag(
            find.byType(CustomScrollView).first, const Offset(0, -220));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.byKey(const ValueKey('progress-view-all-history')),
          findsOneWidget);
    });
  }

  testWidgets('Weekly chart dashboard produces phone previews', (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(
        ProgressOverviewView(
            initial: visualData, clock: () => DateTime(2026, 10, 30)),
        dock: true));
    await tester.pumpAndSettle();
    await fixture.capture(tester, 'progress-weekly-top');
    await reveal(tester, find.byType(ProgressBodyChartCard));
    await fixture.capture(tester, 'progress-weekly-body');
    await reveal(tester, find.byType(ProgressNutritionDonutCard));
    await tester.ensureVisible(find.byType(ProgressNutritionDonutCard));
    await tester.pumpAndSettle();
    await fixture.capture(tester, 'progress-weekly-nutrition');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Activity stays white day circles for a long date range',
      (tester) async {
    fixture.phone(tester);
    await tester.pumpWidget(fixture.page(Scaffold(
        body: ProgressAttendanceCard(
            data: visualData,
            days: List.generate(28, (i) => DateTime(2026, 10, 3 + i)),
            onOpen: () {}))));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressColumnChart), findsNothing);
    final dot = tester.widget<Container>(
        find.byKey(const ValueKey('progress-attendance-2026-10-30')));
    expect((dot.decoration as BoxDecoration).color, Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plan history keeps the calendar filter when View all opens',
      (tester) async {
    fixture.phone(tester);
    final plans = _Plans();
    await tester.pumpWidget(fixture.page(ProgressOverviewView(
        initial: visualData,
        planRepository: plans,
        clock: () => DateTime(2026, 10, 30))));
    await tester.pumpAndSettle();
    final action = find.descendant(
        of: find.byWidgetPredicate(
            (w) => w is ProgressHeading && w.title == 'Plan history'),
        matching: find.byType(TextButton));
    await reveal(tester, action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyPlanHistoryView), findsOneWidget);
    expect(plans.filter, containsPair('start', '2026-10-26'));
    expect(plans.filter, containsPair('end', '2026-10-30'));
    expect(plans.filter, containsPair('period', 'custom'));
    expect(find.text('No plans in this period'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Selection queries and macro math preserve actual logged data', () {
    final query = progressSelectionQuery(BodyDateSelection(
        mode: BodyDateMode.days,
        end: DateTime(2026, 10, 30),
        dates: [DateTime(2026, 10, 30), DateTime(2026, 10, 26)]));
    expect(query['start'], '2026-10-26');
    expect(query['dates'], '2026-10-26,2026-10-30');
    final macros = ProgressMacros.fromRows([
      {'date': '2026-10-26', 'protein': 25, 'carbs': 25, 'fat': 0},
      {'date': '2026-10-27', 'protein': null, 'carbs': 100, 'fat': 20},
      {'date': '2026-10-28', 'protein': 0, 'carbs': 0, 'fat': 0},
    ]);
    expect(macros.total, 200);
    expect(macros.days, 2);
  });
}
