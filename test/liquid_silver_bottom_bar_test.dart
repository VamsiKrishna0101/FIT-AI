import 'package:fitai_mobile/core/components/liquid_silver_bottom_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_native/liquid_glass_native.dart';

void main() {
  const navigationChannel = MethodChannel('fitai/navigation');

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
    expect(bounds.bottom, lessThan(852 - 34));
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
      expect(capsule.width, lessThanOrEqualTo(340));
      expect(capsule.left, greaterThanOrEqualTo(28));
      expect(capsule.bottom, closeTo(852 - 34 - 32, .01));
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
    expect(screenHeight - capsule.bottom, closeTo(32, .01));
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
        66);
    expect(
        tester
            .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
            .every((widget) => widget.duration == Duration.zero),
        isTrue);
    expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
