import 'package:setcraft/core/components/animated_tab_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ValueNotifier<int> selected, {bool reducedMotion = false}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, index, _) => Scaffold(
              body: AnimatedTabStack(
                index: index,
                children: [
                  for (var tab = 0; tab < 3; tab++)
                    TickerMode(
                      enabled: index == tab,
                      child: _TabFixture(tab: tab),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

class _TabFixture extends StatefulWidget {
  final int tab;
  const _TabFixture({required this.tab});

  @override
  State<_TabFixture> createState() => _TabFixtureState();
}

class _TabFixtureState extends State<_TabFixture> {
  final scroll = ScrollController();
  int count = 0;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextButton(
            onPressed: () => setState(() => count++),
            child: Text('Tab ${widget.tab}: $count'),
          ),
          Expanded(
            child: ListView.builder(
              key: ValueKey('scroll-${widget.tab}'),
              controller: scroll,
              itemExtent: 60,
              itemCount: 40,
              itemBuilder: (_, item) => Text('Item $item'),
            ),
          ),
        ],
      );
}

void main() {
  testWidgets('Tabs crossfade and preserve state and scrolling',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_app(selected));
    await tester.tap(find.text('Tab 0: 0'));
    await tester.pump();
    await tester.drag(
        find.byKey(const ValueKey('scroll-0')), const Offset(0, -300));
    await tester.pumpAndSettle();
    final oldState = tester.state<_TabFixtureState>(find.byType(_TabFixture));
    final offset = oldState.scroll.offset;

    selected.value = 1;
    await tester.pump();
    // Both screens remain in the crossfade while touch follows the new tab.
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.text('Tab 0: 1'), findsOneWidget);
    expect(find.text('Tab 1: 0'), findsOneWidget);
    final fades =
        tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(
        fades
            .where((fade) => fade.opacity.value > 0 && fade.opacity.value < 1)
            .length,
        greaterThanOrEqualTo(2));
    final oldPointer = find.ancestor(
        of: find.text('Tab 0: 1'), matching: find.byType(IgnorePointer));
    expect(tester.widget<IgnorePointer>(oldPointer.first).ignoring, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Tab 0: 1'), findsNothing);

    selected.value = 0;
    await tester.pumpAndSettle();
    final restored = tester.state<_TabFixtureState>(find.byType(_TabFixture));
    expect(restored, same(oldState));
    expect(restored.scroll.offset, closeTo(offset, .01));
    expect(find.text('Tab 0: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab changes keep a visible screen throughout the crossfade',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_app(selected));
    selected.value = 1;
    await tester.pump();
    for (var frame = 0; frame < 18; frame++) {
      final opacities = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((fade) => fade.opacity.value);
      expect(
          opacities.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(.5),
          reason: 'A tab must remain visible during every transition frame');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(find.text('Tab 1: 0'), findsOneWidget);
  });

  testWidgets('Rapid taps settle on the latest tab without pending frames',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_app(selected));
    for (final index in [1, 2, 0, 2]) {
      selected.value = index;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
    }
    await tester.pumpAndSettle();
    expect(find.text('Tab 2: 0'), findsOneWidget);
    expect(find.text('Tab 0: 0'), findsNothing);
    expect(find.text('Tab 1: 0'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion switches immediately', (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_app(selected, reducedMotion: true));
    selected.value = 1;
    await tester.pump();
    expect(find.text('Tab 1: 0'), findsOneWidget);
    expect(find.text('Tab 0: 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing motion settings during a tab transition stays stable',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_app(selected));
    selected.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    await tester.pumpWidget(_app(selected, reducedMotion: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tab 1: 0'), findsOneWidget);
    for (final index in [0, 2, 1, 0]) {
      selected.value = index;
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(_app(selected));
    await tester.pumpAndSettle();
    expect(find.text('Tab 0: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
