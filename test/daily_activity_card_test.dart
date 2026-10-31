import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/today/components/daily_activity_card.dart';
import 'package:setcraft/models/home_models.dart';

final today = DateTime(2026, 10, 28);
const captureKey = ValueKey('activity-preview');
const steps = HomeHealthMetrics(
    date: '2026-10-28', source: 'health_connect', steps: 6840);
Widget app(Widget child, {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: FitnessTheme(
                child: RepaintBoundary(key: captureKey, child: child!))),
        home: Scaffold(
            body: SafeArea(
                child:
                    Padding(padding: const EdgeInsets.all(16), child: child))));
void phone(WidgetTester tester, {double width = 393}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 852);
  addTearDown(tester.view.reset);
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
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
  testWidgets('Missing steps offer setup without showing an empty count',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(DailyActivityCard(date: today, now: today)));
    await tester.pumpAndSettle();
    expect(find.text('Set up steps'), findsOneWidget);
    expect(
        find.text('Connect your health app to import steps.'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.byKey(const ValueKey('activity-Steps-value')), findsNothing);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('daily-activity-card')))
            .height,
        lessThan(140));
    await capture(tester, 'steps-setup');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Returning from setup refreshes steps and duplicate taps open once',
      (tester) async {
    phone(tester);
    final result = Completer<HomeHealthMetrics?>();
    var calls = 0;
    await tester.pumpWidget(app(DailyActivityCard(
        date: today,
        now: today,
        onManageHealth: () {
          calls++;
          return result.future;
        })));
    final action = find.byKey(const ValueKey('activity-setup-steps'));
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    result.complete(steps);
    await tester.pumpAndSettle();
    expect(find.text('6,840'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-steps-setup')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Failed refresh can recover while preserving recorded energy',
      (tester) async {
    phone(tester);
    var attempts = 0;
    await tester.pumpWidget(app(DailyActivityCard(
        date: today,
        now: today,
        metrics: const HomeHealthMetrics(
            date: '2026-10-28', source: 'healthkit', activeCalories: 420),
        onManageHealth: () async {
          if (++attempts == 1) throw StateError('Offline');
          return const HomeHealthMetrics(
              date: '2026-10-28',
              source: 'healthkit',
              steps: 0,
              activeCalories: 420);
        })));
    await tester.tap(find.byKey(const ValueKey('activity-setup-steps')));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Could not refresh steps. Open health settings to try again.'),
        findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('activity-setup-steps')));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.textContaining('Could not refresh'), findsNothing);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A late setup result cannot replace the newly selected day',
      (tester) async {
    phone(tester);
    final result = Completer<HomeHealthMetrics?>();
    await tester.pumpWidget(app(DailyActivityCard(
        date: today, now: today, onManageHealth: () => result.future)));
    await tester.tap(find.byKey(const ValueKey('activity-setup-steps')));
    await tester.pump();
    await tester.pumpWidget(
        app(DailyActivityCard(date: DateTime(2026, 10, 27), now: today)));
    result.complete(steps);
    await tester.pumpAndSettle();
    expect(find.text('No steps recorded for this day.'), findsOneWidget);
    expect(find.text('6,840'), findsNothing);
    expect(find.text('Set up steps'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Desktop gives a phone hint without an unsupported setup action',
      (tester) async {
    phone(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(app(DailyActivityCard(date: today, now: today)));
      await tester.pumpAndSettle();
      expect(find.text('Connect your health app on your phone to see steps.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('activity-setup-steps')), findsNothing);
      expect(find.text('—'), findsNothing);
      await capture(tester, 'steps-phone-hint');
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('German setup fits 320 px at enlarged text settings',
      (tester) async {
    phone(tester, width: 320);
    await tester.pumpWidget(app(DailyActivityCard(date: today, now: today),
        locale: 'de', scale: 1.8));
    await tester.pumpAndSettle();
    final message =
        tester.getRect(find.byKey(const ValueKey('activity-steps-message')));
    final action =
        tester.getRect(find.byKey(const ValueKey('activity-setup-steps')));
    expect(action.top, greaterThanOrEqualTo(message.bottom));
    expect(find.text('Schritte einrichten').hitTestable(), findsOneWidget);
    await capture(tester, 'steps-setup-large-de');
    expect(tester.takeException(), isNull);
  });
}
