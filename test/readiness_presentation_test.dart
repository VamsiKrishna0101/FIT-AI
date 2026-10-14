import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/today/components/readiness_score_ring.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/features/today/views/readiness_detail_view.dart';
import 'package:fitai_mobile/models/home_models.dart';

const _captureKey = ValueKey('readiness-preview');
const _sleep = {'sleepMinutes': 372, 'energy': 3, 'rested': 3, 'soreness': 1};
const _reading = HomeReadiness(
  score: 7.1,
  source: 'check_in_estimate',
  date: '2026-10-13',
  label: 'Daily check-in estimate',
  aiTarget: '',
  sleepMinutes: 372,
);

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(
              key: _captureKey, child: FitnessTheme(child: child)),
        ),
      ),
    );

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
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('Readiness shows the saved inputs and a meaningful breakdown',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final data = HomeData.fromJson({
      'user': {'name': 'Vamsi Krishna'},
      'wearableUsage': 'NONE',
      'sleepLog': _sleep,
      'readiness': _reading.toJson(),
      'nutrition': <String, dynamic>{},
      'weeklyStreak': <dynamic>[],
    });
    await tester.pumpWidget(_app(Scaffold(
      backgroundColor: FitnessTheme.canvas,
      body: TodayDashboard(
        data: data,
        now: DateTime(2026, 10, 13),
        onRefresh: () async {},
        onProfile: () {},
        onSession: () {},
        onTrain: () {},
        onNutrition: () {},
        onBody: () {},
      ),
    )));
    await tester
        .ensureVisible(find.byKey(const ValueKey('today-readiness-card')));
    await tester.pumpAndSettle();
    expect(find.text('71'), findsOneWidget);
    expect(find.text('6h 12m'), findsOneWidget);
    expect(find.text('Somewhat rested'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Little'), findsOneWidget);
    expect(find.text('Daily check-in estimate'), findsNothing);
    await _capture(tester, 'readiness-today');

    await tester.pumpWidget(_app(ReadinessDetailView(
        readiness: _reading, sleepLog: _sleep, onEdit: () {})));
    await tester.pumpAndSettle();
    expect(find.text('What went into your score'), findsOneWidget);
    expect(find.textContaining('Sleep contributes 40%'), findsOneWidget);
    expect(find.text('HRV'), findsNothing);
    await _capture(tester, 'readiness-detail');
    await tester.scrollUntilVisible(find.text('Update check-in'), 160);
    await tester.pumpAndSettle();
    expect(find.text('Update check-in').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'compact wearable card puts the real score on the right and shows only recorded vitals',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final data = HomeData.fromJson({
      'user': {'name': 'Vamsi'},
      'readiness': {
        'score': 6.8,
        'source': 'health_connect',
        'date': '2026-10-13',
        'hrvMs': 42,
        'restingHrBpm': 63,
        'sleepMinutes': 410,
      },
      'nutrition': <String, dynamic>{},
      'weeklyStreak': <dynamic>[],
    });
    await tester.pumpWidget(_app(Scaffold(
        body: TodayDashboard(
      data: data,
      now: DateTime(2026, 10, 13),
      onRefresh: () async {},
      onProfile: () {},
      onSession: () {},
      onTrain: () {},
      onNutrition: () {},
      onBody: () {},
    ))));
    await tester
        .ensureVisible(find.byKey(const ValueKey('today-readiness-card')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('today-readiness-card'));
    final ring = find.byKey(const ValueKey('today-readiness-ring'));
    final heading = find.byKey(const ValueKey('today-readiness-heading'));
    expect(tester.getSize(card).height, lessThan(260));
    expect(tester.getSize(ring).width, 92);
    expect(
        tester.getCenter(ring).dx, greaterThan(tester.getCenter(heading).dx));
    expect(find.text('68'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);
    expect(find.text('63 bpm'), findsOneWidget);
    expect(find.text('Sample data'), findsNothing);
    expect(find.text('84'), findsNothing);
    expect(find.text('54 bpm'), findsNothing);
    await _capture(tester, 'readiness-compact-vitals');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Readiness remains readable on a small screen with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
        ReadinessDetailView(
            readiness: _reading, sleepLog: _sleep, onEdit: () {}),
        scale: 1.8));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Little'), 150);
    await tester.pumpAndSettle();
    expect(find.text('Little').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Update check-in'), 150);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing readiness is distinct from a recorded zero score',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const Scaffold(
        body: ReadinessScoreRing(score: null, color: Colors.white))));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Readiness not available'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await tester.pumpWidget(_app(const Scaffold(
        body: ReadinessScoreRing(score: 0, color: Colors.white))));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('0 / 100'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    semantics.dispose();
  });
}
