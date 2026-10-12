import 'package:fitai_mobile/core/components/liquid_silver_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
