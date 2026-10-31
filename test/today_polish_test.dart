import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/models/home_models.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/today/components/readiness_score_ring.dart';
import 'package:setcraft/features/today/models/session_guidance.dart';
import 'package:setcraft/features/today/views/readiness_detail_view.dart';
import 'package:setcraft/features/history/repositories/history_repository.dart';
import 'package:setcraft/features/body_scan/views/widgets/anatomical_training_map.dart';
import '../tool/scroll_benchmark_fixtures.dart';

const _preview = ValueKey('today-polish-preview');
final _history = List.generate(
    7,
    (i) => RecoveryPoint(
        date: DateTime(2026, 9, 30).add(Duration(days: i)),
        recoveryScore: [70, 72, 74, 76, 78, 80, 84][i],
        hrv: 60.0 + i,
        sleepHours: 7.0 + i / 10,
        restingHr: 60 - i));
Widget _app({
  bool reduced = true,
  List<RecoveryPoint>? history,
  HomeData? data,
  VoidCallback? onSleep,
  TextScaler textScaler = TextScaler.noScaling,
  String locale = 'en',
}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: reduced, textScaler: textScaler),
                child: RepaintBoundary(
                    key: _preview,
                    child: FitnessTheme(
                        child: Scaffold(
                            backgroundColor: FitnessTheme.canvas,
                            body: Builder(
                                builder: (bodyContext) => MediaQuery(
                                    data: MediaQuery.of(bodyContext).copyWith(
                                        padding:
                                            MediaQuery.paddingOf(bodyContext)
                                                .copyWith(bottom: 0)),
                                    child: SafeArea(
                                        bottom: false,
                                        child: TodayDashboard(
                                            data: data ?? benchmarkHome,
                                            recovery: history ?? _history,
                                            now: DateTime(2026, 10, 6, 10),
                                            onDateSelected: (_) {},
                                            onRefresh: () async {},
                                            onSleep: onSleep,
                                            onProfile: () {},
                                            onSession: () {},
                                            onTrain: () {},
                                            onNutrition: () {})))),
                            bottomNavigationBar: LiquidSilverBottomBar(selectedIndex: 0, labels: const ['Today', 'Train', 'Body', 'Progress'], onTabSelected: (_) {})))))));
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
    expect(find.byKey(const ValueKey('today-chart-comparison')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-0')));
    await tester.pump();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('today-chart-value')))
            .data,
        '7 h 6 m');
    expect(find.byKey(const ValueKey('today-chart-comparison')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-2')));
    await tester.pump();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('today-chart-value')))
            .data,
        '—');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'six sleep blocks preserve duration ratios and keep the latest day brightest',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final history = List.generate(
        6,
        (i) => RecoveryPoint(
            date: DateTime(2026, 10, i + 1),
            sleepHours: <double?>[3, 4, 5, null, 6, 8][i]));
    await tester.pumpWidget(_app(history: history));
    await tester.pumpAndSettle();
    final chart = find.byKey(const ValueKey('today-chart-card'));
    await tester.scrollUntilVisible(chart, 100,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chart);
    await tester.pumpAndSettle();
    expect(find.text('Recorded sleep'), findsOneWidget);
    expect(find.text('Last 6 days'), findsOneWidget);
    expect(find.textContaining('average'), findsNothing);
    expect(find.byKey(const ValueKey('today-chart-day-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-chart-day-6')), findsNothing);
    Finder bar(int index) => find.byKey(ValueKey('today-sleep-bar-$index'));
    double height(int index) => tester.getSize(bar(index)).height;
    expect(height(5), lessThanOrEqualTo(44));
    expect(height(0) / height(5), closeTo(3 / 8, .001));
    expect(height(1), lessThan(height(2)));
    expect(height(2), lessThan(height(4)));
    expect(height(4), lessThan(height(5)));
    expect(bar(3), findsNothing);
    expect(find.byKey(const ValueKey('today-sleep-missing-3')), findsOneWidget);
    Color fill(int index) =>
        (tester.widget<AnimatedContainer>(bar(index)).decoration
                as BoxDecoration)
            .color!;
    expect(fill(5).computeLuminance(), greaterThan(fill(0).computeLuminance()));
    final bright = fill(5);
    final muted = fill(0);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-0')));
    await tester.pumpAndSettle();
    expect(find.text('3 h 0 m'), findsOneWidget);
    expect(fill(5), bright);
    expect(fill(0), muted);
    await tester.tap(find.byKey(const ValueKey('today-chart-day-5')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('today-recorded-sleep-heading')));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'recorded-sleep-six-days-preview');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sleep labels stay aligned at 320 px with enlarged German text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        _app(locale: 'de', textScaler: const TextScaler.linear(1.8)));
    await tester.pumpAndSettle();
    final chart = find.byKey(const ValueKey('today-chart-card'));
    await tester.scrollUntilVisible(chart, 80,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chart);
    await tester.pumpAndSettle();
    expect(find.text('Erfasster Schlaf'), findsOneWidget);
    expect(find.text('Erholung'), findsOneWidget);
    final value =
        tester.getRect(find.byKey(const ValueKey('today-chart-value')));
    final date = tester.getRect(find.byKey(const ValueKey('today-chart-date')));
    expect(date.top, greaterThan(value.bottom));
    final last = find.byKey(const ValueKey('today-chart-day-5'));
    final lastRect = tester.getRect(last);
    for (var i = 0; i < 5; i++) {
      final rect = tester.getRect(find.byKey(ValueKey('today-chart-day-$i')));
      expect(rect.bottom, closeTo(lastRect.bottom, .1));
      expect(rect.right, lessThanOrEqualTo(lastRect.left));
    }
    await tester.tap(find.byKey(const ValueKey('today-chart-day-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('today-recorded-sleep-heading')));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'recorded-sleep-large-text-preview');
    expect(tester.takeException(), isNull);
  });
  testWidgets('anatomy reuses equivalent paint data', (tester) async {
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
      'empty recovery stays compact while sleep retains its recorded value',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final checkIn = HomeData.fromJson({
      ...benchmarkHome.toJson(),
      'wearableUsage': 'NONE',
      'sleepLog': {
        'sleepMinutes': 450,
        'rested': 4,
        'energy': 4,
        'soreness': 2
      },
      'readiness': {
        'source': 'check_in_estimate',
        'date': '2026-10-06',
        'score': 6.9,
        'sleepMinutes': 450
      },
    });
    await tester.pumpWidget(_app(data: checkIn, history: const []));
    await tester.pumpAndSettle();
    expect(find.text('69'), findsOneWidget);
    expect(find.text('Ready today'), findsOneWidget);
    await _snapshot(tester, 'today-check-in-polished-preview');
    final chart = find.byKey(const ValueKey('today-chart-card'));
    await tester.scrollUntilVisible(chart, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chart);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-chart-empty')), findsNothing);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('today-chart-value')))
            .data,
        '7 h 30 m');
    expect(find.text('HRV'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card press opens Recovery details and settles after returning',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var taps = 0;
    await tester.pumpWidget(_app(reduced: false, onSleep: () => taps++));
    await tester.pumpAndSettle();
    final label = find.byKey(const ValueKey('today-readiness-heading'));
    await tester.scrollUntilVisible(label, 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    final tapArea =
        find.ancestor(of: label, matching: find.byType(InkWell)).first;
    final width = tester.getRect(tapArea).width;
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(tapArea).width, lessThan(width));
    await gesture.up();
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(find.byType(ReadinessDetailView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.getRect(tapArea).width, closeTo(width, .01));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text keeps readiness readable with reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(textScaler: const TextScaler.linear(1.6)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-readiness-heading')), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
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
    await tester
        .ensureVisible(find.byKey(const ValueKey('today-session-card')));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'today-session-preview');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-chart-card')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const ValueKey('today-chart-card')));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'today-polished-progress-preview');
    await tester.scrollUntilVisible(find.text('Fat'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Fat'));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'today-polished-nutrition-preview');
    expect(find.text('Muscles this week'), findsNothing);
    expect(find.byType(AnatomicalTrainingMap), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('today-fixed-header'))),
        header);
    expect(tester.takeException(), isNull);
  });
}
