import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/nutrition/views/nutrition_view.dart';
import 'package:fitai_mobile/features/nutrition/views/meal_portion_view.dart';
import 'package:fitai_mobile/features/nutrition/models/nutrition_diet_models.dart';

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
    await tester.pumpWidget(
        app(NutritionView(initial: plan.copyWith(caloriesTarget: 0))));
    await tester.pumpAndSettle();
    expect(find.text('180'), findsNWidgets(2));
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
    await tester.pumpWidget(app(const NutritionView(initial: plan)));
    await tester.pumpAndSettle();
    expect(find.text('15 g'), findsOneWidget);
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
    await tester.pumpWidget(
        app(const NutritionView(initial: plan), locale: 'de', scale: 1.3));
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
    expect(
        find.text(
            'Add a food name, portion size and all four nutrition values. Enter 0 where appropriate.'),
        findsOneWidget);
    expect(find.text('250'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
