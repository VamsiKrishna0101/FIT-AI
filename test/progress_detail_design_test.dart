import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/progress/components/muscle_progress_content.dart';
import 'package:setcraft/features/progress/components/body_progress_content.dart';
import 'package:setcraft/features/progress/components/exercise_progress_content.dart';
import 'package:setcraft/features/progress/components/wellness_progress_content.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';
import 'package:setcraft/features/progress/components/progress_date_filter.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';

const locales = [Locale('en', 'GB'), Locale('de', 'DE'), Locale('de', 'CH')];
const nutrition = {
  'nutrition': [
    {
      'date': '2026-10-01',
      'calories': 2200,
      'protein': 130,
      'carbs': 240,
      'fat': 65,
      'water': 2000,
      'mealLogs': 3
    },
    {
      'date': '2026-10-05',
      'calories': 2400,
      'protein': 150,
      'carbs': 260,
      'fat': 70,
      'water': 2500,
      'mealLogs': 4
    },
    {
      'date': '2026-10-09',
      'calories': 2300,
      'protein': 140,
      'carbs': 250,
      'fat': 68,
      'water': 2200,
      'mealLogs': 3
    },
  ],
  'currentTargets': {
    'targetCalories': 2400,
    'targetProtein': 150,
    'targetCarbs': 280,
    'targetFat': 75
  }
};
const muscles = [
  {'id': 'chest', 'label': 'Chest', 'directSets': 12, 'assistingSets': 2},
  {'id': 'triceps', 'label': 'Triceps', 'directSets': 6, 'assistingSets': 18},
  {'id': 'quads', 'label': 'Quads', 'directSets': 0, 'assistingSets': 0},
];
const muscle = {
  'muscle': {
    'id': 'chest',
    'directSets': 12,
    'assistingSets': 2,
    'trainingDays': 3,
    'lastTrained': '2026-10-09'
  },
  'weeks': [
    {'date': '2026-09-21', 'sets': 0},
    {'date': '2026-09-28', 'sets': 4},
    {'date': '2026-10-05', 'sets': 8},
    {'date': '2026-10-12', 'sets': 0},
  ],
  'exercises': [
    {
      'id': 'bench',
      'name': 'Bench press',
      'latest': {'weight': 62.5, 'reps': 8}
    }
  ]
};
const body = {
  'metrics': [
    {
      'id': 'weightKg',
      'label': 'Weight',
      'unit': 'kg',
      'latest': {'date': '2026-10-09', 'value': 78.5, 'source': 'scale'},
      'series': [
        {
          'source': 'scale',
          'points': [
            {'date': '2026-10-01', 'value': 79},
            {'date': '2026-10-05', 'value': 78.8},
            {'date': '2026-10-09', 'value': 78.5}
          ]
        }
      ]
    },
    {
      'id': 'waistCm',
      'label': 'Waist',
      'unit': 'cm',
      'latest': {'date': '2026-10-09', 'value': 82, 'source': 'tape'},
      'series': [
        {
          'source': 'tape',
          'points': [
            {'date': '2026-10-09', 'value': 82}
          ]
        }
      ]
    },
  ],
  'assessments': []
};
const wellness = {
  'recovery': [
    {
      'date': '2026-10-01',
      'recovery': 70,
      'sleep': 7.5,
      'hrv': 48,
      'hrvMethod': 'RMSSD',
      'rhr': 58
    },
    {
      'date': '2026-10-05',
      'recovery': 85,
      'sleep': 8,
      'hrv': 55,
      'hrvMethod': 'RMSSD',
      'rhr': 56
    },
    {
      'date': '2026-10-09',
      'recovery': 78,
      'sleep': 7.8,
      'hrv': 51,
      'hrvMethod': 'RMSSD',
      'rhr': 57
    },
  ]
};
const exercise = {
  'series': [
    {
      'date': '2026-10-01',
      'load': 55,
      'reps': 8,
      'volume': 440,
      'estimatedStrength': 69.7
    },
    {
      'date': '2026-10-05',
      'load': 60,
      'reps': 8,
      'volume': 480,
      'estimatedStrength': 76
    },
    {
      'date': '2026-10-09',
      'load': 62.5,
      'reps': 8,
      'volume': 500,
      'estimatedStrength': 79.2
    },
  ],
  'records': {
    'bestLoad': {'weight': 62.5, 'reps': 8, 'date': '2026-10-09'},
    'repsAtLoad': [
      {'weight': 62.5, 'reps': 8, 'date': '2026-10-09'}
    ]
  },
  'previous': [
    {
      'date': '2026-10-09',
      'bestSet': {'weight': 62.5, 'reps': 8}
    }
  ],
  'history': [
    {
      'date': '2026-10-09',
      'entries': [
        {'setNumber': 1, 'weight': 62.5, 'reps': 8}
      ]
    }
  ]
};

Widget screen(Widget content, Locale locale, {double scale = 1.4}) =>
    MaterialApp(
        locale: locale,
        supportedLocales: locales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: RepaintBoundary(
                    key: const ValueKey('detail-capture'),
                    child: FitnessTheme(
                        child: Scaffold(
                            appBar: AppBar(title: const Text('Setcraft')),
                            body: SingleChildScrollView(
                                key: ObjectKey(content),
                                padding: const EdgeInsets.all(18),
                                child: content)))))));

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('detail-capture')))
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
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final locale in locales) {
    testWidgets(
        'All detail screens fit narrow ${locale.toLanguageTag()} with larger text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final views = <String, Widget>{
        'nutrition':
            const WellnessProgressContent(data: nutrition, nutrition: true),
        'muscles':
            MuscleDistributionContent(muscles: muscles, onMuscle: (_) {}),
        'muscle': MuscleProgressContent(data: muscle, onExercise: (_) {}),
        'body': BodyProgressContent(data: body, onAdd: () {}, onRecord: (_) {}),
        'recovery': const WellnessProgressContent(data: wellness),
        'exercise': const ExerciseProgressContent(data: exercise),
      };
      for (final view in views.entries) {
        await tester.pumpWidget(screen(view.value, locale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: view.key);
        await capture(tester, 'detail-${view.key}-${locale.toLanguageTag()}');
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -850));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${view.key} scrolled');
      }
      await tester.pumpWidget(screen(
          ProgressDateFilter(
              period: '4w',
              rangeLabel: '21 September 2026 – 18 October 2026',
              onChanged: (_, __) {}),
          locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Muscle selector changes ordering without treating assisting sets as direct sets',
      (tester) async {
    await tester.pumpWidget(screen(
        MuscleDistributionContent(muscles: muscles, onMuscle: (_) {}),
        locales.first,
        scale: 1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Chest')).dy,
        lessThan(tester.getTopLeft(find.text('Triceps')).dy));
    await tester.tap(find.text('Assisting sets'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Triceps')).dy,
        lessThan(tester.getTopLeft(find.text('Chest')).dy));
    expect(find.text('18'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Chart reading table paginates and retains a real zero',
      (tester) async {
    await tester.pumpWidget(screen(
        ProgressChart(
            points: List.generate(
                10,
                (index) => ProgressPoint(
                    DateTime(2026, 10, index + 1), index.toDouble())),
            showReadings: true,
            unit: 'kg'),
        locales.first,
        scale: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recorded readings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('0 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
