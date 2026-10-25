import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_live_previews.dart';

Widget page(Widget child,
        {bool reduced = false,
        double scale = 1,
        Locale locale = const Locale('en', 'GB')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('de', 'DE'),
        Locale('de', 'CH')
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
          child: child!),
      home: FitnessTheme(
          child: Scaffold(
              body: RepaintBoundary(
                  key: const ValueKey('preview-capture'),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20), child: child)))),
    );

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview-capture')))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('Frequency preview reflects every supported selection',
      (tester) async {
    for (final count in [2, 3, 4, 5, 6]) {
      await tester
          .pumpWidget(page(OnboardingFrequencyPreview(frequency: count)));
      await tester.pumpAndSettle();
      final selected = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.selected == true);
      expect(selected.length, count);
      expect(find.text('Training days'), findsOneWidget);
      expect(find.text('Choose your exact days later.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'Muscle highlights animate selection and clear deselected regions',
      (tester) async {
    await tester.pumpWidget(page(const OnboardingMusclePreview(selected: {})));
    await tester
        .pumpWidget(page(const OnboardingMusclePreview(selected: {'chest'})));
    await tester.pump(const Duration(milliseconds: 100));
    var illustrations = tester
        .widgetList<AnatomicalMuscleIllustration>(
            find.byType(AnatomicalMuscleIllustration))
        .toList();
    expect(illustrations.length, 2);
    expect(illustrations.first.colors['chest'], isNot(const Color(0xFFD56B55)));
    await tester.pumpAndSettle();
    illustrations = tester
        .widgetList<AnatomicalMuscleIllustration>(
            find.byType(AnatomicalMuscleIllustration))
        .toList();
    expect(illustrations.first.colors['chest'], const Color(0xFFD56B55));
    await tester
        .pumpWidget(page(const OnboardingMusclePreview(selected: {'lats'})));
    await tester.pumpAndSettle();
    illustrations = tester
        .widgetList<AnatomicalMuscleIllustration>(
            find.byType(AnatomicalMuscleIllustration))
        .toList();
    expect(illustrations.last.back, isTrue);
    expect(illustrations.last.colors['lats'], const Color(0xFFD56B55));
    expect(illustrations.first.colors['chest'], const Color(0xFF505050));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion applies muscle selection immediately',
      (tester) async {
    await tester.pumpWidget(
        page(const OnboardingMusclePreview(selected: {}), reduced: true));
    await tester.pumpWidget(page(
        const OnboardingMusclePreview(selected: {'quads'}),
        reduced: true));
    final illustration = tester
        .widgetList<AnatomicalMuscleIllustration>(
            find.byType(AnatomicalMuscleIllustration))
        .first;
    expect(illustration.colors['quads'], const Color(0xFFD56B55));
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final locale in [
    const Locale('en', 'GB'),
    const Locale('de', 'DE'),
    const Locale('de', 'CH')
  ]) {
    testWidgets('Previews fit narrow large-text ${locale.toLanguageTag()}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(page(
          const Column(children: [
            OnboardingFrequencyPreview(frequency: 3),
            SizedBox(height: 16),
            OnboardingMusclePreview(selected: {'chest', 'lats', 'quads'}),
          ]),
          scale: 1.4,
          locale: locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'onboarding-live-${locale.toLanguageTag()}');
    });
  }
}
