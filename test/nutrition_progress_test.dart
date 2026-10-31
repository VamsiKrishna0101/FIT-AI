import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/progress/components/wellness_progress_content.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';

const data = <String, dynamic>{
  'nutrition': [
    {
      'date': '2026-10-01',
      'calories': 2000,
      'protein': 0,
      'carbs': 250,
      'fat': 60,
      'water': 2000,
      'mealLogs': 3
    },
    {
      'date': '2026-10-02',
      'calories': null,
      'protein': null,
      'carbs': null,
      'fat': null,
      'water': 1000,
      'mealLogs': 0
    },
    {
      'date': '2026-10-03',
      'calories': 2600,
      'protein': 160,
      'carbs': 300,
      'fat': 80,
      'water': 3000,
      'mealLogs': 4
    },
  ],
  'currentTargets': {
    'targetCalories': 2400,
    'targetProtein': 150,
    'targetCarbs': 300,
    'targetFat': 70
  },
};

Widget screen(ProgressJson data,
        {bool compact = false,
        double scale = 1,
        Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
          data: MediaQueryData(
              disableAnimations: true, textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: FitnessTheme(
                  child: Scaffold(
                appBar: AppBar(title: const Text('Nutrition')),
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: WellnessProgressContent(
                        data: data, nutrition: true, compact: compact)),
              )))),
    );

Future<void> capture(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
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

  testWidgets(
      'nutrition averages exclude missing values and retain a recorded zero',
      (tester) async {
    await tester.pumpWidget(screen(data));
    await tester.pumpAndSettle();
    final chart = tester.widget<ProgressChart>(find.byType(ProgressChart));
    expect(chart.points.map((point) => point.value), [2000, 2600]);
    expect(chart.reference, 2400);
    expect(find.text('80 g'), findsOneWidget);
    expect(find.text('2 recorded days'), findsOneWidget);
    await tester.tap(find.text('Protein').first);
    await tester.pumpAndSettle();
    final protein = tester.widget<ProgressChart>(find.byType(ProgressChart));
    expect(protein.points.map((point) => point.value), [0, 160]);
    expect(protein.reference, 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('water uses liters and does not invent a hydration goal',
      (tester) async {
    await tester.pumpWidget(screen(data));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Water').first);
    await tester.tap(find.text('Water').first);
    await tester.pumpAndSettle();
    final chart = tester.widget<ProgressChart>(find.byType(ProgressChart));
    expect(chart.points.map((point) => point.value), [2, 1, 3]);
    expect(chart.unit, 'L');
    expect(chart.reference, isNull);
    expect(chart.showReference, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty nutrition keeps totals unknown without sample values',
      (tester) async {
    await tester.pumpWidget(screen(const {'nutrition': []}));
    await tester.pumpAndSettle();
    expect(find.text('No readings in this period'), findsOneWidget);
    expect(find.text('0 g'), findsNothing);
    expect(find.text('Current target'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nutrition supports narrow German layout and larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(screen(data, scale: 1.8, locale: const Locale('de')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated compact nutrition and detail render at phone size',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preview = {
      ...data,
      'nutrition': List.generate(
          28,
          (index) => {
                'date': DateTime(2026, 9, 17 + index)
                    .toIso8601String()
                    .substring(0, 10),
                'calories': 2150 + index % 5 * 120,
                'protein': 130 + index % 7 * 5,
                'carbs': 230 + index % 4 * 15,
                'fat': 60 + index % 3 * 5,
                'water': 2000 + index % 4 * 250,
                'mealLogs': 4,
              }),
    };
    await tester.pumpWidget(screen(preview, compact: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/nutrition-progress-preview.png');
    await tester.pumpWidget(screen(preview));
    await tester.pumpAndSettle();
    await capture(tester, 'build/nutrition-progress-detail-preview.png');
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(find.text('Your logging rhythm'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/nutrition-progress-summary-preview.png');
  });
}
