import 'package:setcraft/features/progress/components/progress_visual_cards.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/fitness_copy.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/progress_exercise_focus.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';

const bench = <String, dynamic>{
  'id': 'bench',
  'name': 'Bench press',
  'metric': 'load',
  'latest': {'weight': 60, 'reps': 8},
  'first': {'weight': 50, 'reps': 8},
  'firstDate': '2026-10-05',
  'latestDate': '2026-10-30',
  'sessions': 4,
  'loggedSets': 12,
  'totalReps': 96,
  'volume': 5280,
  'change': 20,
  'sparkline': [
    {'date': '2026-10-05', 'value': 50},
    {'date': '2026-10-12', 'value': 55},
    {'date': '2026-10-19', 'value': 55},
    {'date': '2026-10-30', 'value': 60},
  ],
};
const pullUp = <String, dynamic>{
  'id': 'pull-up',
  'name': 'Pull-up',
  'metric': 'reps',
  'latest': {'weight': 0, 'reps': 8},
  'first': {'weight': 0, 'reps': 6},
  'firstDate': '2026-10-05',
  'latestDate': '2026-10-30',
  'sessions': 2,
  'loggedSets': 6,
  'totalReps': 42,
  'volume': null,
  'change': null,
  'sparkline': [
    {'date': '2026-10-05', 'value': 6},
    {'date': '2026-10-30', 'value': 8},
  ],
};
const overview = ProgressOverview({
  'range': {
    'start': '2026-10-03',
    'end': '2026-10-30',
    'previousStart': '2026-09-05',
    'previousEnd': '2026-10-02',
    'comparable': true,
  },
  'summary': {
    'workouts': 12,
    'sets': 144,
    'records': 3,
    'workoutChange': 2,
    'previousWorkouts': 10,
    'hasPreviousTraining': true,
  },
  'weeks': [
    {'date': '2026-09-28', 'workouts': 1, 'sets': 12, 'partial': true},
    {'date': '2026-10-05', 'workouts': 3, 'sets': 36},
    {'date': '2026-10-12', 'workouts': 2, 'sets': 24},
    {'date': '2026-10-19', 'workouts': 3, 'sets': 36},
    {'date': '2026-10-26', 'workouts': 3, 'sets': 36, 'partial': true},
  ],
  'exercises': [bench, pullUp],
  'recentSessions': [
    {'id': 'latest', 'name': 'Upper body', 'date': '2026-10-30'},
  ],
});

Widget page(Widget child,
        {Locale locale = const Locale('en'),
        double scale = 1,
        bool dock = false}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        locale: locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: true, textScaler: TextScaler.linear(scale)),
            child: child!),
        home: RepaintBoundary(
            key: const ValueKey('progress-redesign-preview'),
            child: Scaffold(
                extendBody: true,
                body: child,
                bottomNavigationBar: dock
                    ? LiquidSilverBottomBar(
                        selectedIndex: 3,
                        labels: const ['Today', 'Train', 'Body', 'Progress'],
                        onTabSelected: (_) {})
                    : null)));

void phone(WidgetTester tester, {double width = 393}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 852);
  tester.view.viewPadding = const FakeViewPadding(bottom: 34);
  tester.view.padding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.reset);
}

Future<void> capture(WidgetTester tester, String name,
    {Finder? boundaryFinder}) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        boundaryFinder ??
            find.byKey(const ValueKey('progress-redesign-preview')));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 35 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsWidgets);
}

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

  testWidgets('Featured exercise switches units and opens the chosen exercise',
      (tester) async {
    phone(tester);
    ProgressJson? opened;
    Widget focus() => ProgressExerciseFocus(
        exercises: const [bench, pullUp], onOpen: (row) => opened = row);
    await tester.pumpWidget(page(focus()));
    await tester.pumpAndSettle();
    expect(find.text('60 kg'), findsOneWidget);
    expect(find.text('+20%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-featured-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pull-up').last);
    await tester.pumpAndSettle();
    expect(find.text('8 reps'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('progress-exercise-change')), findsNothing);
    expect(find.text('Best weight'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-featured-details')));
    expect(opened?['id'], 'pull-up');
    await tester.pumpWidget(page(focus()));
    await tester.pumpAndSettle();
    expect(find.text('8 reps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Pins select an available exercise and refresh handles its removal',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(page(ProgressExerciseFocus(
        exercises: const [bench, pullUp],
        pins: const ['pull-up'],
        onOpen: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('8 reps'), findsOneWidget);
    await tester.pumpWidget(page(ProgressExerciseFocus(
        exercises: const [bench], pins: const ['pull-up'], onOpen: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('60 kg'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Period comparison comes from the API, not the truncated chart',
      (tester) async {
    phone(tester);
    final exercise = {
      ...bench,
      'sessions': 24,
      'change': 50,
      'sparkline': [
        for (var i = 0; i < 12; i++)
          {
            'date': '2026-10-${(i + 1).toString().padLeft(2, '0')}',
            'value': 60
          },
      ],
    };
    await tester.pumpWidget(
        page(ProgressExerciseFocus(exercises: [exercise], onOpen: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('+50%'), findsOneWidget);
    expect(find.text('12 recent sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty overview keeps chart destinations and the training action',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const ProgressOverviewView(
        initial: ProgressOverview({
      'summary': {'workouts': 0},
    }))));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('progress-open-training')), findsOneWidget);
    await reveal(
        tester, find.byKey(const ValueKey('progress-view-all-history')));
    expect(find.text('Recovery'), findsNothing);
    expect(find.text('HRV'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overview footer scrolls clear of the raised dock',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(
        page(const ProgressOverviewView(initial: overview), dock: true));
    await tester.pumpAndSettle();
    await capture(tester, 'progress-overview-focused');
    await reveal(
        tester, find.byKey(const ValueKey('progress-view-all-history')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    final footer =
        tester.getRect(find.byKey(const ValueKey('progress-view-all-history')));
    final dock =
        tester.getRect(find.byKey(const ValueKey('navigation-capsule')));
    expect(footer.bottom, lessThan(dock.top));
    expect(tester.takeException(), isNull);
    await capture(tester, 'progress-overview-explore');
  });

  for (final language in AppLanguage.values) {
    testWidgets('New progress copy and narrow layout use ${language.code}',
        (tester) async {
      phone(tester, width: 320);
      await tester.pumpWidget(page(
          const ProgressOverviewView(initial: overview),
          locale: language.locale,
          scale: 1.6));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ProgressOverviewView));
      for (final key in [
        'Muscles',
        'Explore progress',
        'Best weight',
        '{change} workout vs previous period',
        '{change} workouts vs previous period',
        '{count} recent sessions',
      ]) {
        final translated = fitnessText(context, key);
        if (language.locale.languageCode != 'en' &&
            !(language.locale.languageCode == 'fr' && key == 'Muscles')) {
          expect(translated, isNot(key));
        }
        expect(translated, isNotEmpty);
      }
      expect(
          tester
              .renderObject<RenderParagraph>(
                  find.byKey(const ValueKey('progress-title')))
              .didExceedMaxLines,
          isFalse);
      expect(
          tester
              .renderObject<RenderParagraph>(
                  find.byKey(const ValueKey('progress-range-label')))
              .didExceedMaxLines,
          isFalse);
      expect(tester.takeException(), isNull);
      if (language == AppLanguage.germany) {
        await capture(tester, 'progress-overview-german-large');
      }
      await tester.scrollUntilVisible(
          find.byType(ProgressExerciseChartShelf), 120,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('progress-exercise-bench')),
          findsOneWidget);
      await reveal(
          tester, find.byKey(const ValueKey('progress-view-all-history')));
      expect(find.byKey(const ValueKey('progress-view-all-history')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('progress-calendar-button')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
