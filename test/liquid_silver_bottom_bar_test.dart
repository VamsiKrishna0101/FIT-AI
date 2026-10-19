import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'package:fitai_mobile/core/components/liquid_silver_bottom_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_native/liquid_glass_native.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart' as glass;

void main() {
  const navigationChannel = MethodChannel('fitai/navigation');
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });

  testWidgets('Older iOS keeps the floating dock and working destinations',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(navigationChannel, (_) async => false);
    addTearDown(
        () => messenger.setMockMethodCallHandler(navigationChannel, null));

    final selected = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: LiquidSilverBottomBar(
          selectedIndex: 0,
          labels: const ['Today', 'Train', 'Body', 'Progress'],
          onTabSelected: selected.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassTabBar), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('Body'));
    expect(selected, [2]);
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('iOS 26 bridges native tabs, updates selection and language',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    final messenger = tester.binding.defaultBinaryMessenger;
    final views = <Map<dynamic, dynamic>>[];
    final updates = <MethodCall>[];
    final nativeChannels = <MethodChannel>[];
    messenger.setMockMethodCallHandler(navigationChannel, (_) async => true);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views,
        (call) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<dynamic, dynamic>;
        views.add(args);
        final channel = MethodChannel('${args['viewType']}/${args['id']}');
        nativeChannels.add(channel);
        messenger.setMockMethodCallHandler(channel, (call) async {
          updates.add(call);
          return null;
        });
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(navigationChannel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
      for (final channel in nativeChannels) {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });

    var selectedIndex = 0;
    var labels = ['Today', 'Train', 'Body', 'Progress'];
    late StateSetter update;
    final selections = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: LiquidSilverBottomBar(
            selectedIndex: selectedIndex,
            labels: labels,
            onTabSelected: (index) {
              selections.add(index);
              setState(() => selectedIndex = index);
            },
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();

    expect(views, hasLength(1));
    expect(views.single['viewType'], 'flutter_native_view/glass_tab_bar');
    final params = const StandardMessageCodec().decodeMessage(
        ByteData.sublistView(views.single['params'] as Uint8List)) as Map;
    expect(params['currentIndex'], 0);
    expect((params['items'] as List).map((item) => item['label']), labels);
    expect(params['brightness'], 'dark');
    expect(params['respectAccessibility'], true);
    expect(find.byType(BackdropFilter), findsNothing);
    final bounds = tester.getRect(find.byType(UiKitView));
    expect(bounds.center.dx, closeTo(393 / 2, .01));
    expect(bounds.width, 320);
    // The host reaches the screen edge; UIKit floats the visible glass above
    // the home indicator instead of receiving the safe area twice.
    expect(bounds.bottom, closeTo(852, .01));
    expect(bounds.height, 100);

    // Exercise the real method-channel callback, rather than calling the Dart
    // widget's callback directly. The existing tab stack owns the selection.
    await messenger.handlePlatformMessage(
      nativeChannels.single.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('onIndexChanged', 2)),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(selections, [2]);
    expect(views, hasLength(1));
    expect(updates.last.arguments['currentIndex'], 2);

    await messenger.handlePlatformMessage(
      nativeChannels.single.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('onIndexChanged', 2)),
      (_) {},
    );
    expect(selections, [2]);

    update(() => labels = ['Heute', 'Training', 'Körper', 'Fortschritt']);
    await tester.pumpAndSettle();
    expect(views, hasLength(2));
    final translated = const StandardMessageCodec().decodeMessage(
        ByteData.sublistView(views.last['params'] as Uint8List)) as Map;
    expect((translated['items'] as List).map((item) => item['label']), labels);
    expect(translated['currentIndex'], 2);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  for (final width in [320.0, 393.0, 768.0]) {
    testWidgets('Four destinations stay centered at width $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 852);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      final selected = <int>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: LiquidSilverBottomBar(
            selectedIndex: 0,
            labels: const ['Heute', 'Training', 'Körper', 'Fortschritt'],
            onTabSelected: selected.add,
          ),
        ),
      ));
      final capsule =
          tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
      expect(capsule.center.dx, closeTo(width / 2, .01));
      expect(capsule.width, closeTo(width < 384 ? width - 64 : 320, .01));
      expect(capsule.left, greaterThanOrEqualTo(32));
      expect(capsule.bottom, closeTo(852 - 34 - 12, .01));
      expect(find.byType(BackdropFilter), findsOneWidget);
      for (final label in ['Training', 'Körper', 'Fortschritt']) {
        await tester.tap(find.text(label));
      }
      expect(selected, [1, 2, 3]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('The glass lens follows the selected tab after a tap',
      (tester) async {
    var selectedIndex = 0;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          bottomNavigationBar: LiquidSilverBottomBar(
            selectedIndex: selectedIndex,
            labels: const ['Today', 'Train', 'Body', 'Progress'],
            onTabSelected: (index) => setState(() => selectedIndex = index),
          ),
        ),
      ),
    ));
    final capsule =
        tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(screenHeight - capsule.bottom, closeTo(12, .01));
    final lens = find.byKey(const ValueKey('navigation-active-lens'));
    expect(tester.getCenter(lens).dx,
        closeTo(tester.getCenter(find.text('Today')).dx, .01));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);
    expect(tester.getCenter(lens).dx,
        closeTo(tester.getCenter(find.text('Progress')).dx, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large labels and reduced motion fit the centered dock',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6), disableAnimations: true),
        child: Scaffold(
            bottomNavigationBar: LiquidSilverBottomBar(
          selectedIndex: 2,
          labels: const ['Aujourd’hui', 'Entraînement', 'Corps', 'Progression'],
          onTabSelected: (_) {},
        )),
      ),
    )));
    expect(
        tester.getSize(find.byKey(const ValueKey('navigation-capsule'))).height,
        closeTo(66.6, .01));
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        Duration.zero);
    expect(find.byType(AnimatedScale), findsNothing);
    expect(find.byType(glass.GlassGlow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragging previews a tab and opens it only once on release',
      (tester) async {
    final selections = <int>[];
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
                bottomNavigationBar: LiquidSilverBottomBar(
                  selectedIndex: selected,
                  labels: const ['Today', 'Train', 'Body', 'Progress'],
                  onTabSelected: (index) {
                    selections.add(index);
                    setState(() => selected = index);
                  },
                ),
              )),
    ));

    final touch =
        await tester.startGesture(tester.getCenter(find.text('Today')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        greaterThan(1));
    await touch.moveTo(tester.getCenter(find.text('Train')));
    await tester.pump(const Duration(milliseconds: 100));
    await touch.moveTo(tester.getCenter(find.text('Progress')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(selections, isEmpty);
    expect(
        tester
            .getCenter(find.byKey(const ValueKey('navigation-active-lens')))
            .dx,
        closeTo(tester.getCenter(find.text('Progress')).dx, .1));
    expect(
        tester
            .widget<glass.RawLiquidStretch>(find.byType(glass.RawLiquidStretch))
            .stretchPixels
            .dx,
        greaterThan(0));

    await touch.up();
    await tester.pumpAndSettle();
    expect(selections, [3]);
    expect(
        tester
            .widget<glass.RawLiquidStretch>(find.byType(glass.RawLiquidStretch))
            .stretchPixels,
        Offset.zero);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Accessibility changes during a press leave no elastic state',
      (tester) async {
    var reducedMotion = false;
    late StateSetter update;
    final selections = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reducedMotion,
            highContrast: reducedMotion,
          ),
          child: Scaffold(
            bottomNavigationBar: LiquidSilverBottomBar(
              selectedIndex: 0,
              labels: const ['Today', 'Train', 'Body', 'Progress'],
              onTabSelected: selections.add,
            ),
          ),
        );
      }),
    ));
    final touch =
        await tester.startGesture(tester.getCenter(find.text('Today')));
    await touch.moveTo(tester.getCenter(find.text('Train')));
    await tester.pump(const Duration(milliseconds: 100));
    update(() => reducedMotion = true);
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedScale), findsNothing);
    expect(find.byType(glass.GlassGlow), findsNothing);
    await touch.cancel();
    update(() => reducedMotion = false);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();
    expect(selections, [2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelled touches settle without navigating', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      bottomNavigationBar: LiquidSilverBottomBar(
        selectedIndex: 0,
        labels: const ['Today', 'Train', 'Body', 'Progress'],
        onTabSelected: selections.add,
      ),
    )));
    final touch =
        await tester.startGesture(tester.getCenter(find.text('Train')));
    await touch.moveBy(const Offset(45, 0));
    await tester.pump(const Duration(milliseconds: 160));
    await touch.cancel();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(
        tester
            .widget<glass.RawLiquidStretch>(find.byType(glass.RawLiquidStretch))
            .stretchPixels,
        Offset.zero);
    expect(
        tester
            .getCenter(find.byKey(const ValueKey('navigation-active-lens')))
            .dx,
        closeTo(tester.getCenter(find.text('Today')).dx, .1));
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();
    expect(selections, [2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragging out of the dock does not change destinations',
      (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      bottomNavigationBar: LiquidSilverBottomBar(
        selectedIndex: 0,
        labels: const ['Today', 'Train', 'Body', 'Progress'],
        onTabSelected: selections.add,
      ),
    )));
    final touch =
        await tester.startGesture(tester.getCenter(find.text('Today')));
    await touch.moveTo(tester.getCenter(find.text('Progress')));
    await tester.pump();
    await touch.moveBy(const Offset(0, -120));
    await touch.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Content can scroll clear of the floating dock and icon style stays consistent',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    var selected = 2;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      home: RepaintBoundary(
        key: const ValueKey('navigation-preview'),
        child: StatefulBuilder(
            builder: (context, setState) => Scaffold(
                  extendBody: true,
                  body: ListView(
                    padding: EdgeInsets.fromLTRB(16, 48, 16,
                        LiquidSilverBottomBar.scrollBottomInset(context)),
                    children: [
                      const Text('Body', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 24),
                      Container(
                          height: 380,
                          decoration: BoxDecoration(
                              color: const Color(0xFF202020),
                              borderRadius: BorderRadius.circular(24))),
                      const SizedBox(height: 20),
                      Container(
                          height: 300,
                          decoration: BoxDecoration(
                              color: const Color(0xFF202020),
                              borderRadius: BorderRadius.circular(24)),
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(20),
                          child: const Text('Strength map',
                              style: TextStyle(fontSize: 18))),
                      const SizedBox(height: 20),
                      OutlinedButton(
                          onPressed: () {}, child: const Text('Open workout')),
                    ],
                  ),
                  bottomNavigationBar: LiquidSilverBottomBar(
                      selectedIndex: selected,
                      labels: const ['Today', 'Train', 'Body', 'Progress'],
                      onTabSelected: (value) =>
                          setState(() => selected = value)),
                )),
      ),
    ));
    await tester.pumpAndSettle();
    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((icon) => icon.icon)
        .toList();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(
        tester
            .widgetList<Icon>(find.byType(Icon))
            .map((icon) => icon.icon)
            .toList(),
        icons);
    expect(icons, contains(CupertinoIcons.person_crop_rectangle));
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    final capsule =
        tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
    expect(capsule.height, 60);
    expect(
        tester
            .getRect(find.widgetWithText(OutlinedButton, 'Open workout'))
            .bottom,
        lessThanOrEqualTo(capsule.top - 24));
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('navigation-preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/navigation-refined.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scrolling content remains visible behind the translucent dock',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      home: RepaintBoundary(
        key: const ValueKey('navigation-overlay-preview'),
        child: Scaffold(
          extendBody: true,
          body: Stack(children: [
            const Positioned(
                top: 64,
                left: 16,
                child: Text('Readiness', style: TextStyle(fontSize: 22))),
            Positioned(
              top: 112,
              left: 16,
              right: 16,
              bottom: -100,
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF202020),
                    borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.all(20),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Based on your check-in',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(height: 18),
                      Text('Your day, at a glance',
                          style: TextStyle(fontSize: 20))
                    ]),
              ),
            ),
          ]),
          bottomNavigationBar: LiquidSilverBottomBar(
              selectedIndex: 0,
              labels: const ['Today', 'Train', 'Body', 'Progress'],
              onTabSelected: (_) {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('navigation-overlay-preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      // Keep a gentle bottom fade without hiding the content under the glass.
      final pixel = ((image.height - 4) * image.width + 48) * 4;
      expect(raw.getUint8(pixel), lessThan(20));
      expect(raw.getUint8(pixel + 1), lessThan(20));
      expect(raw.getUint8(pixel + 2), lessThan(20));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/navigation-overlay-refined.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
