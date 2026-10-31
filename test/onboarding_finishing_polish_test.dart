import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/components/onboarding_scaffold.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
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
      'Choose each day exposes options, fills missing days and preserves edits',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final controller = OnboardingController(
        load: () async => OnboardingDraft(
                name: 'Elena',
                experienceLevel: 'BEGINNER',
                trainingLocation: 'GYM',
                workoutDuration: 'MIN_45',
                trainingDays: [
                  'MONDAY',
                  'TUESDAY',
                  'WEDNESDAY',
                  'THURSDAY',
                  'FRIDAY'
                ]),
        save: (_) async {});
    await controller.initialize();
    var completed = false;
    await tester.pumpWidget(app(TrainingPreferencesView(
        controller: controller, onContinue: () => completed = true)));
    await tester.pumpAndSettle();
    await next(tester);
    await next(tester);
    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tap(find.byKey(const ValueKey('training-style-alternatives')));
    await tap(find.byKey(const ValueKey('training-style-CUSTOM')));
    expect(find.byKey(const ValueKey('training-style-AUTO')), findsNothing,
        reason: 'Close the style menu so the day controls are visible.');
    expect(find.byKey(const ValueKey('custom-suggest-muscles')).hitTestable(),
        findsOneWidget,
        reason: 'Scroll directly to the custom-day controls.');
    await capture(tester, 'onboarding-custom-day-start');
    expect(find.text('Choose your days in Your week above.'), findsNothing);
    expect(find.byKey(const ValueKey('custom-training-day-MONDAY')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('custom-training-day-FRIDAY')),
        findsOneWidget);
    await next(tester);
    expect(find.text('Choose at least one muscle group for each training day.'),
        findsOneWidget);
    expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .title,
        'Your training style');

    final monday = find.byKey(const ValueKey('custom-training-day-MONDAY'));
    await tap(find.descendant(of: monday, matching: find.text('Chest')));
    await tap(find.byKey(const ValueKey('custom-suggest-muscles')));
    expect(controller.draft.customTrainingSplit['MONDAY'], ['chest']);
    expect(
        controller.draft.trainingDays.every((day) =>
            controller.draft.customTrainingSplit[day]?.isNotEmpty == true),
        true);
    expect(controller.draft.customTrainingSplit['TUESDAY'], ['back', 'biceps']);
    expect(find.text('Choose at least one muscle group for each training day.'),
        findsNothing);
    await tap(find.descendant(of: monday, matching: find.text('Triceps')));
    expect(
        controller.draft.customTrainingSplit['MONDAY'], ['chest', 'triceps']);
    await tester.scrollUntilVisible(find.text('Choose each day'), -200,
        scrollable: find.byType(Scrollable).first);
    await capture(tester, 'onboarding-custom-day-options');
    await next(tester);
    expect(find.text('Final details'), findsOneWidget);
    await next(tester);
    expect(completed, true);
    final payload = controller.draft.personalizationPayload();
    expect((payload['customTrainingSplit'] as Map)['MONDAY'],
        ['chest', 'triceps']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'A custom split without weekdays has a working route to the day picker',
      (tester) async {
    final controller =
        OnboardingController(load: () async => draft(), save: (_) async {});
    await controller.initialize();
    await tester.pumpWidget(app(
        TrainingPreferencesView(controller: controller, onContinue: () {})));
    await tester.pumpAndSettle();
    await next(tester);
    await next(tester);
    // Simulate a legacy draft with a frequency but no selected weekdays.
    controller.draft.trainingDays = [];
    final alternatives =
        find.byKey(const ValueKey('training-style-alternatives'));
    await tester.ensureVisible(alternatives);
    await tester.pumpAndSettle();
    await tester.tap(alternatives);
    await tester.pumpAndSettle();
    final custom = find.byKey(const ValueKey('training-style-CUSTOM'));
    await tester.ensureVisible(custom);
    await tester.pumpAndSettle();
    await tester.tap(custom);
    await tester.pumpAndSettle();
    final chooseDays =
        find.byKey(const ValueKey('custom-choose-training-days'));
    await tester.ensureVisible(chooseDays);
    await tester.pumpAndSettle();
    await tester.tap(chooseDays);
    await tester.pumpAndSettle();
    expect(find.text('Which days work for you?'), findsOneWidget);
    expect(find.text('Select at least 2 training days to continue.'),
        findsOneWidget);
    expect(controller.draft.trainingDays, isEmpty,
        reason: 'The app must let the user choose weekdays.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

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
