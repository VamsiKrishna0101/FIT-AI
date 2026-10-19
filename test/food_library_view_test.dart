import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/nutrition/views/food_library_view.dart';
import 'package:fitai_mobile/features/nutrition/views/meal_portion_view.dart';
import 'package:fitai_mobile/features/nutrition/models/food_catalog_page.dart';
import 'package:fitai_mobile/features/nutrition/models/nutrition_diet_models.dart';
import 'nutrition_view_test.dart' show app, capture;

NutritionFoodItemModel food(int n, {String? name}) => NutritionFoodItemModel(
    id: 'food-$n',
    name: name ?? 'Food ${n.toString().padLeft(3, '0')}',
    category: n.isEven ? 'DAIRY' : 'VEGETABLE',
    servingSize: 100,
    servingUnit: 'g',
    caloriesPerServing: 120,
    proteinPerServing: n.isEven ? 20 : 2,
    carbsPerServing: 10,
    fatPerServing: 4,
    fiberPerServing: n.isEven ? 0 : 4);

void phone(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  testWidgets('Library paginates and category filters reset to page one',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(FoodLibraryView(
        initialFoods: List.generate(60, food), onMealAdded: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 3'), findsOneWidget);
    await capture(tester, 'build/food-library-preview.png');
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dairy').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('30 foods'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Successful save returns to nutrition and refreshes once',
      (tester) async {
    phone(tester);
    var refreshes = 0;
    await tester.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => FoodLibraryView(
                        initialFoods: [food(0)],
                        onMealAdded: () => refreshes++,
                        saveMeal: (_) async => true))),
                child: const Text('Open library'))))));
    await tester.tap(find.text('Open library'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Food 000'));
    await tester.tap(find.text('Food 000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(find.text('Open library'), findsOneWidget);
    expect(find.byType(MealPortionView), findsNothing);
    expect(find.byType(FoodLibraryView), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Custom form opens while catalogue request is still pending',
      (tester) async {
    phone(tester);
    final pending = Completer<FoodCatalogPage>();
    await tester.pumpWidget(app(FoodLibraryView(
        onMealAdded: () {},
        pageLoader: (_, __, ___, ____, _____, ______) => pending.future)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Create food'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MealPortionView), findsOneWidget);
    expect(find.text('Food name'), findsOneWidget);
    expect(find.text('Log meal'), findsOneWidget);
    pending.complete(
        const FoodCatalogPage(foods: [], page: 1, total: 0, totalPages: 0));
    await tester.pumpAndSettle();
    final error = tester.takeException();
    if (error is FlutterError) {
      for (final diagnostic in error.diagnostics) {
        debugPrint(diagnostic.toStringDeep());
      }
    }
    expect(error, isNull);
  });
  testWidgets('Old search response cannot replace a newer search',
      (tester) async {
    phone(tester);
    final old = Completer<FoodCatalogPage>(),
        fresh = Completer<FoodCatalogPage>();
    await tester.pumpWidget(app(FoodLibraryView(
        onMealAdded: () {},
        pageLoader: (_, query, ___, ____, _____, ______) {
          if (query == 'old') return old.future;
          if (query == 'new') return fresh.future;
          return Future.value(const FoodCatalogPage(
              foods: [], page: 1, total: 0, totalPages: 0));
        })));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 350));
    fresh.complete(FoodCatalogPage(
        foods: [food(1, name: 'New result')],
        page: 1,
        total: 1,
        totalPages: 1));
    await tester.pumpAndSettle();
    old.complete(FoodCatalogPage(
        foods: [food(0, name: 'Old result')],
        page: 1,
        total: 1,
        totalPages: 1));
    await tester.pumpAndSettle();
    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
  });
  testWidgets('Narrow library handles larger text', (tester) async {
    phone(tester, width: 360);
    await tester.pumpWidget(app(
        FoodLibraryView(initialFoods: [
          food(0,
              name: 'Greek yoghurt, plain, whole milk, traditional preparation')
        ], onMealAdded: () {}),
        locale: 'de',
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'build/food-library-small-preview.png');
  });
  testWidgets('Grams save the correct multiplier and disable duplicate submits',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? payload;
    var calls = 0;
    final saved = Completer<bool>();
    await tester.pumpWidget(app(MealPortionView(
        food: food(0),
        saveMeal: (value) {
          payload = value;
          calls++;
          return saved.future;
        })));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();
    await tester.tap(find.text('Log meal'));
    await tester.pump();
    expect(payload!['servings'], 1.5);
    expect(calls, 1);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    saved.complete(false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Could not save. Your entry is still here. Try again.'), 150,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('Could not save. Your entry is still here. Try again.'),
        findsOneWidget);
    expect((tester.widget<TextField>(find.byType(TextField))).controller!.text,
        '150');
  });
  testWidgets('Custom form keeps inputs through keyboard and scrolling',
      (tester) async {
    phone(tester, width: 360);
    await tester.pumpWidget(app(const MealPortionView(), scale: 1.3));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My oats');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await capture(tester, 'build/custom-meal-small-preview.png');
    final error = tester.takeException();
    if (error is FlutterError) {
      for (final diagnostic in error.diagnostics) {
        debugPrint(diagnostic.toStringDeep());
      }
    }
    expect(error, isNull);
  });
}
