import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/components/onboarding_focus_body.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
import 'package:setcraft/features/train/components/graphite_anatomy.dart';

const _capture = ValueKey('focus-capture');
Widget app(Widget child, {bool reduced = true, double textScale = 1}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: RepaintBoundary(key: _capture, child: child));
Future<void> warm(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final asset in [
      onboardingBodyAsset(female: false),
      onboardingBodyAsset(female: true),
      graphiteAnatomyAsset
    ]) {
      await precacheImage(AssetImage(asset),
          tester.element(find.byType(OnboardingFocusFigure).first));
    }
  });
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) =>
    tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(_capture))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
OnboardingFocusFigure figure(WidgetTester tester) =>
    tester.widget<OnboardingFocusFigure>(find.byType(OnboardingFocusFigure));

Future<Color> musclePixel(WidgetTester tester, Offset sourcePoint,
    {bool graphite = false}) async {
  final root =
      find.byType(graphite ? GraphiteMuscleFigure : OnboardingFocusFigure);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: root, matching: find.byType(RepaintBoundary)).first);
  final Rect source;
  if (graphite) {
    final widget = tester.widget<GraphiteMuscleFigure>(root);
    source = GraphiteAnatomyPainter(
        image: null,
        female: widget.female,
        back: widget.back,
        primary: const {},
        secondary: const {}).viewport;
  } else {
    final widget = figure(tester);
    source = onboardingFocusViewport(female: widget.female, back: widget.back);
  }
  final size = boundary.size;
  final widthScale = size.width / source.width;
  final heightScale = size.height / source.height;
  final scale = widthScale < heightScale ? widthScale : heightScale;
  final point = Offset((size.width - source.width * scale) / 2,
          (size.height - source.height * scale) / 2) +
      (sourcePoint - source.topLeft) * scale;
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var red = 0, green = 0, blue = 0, count = 0;
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        final x = (point.dx * 2).round() + dx;
        final y = (point.dy * 2).round() + dy;
        final offset = (y * image.width + x) * 4;
        red += bytes.getUint8(offset);
        green += bytes.getUint8(offset + 1);
        blue += bytes.getUint8(offset + 2);
        count++;
      }
    }
    image.dispose();
    return Color.fromARGB(255, (red / count).round(), (green / count).round(),
        (blue / count).round());
  });
  return color!;
}

void expectHighlighted(Color color) {
  expect(color.r - color.g, greaterThan(.08));
  expect(color.r - color.b, greaterThan(.08));
}

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final female in [false, true]) {
    testWidgets(
        'Original ${female ? 'female' : 'male'} image, selection animation and posterior view',
        (tester) async {
      Widget body(Set<String> selected) => app(
          Scaffold(
              body: OnboardingFocusBody(
                  female: female, selected: selected, onSelected: (_) {})),
          reduced: false);
      await tester.pumpWidget(body({}));
      await warm(tester);
      expect(figure(tester).asset, onboardingBodyAsset(female: female));
      expect(figure(tester).activation.values.every((v) => v == 0), true);
      final paint = find.descendant(
          of: find.byType(OnboardingFocusFigure),
          matching: find.byType(CustomPaint));
      expect(
          (tester.widget<CustomPaint>(paint).painter as OnboardingFocusPainter)
              .image,
          isNotNull);
      await tester.pumpWidget(body({'chest'}));
      await tester.pump(const Duration(milliseconds: 50));
      expect(figure(tester).activation['chest'], inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(figure(tester).activation['chest'], 1);
      await tester.pumpWidget(body({'lats'}));
      await tester.pumpAndSettle();
      expect(figure(tester).back, true);
      expect(figure(tester).activation['lats'], 1);
      expect(figure(tester).activation['chest'], 0);
      await tester.tap(find.byKey(const ValueKey('focus-body-front')));
      await tester.pumpAndSettle();
      expect(figure(tester).back, false);
      expect(figure(tester).activation['lats'], 1);
      expect(onboardingFocusPaths(female: female, back: false),
          contains('calves'));
      expect(onboardingFocusPaths(female: female, back: false),
          isNot(contains('hamstrings')));
      expect(tester.takeException(), isNull);
    });
    testWidgets(
        'Focus chips, body taps and full body stay synced for ${female ? 'female' : 'male'}',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);
      final controller = OnboardingController(
          load: () async => OnboardingDraft(), save: (_) async {});
      await controller.initialize();
      controller.draft.gender = female ? 'FEMALE' : 'MALE';
      await tester.pumpWidget(app(
          TrainingPreferencesView(controller: controller, onContinue: () {})));
      await tester.pumpAndSettle();
      await warm(tester);
      expect(controller.draft.focusMuscles, isEmpty);
      expect(figure(tester).activation.keys, containsAll(trainingMuscles.keys));
      final calfPoint =
          female ? const Offset(390, 1160) : const Offset(350, 1150);
      expectHighlighted(await musclePixel(tester, calfPoint));
      expectHighlighted(
          await musclePixel(tester, Offset(1024 - calfPoint.dx, calfPoint.dy)));
      await tester.tap(find.byKey(const ValueKey('training-choice-Chest')));
      await tester.pumpAndSettle();
      expect(controller.draft.focusMuscles, ['chest']);
      final unselectedCalf = await musclePixel(tester, calfPoint);
      expect((unselectedCalf.r - unselectedCalf.g).abs(), lessThan(.01));
      await capture(tester, 'focus-${female ? 'female' : 'male'}-chest');
      final focus = find.byType(OnboardingFocusFigure);
      await Scrollable.ensureVisible(tester.element(focus), alignment: .15);
      await tester.pumpAndSettle();
      final rect = tester.getRect(focus);
      final sourcePoint =
          female ? const Offset(350, 300) : const Offset(320, 320);
      final scale = rect.height / 1536;
      await tester.tapAt(rect.topLeft +
          Offset((rect.width - 1024 * scale) / 2, 0) +
          sourcePoint * scale);
      await tester.pumpAndSettle();
      expect(
          controller.draft.focusMuscles, containsAll(['chest', 'shoulders']));
      await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('training-choice-Back'))),
          alignment: .15);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('training-choice-Back')));
      await tester.pumpAndSettle();
      expect(figure(tester).back, true);
      expect(
          controller.draft.focusMuscles,
          containsAll(
              ['chest', 'shoulders', 'upper_back', 'lats', 'lower_back']));
      await capture(tester, 'focus-${female ? 'female' : 'male'}-back');
      await tester.tap(find.byKey(const ValueKey('focus-full-body')));
      await tester.pumpAndSettle();
      expect(controller.draft.focusMuscles, isEmpty);
      expect(
          figure(tester).activation.values.every((value) => value == 1), true);
      expect(figure(tester).back, false);
      expectHighlighted(await musclePixel(tester, calfPoint));
      await capture(tester, 'focus-${female ? 'female' : 'male'}-full-body');

      await tester.tap(find.byKey(const ValueKey('training-choice-Legs')));
      await tester.pumpAndSettle();
      expect(figure(tester).back, false);
      expect(controller.draft.focusMuscles,
          containsAll(['quads', 'hamstrings', 'calves']));
      expectHighlighted(await musclePixel(tester, calfPoint));
      await capture(tester, 'focus-${female ? 'female' : 'male'}-legs');

      // Lower-leg touch selection uses the same masks as the painter.
      await Scrollable.ensureVisible(
          tester.element(find.byType(OnboardingFocusFigure)),
          alignment: .1);
      await tester.pumpAndSettle();
      final calfRect = tester.getRect(find.byType(OnboardingFocusFigure));
      final calfScale = calfRect.height / 1536;
      await tester.tapAt(calfRect.topLeft +
          Offset(
              (calfRect.width - 1024 * calfScale) / 2 +
                  calfPoint.dx * calfScale,
              calfPoint.dy * calfScale));
      await tester.pumpAndSettle();
      expect(controller.draft.focusMuscles, isNot(contains('calves')));
      final clearedCalf = await musclePixel(tester, calfPoint);
      expect((clearedCalf.r - clearedCalf.g).abs(), lessThan(.01));
      expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await controller.flush();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
    testWidgets(
        'Exercise atlas highlights both front calves for ${female ? 'female' : 'male'}',
        (tester) async {
      await tester.pumpWidget(app(Scaffold(
          body: Center(
              child: SizedBox(
                  width: 300,
                  height: 440,
                  child: GraphiteMuscleFigure(
                      female: female,
                      back: false,
                      primary: const {'calves'},
                      secondary: const {}))))));
      await tester.runAsync(() async {
        await precacheImage(const AssetImage(graphiteAnatomyAsset),
            tester.element(find.byType(GraphiteMuscleFigure)));
      });
      await tester.pumpAndSettle();
      final point = female ? const Offset(205, 1300) : const Offset(205, 550);
      expectHighlighted(await musclePixel(tester, point, graphite: true));
      expectHighlighted(await musclePixel(
          tester, Offset(550 - point.dx, point.dy),
          graphite: true));
      await capture(
          tester, 'exercise-${female ? 'female' : 'male'}-front-calves');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Capture registered muscle masks for visual review',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(720, 960);
    addTearDown(tester.view.reset);
    for (final female in [false, true]) {
      for (final back in [false, true]) {
        final regions = onboardingFocusPaths(female: female, back: back).keys;
        await tester.pumpWidget(app(Scaffold(
            backgroundColor: Colors.black,
            body: Wrap(children: [
              for (final region in regions)
                SizedBox(
                    width: 240,
                    height: 310,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(region)),
                          Expanded(
                              child: OnboardingFocusFigure(
                                  female: female,
                                  back: back,
                                  activation: {region: 1},
                                  onSelected: (_) {})),
                        ])),
            ]))));
        await warm(tester);
        for (final element in find.byType(OnboardingFocusFigure).evaluate()) {
          expect(tester.getSize(find.byWidget(element.widget)).width,
              greaterThan(200));
        }
        await capture(tester,
            'focus-masks-${female ? 'female' : 'male'}-${back ? 'back' : 'front'}');
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('Reduced motion and a narrow large-text focus page',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.reset);
    final controller = OnboardingController();
    await controller.initialize();
    controller.draft.gender = 'FEMALE';
    await tester.pumpWidget(app(
        TrainingPreferencesView(controller: controller, onContinue: () {}),
        textScale: 1.6));
    await tester.pumpAndSettle();
    await warm(tester);
    await tester.tap(find.byKey(const ValueKey('training-choice-Chest')));
    await tester.pump();
    expect(figure(tester).activation['chest'], 1);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, false);
    expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
    await capture(tester, 'focus-large-text');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
