import 'dart:io';
import 'dart:ui' as ui;
import 'package:setcraft/core/components/navigation_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/core/theme/ds_colors.dart';

class _NavigationPreview extends StatefulWidget {
  final double scale;
  final bool reduced, rtl, highContrast;
  final List<String> labels;
  final ValueChanged<int>? onSelected;
  final Widget? body;
  const _NavigationPreview(
      {this.scale = 1,
      this.reduced = false,
      this.rtl = false,
      this.highContrast = false,
      this.labels = const ['Today', 'Train', 'Body', 'Progress'],
      this.onSelected,
      this.body});
  @override
  State<_NavigationPreview> createState() => _NavigationPreviewState();
}

class _NavigationPreviewState extends State<_NavigationPreview> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(widget.scale),
              disableAnimations: widget.reduced,
              highContrast: widget.highContrast),
          child: Directionality(
              textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!)),
      home: RepaintBoundary(
          key: const ValueKey('navigation-preview'),
          child: Scaffold(
            extendBody: true,
            body: widget.body ??
                const SizedBox.expand(key: ValueKey('navigation-content')),
            bottomNavigationBar: LiquidSilverBottomBar(
                selectedIndex: selected,
                labels: widget.labels,
                onTabSelected: (value) {
                  widget.onSelected?.call(value);
                  setState(() => selected = value);
                }),
          )));
}

void phone(WidgetTester tester, {double width = 393, double inset = 34}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 852);
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  tester.view.padding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('navigation-preview')));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<List<Color>> samplePixels(
    WidgetTester tester, Iterable<Offset> points) async {
  return (await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('navigation-preview')));
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      return points.map((point) {
        final offset = (point.dy.round() * image.width + point.dx.round()) * 4;
        return Color.fromARGB(
            bytes.getUint8(offset + 3),
            bytes.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2));
      }).toList();
    } finally {
      image.dispose();
    }
  }))!;
}

Color iconColor(WidgetTester tester, String label) => tester
    .widget<NavigationGlyph>(find.descendant(
        of: find.byTooltip(label), matching: find.byType(NavigationGlyph)))
    .color;
void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('Navigation uses the same floating capsule on Android and iOS',
      (tester) async {
    phone(tester);
    var nativeRequests = 0;
    const channel = MethodChannel('fitai/navigation');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (_) async {
      nativeRequests++;
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final selections = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selections.add));
    await tester.pumpAndSettle();
    expect(nativeRequests, 0);
    expect(find.byType(UiKitView), findsNothing);
    // One frosted pass, identical on both platforms.
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
        find.byKey(const ValueKey('navigation-active-pill')), findsOneWidget);
    // Each tab face is drawn exactly once: no duplicated icons in a lens.
    expect(find.text('Today'), findsOneWidget);
    expect(find.byTooltip('Today'), findsOneWidget);
    await tester.tap(find.byTooltip('Body'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Body'));
    expect(selections, [2]);
    expect(iconColor(tester, 'Body'), DSColors.navGlassText);
    expect(tester.takeException(), isNull);
  },
      variant: const TargetPlatformVariant(
          {TargetPlatform.android, TargetPlatform.iOS}));

  for (final width in [320.0, 393.0, 768.0]) {
    testWidgets(
        'Navigation reserves space and preserves comfortable taps at width $width',
        (tester) async {
      phone(tester, width: width);
      final selections = <int>[];
      await tester.pumpWidget(_NavigationPreview(onSelected: selections.add));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(const ValueKey('navigation-bar')));
      final tabs =
          tester.getRect(find.byKey(const ValueKey('navigation-tabs')));
      final capsule =
          tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
      expect(bar.left, 0);
      expect(bar.right, width);
      expect(bar.bottom, 852);
      expect(capsule.left, greaterThanOrEqualTo(32));
      expect(capsule.right, lessThanOrEqualTo(width - 32));
      expect(capsule.width, lessThanOrEqualTo(372));
      expect(capsule.height, closeTo(50, .01));
      expect(capsule.bottom, closeTo(852 - 34 - 12, .01));
      expect(tabs.bottom, closeTo(capsule.bottom - 3, .01));
      expect(
          tester
              .getRect(find.byKey(const ValueKey('navigation-content')))
              .bottom,
          closeTo(bar.bottom, .01));
      for (var i = 0; i < 4; i++) {
        final tap = tester.getRect(find.byKey(ValueKey('navigation-tab-$i')));
        expect(tap.height, greaterThanOrEqualTo(44));
        expect(tap.width, greaterThanOrEqualTo(44));
      }
      for (final label in ['Train', 'Body', 'Progress']) {
        await tester.tap(find.byTooltip(label));
      }
      expect(selections, [1, 2, 3]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('The selection glides without changing shape while icons stay',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    final positions = [
      for (final label in ['Today', 'Train', 'Body', 'Progress'])
        tester.getRect(find.byTooltip(label))
    ];
    final pill = find.byKey(const ValueKey('navigation-active-pill'));
    final before = tester.getRect(pill);
    await tester.tap(find.byTooltip('Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final moving = tester.getRect(pill);
    expect(moving.center.dx, greaterThan(before.center.dx));
    expect(moving.center.dx,
        lessThan(tester.getCenter(find.byTooltip('Progress')).dx));
    expect(moving.size, before.size);
    expect(iconColor(tester, 'Progress'), isNot(DSColors.navGlassText));
    await capture(tester, 'navigation-liquid-glass-moving');
    await tester.pumpAndSettle();
    expect(iconColor(tester, 'Progress'), DSColors.navGlassText);
    expect(tester.getCenter(pill).dx,
        closeTo(tester.getCenter(find.byTooltip('Progress')).dx, .01));
    expect(tester.getSize(pill).width, closeTo(before.width, .01));
    final after = [
      for (final label in ['Today', 'Train', 'Body', 'Progress'])
        tester.getRect(find.byTooltip(label))
    ];
    expect(after, positions);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The dock is clear dark glass with a lighter glass selection',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    await tester.pumpAndSettle();
    final lens =
        tester.getRect(find.byKey(const ValueKey('navigation-active-pill')));
    final train = tester.getCenter(find.byTooltip('Train'));
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('navigation-preview')));
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        Color pixel(Offset point) {
          final offset =
              (point.dy.round() * image.width + point.dx.round()) * 4;
          return Color.fromARGB(
              bytes.getUint8(offset + 3),
              bytes.getUint8(offset),
              bytes.getUint8(offset + 1),
              bytes.getUint8(offset + 2));
        }

        final shell = pixel(train + const Offset(17, 0));
        final selection = pixel(lens.center + const Offset(16, 0));
        expect(shell.computeLuminance(), greaterThan(.0015),
            reason: 'The shell must separate from pure black');
        expect(shell.computeLuminance(), lessThan(.012),
            reason: 'The dock must retain its black finish');
        expect(selection.computeLuminance(),
            greaterThan(shell.computeLuminance() + .01),
            reason: 'The selection must read as a lighter glass pill');
        expect(selection.computeLuminance(), lessThan(.12),
            reason: 'The selection must stay translucent rather than silver');
      } finally {
        image.dispose();
      }
    });
  });

  testWidgets('Page colours remain visible through the glass shell',
      (tester) async {
    phone(tester);
    final backdrop = ValueNotifier(const Color(0xFFD03030));
    addTearDown(backdrop.dispose);
    await tester.pumpWidget(_NavigationPreview(
        body: ValueListenableBuilder<Color>(
            valueListenable: backdrop,
            builder: (_, colour, __) =>
                SizedBox.expand(child: ColoredBox(color: colour)))));
    await tester.pumpAndSettle();
    final sample =
        tester.getCenter(find.byTooltip('Train')) + const Offset(20, 8);
    final red = (await samplePixels(tester, [sample])).single;
    backdrop.value = const Color(0xFF3030D0);
    await tester.pumpAndSettle();
    final blue = (await samplePixels(tester, [sample])).single;
    expect(red.r - blue.r, greaterThan(40 / 255),
        reason: 'The shell must transmit the page instead of hiding its blur');
    expect(blue.b - red.b, greaterThan(40 / 255));
    expect(tester.takeException(), isNull);
  });

  testWidgets('The resting and pressed glass have no coloured halo',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    await tester.pumpAndSettle();
    Future<void> expectNeutralLens() async {
      final lens = tester
          .getRect(find.byKey(const ValueKey('navigation-active-pill')))
          .inflate(2);
      final pixels = await samplePixels(tester, [
        for (var y = lens.top.ceil(); y < lens.bottom.floor(); y++)
          for (var x = lens.left.ceil(); x < lens.right.floor(); x++)
            Offset(x.toDouble(), y.toDouble()),
      ]);
      for (final pixel in pixels) {
        final channels = [pixel.r, pixel.g, pixel.b]..sort();
        expect(channels.last - channels.first, lessThanOrEqualTo(8 / 255),
            reason: 'A neutral page must not acquire tinted glass edges');
      }
    }

    await expectNeutralLens();
    final touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await tester.pumpAndSettle();
    await expectNeutralLens();
    await touch.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rapid tab changes retarget the lens without jumping',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    final pill = find.byKey(const ValueKey('navigation-active-pill'));
    await tester.tap(find.byTooltip('Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final moving = tester.getCenter(pill);
    await tester.tap(find.byTooltip('Train'));
    await tester.pump();
    expect(tester.getCenter(pill).dx, closeTo(moving.dx, .01));
    await tester.pumpAndSettle();
    expect(tester.getCenter(pill).dx,
        closeTo(tester.getCenter(find.byTooltip('Train')).dx, .01));
    expect(iconColor(tester, 'Train'), DSColors.navGlassText);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Holding a tab never swells the selection past the dock',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    await tester.pumpAndSettle();
    final lens = find.byKey(const ValueKey('navigation-active-pill'));
    final resting = tester.getSize(lens);
    final icon = find.descendant(
        of: find.byTooltip('Today'), matching: find.byType(NavigationGlyph));
    final iconBefore = tester.getRect(icon);
    final touch = await tester.startGesture(tester.getCenter(icon));
    await tester.pumpAndSettle();
    expect(tester.getSize(lens), resting);
    final capsule =
        tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
    final held = tester.getRect(lens);
    expect(held.top, greaterThanOrEqualTo(capsule.top));
    expect(held.bottom, lessThanOrEqualTo(capsule.bottom));
    expect(tester.getRect(icon), iconBefore);
    await capture(tester, 'navigation-glass-pressed');
    await touch.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(lens), resting);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('The lens follows between icons and settles at the released tab',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selected.add));
    final lens = find.byKey(const ValueKey('navigation-active-pill'));
    final train = tester.getCenter(find.byTooltip('Train'));
    final body = tester.getCenter(find.byTooltip('Body'));
    final between = Offset(ui.lerpDouble(train.dx, body.dx, .3)!, train.dy);
    final touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await touch.moveTo(between);
    await tester.pumpAndSettle();
    expect(tester.getCenter(lens).dx, closeTo(between.dx, .01));
    expect(selected, isEmpty);
    await touch.up();
    await tester.pumpAndSettle();
    expect(selected, [1]);
    expect(tester.getCenter(lens).dx, closeTo(train.dx, .01));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('A second finger cancels the preview without switching tabs',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selected.add));
    final first = await tester
        .startGesture(tester.getCenter(find.byTooltip('Today')), pointer: 1);
    await first.moveTo(tester.getCenter(find.byTooltip('Train')));
    final second = await tester
        .startGesture(tester.getCenter(find.byTooltip('Body')), pointer: 2);
    await first.up();
    await tester.pumpAndSettle();
    await second.up();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();
    expect(selected, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('High contrast keeps an opaque readable selection without blur',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview(highContrast: true));
    await tester.tap(find.byTooltip('Body'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
        tester
            .getCenter(find.byKey(const ValueKey('navigation-active-pill')))
            .dx,
        closeTo(tester.getCenter(find.byTooltip('Body')).dx, .01));
    expect(iconColor(tester, 'Body'), DSColors.navGlassText);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Localized tooltips remain available and reduced motion is immediate',
      (tester) async {
    phone(tester, width: 320);
    await tester.pumpWidget(const _NavigationPreview(
        scale: 1.8,
        reduced: true,
        labels: ['Aujourd’hui', 'Entraînement', 'Corps', 'Progression']));
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byKey(const ValueKey('navigation-tabs')));
    final icons = tester
        .widgetList<NavigationGlyph>(find.descendant(
            of: find.byType(Tooltip), matching: find.byType(NavigationGlyph)))
        .toList();
    expect(icons.map((icon) => icon.kind), [
      NavigationGlyphKind.today,
      NavigationGlyphKind.train,
      NavigationGlyphKind.body,
      NavigationGlyphKind.progress
    ]);
    final tops = [
      for (final label in [
        'Aujourd’hui',
        'Entraînement',
        'Corps',
        'Progression'
      ])
        tester.getTopLeft(find.byTooltip(label)).dy
    ];
    expect(tops.every((top) => (top - tops.first).abs() < .01), isTrue);
    for (var i = 0; i < 4; i++) {
      expect(tester.getRect(find.byKey(ValueKey('navigation-tab-$i'))).bottom,
          bar.bottom);
    }
    await tester.tap(find.byTooltip('Corps'));
    await tester.pump();
    expect(iconColor(tester, 'Corps'), DSColors.navGlassText);
    expect(
        tester
            .getCenter(find.byKey(const ValueKey('navigation-active-pill')))
            .dx,
        closeTo(tester.getCenter(find.byTooltip('Corps')).dx, .01));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await capture(tester, 'navigation-capsule-large');
  });

  testWidgets(
      'Dragging previews quietly and opens only the released destination',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selected.add));
    final before =
        tester.getRect(find.byKey(const ValueKey('navigation-tabs')));
    final touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await touch.moveTo(tester.getCenter(find.byTooltip('Progress')));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(iconColor(tester, 'Progress'), DSColors.navGlassText);
    expect(
        tester.getRect(find.byKey(const ValueKey('navigation-tabs'))), before);
    await touch.up();
    await tester.pumpAndSettle();
    expect(selected, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelled and out-of-bounds drags never navigate',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selected.add));
    var touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await touch.moveTo(tester.getCenter(find.byTooltip('Body')));
    await touch.cancel();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(iconColor(tester, 'Today'), DSColors.navGlassText);
    touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await touch.moveTo(tester.getCenter(find.byTooltip('Progress')));
    await touch.moveBy(const Offset(0, -140));
    await touch.up();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    await tester.tap(find.byTooltip('Train'));
    expect(selected, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Right-to-left dragging follows visual tab positions',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester
        .pumpWidget(_NavigationPreview(rtl: true, onSelected: selected.add));
    expect(tester.getCenter(find.byTooltip('Today')).dx,
        greaterThan(tester.getCenter(find.byTooltip('Progress')).dx));
    final touch =
        await tester.startGesture(tester.getCenter(find.byTooltip('Today')));
    await touch.moveTo(tester.getCenter(find.byTooltip('Body')));
    await touch.up();
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard focus and activation reach every destination',
      (tester) async {
    phone(tester);
    final selected = <int>[];
    await tester.pumpWidget(_NavigationPreview(onSelected: selected.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, [1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(selected, [1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Screen readers receive labelled tab actions and committed selection',
      (tester) async {
    phone(tester);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const _NavigationPreview());
      for (final label in ['Today', 'Train', 'Body', 'Progress']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      }
      await tester.tap(find.byTooltip('Body'));
      await tester.pumpAndSettle();
      final tabs = tester.widgetList<Semantics>(find.descendant(
          of: find.byType(LiquidSilverBottomBar),
          matching: find.byType(Semantics)));
      final selected =
          tabs.where((tab) => tab.properties.selected == true).toList();
      expect(selected.length, 1);
      expect(selected.single.properties.label, 'Body');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Keyboard opening hides the navigation surface', (tester) async {
    phone(tester);
    await tester.pumpWidget(const _NavigationPreview());
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-tabs')), findsNothing);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-tabs')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A footer scrolls clear of the floating capsule', (tester) async {
    phone(tester);
    await tester.pumpWidget(_NavigationPreview(
        body: Builder(
            builder: (context) => ListView(
                    padding: EdgeInsets.fromLTRB(16, 32, 16,
                        LiquidSilverBottomBar.scrollBottomInset(context)),
                    children: [
                      const Text('Your progress',
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 20),
                      Container(
                          height: 420,
                          decoration: BoxDecoration(
                              color: const Color(0xFF202020),
                              borderRadius: BorderRadius.circular(18))),
                      const SizedBox(height: 20),
                      Container(
                          height: 300,
                          decoration: BoxDecoration(
                              color: const Color(0xFF202020),
                              borderRadius: BorderRadius.circular(18))),
                      const SizedBox(height: 20),
                      OutlinedButton(
                          onPressed: () {}, child: const Text('Open workout'))
                    ]))));
    await tester.pumpAndSettle();
    await capture(tester, 'navigation-liquid-glass-over-content');
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    final footer =
        tester.getRect(find.widgetWithText(OutlinedButton, 'Open workout'));
    final bar = tester.getRect(find.byKey(const ValueKey('navigation-bar')));
    expect(bar.top - footer.bottom, closeTo(24, .1));
    await tester.tap(find.byTooltip('Body'));
    await tester.pumpAndSettle();
    await capture(tester, 'navigation-capsule');
    expect(tester.takeException(), isNull);
  });
}
