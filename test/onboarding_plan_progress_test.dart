import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/planner/views/widgets/plan_particle_orb.dart';
import 'package:setcraft/core/localization/plan_checkout_copy.dart';

Widget app(int percent,
        {bool active = true, bool reduced = false, VoidCallback? done}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Center(
                child: SizedBox(
                    width: 220,
                    child: PlanParticleOrb(
                        percent: percent,
                        animating: active,
                        onComplete: done)))));
int value(WidgetTester tester) => int.parse(tester
    .widget<Text>(find.byKey(const ValueKey('plan-progress-label')))
    .data!
    .replaceAll('%', ''));
void main() {
  testWidgets(
      'Progress visits every integer and never passes confirmed server progress',
      (tester) async {
    await tester.pumpWidget(app(8));
    expect(value(tester), 0);
    for (var n = 1; n <= 8; n++) {
      await tester.pump(const Duration(milliseconds: 24));
      expect(value(tester), n);
    }
    await tester.pump(const Duration(seconds: 1));
    expect(value(tester), 8);
    await tester.pumpWidget(app(23));
    for (var n = 9; n <= 23; n++) {
      await tester.pump(const Duration(milliseconds: 24));
      expect(value(tester), n);
    }
    await tester.pumpWidget(app(12));
    await tester.pump(const Duration(milliseconds: 100));
    expect(value(tester), 23);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Counter pauses in background and completes once at 100',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(app(100, active: false, done: () => completed++));
    await tester.pump(const Duration(seconds: 1));
    expect(value(tester), 0);
    expect(completed, 0);
    await tester.pumpWidget(app(100, done: () => completed++));
    for (var n = 1; n <= 100; n++) {
      await tester.pump(const Duration(milliseconds: 24));
      expect(value(tester), n);
    }
    await tester.pump();
    expect(completed, 1);
    await tester.pumpWidget(app(100, done: () => completed++));
    await tester.pump(const Duration(milliseconds: 100));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Reduced motion shows confirmed progress immediately',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(app(63, reduced: true));
    expect(value(tester), 63);
    await tester.pumpWidget(app(100, reduced: true, done: () => completed++));
    await tester.pump();
    expect(value(tester), 100);
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
  });
  test('Checkout and age copy cover every language family', () {
    for (final language in ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it']) {
      for (final phrase in [
        'Your plan is ready',
        'View full week',
        'Choose your membership',
        'Start my 14-day trial',
        'How old are you?',
        'Continue with monthly',
        'Continue with yearly',
        'Billed {price} · auto-renews'
      ]) {
        final translation = planCheckoutTranslation(language, phrase);
        expect(translation, isNotNull);
        expect(translation, isNot(phrase));
        if (phrase.contains('{price}')) {
          expect(translation, contains('{price}'));
        }
      }
    }
  });
}
