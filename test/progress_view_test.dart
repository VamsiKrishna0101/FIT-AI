import 'package:setcraft/features/progress/components/progress_visual_cards.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/progress/components/body_progress_content.dart';
import 'package:setcraft/features/progress/components/exercise_progress_content.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/progress_activity.dart';
import 'package:setcraft/features/progress/components/progress_surface.dart';
import 'package:setcraft/features/progress/components/progress_weekly_bars.dart';
import 'package:setcraft/features/progress/components/progress_date_filter.dart';
import 'package:setcraft/features/progress/components/wellness_progress_content.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';

const boundary = ValueKey('progress-preview');
Widget page(Widget child,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('de'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: RepaintBoundary(
                    key: boundary, child: FitnessTheme(child: child)))));

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
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
      'Sparse training keeps the exercise visible and activity one tap away',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const data = ProgressOverview({
      'range': {'start': '2026-09-21', 'end': '2026-10-18'},
      'summary': {'workouts': 2, 'sets': 45, 'records': 0},
      'weeks': [
        {'date': '2026-10-05', 'workouts': 0, 'sets': 0},
        {'date': '2026-10-12', 'workouts': 2, 'sets': 45},
      ],
      'exercises': [
        {
          'id': 'bench',
          'name': 'Bench press',
          'latest': {'weight': 40, 'reps': 8},
          'sparkline': [
            {'date': '2026-10-14', 'value': 40}
          ]
        },
      ],
    });
    await tester.pumpWidget(page(const ProgressOverviewView(initial: data)));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('Bench press')).dy, lessThan(852));
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.byType(ProgressChart), findsNothing);
    expect(find.byType(ProgressAttendanceCard), findsOneWidget);
    expect(find.byType(ProgressActivity), findsNothing);
    await capture(tester, 'progress-sparse-redesign');
    await tester.tap(find.byKey(const ValueKey('progress-open-activity')));
    await tester.pumpAndSettle();
    final activity = find.descendant(
        of: find.byType(ProgressActivity),
        matching: find.byType(ExpansionTile));
    expect(tester.widget<ExpansionTile>(activity).initiallyExpanded, isFalse);
    expect(find.text('45'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('progress-view-all-history')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-view-all-history')), findsOneWidget);
    expect(find.text('Recovery'), findsNothing);
    expect(find.byType(ProgressSetupRow), findsNothing);
    await capture(tester, 'progress-setup-redesign');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weekly bars keep zeroes and dates visible when changing metrics',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page(
        const Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(18),
                    child: ProgressActivity(weeks: [
                      {'date': '2026-09-21', 'workouts': 0, 'sets': 0},
                      {'date': '2026-09-28', 'workouts': 0, 'sets': 0},
                      {'date': '2026-10-05', 'workouts': 1, 'sets': 20},
                      {'date': '2026-10-12', 'workouts': 2, 'sets': 45},
                    ], activity: [], endDate: '2026-10-18')))),
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('10/12'), findsOneWidget);
    await tester.tap(find.text('Logged sets'));
    await tester.pumpAndSettle();
    expect(find.text('45'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await capture(tester, 'progress-weekly-bars-redesign');
  });

  test('Chart data keeps valid zeroes and ignores missing values and dates',
      () {
    final points = ProgressPoint.parse([
      {'date': '2026-10-01', 'value': 0},
      {'date': '2026-10-02', 'value': null},
      {'date': 'invalid', 'value': 99},
      {'date': '2026-02-30', 'value': 99},
    ], 'value');
    expect(points.length, 1);
    expect(points.single.value, 0);
  });

  testWidgets('Chart scrubbing exposes the selected real point',
      (tester) async {
    await tester.pumpWidget(page(Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(18),
            child: ProgressChart(points: [
              ProgressPoint(DateTime(2026, 10, 1), 40),
              ProgressPoint(DateTime(2026, 10, 7), 50),
            ], unit: 'kg')))));
    expect(find.text('50 kg'), findsOneWidget);
    final chart = find.byType(CustomPaint).last;
    await tester.tapAt(tester.getTopLeft(chart) + const Offset(5, 25));
    await tester.pump();
    expect(find.text('40 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Body sources switch without merging photo and tape values',
      (tester) async {
    await tester.pumpWidget(page(Scaffold(
        body: SingleChildScrollView(
            child: BodyProgressContent(data: const {
      'metrics': [
        {
          'id': 'weightKg',
          'label': 'Weight',
          'unit': 'kg',
          'latest': null,
          'series': [
            {
              'source': 'scale',
              'change': null,
              'points': [
                {'date': '2026-10-01', 'value': 75}
              ]
            },
            {
              'source': 'photo_estimate',
              'change': null,
              'points': [
                {'date': '2026-10-01', 'value': 80, 'low': 77, 'high': 83}
              ]
            },
          ]
        }
      ],
      'assessments': [],
    }, onAdd: () {}, onRecord: (_) {})))));
    expect(
        find.descendant(
            of: find.byType(ProgressChart), matching: find.text('75 kg')),
        findsOneWidget);
    await tester.tap(find.text('Photo estimate').first);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(ProgressChart), matching: find.text('80 kg')),
        findsOneWidget);
    expect(find.text('75 kg'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Average charts use recorded values and allow selecting a real zero',
      (tester) async {
    await tester.pumpWidget(page(Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(18),
            child: ProgressChart(points: [
              ProgressPoint(DateTime(2026, 10, 1), 0),
              ProgressPoint(DateTime(2026, 10, 3), 80),
            ], unit: '/100', daily: true, average: true, maximum: 100)))));
    expect(find.text('40 /100'), findsOneWidget);
    final chart = find.byType(CustomPaint).last;
    await tester.tapAt(tester.getTopLeft(chart) + const Offset(12, 40));
    await tester.pump();
    expect(find.text('0 /100'), findsOneWidget);
    expect(find.text('Selected reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wellness tabs change metric, units and recorded-day average',
      (tester) async {
    await tester.pumpWidget(page(const Scaffold(
        body: SingleChildScrollView(
            child: WellnessProgressContent(data: {
      'recovery': [
        {'date': '2026-10-01', 'recovery': 70, 'sleep': 8, 'hrv': null},
        {'date': '2026-10-02', 'recovery': null, 'sleep': 6, 'hrv': 60},
      ]
    })))));
    expect(find.text('70 /100'), findsWidgets);
    expect(find.text('1 recorded days'), findsOneWidget);
    await tester.tap(find.text('Sleep').first);
    await tester.pumpAndSettle();
    expect(find.text('7 h'), findsWidgets);
    expect(find.text('2 recorded days'), findsOneWidget);
    await tester.tap(find.text('HRV').first);
    await tester.pumpAndSettle();
    expect(find.text('60 ms'), findsWidgets);
    expect(find.text('1 recorded days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overview uses real account data and keeps its header fixed',
      (tester) async {
    final file = File('build/progress-real-overview.json');
    if (!file.existsSync()) return;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = ProgressOverview(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map));
    await tester.pumpWidget(page(ProgressOverviewView(initial: data)));
    await capture(tester, 'progress-real-preview');
    final before = tester.getTopLeft(find.text('Progress'));
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Progress')), before);
    expect(find.text('Sample data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Populated overview and exercise layout render at phone size',
      (tester) async {
    final file = File('build/progress-test-overview.json');
    if (!file.existsSync()) return;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final json =
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
    await tester.pumpWidget(
        page(ProgressOverviewView(initial: ProgressOverview(json))));
    await capture(tester, 'progress-fixture-preview');
    expect(tester.takeException(), isNull);
    final detail = Map<String, dynamic>.from(
        jsonDecode(File('build/progress-test-exercise.json').readAsStringSync())
            as Map);
    await tester.pumpWidget(page(Scaffold(
        appBar: AppBar(title: const Text('Bench press')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ExerciseProgressContent(data: detail)))));
    await capture(tester, 'progress-exercise-preview');
    expect(tester.takeException(), isNull);
  });

  testWidgets('German overview supports a small screen and larger text',
      (tester) async {
    final file = File('build/progress-test-overview.json');
    if (!file.existsSync()) return;
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final json =
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
    await tester.pumpWidget(page(
        ProgressOverviewView(initial: ProgressOverview(json)),
        locale: const Locale('de'),
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -1400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(page(
        Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: WellnessProgressContent(
                    data: Map<String, dynamic>.from(json['wellness'] as Map)))),
        locale: const Locale('de'),
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Custom range dropdown opens a date-range picker and cancel preserves selection',
      (tester) async {
    String? period;
    await tester.pumpWidget(page(Scaffold(
        body: ProgressDateFilter(
            period: '4w', onChanged: (value, _) => period = value))));
    await tester.tap(find.text('4 weeks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom range').last);
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(period, isNull);
    expect(find.text('4 weeks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Populated overview has no real or preview data selector',
      (tester) async {
    final file = File('build/progress-seeded-preview.json');
    if (!file.existsSync()) return;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final json =
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
    json['dataset'] = 'real';
    await tester.pumpWidget(
        page(ProgressOverviewView(initial: ProgressOverview(json))));
    await capture(tester, 'progress-seeded-preview');
    expect(find.text('Preview data'), findsNothing);
    expect(find.text('Real data'), findsNothing);
    expect(find.byType(ProgressAttendanceCard), findsOneWidget);
    expect(find.text('Recent exercises'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -720));
    await tester.pumpAndSettle();
    await capture(tester, 'progress-dashboard-details-preview');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(page(Scaffold(
        appBar: AppBar(title: const Text('Recovery')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: WellnessProgressContent(
                data: Map<String, dynamic>.from(json['wellness'] as Map))))));
    await capture(tester, 'progress-recovery-preview');
    expect(tester.takeException(), isNull);
  });
}
