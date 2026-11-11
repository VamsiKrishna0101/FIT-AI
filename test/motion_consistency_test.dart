import 'dart:io';
import 'dart:ui' as ui;

import 'package:setcraft/core/components/content_transition.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/features/history/repositories/history_repository.dart';
import 'package:setcraft/features/onboarding/components/onboarding_scaffold.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const captureKey = ValueKey('motion-capture');

Widget app(Widget child, {bool reduced = false}) => RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: child,
      ),
    );

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
}

Widget onboarding(ValueNotifier<int> part, VoidCallback oldAction,
        {bool reduced = false}) =>
    app(
        ValueListenableBuilder<int>(
          valueListenable: part,
          builder: (context, value, _) => OnboardingScaffold(
            step: 3,
            part: value,
            parts: 3,
            sectionLabel: 'Your training',
            title: [
              'Choose your days',
              'Choose your session length',
              'Choose your space'
            ][value],
            subtitle: 'A plan that fits your week.',
            actionTitle: 'Continue',
            onBack: () => part.value = (part.value - 1).clamp(0, 2),
            onContinue: () => part.value = (part.value + 1).clamp(0, 2),
            children: [
              OnboardingChoice(
                title: ['3 days a week', '45 minutes', 'Gym'][value],
                selected: true,
                onTap: oldAction,
              ),
            ],
          ),
        ),
        reduced: reduced);

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

  testWidgets(
      'Onboarding transitions keep chrome fixed and block outgoing choices',
      (tester) async {
    phone(tester);
    final part = ValueNotifier(0);
    addTearDown(part.dispose);
    await tester.pumpWidget(onboarding(part, () {}));
    final buttonBefore = tester.getRect(find.byType(LiquidChromeButton));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    // Continue paints its busy state before starting the next question.
    await tester.pump();
    // The outgoing question has blurred away; the next is still sharpening.
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Choose your days'), findsOneWidget);
    expect(find.text('Choose your session length'), findsOneWidget);
    expect(tester.getRect(find.byType(LiquidChromeButton)), buttonBefore);
    final ignored = find.ancestor(
        of: find.text('3 days a week'), matching: find.byType(IgnorePointer));
    expect(
        tester.widgetList<IgnorePointer>(ignored).any((w) => w.ignoring), true);
    final fades = [
      for (final title in ['Choose your days', 'Choose your session length'])
        tester.widget<Opacity>(find
            .ancestor(of: find.text(title), matching: find.byType(Opacity))
            .first),
    ];
    expect(fades.first.opacity, 0);
    expect(fades.last.opacity, inExclusiveRange(0, 1));
    await capture(tester, 'motion-onboarding-mid');
    await tester.pumpAndSettle();
    expect(find.text('Choose your days'), findsNothing);
    await capture(tester, 'motion-onboarding-settled');
    for (final next in [2, 1, 0, 2]) {
      part.value = next;
      await tester.pump(const Duration(milliseconds: 35));
    }
    await tester.pumpAndSettle();
    expect(find.text('Choose your space'), findsOneWidget);
    expect(find.text('Choose your days'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion replaces questions immediately', (tester) async {
    final part = ValueNotifier(0);
    addTearDown(part.dispose);
    await tester.pumpWidget(onboarding(part, () {}, reduced: true));
    part.value = 1;
    await tester.pump();
    expect(find.text('Choose your days'), findsNothing);
    expect(find.text('Choose your session length'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choice foreground and background animate together',
      (tester) async {
    final selected = ValueNotifier(false);
    addTearDown(selected.dispose);
    await tester.pumpWidget(app(Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: selected,
        builder: (_, value, __) => OnboardingChoice(
            title: 'Three days',
            selected: value,
            onTap: () => selected.value = !value),
      ),
    )));
    await tester.tap(find.text('Three days'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final label = tester.widget<Text>(find.text('Three days'));
    expect(label.style!.color, isNot(Colors.black));
    expect(label.style!.color, isNot(Colors.white));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Three days')).style!.color,
        Colors.black);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continue label stays centered when loading starts',
      (tester) async {
    final loading = ValueNotifier(false);
    addTearDown(loading.dispose);
    await tester.pumpWidget(app(Scaffold(
        body: Center(
      child: SizedBox(
          width: 320,
          child: ValueListenableBuilder<bool>(
            valueListenable: loading,
            builder: (_, busy, __) => LiquidChromeButton(
                title: 'Continue',
                showArrow: false,
                isLoading: busy,
                onPressed: () {}),
          )),
    ))));
    final center = tester.getCenter(find.text('Continue'));
    loading.value = true;
    await tester.pump();
    expect(tester.getCenter(find.text('Continue')), center);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Home loading fades and late sleep history leaves readiness anchored',
      (tester) async {
    phone(tester);
    final loaded = ValueNotifier(false);
    final history = ValueNotifier<List<RecoveryPoint>>([]);
    addTearDown(loaded.dispose);
    addTearDown(history.dispose);
    final date = DateTime(2026, 10, 6);
    final data = HomeData(
        user: const HomeUser(name: 'Vikram', streakDays: 0),
        nutrition: HomeNutrition.fromJson({}),
        weeklyStreak: const []);
    Widget dashboard() => app(Scaffold(
            body: SafeArea(
                child: ValueListenableBuilder<bool>(
          valueListenable: loaded,
          builder: (_, ready, __) => TodayDashboard(
            data: ready ? data : null,
            loading: !ready,
            now: date,
            recoveryUpdates: history,
            onRefresh: () async {},
            onProfile: () {},
            onSession: () {},
            onTrain: () {},
            onNutrition: () {},
          ),
        ))));
    await tester.pumpWidget(dashboard());
    final header =
        tester.getRect(find.byKey(const ValueKey('today-fixed-header')));
    loaded.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final fades = tester.widgetList<FadeTransition>(find.descendant(
        of: find.byType(ContentTransition).first,
        matching: find.byType(FadeTransition)));
    expect(
        fades.any((fade) => fade.opacity.value > 0 && fade.opacity.value < 1),
        true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('today-fixed-header'))),
        header);
    final ring = find.byKey(const ValueKey('today-readiness-heading'));
    final before = tester.getTopLeft(ring).dy;
    final ringState = tester.element(ring);
    history.value = [RecoveryPoint(date: date, sleepHours: 7.5)];
    await tester.pump();
    expect(tester.getTopLeft(ring).dy, closeTo(before, .1));
    await tester.pump(const Duration(milliseconds: 90));
    final during = tester.getTopLeft(ring).dy;
    await capture(tester, 'motion-home-history-mid');
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(ring).dy;
    expect(during, closeTo(before, .1));
    expect(after, closeTo(before, .1));
    expect(tester.element(ring), same(ringState));
    await capture(tester, 'motion-home-history-settled');
    await tester.pumpWidget(dashboard());
    expect(tester.element(ring), same(ringState));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion resizes late sections immediately',
      (tester) async {
    final height = ValueNotifier(0.0);
    addTearDown(height.dispose);
    await tester.pumpWidget(app(
        Scaffold(
            body: Column(children: [
          ValueListenableBuilder<double>(
              valueListenable: height,
              builder: (_, value, __) =>
                  ContentResize(child: SizedBox(height: value))),
          const Text('Next section'),
        ])),
        reduced: true));
    height.value = 120;
    await tester.pump();
    expect(tester.getTopLeft(find.text('Next section')).dy, 120);
    expect(tester.binding.hasScheduledFrame, false);
    expect(tester.takeException(), isNull);
  });
}
