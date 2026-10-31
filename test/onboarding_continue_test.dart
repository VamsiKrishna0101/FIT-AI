import 'dart:async';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/features/onboarding/components/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget screen(FutureOr<void> Function() action) => MaterialApp(
    home: OnboardingScaffold(
        step: 1,
        sectionLabel: 'About you',
        title: 'Your starting point',
        subtitle: '',
        actionTitle: 'Continue',
        onContinue: action,
        children: const []));

void main() {
  testWidgets(
      'Continue locks immediately and stays busy until the save finishes',
      (tester) async {
    final saved = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(screen(() async {
      calls++;
      await saved.future;
    }));
    final button = find.byType(LiquidChromeButton);
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Continuing…'), findsOneWidget);
    expect(tester.widget<LiquidChromeButton>(button).onPressed, isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(button);
    expect(calls, 1);
    saved.complete();
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.widget<LiquidChromeButton>(button).onPressed, isNotNull);
  });

  testWidgets('Local question transitions cannot be skipped by repeated taps',
      (tester) async {
    var part = 0;
    await tester.pumpWidget(screen(() {
      part++;
    }));
    final button = find.byType(LiquidChromeButton);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 90));
    expect(part, 1);
    expect(find.text('Continuing…'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(part, 2);
  });

  testWidgets('A handled save failure lets the user retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(screen(() async {
      calls++;
      try {
        await Future<void>.error(StateError('offline'));
      } catch (_) {}
    }));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Closing a step cancels its transition timer', (tester) async {
    final saved = Completer<void>();
    await tester.pumpWidget(screen(() => saved.future));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    saved.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
