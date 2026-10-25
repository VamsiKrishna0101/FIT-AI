import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/components/liquid_chrome_button.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_scaffold.dart';
import 'package:fitai_mobile/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';
import 'onboarding_focus_body_test.dart' show app, capture;

Future<void> next(WidgetTester tester) async {
  tester
      .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
      .onContinue!();
  await tester.pumpAndSettle();
}

OnboardingDraft draft() => OnboardingDraft(
    gender: 'FEMALE',
    experienceLevel: 'BEGINNER',
    trainingLocation: 'GYM',
    daysPerWeek: 'DAYS_3',
    trainingDays: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
    workoutDuration: 'MIN_45',
    customLimitations: 'Avoid overhead movements',
    foodAllergies: ['Peanuts'],
    customWeeklyFoodBudget: 40,
    foodBudgetCurrency: 'EUR');
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
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'Compact style and optional final details preserve data and reopen validation errors',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final controller =
        OnboardingController(load: () async => draft(), save: (_) async {});
    await controller.initialize();
    var completed = false;
    await tester.pumpWidget(app(TrainingPreferencesView(
        controller: controller, onContinue: () => completed = true)));
    await tester.pumpAndSettle();
    await next(tester);
    await next(tester);
    expect(find.text('Your training style'), findsOneWidget);
    expect(find.text('Muscle focus days'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.textContaining('Based on your experience'), findsNothing);
    expect(find.textContaining('Also includes'), findsNothing);
    expect(find.textContaining('Muscle focus preview'), findsNothing);
    await capture(tester, 'onboarding-training-style');
    await next(tester);
    expect(find.text('Final details'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsNothing);
    expect(find.text('Edit'), findsNWidgets(2));
    await capture(tester, 'onboarding-final-details');
    await tester.tap(find.text('Movement notes'));
    await tester.pumpAndSettle();
    final notes = find.byType(TextField);
    expect(tester.widget<TextField>(notes).controller!.text,
        'Avoid overhead movements');
    await tester.enterText(notes, 'Avoid overhead presses');
    tester.testTextInput.hide();
    await tester.tap(find.text('Movement notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food preferences'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    expect(tester.widget<TextField>(field('Food allergies')).controller!.text,
        'Peanuts');
    await tester.enterText(field('Food allergies'), 'Peanuts, shellfish');
    await tester.ensureVisible(field('Weekly food budget'));
    await tester.enterText(field('Weekly food budget'), '-4');
    tester.testTextInput.hide();
    await next(tester);
    expect(completed, false);
    expect(find.text('Enter a valid weekly budget, or leave it blank.'),
        findsOneWidget);
    expect(field('Weekly food budget'), findsOneWidget);
    await tester.ensureVisible(field('Weekly food budget'));
    await tester.enterText(field('Weekly food budget'), '60');
    tester.testTextInput.hide();
    await next(tester);
    expect(completed, true);
    expect(controller.draft.customLimitations, 'Avoid overhead presses');
    expect(controller.draft.foodAllergies, ['Peanuts', 'shellfish']);
    expect(controller.draft.customWeeklyFoodBudget, 60);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('Compact final steps fit a narrow phone with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.reset);
    final controller =
        OnboardingController(load: () async => draft(), save: (_) async {});
    await controller.initialize();
    await tester.pumpWidget(app(
        TrainingPreferencesView(controller: controller, onContinue: () {}),
        textScale: 1.6));
    await tester.pumpAndSettle();
    await next(tester);
    await next(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
    await capture(tester, 'onboarding-training-style-large');
    await next(tester);
    expect(find.byType(TextField).hitTestable(), findsNothing);
    expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
    await capture(tester, 'onboarding-final-details-large');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
