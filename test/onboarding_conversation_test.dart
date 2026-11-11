import 'package:setcraft/features/onboarding/views/schedule_location_view.dart';
import 'package:setcraft/features/onboarding/views/lifestyle_nutrition_limitations_view.dart';
import 'package:setcraft/features/onboarding/components/coach_mascot.dart';
import 'package:setcraft/features/onboarding/components/welcome_coach_stage.dart';
import 'package:setcraft/features/onboarding/components/onboarding_progress_bar.dart';
import 'package:setcraft/features/onboarding/components/biometric_ruler_card.dart';
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
    expect(tester.takeException(), isNull);
  }

  Future<void> next(WidgetTester tester) async {
    final action = tester
        .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
        .onContinue;
    expect(action, isNotNull);
    await tester.tap(find
        .descendant(
            of: find.byType(OnboardingContinueButton),
            matching: find.byType(InkWell))
        .first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> warmImages(WidgetTester tester) async {
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final context = tester.element(find.byType(OnboardingScaffold));
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Original full-width choices wait for Continue and retain selection on Back',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingProgressBar), findsOneWidget);
    final choices = find.byType(OnboardingChoice);
    expect(tester.getSize(choices.first).width,
        closeTo(tester.getSize(choices.last).width, .1));
    await pick(tester, 2);
    expect(c.draft.workingToward, 'GET_STRONGER');
    expect(find.byType(GoalSelectionView), findsOneWidget);
    await tester.drag(
        find.byKey(const ValueKey('onboarding-scroll')), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await capture(tester, 'restored-02-goal');
    await next(tester);
    expect(find.byType(AboutYouExperienceView), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byType(OnboardingBackButton));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OnboardingChoice>(find.byType(OnboardingChoice).at(2))
            .selected,
        isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
      'Original setup reaches account creation without asking for body measurements',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingJourney.start(c)));
    await tester.pumpAndSettle();
    await pick(tester, 0);
    await next(tester);
    await tester.enterText(find.byType(TextField), 'Nora');
    await tester.pump();
    await next(tester);
    await tester
        .ensureVisible(find.byKey(const ValueKey('onboarding-gender-FEMALE')));
    await tester.tap(find.byKey(const ValueKey('onboarding-gender-FEMALE')));
    await tester.pumpAndSettle();
    await warmImages(tester);
    await capture(tester, 'restored-04-profile');
    await next(tester);
    expect(find.byType(BiometricRulerCard), findsNothing);
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
    await next(tester);
    await pick(tester, 0);
    await next(tester);
    expect(find.byType(ScheduleLocationView), findsOneWidget);
    await pick(tester, 1);
    await next(tester);
    await pick(tester, 1);
    await next(tester);
    await pick(tester, 0);
    await next(tester);
    expect(find.byType(EquipmentSelectionView), findsOneWidget);
    await warmImages(tester);
    await capture(tester, 'restored-08-equipment');
    await next(tester);
    expect(find.byType(LifestyleNutritionLimitationsView), findsOneWidget);
    await pick(tester, 2);
    final sleep = find.text('6–7 hrs');
    await tester.ensureVisible(sleep);
    await tester.pumpAndSettle();
    await tester.tap(sleep);
    await next(tester);
    await pick(tester, 0);
    await next(tester);
    await next(tester);
    expect(find.byType(TrainingPreferencesView), findsOneWidget);
    await next(tester);
    for (final day in ['Mon', 'Wed', 'Fri']) {
      final f = find.byKey(ValueKey('training-choice-$day'));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }
    await next(tester);
    await capture(tester, 'restored-13-training-style');
    await next(tester);
    await next(tester);
    expect(find.byType(AuthView), findsOneWidget);
    await capture(tester, 'restored-15-create-account');
    expect(c.draft.name, 'Nora');
    expect(c.draft.gender, 'FEMALE');
    expect(c.draft.age, 30);
    expect(c.draft.heightCm, isNull);
    expect(c.draft.weightKg, isNull);
    expect(c.draft.targetWeightKg, isNull);
    expect(c.draft.trainingDays, ['MONDAY', 'WEDNESDAY', 'FRIDAY']);
    expect(c.draft.experienceLevel, 'BEGINNER');
    expect(c.draft.equipmentIds, ['bodyweight_only']);
    expect(c.draft.completedStep, 7);
    await tester.tap(find.textContaining('Already have an account?'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await capture(tester, 'restored-16-sign-in');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Original questions fit a narrow phone with large German text',
      (tester) async {
    phone(tester, const Size(320, 640));
    final c = await model(language: 'de');
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await tester.pumpWidget(app(OnboardingJourney.start(c),
        scale: 1.6, locale: const Locale('de', 'DE')));
    await tester.pumpAndSettle();
    await capture(tester, 'restored-goal-narrow-german');
    await pick(tester, 0);
    await next(tester);
    expect(find.byType(AboutYouExperienceView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
      'Welcome greets with Mochi, its promise and the Get started action',
      (tester) async {
    phone(tester);
    final c = await model();
    await tester.pumpWidget(app(OnboardingView(controller: c)));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeCoachStage), findsOneWidget);
    expect(find.byType(CoachHero), findsOneWidget);
    expect(find.text("Hi! I'm Mochi, your AI coach"), findsOneWidget);
    expect(find.text('Your plan, built around you.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final spec in [
    (
      name: 'small',
      size: const Size(320, 568),
      scale: 1.0,
      locale: const Locale('en', 'GB'),
      notch: 20.0
    ),
    (
      name: 'phone',
      size: const Size(393, 852),
      scale: 1.0,
      locale: const Locale('en', 'GB'),
      notch: 44.0
    ),
    (
      name: 'large',
      size: const Size(430, 932),
      scale: 1.0,
      locale: const Locale('en', 'GB'),
      notch: 59.0
    ),
    (
      name: 'large-text-fr',
      size: const Size(393, 852),
      scale: 1.5,
      locale: const Locale('fr', 'FR'),
      notch: 44.0
    ),
  ]) {
    testWidgets('Welcome fits ${spec.name}', (tester) async {
      phone(tester, spec.size);
      tester.view.padding = FakeViewPadding(top: spec.notch, bottom: 24);
      tester.view.viewPadding = FakeViewPadding(top: spec.notch, bottom: 24);
      final c = await model(language: spec.locale.languageCode);
      await tester.pumpWidget(app(OnboardingView(controller: c),
          scale: spec.scale, locale: spec.locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeCoachStage), findsOneWidget);
      if (spec.scale == 1) {
        expect(
            tester
                .getRect(find.byKey(const ValueKey('welcome-get-started')))
                .bottom,
            lessThanOrEqualTo(spec.size.height - 24));
      }
      await capture(tester, 'welcome-coach-${spec.name}');
      await tester
          .ensureVisible(find.byKey(const ValueKey('welcome-get-started')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome-get-started')).hitTestable(),
          findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
