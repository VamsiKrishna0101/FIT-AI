import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/components/liquid_silver_bottom_bar.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/features/today/components/readiness_score_ring.dart';
import 'package:fitai_mobile/features/today/components/today_training_preview.dart';
import 'package:fitai_mobile/features/today/models/session_guidance.dart';
import 'package:fitai_mobile/features/history/repositories/history_repository.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/anatomical_training_map.dart';
import '../tool/scroll_benchmark_fixtures.dart';

const _preview = ValueKey('today-polish-preview');
final _map = TrainingMapData.fromJson(
    jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
        as Map<String, dynamic>);
final _history = List.generate(
    7,
    (i) => RecoveryPoint(
        date: DateTime(2026, 9, 30).add(Duration(days: i)),
        recoveryScore: [70, 72, 74, 76, 78, 80, 84][i],
        hrv: 60.0 + i,
        sleepHours: 7.0 + i / 10,
        restingHr: 60 - i));
Widget _app({bool reduced = true, List<RecoveryPoint>? history}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Builder(
        builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: RepaintBoundary(
                key: _preview,
                child: FitnessTheme(
                    child: Scaffold(
                        backgroundColor: FitnessTheme.canvas,
                        extendBody: true,
                        body: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                                padding: MediaQuery.paddingOf(context)
                                    .copyWith(bottom: 0)),
                            child: SafeArea(
                                bottom: false,
                                child: TodayDashboard(
                                    data: benchmarkHome,
                                    trainingMap: _map,
                                    recovery: history ?? _history,
                                    now: DateTime(2026, 10, 6, 10),
                                    onRefresh: () async {},
                                    onProfile: () {},
                                    onSession: () {},
                                    onTrain: () {},
                                    onBody: () {},
                                    onNutrition: () {}))),
                        bottomNavigationBar: LiquidSilverBottomBar(
                            selectedIndex: 0,
                            labels: const ['Today', 'Train', 'Body', 'Progress'],
                            onTabSelected: (_) {})))))));
Future<void> _snapshot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(_preview))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  test('legacy effort is displayed as a plan target without recovery certainty',
      () {
    final guidance = SessionGuidance.fromNote(
        'Target Effort: 8.5/10 — Full recovery detected. Prime window for hypertrophy.',
        fallback: 'Adjust to how you feel today.');
    expect(guidance.effortLabel, '8.5 / 10');
    expect(guidance.summary, 'Adjust to how you feel today.');
    expect(
        SessionGuidance.fromNote('Target Effort: 25/10 — A note.', fallback: '')
            .effort,
        isNull);
    expect(
        SessionGuidance.fromNote(
                'Use a comfortable load. Keep your usual rest.',
                fallback: '')
            .summary,
        'Use a comfortable load.');
    expect(SessionGuidance.fromNote(null, fallback: '').effortLabel, isEmpty);
  });
  testWidgets(
      'ring settles once, updates real scores and respects reduced motion',
      (tester) async {
    Widget app(int score, bool reduced) => MaterialApp(
        home: Builder(
            builder: (context) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(disableAnimations: reduced),
                child: Center(
                    child: ReadinessScoreRing(
                        score: score, color: Colors.white)))));
    await tester.pumpWidget(app(84, false));
    expect(find.text('84'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(app(62, false));
    expect(find.text('62'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(app(49, true));
    await tester.pump();
    expect(find.text('49'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  testWidgets(
      'chart taps show the selected day and never substitute a missing reading',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final history = _history.where((p) => p.date.day != 3).toList();
    await tester.pumpWidget(_app(history: history));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-chart-card')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const ValueKey('today-chart-card')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('today-chart-comparison')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-0')));
    await tester.pump();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('today-chart-value')))
            .data,
        '70 / 100');
    expect(find.byKey(const ValueKey('today-chart-comparison')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-3')));
    await tester.pump();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('today-chart-value')))
            .data,
        '—');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'body preview colours only direct logged sets and reuses equivalent paint data',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: Center(child: TodayTrainingPreview(data: _map))));
    final map = tester
        .widgetList<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
        .first;
    for (final region in _map.regions) {
      expect(map.colors[region.id] == const Color(0xFF555555),
          region.completedSets == 0);
    }
    Widget anatomy() => MaterialApp(
        home: SizedBox(
            width: 220,
            height: 440,
            child: AnatomicalTrainingMap(
                colors: Map.of({'chest': Colors.blue}), onSelected: (_) {})));
    await tester.pumpWidget(anatomy());
    final paint = find.descendant(
        of: find.byType(AnatomicalTrainingMap),
        matching: find.byType(CustomPaint));
    final before = tester.widget<CustomPaint>(paint).painter!;
    await tester.pumpWidget(anatomy());
    final after = tester.widget<CustomPaint>(paint).painter!;
    expect(after.shouldRepaint(before), isFalse);
  });
  testWidgets(
      'premium Today previews preserve compact surfaces and the fixed header',
      (tester) async {
    tester.view.physicalSize = const Size(786, 1704);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final header =
        tester.getRect(find.byKey(const ValueKey('today-fixed-header')));
    expect(find.textContaining('Full recovery detected'), findsNothing);
    await _snapshot(tester, 'today-polished-preview');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-effort-pill')), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('today-effort-pill')), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-chart-card')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const ValueKey('today-chart-card')));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'today-polished-progress-preview');
    await tester.scrollUntilVisible(find.byType(TodayTrainingPreview), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byType(TodayTrainingPreview));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'today-polished-body-preview');
    expect(tester.getRect(find.byKey(const ValueKey('today-fixed-header'))),
        header);
    expect(tester.takeException(), isNull);
  });
}
