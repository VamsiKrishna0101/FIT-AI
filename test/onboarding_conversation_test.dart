import 'package:setcraft/features/onboarding/components/biometric_ruler_card.dart';
import 'package:setcraft/features/onboarding/components/onboarding_question_reveal.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
import 'package:setcraft/features/onboarding/views/onboarding_view.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/components/onboarding_scaffold.dart';
import 'package:setcraft/features/onboarding/components/onboarding_chrome.dart';
import 'package:setcraft/features/onboarding/views/onboarding_journey.dart';
import 'package:setcraft/features/onboarding/views/goal_selection_view.dart';
import 'package:setcraft/features/onboarding/views/about_you_experience_view.dart';
import 'package:setcraft/features/onboarding/views/equipment_selection_view.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/features/auth/views/auth_view.dart';

const boundary = ValueKey('conversation-preview');
Widget app(Widget child,
        {double scale = 1, Locale locale = const Locale('en', 'GB')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('de', 'DE'),
        Locale('fr', 'FR')
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      builder: (context, child) => RepaintBoundary(
          key: boundary,
          child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale)),
              child: child!)),
      home: child,
    );
Future<void> capture(WidgetTester tester, String name) =>
    tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
          .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/conversation-preview/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
void main() {
  setUpAll(() async {
    for (final f in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(f.key)..addFont(rootBundle.load(f.value))).load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
  });
  Future<OnboardingController> model({String language = 'en'}) async {
    final c = OnboardingController(
        load: () async => OnboardingDraft(languageCode: language),
        save: (_) async {});
    await c.initialize();
    return c;
  }

  void phone(WidgetTester tester, [Size size = const Size(393, 852)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pick(WidgetTester tester, int index) async {
    final f = find
        .descendant(
            of: find.byType(OnboardingChoice).at(index),
            matching: find.byType(InkWell))
        .first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    final error = tester.takeException();
    expect(error, isNull);
  }

  Future<void> next(WidgetTester tester) async {
    final action = tester
        .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
        .onContinue;
    expect(action, isNotNull);
    await Future<void>.sync(action!);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
      'Answer bubbles share a right edge, fit content and advance only once',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pumpAndSettle();
    expect(find.text('What’s your main\nfitness goal?'), findsOneWidget);
    final bubbles = find.byType(OnboardingChoice);
    final first =
        find.descendant(of: bubbles.first, matching: find.byType(InkWell));
    final last =
        find.descendant(of: bubbles.last, matching: find.byType(InkWell));
    expect(
        tester.getRect(first).right, closeTo(tester.getRect(last).right, .1));
    expect(tester.getSize(first).width,
        isNot(closeTo(tester.getSize(last).width, .1)));
    await capture(tester, '02-goal');
    await tester.tap(first);
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(c.draft.workingToward, 'BUILD_MUSCLE');
    expect(find.byType(AboutYouExperienceView), findsOneWidget);
    expect(find.byType(TextField), findsNothing,
        reason: 'Experience comes before profile forms.');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('Age requires an explicit valid answer without body measurements',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(AboutYouExperienceView(
        controller: c, coaching: true, questionParts: const [4])));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .onContinue,
        isNull);
    await tester.enterText(find.byKey(const ValueKey('onboarding-age')), '12');
    await tester.pumpAndSettle();
    expect(find.text('Enter an age from 13 to 100'), findsOneWidget);
    expect(c.draft.age, isNull);
    await tester.enterText(find.byKey(const ValueKey('onboarding-age')), '30');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .onContinue,
        isNotNull);
    expect(c.draft.age, 30);
    expect(c.draft.heightCm, isNull);
    expect(c.draft.weightKg, isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
      'The complete coached journey preserves answers through registration',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pumpAndSettle();
    await pick(tester, 0);
    await capture(tester, '03-experience');
    await pick(tester, 0);
    await capture(tester, '04-location');
    expect(c.draft.experienceLevel, 'BEGINNER');
    await pick(tester, 0);
    expect(find.byType(EquipmentSelectionView), findsOneWidget);
    final equipmentContext =
        tester.element(find.byType(EquipmentSelectionView));
    final equipmentImages =
        tester.widgetList<Image>(find.byType(Image)).toList();
    await tester.runAsync(() async {
      for (final image in equipmentImages) {
        await precacheImage(image.image, equipmentContext);
      }
    });
    await tester.pumpAndSettle();
    await capture(tester, '05-equipment');
    await next(tester);
    await capture(tester, '06-frequency');
    await pick(tester, 1);
    await capture(tester, '07-duration');
    await pick(tester, 1);
    await capture(tester, '08-week');
    for (final day in ['Mon', 'Wed', 'Fri']) {
      final f = find.byKey(ValueKey('training-choice-$day'));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }
    await next(tester);
    await capture(tester, '09-style');
    await next(tester);
    await capture(tester, '10-name');
    await tester.enterText(find.byType(TextField), 'Nora');
    await tester.pump();
    await next(tester);
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/onboarding_bodies/female-front.png'),
        tester.element(find.byType(AboutYouExperienceView))));
    await capture(tester, '11-body-style');
    final female = find.byKey(const ValueKey('onboarding-gender-FEMALE'));
    await tester.ensureVisible(female);
    await tester.tap(female);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('onboarding-age')), '30');
    await tester.pump();
    await capture(tester, '12-age');
    await next(tester);
    await capture(tester, '13-focus');
    await next(tester);
    await capture(tester, '14-activity');
    await pick(tester, 0);
    await capture(tester, '15-sleep');
    await pick(tester, 2);
    await capture(tester, '16-nutrition');
    await pick(tester, 0);
    await capture(tester, '17-limitations');
    await next(tester);
    await capture(tester, '18-final-details');
    await next(tester);
    expect(find.byType(AuthView), findsOneWidget);
    await capture(tester, '19-create-account');
    expect(c.draft.name, 'Nora');
    expect(c.draft.gender, 'FEMALE');
    expect(c.draft.trainingDays, ['MONDAY', 'WEDNESDAY', 'FRIDAY']);
    expect(c.draft.equipmentIds, ['bodyweight_only']);
    expect(c.draft.completedStep, 7);
    expect(c.draft.heightCm, isNull);
    expect(c.draft.weightKg, isNull);
    expect(c.draft.age, 30);
    expect(c.draft.experienceLevel, 'BEGINNER');
    await tester.tap(find.textContaining('Already have an account?'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await capture(tester, '20-sign-in');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('Back navigation restores the selected answer', (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pumpAndSettle();
    await pick(tester, 0);
    await tester.tap(find.byType(OnboardingBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(GoalSelectionView), findsOneWidget);
    expect(
        tester
            .widget<OnboardingChoice>(find.byType(OnboardingChoice).first)
            .selected,
        isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
      'Long translated answers and large text remain usable on a narrow phone',
      (tester) async {
    phone(tester, const Size(320, 640));
    final c = await model(language: 'de');
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await tester.pumpWidget(app(OnboardingJourney.start(c),
        scale: 1.6, locale: const Locale('de', 'DE')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'goal-narrow-german');
    await pick(tester, 0);
    expect(find.byType(AboutYouExperienceView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
      'Message uses a readable pace, then all answers appear without moving',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: OnboardingScaffold(
          step: 2,
          sectionLabel: '',
          title: 'What is your goal?',
          subtitle: '',
          greeting: 'Let’s build your plan.',
          previousAnswer: 'Old answer must not appear',
          actionTitle: 'Continue',
          showContinue: false,
          children: [
            OnboardingChoice(
                title: 'Get stronger', selected: false, onTap: () {})
          ],
        )));
    final answer = find
        .descendant(
            of: find.byType(OnboardingChoice), matching: find.byType(InkWell))
        .first;
    final originalRect = tester.getRect(answer);
    expect(find.text('Old answer must not appear'), findsNothing);
    expect(answer.hitTestable(), findsNothing);
    await tester.pump(const Duration(milliseconds: 760));
    expect(answer.hitTestable(), findsNothing);
    await tester.pump(const Duration(milliseconds: 1241));
    expect(answer.hitTestable(), findsOneWidget);
    expect(tester.getRect(answer), originalRect);
    expect(tester.hasRunningAnimations, isFalse);
  });
  test('Reveal timing follows text length and caps long translations', () {
    expect(OnboardingQuestionReveal.durationFor('Short question?'),
        const Duration(seconds: 1));
    expect(OnboardingQuestionReveal.durationFor('x' * 50),
        const Duration(milliseconds: 1600));
    expect(OnboardingQuestionReveal.durationFor('x' * 300),
        const Duration(seconds: 2));
  });
  testWidgets('Reduced motion shows the full question and answers immediately',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pump();
    expect(
        find
            .descendant(
                of: find.byType(OnboardingChoice).first,
                matching: find.byType(InkWell))
            .first
            .hitTestable(),
        findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('Back stays within the requested question group before popping',
      (tester) async {
    phone(tester);
    final c = await model();
    c.draft.trainingDays = ['MONDAY', 'WEDNESDAY', 'FRIDAY'];
    await tester.pumpWidget(app(Builder(
        builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => TrainingPreferencesView(
                            controller: c,
                            coaching: true,
                            questionParts: const [1, 2],
                            onContinue: () {}))),
                child: const Text('Open preferences'))))));
    await tester.tap(find.text('Open preferences'));
    await tester.pumpAndSettle();
    await next(tester);
    expect(
        find.text('Do you have a preferred training split?'), findsOneWidget);
    await tester.tap(find.byType(OnboardingBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Which days work for you?'), findsOneWidget);
    await tester.tap(find.byType(OnboardingBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open preferences'), findsOneWidget);
    expect(find.text('What do you want to focus on?'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('Measurements show four rows and edit one value at a time',
      (tester) async {
    phone(tester);
    final c = await model();
    c.draft
      ..heightCm = 178
      ..weightKg = 80
      ..targetWeightKg = 77
      ..age = 30
      ..name = 'Nora';
    await tester.pumpWidget(app(AboutYouExperienceView(
        controller: c,
        coaching: true,
        questionParts: const [2],
        onContinue: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Your body stats'), findsOneWidget);
    expect(find.byType(BiometricRulerCard), findsNothing);
    expect(find.text('BIOMETRICS'), findsNothing);
    await capture(tester, 'measurements-refined');
    final oldWeight = c.draft.weightKg;
    final oldHeight = c.draft.heightCm;
    for (final metric in ['weight', 'height', 'age', 'target']) {
      final row = find.byKey(ValueKey('select-biometric-$metric'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(BiometricRulerCard), findsOneWidget);
      expect(
          tester
              .widget<BiometricRulerCard>(find.byType(BiometricRulerCard))
              .plain,
          isTrue);
      await tester.drag(find.byKey(const ValueKey('biometric-ruler-track')),
          const Offset(-50, 0));
      await tester.pumpAndSettle();
      if (metric == 'weight') await capture(tester, 'measurements-editor');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(BiometricRulerCard), findsNothing);
    }
    expect(c.draft.weightKg, isNot(oldWeight));
    expect(c.draft.heightCm, isNot(oldHeight));
    expect(c.draft.age, greaterThan(30));
    expect(c.draft.targetWeightKg, isNot(77));
    final storedWeight = c.draft.weightKg, storedHeight = c.draft.heightCm;
    await tester.tap(find.text('cm / kg'));
    await tester.pumpAndSettle();
    expect(c.draft.weightKg, storedWeight);
    expect(c.draft.heightCm, storedHeight);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
      'Measurement rows and editor fit large German text on a narrow phone',
      (tester) async {
    phone(tester, const Size(320, 640));
    final c = await model(language: 'de');
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await tester.pumpWidget(app(
        AboutYouExperienceView(
            controller: c,
            coaching: true,
            questionParts: const [2],
            onContinue: () {}),
        scale: 1.6,
        locale: const Locale('de', 'DE')));
    await tester.pumpAndSettle();
    await capture(tester, 'measurements-narrow-german');
    for (final metric in ['age', 'height', 'weight', 'target']) {
      final row = find.byKey(ValueKey('select-biometric-$metric'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(BiometricRulerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (metric == 'weight') {
        await capture(tester, 'measurements-editor-narrow-german');
      }
      final done = find.text('Fertig');
      await tester.ensureVisible(done);
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
      'Entry has only a short headline and controls, with no background image',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingView(controller: c)));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Train smarter.\nGet stronger.'), findsOneWidget);
    expect(find.text('BUILT AROUND YOU'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    await capture(tester, '01-entry');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
