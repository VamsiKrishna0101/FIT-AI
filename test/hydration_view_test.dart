import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/views/hydration_view.dart';
import 'nutrition_view_test.dart' show app, plan, capture;

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
  final today = DateTime(2026, 10, 28);
  testWidgets(
      'Water saves once, disables both actions, then shows confirmed total',
      (tester) async {
    final save = Completer<bool>();
    var calls = 0, loads = 0;
    await tester.pumpWidget(app(HydrationView(
        date: today,
        clock: () => today,
        loader: () async =>
            plan.copyWith(waterConsumed: loads++ == 0 ? 750 : 1000),
        logWater: (ml) {
          calls++;
          expect(ml, 250);
          return save.future;
        })));
    await tester.pumpAndSettle();
    expect(find.text('0.75 L'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-water-250')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-water-500')));
    expect(calls, 1);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('add-water-500')))
            .onPressed,
        isNull);
    save.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('1 L'), findsOneWidget);
    expect(find.text('Water saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed save preserves intake and allows retry', (tester) async {
    await tester.pumpWidget(app(HydrationView(
        date: today,
        clock: () => today,
        loader: () async => plan,
        logWater: (_) async => false)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-water-500')));
    await tester.pumpAndSettle();
    expect(find.text('0.75 L'), findsOneWidget);
    expect(find.text('Could not save. Try again.'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('add-water-500')))
            .onPressed,
        isNotNull);
  });

  testWidgets('Committed water survives failed or stale refresh',
      (tester) async {
    var loads = 0;
    await tester.pumpWidget(app(HydrationView(
        date: today,
        clock: () => today,
        loader: () async {
          if (loads++ > 0) throw StateError('offline');
          return plan;
        },
        logWater: (_) async => true)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-water-250')));
    await tester.pumpAndSettle();
    expect(find.text('1 L'), findsOneWidget);
    expect(find.text('Water saved'), findsOneWidget);
    expect(find.text('Showing last saved intake.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Previous days are read only and midnight prevents another save',
      (tester) async {
    var now = today;
    var calls = 0;
    await tester.pumpWidget(app(HydrationView(
        date: today,
        clock: () => now,
        loader: () async => plan,
        logWater: (_) async {
          calls++;
          return true;
        })));
    await tester.pumpAndSettle();
    now = today.add(const Duration(days: 1));
    await tester.tap(find.byKey(const ValueKey('add-water-250')));
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(HydrationView(
        date: today, clock: () => now, loader: () async => plan)));
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Read-only'), findsOneWidget);
  });

  testWidgets(
      'Water supports narrow screens, large text and an honest unknown state',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(
        HydrationView(
            date: today, clock: () => today, loader: () async => plan),
        scale: 1.8));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(HydrationView(
        date: today, clock: () => today, loader: () async => null)));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Could not load water.'), findsOneWidget);
    expect(find.text('0 L'), findsNothing);
  });

  testWidgets('Capture the separate water screen', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(HydrationView(
        date: today,
        clock: () => today,
        loader: () async => plan.copyWith(waterConsumed: 1750))));
    await tester.pumpAndSettle();
    await capture(tester, 'build/hydration-preview.png');
  });
}
