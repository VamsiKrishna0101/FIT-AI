import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/components/liquid_chrome_button.dart';
import 'package:fitai_mobile/core/components/liquid_silver_bottom_bar.dart';
import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_focus_body.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_scaffold.dart';
import 'package:fitai_mobile/features/onboarding/views/discovery_onboarding_gate.dart';
import 'package:fitai_mobile/features/onboarding/data/discovery_repository.dart';
import 'package:fitai_mobile/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:fitai_mobile/features/onboarding/views/about_you_experience_view.dart';
import 'package:fitai_mobile/features/onboarding/views/schedule_location_view.dart';
import 'package:fitai_mobile/features/onboarding/views/lifestyle_nutrition_limitations_view.dart';
import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';
import 'package:fitai_mobile/features/onboarding/views/onboarding_view.dart';

const _preview = ValueKey('redesign-preview');
Widget app(Widget child, {double scale = 1}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Builder(
        builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: _preview, child: child))));

Future<void> next(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byType(LiquidChromeButton));
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(_preview))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/onboarding-redesign/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class Survey extends DiscoveryRepository {
  final answers = <String?>[];
  bool done = false, fail = false;
  static int _counter = 0;
  String account = 'survey-test-${_counter++}';
  @override
  Future<String?> owner() async => account;
  @override
  Future<bool> completed(String user) async => done;
  @override
  Future<void> save(String user, String? source) async {
    if (user != account || fail) throw StateError('Unavailable');
    answers.add(source);
    done = true;
  }
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
  });

  Future<OnboardingController> controller([OnboardingDraft? draft]) async {
    final model = OnboardingController(
        load: () async => draft ?? OnboardingDraft(), save: (_) async {});
    await model.initialize();
    return model;
  }

  testWidgets(
      'Profile steps validate names, preserve details and go back within the flow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final model = await controller(OnboardingDraft(
        heightCm: 168, weightKg: 64, age: 28, targetWeightKg: 62));
    var continued = false;
    await tester.pumpWidget(app(AboutYouExperienceView(
        controller: model, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-country')), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(model.draft.countryCode, 'ZZ');
    expect(OnboardingDraft.fromJson({}).countryCode, 'ZZ');
    expect(OnboardingDraft.fromJson({'countryCode': 'DK'}).countryCode, 'DK');
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField).first, 'Nora');
    await tester.pump();
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .onPressed,
        isNotNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await next(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding-gender-FEMALE')));
    await tester.pumpAndSettle();
    expect(model.draft.gender, 'FEMALE');
    await tester.runAsync(() async {
      final context = tester.element(find.byType(AboutYouExperienceView));
      await Future.wait([
        for (final sex in ['male', 'female'])
          precacheImage(
              AssetImage('assets/onboarding_bodies/$sex-front.png'), context)
      ]);
    });
    await tester.pumpAndSettle();
    await capture(tester, 'body-selection');
    await next(tester);
    expect(
        find.byKey(const ValueKey('select-biometric-height')), findsOneWidget);
    await capture(tester, 'measurements');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('onboarding-gender-FEMALE')), findsOneWidget);
    await next(tester);
    await next(tester);
    expect(
        tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold)).part,
        3);
    await next(tester);
    expect(continued, isTrue);
    expect(model.draft.name, 'Nora');
    expect(model.draft.heightCm, 168);
    expect(model.draft.weightKg, 64);
    expect(model.draft.targetWeightKg, 62);
    expect(model.draft.age, 28);
    expect(model.draft.completedStep, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets(
      'Schedule choices are required per page and saved without inventing weekdays',
      (tester) async {
    final model = await controller();
    var continued = false;
    await tester.pumpWidget(app(ScheduleLocationView(
        controller: model, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .onPressed,
        isNull);
    await tester.tap(find.text('3 days a week'));
    await next(tester);
    await tester.tap(find.byType(OnboardingChoice).at(2));
    await next(tester);
    await tester.tap(find.byType(OnboardingChoice).at(1));
    await next(tester);
    expect(continued, isTrue);
    expect(model.draft.daysPerWeek, 'DAYS_3');
    expect(model.draft.workoutDuration, 'MIN_45');
    expect(model.draft.trainingLocation, 'HOME');
    expect(model.draft.trainingDays, isEmpty);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets(
      'Muscle buttons and body taps share red highlighting and stored IDs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final model = await controller(OnboardingDraft(gender: 'FEMALE'));
    var continued = false;
    await tester.pumpWidget(app(TrainingPreferencesView(
        controller: model, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('training-choice-Chest')));
    await tester.pumpAndSettle();
    final front = tester
        .widget<OnboardingFocusFigure>(find.byType(OnboardingFocusFigure));
    expect(front.female, isTrue);
    expect(front.asset, onboardingBodyAsset(female: true));
    expect(front.activation['chest'], 1);
    expect(front.activation['shoulders'] ?? 0, 0);
    expect(model.draft.focusMuscles, ['chest']);
    await capture(tester, 'muscle-focus');
    final mapFinder = find.byType(OnboardingFocusFigure);
    final paths = onboardingFocusPaths(back: false, female: true)['shoulders']!;
    final path = paths.first;
    final bounds = path.getBounds();
    Offset? inside;
    for (var x = bounds.left; x < bounds.right && inside == null; x += .5) {
      for (var y = bounds.top; y < bounds.bottom; y += .5) {
        if (path.contains(Offset(x, y))) {
          inside = Offset(x, y);
          break;
        }
      }
    }
    final point = inside!;
    await Scrollable.ensureVisible(tester.element(mapFinder), alignment: .1);
    await tester.pumpAndSettle();
    final rect = tester.getRect(mapFinder);
    final scale = rect.height / 1536;
    await tester.tapAt(rect.topLeft +
        Offset((rect.width - 1024 * scale) / 2, 0) +
        point * scale);
    await tester.pumpAndSettle();
    expect(model.draft.focusMuscles, contains('shoulders'));
    await next(tester);
    await next(tester);
    await next(tester);
    await next(tester);
    expect(continued, isTrue);
    expect(model.draft.focusMuscles, containsAll(['chest', 'shoulders']));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('Lifestyle steps preserve activity, sleep, diet and limitations',
      (tester) async {
    final model = await controller();
    var continued = false;
    await tester.pumpWidget(app(LifestyleNutritionLimitationsView(
        controller: model, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OnboardingChoice).last);
    await tester.scrollUntilVisible(find.text('6–7 hrs'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('6–7 hrs'));
    await next(tester);
    await tester.tap(find.byType(OnboardingChoice).at(3));
    await next(tester);
    await tester.tap(find.byType(OnboardingChoice).at(2));
    await next(tester);
    expect(continued, isTrue);
    expect(model.draft.activityLevel, 'HIGH');
    expect(model.draft.sleepDuration, 'HOURS_6_TO_7');
    expect(model.draft.eatingStyle, 'VEGAN');
    expect(model.draft.limitations, ['KNEE']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets(
      'Welcome, every profile page and the dock fit a narrow large-text phone',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final model = await controller(OnboardingDraft(name: 'Nora'));
    await tester.pumpWidget(app(OnboardingView(controller: model), scale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(
        AboutYouExperienceView(controller: model, onContinue: () {}),
        scale: 1.6));
    await tester.pumpAndSettle();
    for (var page = 0; page < 4; page++) {
      expect(tester.takeException(), isNull);
      expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
      await next(tester);
    }
    await tester.pumpWidget(app(
        Scaffold(
            bottomNavigationBar: LiquidSilverBottomBar(
                selectedIndex: 2,
                labels: const ['Today', 'Train', 'Body', 'Progress'],
                onTabSelected: (_) {})),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('Optional survey retries safely and records a single answer',
      (tester) async {
    final repo = Survey()..fail = true;
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Plan preview')))));
    await tester.pumpAndSettle();
    expect(find.text('Plan preview'), findsNothing);
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    expect(repo.answers, isEmpty);
    await next(tester);
    expect(find.text('Could not save your answer. Try again.'), findsOneWidget);
    repo.fail = false;
    await next(tester);
    expect(repo.answers, ['INSTAGRAM']);
    expect(find.text('Plan preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dismissal is optional, remembered and scoped to the account',
      (tester) async {
    final repo = Survey();
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Plan preview')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skip-discovery')));
    await tester.pumpAndSettle();
    expect(repo.answers, [null]);
    await tester.pumpWidget(const SizedBox());
    repo.done = false;
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Plan preview')))));
    await tester.pumpAndSettle();
    expect(find.text('Plan preview'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    repo.account = 'another-account';
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Plan preview')))));
    await tester.pumpAndSettle();
    expect(
        find.text('Where did you first hear about Setcraft?'), findsOneWidget);
  });

  testWidgets('Capture welcome and bottom navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final model = await controller();
    await tester.pumpWidget(app(OnboardingView(controller: model)));
    await tester.pumpAndSettle();
    await capture(tester, 'welcome');
    await tester.pumpWidget(app(Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: LiquidSilverBottomBar(
            selectedIndex: 2,
            labels: const ['Today', 'Train', 'Body', 'Progress'],
            onTabSelected: (_) {}))));
    await tester.pumpAndSettle();
    await capture(tester, 'navigation');
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
