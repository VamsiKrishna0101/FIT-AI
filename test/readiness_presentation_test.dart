import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/today/components/daily_activity_card.dart';
import 'package:setcraft/features/today/components/readiness_score_ring.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/today/views/readiness_detail_view.dart';
import 'package:setcraft/models/home_models.dart';

const _captureKey = ValueKey('readiness-preview');
const _sleep = {'sleepMinutes': 372, 'energy': 3, 'rested': 3, 'soreness': 1};
const _reading = HomeReadiness(
    score: 7.1,
    source: 'check_in_estimate',
    date: '2026-10-13',
    label: 'Daily check-in estimate',
    aiTarget: '',
    sleepMinutes: 372);
const _health = HomeHealthMetrics(
    date: '2026-10-13',
    source: 'health_connect',
    steps: 6840,
    activeCalories: 420);
final _date = DateTime(2026, 10, 13);
Widget _app(Widget child, {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: RepaintBoundary(
                key: _captureKey, child: FitnessTheme(child: child!))),
        home: child);
Widget _today(
        {HomeReadiness? reading = _reading,
        Map<String, dynamic>? sleep = _sleep,
        HomeHealthMetrics? health = _health,
        VoidCallback? onSleep}) =>
    Scaffold(
        backgroundColor: FitnessTheme.canvas,
        body: SafeArea(
            child: TodayDashboard(
                data: HomeData.fromJson({
                  'user': {'name': 'Vamsi Krishna'},
                  'wearableUsage': 'NONE',
                  'sleepLog': sleep,
                  'readiness': reading?.toJson(),
                  'healthMetrics': health?.toJson(),
                  'nutrition': <String, dynamic>{},
                  'weeklyStreak': <dynamic>[]
                }),
                now: _date,
                onRefresh: () async {},
                onProfile: () {},
                onSession: () {},
                onTrain: () {},
                onNutrition: () {},
                onSleep: onSleep)));
void _phone(WidgetTester tester, {double width = 393}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 852);
  addTearDown(tester.view.reset);
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 100,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
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
      'Compact summary opens saved check-in and editing returns to Today',
      (tester) async {
    _phone(tester);
    var edits = 0;
    await tester.pumpWidget(_app(_today(onSleep: () => edits++)));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('today-readiness-card'));
    await _show(tester, card);
    expect(find.text('71'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
    expect(find.text('Check-in saved'), findsNothing);
    expect(find.byKey(const ValueKey('today-readiness-date')), findsNothing);
    expect(find.text('Add answer'), findsNothing);
    expect(find.text('Rested'), findsOneWidget);
    expect(tester.getSize(card).height, lessThan(280));
    final activity = find.byKey(const ValueKey('daily-activity-card'));
    expect(tester.getRect(activity).top, lessThan(tester.getRect(card).bottom));
    expect(find.text('6,840'), findsOneWidget);
    await _capture(tester, 'readiness-today');
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(ReadinessDetailView), findsOneWidget);
    expect(find.text('Your check-in'), findsOneWidget);
    expect(find.text('6h 12m'), findsOneWidget);
    expect(find.text('Somewhat rested'), findsOneWidget);
    expect(find.text('Little'), findsOneWidget);
    expect(find.text('How this is calculated'), findsNothing);
    expect(find.textContaining('40%'), findsNothing);
    expect(find.text('What went into your score'), findsNothing);
    expect(find.text('HRV'), findsNothing);
    expect(find.text('Update check-in').hitTestable(), findsOneWidget);
    await _capture(tester, 'readiness-detail');
    await _show(tester, find.byKey(const ValueKey('daily-activity-card')));
    expect(find.text('6,840'), findsOneWidget);
    expect(find.text('420 kcal'), findsNothing);
    await _capture(tester, 'readiness-detail-inputs');
    await tester.tap(find.text('Update check-in'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(find.byType(ReadinessDetailView), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Incomplete recovery opens detail with one finish action and no empty ring',
      (tester) async {
    _phone(tester);
    var edits = 0;
    await tester.pumpWidget(_app(_today(
        reading: null,
        sleep: {'sleepMinutes': 420, 'energy': 3},
        onSleep: () => edits++)));
    await tester.pumpAndSettle();
    await _show(tester, find.byKey(const ValueKey('today-readiness-heading')));
    expect(find.byType(ReadinessScoreRing), findsNothing);
    expect(find.text('Progress saved'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
    expect(find.text('Add answer'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('today-readiness-card')));
    await tester.pumpAndSettle();
    expect(find.byType(ReadinessDetailView), findsOneWidget);
    expect(find.text('7h 0m'), findsOneWidget);
    expect(find.text('Not added'), findsNWidgets(2));
    expect(find.byType(ReadinessScoreRing), findsNothing);
    await _capture(tester, 'readiness-detail-incomplete');
    await tester.tap(find.text('Finish check-in'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Activity preserves recorded zero and rejects a different date or sample source',
      (tester) async {
    for (final metrics in <HomeHealthMetrics?>[
      null,
      const HomeHealthMetrics(
          date: '2026-10-13', source: 'healthkit', steps: 0),
      const HomeHealthMetrics(
          date: '2026-10-12', source: 'healthkit', steps: 6840),
      const HomeHealthMetrics(
          date: '2026-10-13', source: 'preview', steps: 6840),
    ]) {
      await tester.pumpWidget(_app(
          Scaffold(body: DailyActivityCard(metrics: metrics, date: _date))));
      await tester.pumpAndSettle();
      final recordedZero = metrics?.steps == 0;
      expect(find.text('0'), recordedZero ? findsOneWidget : findsNothing);
      expect(find.text('—'), findsNothing);
      expect(find.byKey(const ValueKey('activity-steps-setup')),
          recordedZero ? findsNothing : findsOneWidget);
      expect(find.text('6,840'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'Past-week detail remains read-only even if a callback is supplied',
      (tester) async {
    _phone(tester);
    var edits = 0;
    await tester.pumpWidget(_app(ReadinessDetailView(
        readiness: _reading,
        sleepLog: _sleep,
        health: _health,
        readOnly: true,
        onEdit: () => edits++)));
    await tester.pumpAndSettle();
    expect(find.text('Past week · Read-only'), findsOneWidget);
    expect(find.text('Update check-in'), findsNothing);
    expect(find.text('Complete check-in'), findsNothing);
    await _show(tester, find.text('Little'));
    expect(find.text('Little').hitTestable(), findsOneWidget);
    expect(edits, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'German detail stays aligned with large text and a reachable fixed action',
      (tester) async {
    _phone(tester, width: 320);
    var edits = 0;
    await tester.pumpWidget(_app(
        ReadinessDetailView(
            readiness: _reading,
            sleepLog: _sleep,
            health: _health,
            onEdit: () => edits++),
        scale: 1.8,
        locale: 'de'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('readiness-detail-update')).hitTestable(),
        findsOneWidget);
    await _capture(tester, 'readiness-detail-large-top');
    await _show(tester, find.byKey(const ValueKey('daily-activity-card')));
    expect(find.text('6.840'), findsOneWidget);
    await _capture(tester, 'readiness-detail-large-inputs');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('readiness-detail-update')));
    await tester.pumpAndSettle();
    expect(edits, 1);
  });
  testWidgets('Missing readiness is distinct from a recorded zero score',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const Scaffold(
        body: ReadinessScoreRing(score: null, color: Colors.white))));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Readiness not available'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await tester.pumpWidget(_app(const ReadinessDetailView(
        readiness: HomeReadiness(
            score: 0,
            source: 'check_in_estimate',
            date: '2026-10-13',
            label: '',
            aiTarget: '',
            sleepMinutes: 0),
        sleepLog: {
          'sleepMinutes': 0,
          'energy': 1,
          'rested': 1,
          'soreness': 5
        })));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('0 / 100')), findsOneWidget);
    expect(find.text('0h 0m'), findsOneWidget);
    expect(find.text('Take it easier'), findsOneWidget);
    semantics.dispose();
  });
}
