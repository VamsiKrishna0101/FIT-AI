import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/views/nutrition_view.dart';
import 'package:setcraft/features/nutrition/components/nutrition_summary_card.dart';
import 'package:setcraft/features/nutrition/components/liquid_water_visual.dart';
import 'package:setcraft/features/nutrition/components/food_art.dart';
import 'package:setcraft/features/nutrition/components/food_detail_sheet.dart';
import 'package:setcraft/features/nutrition/components/nutrition_meal_diary.dart';
import 'package:setcraft/features/nutrition/views/meal_portion_view.dart';
import 'package:setcraft/features/nutrition/models/nutrition_diet_models.dart';

const food = NutritionFoodItemModel(
    id: 'test-food',
    name: 'Greek yogurt',
    category: 'DAIRY',
    servingSize: 100,
    servingUnit: 'g',
    caloriesPerServing: 120,
    proteinPerServing: 10,
    carbsPerServing: 12,
    fatPerServing: 4);
const log = UserMealLogItemModel(
    id: 'test-log',
    mealType: 'BREAKFAST',
    calories: 180,
    protein: 15,
    carbs: 18,
    fat: 6,
    status: 'LOGGED',
    servings: 1.5,
    food: food);
const plan = TodayDietPlanModel(
    caloriesConsumed: 180,
    caloriesTarget: 2400,
    proteinConsumed: 15,
    proteinTarget: 150,
    carbsConsumed: 18,
    carbsTarget: 300,
    fatConsumed: 6,
    fatTarget: 70,
    waterConsumed: 750,
    waterTarget: 2800,
    logs: [log]);

Future<Map<String, dynamic>> emptyPlannedMeals() async => {
      'settings': {'mode': 'ROUTINE'},
      'meals': []
    };

Widget app(Widget child, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: RepaintBoundary(
            key: const ValueKey('nutrition-capture'), child: child));

Future<void> capture(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('nutrition-capture')));
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
  testWidgets('Nutrition shows actual intake even without a target',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(NutritionView(
        initial: plan.copyWith(caloriesTarget: 0),
        plannedMealsLoader: emptyPlannedMeals)));
    await tester.pumpAndSettle();
    // Planned meals never contribute to actual intake until logged.
    expect(
        find.descendant(
            of: find.byType(NutritionSummaryCard), matching: find.text('180')),
        findsOneWidget);
    final meters =
        tester.widgetList<LiquidWaterVisual>(find.byType(LiquidWaterVisual));
    expect(meters.length, 3);
    expect(meters.every((meter) => !meter.reactToTilt && !meter.perspective),
        isTrue);
    expect(find.text('Water'), findsNothing);
    expect(find.text('Add meal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Nutrition renders compact macros and meal sections at phone size',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const NutritionView(
        initial: plan, plannedMealsLoader: emptyPlannedMeals)));
    await tester.pumpAndSettle();
    expect(find.text('15 / 150 g'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(NutritionSummaryCard), matching: find.byType(Icon)),
        findsNothing);
    final labels = ['Protein', 'Carbs', 'Fat']
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(labels[0], closeTo(labels[1], .01));
    expect(labels[1], closeTo(labels[2], .01));
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/nutrition-preview.png');
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/nutrition-meals-preview.png');
  });

  testWidgets('German nutrition supports a narrow screen and larger text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(
        const NutritionView(
            initial: plan, plannedMealsLoader: emptyPlannedMeals),
        locale: 'de',
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(find.text('Daily intake'), findsNothing);
    await capture(tester, 'build/nutrition-german-preview.png');
    final error = tester.takeException();
    if (error is FlutterError) {
      for (final diagnostic in error.diagnostics) {
        debugPrint(diagnostic.toStringDeep());
      }
    }
    expect(error, isNull);
    await tester.tap(find.text('Essensplan'));
    await tester.pumpAndSettle();
    await capture(tester, 'build/nutrition-plan-german-preview.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Diary and meal plan stay separate without changing intake',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loads = 0;
    await tester.pumpWidget(app(NutritionView(
        initial: plan,
        plannedMealsLoader: () async {
          loads++;
          return {
            'settings': {'mode': 'ROUTINE'},
            'meals': [
              {
                'key': 'routine:oats',
                'mealType': 'LUNCH',
                'name': 'Oats and berries',
                'source': 'ROUTINE',
                'status': 'PENDING',
                'entries': [
                  {
                    'name': 'Oats',
                    'servingSize': 100,
                    'servingUnit': 'g',
                    'servings': 1,
                    'calories': 380,
                    'protein': 13,
                  }
                ]
              }
            ]
          };
        })));
    await tester.pumpAndSettle();
    expect(loads, 0);
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('Planned for you'), findsNothing);
    final art = tester.widget<FoodArt>(find.byType(FoodArt));
    expect(art.food.id, food.id);
    expect(art.food.imageUrl, isNull); // Custom meals need no photo.
    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.text('Oats and berries'), findsOneWidget);
    expect(find.text('Greek yogurt').hitTestable(), findsNothing);
    expect(
        tester
            .widget<NutritionSummaryCard>(find.byType(NutritionSummaryCard))
            .calories,
        180);
    await capture(tester, 'build/nutrition-plan-preview.png');
    await tester.tap(find.text('Diary'));
    await tester.pumpAndSettle();
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text('Oats and berries').hitTestable(), findsNothing);
    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(
        loads, 1); // The plan and any in-flight actions survive tab switches.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recorded nutrition allows details and prevents editing',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(NutritionView(
        initial: plan,
        date: DateTime.now().subtract(const Duration(days: 7)),
        plannedMealsLoader: emptyPlannedMeals)));
    await tester.pumpAndSettle();
    expect(find.text('Recorded intake'), findsOneWidget);
    expect(find.text('Add meal'), findsNothing);
    expect(find.text('Add food'), findsNothing);
    await tester.tap(find.text('Greek yogurt'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailSheet), findsOneWidget);
    expect(find.text('Remove meal'), findsNothing);
    expect(find.text('180 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty meal slots add to the chosen meal with compact targets',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosen;
    await tester.pumpWidget(app(Scaffold(
        body: NutritionMealDiary(
            logs: const [],
            readOnly: false,
            onAdd: (slot) => chosen = slot,
            onDetail: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Add food'), findsNWidgets(4));
    expect(tester.getSize(find.byKey(const ValueKey('diary-LUNCH'))).height,
        inInclusiveRange(44, 80));
    await tester.tap(find.text('Lunch'));
    expect(chosen, 'LUNCH');
    await tester.tap(find.text('Snacks'));
    expect(chosen, 'SNACK');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food selection previews the actual serving multiplier',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const MealPortionView(food: food)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '150');
    await tester.pumpAndSettle();
    expect(find.text('180 kcal'), findsOneWidget);
    expect(find.text('15.0 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/add-meal-preview.png');
  });

  testWidgets('Custom meal does not silently invent missing nutrition values',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const MealPortionView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(find.text('Use 2–100 characters for the name.'), findsOneWidget);
    expect(find.text('250'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
