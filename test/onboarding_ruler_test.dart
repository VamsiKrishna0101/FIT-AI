import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/onboarding/components/about_you_controls.dart';
import 'package:setcraft/features/onboarding/components/biometric_ruler_card.dart';
import 'package:setcraft/features/onboarding/views/about_you_experience_view.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
import 'package:setcraft/features/onboarding/viewmodels/about_you_viewmodel.dart';

const _preview = ValueKey('onboarding-preview');

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Builder(
        builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(
                  key: _preview, child: FitnessTheme(child: child)),
            )));

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  testWidgets('Swiping changes a precise weight and settles on a tick',
      (tester) async {
    double value = 80.7;
    await tester.pumpWidget(_app(Scaffold(
        body: StatefulBuilder(
      builder: (context, update) => BiometricRulerCard(
        label: 'Weight',
        value: value,
        valueDisplay: value.toStringAsFixed(1),
        unit: 'kg',
        min: 30,
        max: 250,
        step: .1,
        majorEvery: 10,
        tickLabel: (value) => '${value.round()}',
        onChanged: (next) => update(() => value = next),
      ),
    ))));
    await tester.pumpAndSettle();
    expect(value, 80.7,
        reason: 'Opening the control must not modify the saved value.');
    await tester.drag(find.byKey(const ValueKey('biometric-ruler-track')),
        const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(value, greaterThan(80.7));
    expect(value * 10, closeTo((value * 10).roundToDouble(), .0001));
    expect(find.text(value.toStringAsFixed(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ruler clamps to both ends without overflow', (tester) async {
    double value = 16;
    await tester.pumpWidget(_app(Scaffold(
        body: StatefulBuilder(
      builder: (context, update) => BiometricRulerCard(
        label: 'Age',
        value: value,
        valueDisplay: '${value.round()}',
        min: 13,
        max: 20,
        step: 1,
        majorEvery: 5,
        tickLabel: (value) => '${value.round()}',
        onChanged: (next) => update(() => value = next),
      ),
    ))));
    await tester.pumpAndSettle();
    final track = find.byKey(const ValueKey('biometric-ruler-track'));
    await tester.drag(track, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(value, 20);
    await tester.drag(track, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(value, 13);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Unit changes preserve values and ruler edits save canonical measurements',
      (tester) async {
    await OnboardingDraft(
            name: 'Vamsi',
            heightCm: 177.8,
            weightKg: 80.7,
            targetWeightKg: 74.8)
        .save();
    final model = AboutYouViewModel();
    await tester.pumpAndSettle();
    model.setImperial(false);
    model.setImperial(true);
    expect(model.heightCm, 177.8);
    expect(model.weightKg, 80.7);
    model.setHeight(70);
    model.setWeight(178);
    model.setTargetWeight(165);
    await model.continueToNextStep();
    await model.controller.flush();
    final saved = await OnboardingDraft.load();
    expect(saved.heightCm, 177.8);
    expect(saved.weightKg, closeTo(178 / 2.20462, .051));
    expect(saved.targetWeightKg, closeTo(165 / 2.20462, .051));
    model.dispose();
  });

  testWidgets('About you switches measurements and renders the silver ruler',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await OnboardingDraft(
            name: 'Vamsi',
            heightCm: 177.8,
            weightKg: 80.7,
            targetWeightKg: 74.8)
        .save();
    await tester.pumpWidget(_app(const AboutYouExperienceView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await _capture(tester, 'body-selection');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(BiometricRulerCard), findsOneWidget);
    await _capture(tester, 'about-you-ruler');
    final height = find.byKey(const ValueKey('select-biometric-height'));
    await tester.ensureVisible(height);
    await tester.tap(height);
    await tester.pumpAndSettle();
    expect(
        tester.widget<BiometricRulerCard>(find.byType(BiometricRulerCard)).step,
        1);
    expect(
        tester
            .widget<BiometricRulerCard>(find.byType(BiometricRulerCard))
            .value,
        70);

    final header = find.byType(BiometricsHeaderWithUnits);
    final headerHeight = tester.getSize(header).height;
    Future<void> selectMetric(String metric) async {
      final choice = find.byKey(ValueKey('select-biometric-$metric'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
    }

    await selectMetric('age');
    expect(
        tester.widget<BiometricRulerCard>(find.byType(BiometricRulerCard)).unit,
        AppLanguage.uk.yearsUnit);
    expect(find.descendant(of: header, matching: find.byType(GestureDetector)),
        findsNothing);
    expect(tester.getSize(header).height, headerHeight);
    await _capture(tester, 'about-you-age-units');

    await selectMetric('weight');
    expect(
        tester.widget<BiometricRulerCard>(find.byType(BiometricRulerCard)).unit,
        'lb');
    final metricUnits = find.descendant(
        of: header, matching: find.text(AppLanguage.uk.unitMetricLabel));
    await tester.ensureVisible(metricUnits);
    await tester.pumpAndSettle();
    await tester.tap(metricUnits);
    await tester.pumpAndSettle();
    expect(
        tester.widget<BiometricRulerCard>(find.byType(BiometricRulerCard)).unit,
        'kg');

    await selectMetric('age');
    expect(find.descendant(of: header, matching: find.byType(GestureDetector)),
        findsNothing);
    expect(
        tester
            .widget<BiometricRulerCard>(find.byType(BiometricRulerCard))
            .value,
        27);
    await selectMetric('height');
    final heightRuler =
        tester.widget<BiometricRulerCard>(find.byType(BiometricRulerCard));
    expect(heightRuler.unit, 'cm');
    expect(heightRuler.value, 177.8);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Make it yours uses silver choices and preserves priorities',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await OnboardingDraft(
        focusMuscles: ['chest'], trainingDays: ['MONDAY', 'WEDNESDAY']).save();
    bool continued = false;
    await tester.pumpWidget(
        _app(TrainingPreferencesView(onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose individual muscles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose individual muscles'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Biceps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biceps'));
    await tester.pumpAndSettle();
    await _capture(tester, 'make-it-yours');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Build my plan'));
    await tester.pumpAndSettle();
    expect((await OnboardingDraft.load()).focusMuscles, ['chest', 'biceps']);
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Both screens support small phones and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final page in [
      const AboutYouExperienceView(),
      const TrainingPreferencesView()
    ]) {
      await tester.pumpWidget(_app(page, scale: 1.8));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const ValueKey('onboarding-scroll')),
          const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
