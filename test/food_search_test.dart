import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/views/food_library_view.dart';
import 'package:setcraft/features/nutrition/models/nutrition_diet_models.dart';
import 'nutrition_view_test.dart' as nutrition show app;

NutritionFoodItemModel makeFood({
  required String id,
  required String name,
  String category = 'PROTEIN_SOURCE',
}) =>
    NutritionFoodItemModel(
      id: id,
      name: name,
      category: category,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPerServing: 140,
      proteinPerServing: 13,
      carbsPerServing: 1,
      fatPerServing: 10,
    );

void main() {
  final sampleFoods = [
    makeFood(id: '1', name: 'Egg — raw'),
    makeFood(id: '2', name: 'Boiled egg'),
    makeFood(id: '3', name: 'Scrambled egg'),
    makeFood(id: '4', name: 'Fried egg'),
    makeFood(id: '5', name: 'Poached egg'),
    makeFood(id: '6', name: 'Egg white — raw'),
    makeFood(id: '7', name: 'Aubergine — raw', category: 'VEGETABLE'),
    makeFood(id: '8', name: 'Aubergine — cooked', category: 'VEGETABLE'),
    makeFood(id: '9', name: 'Apple', category: 'FRUIT'),
    makeFood(id: '10', name: 'Blueberries', category: 'FRUIT'),
    makeFood(id: '11', name: 'Rolled oats — dry', category: 'CARB_SOURCE'),
  ];

  testWidgets('Searching "egg" returns eggs with Egg — raw first and excludes Aubergine',
      (tester) async {
    await tester.pumpWidget(nutrition.app(FoodLibraryView(
      initialFoods: sampleFoods,
      onMealAdded: () {},
    )));
    await tester.pumpAndSettle();

    // Type "egg"
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'egg');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // "Egg — raw" must be visible
    expect(find.text('Egg — raw'), findsOneWidget);
    expect(find.text('Boiled egg'), findsOneWidget);

    // Aubergine must NOT be found when searching "egg"
    expect(find.text('Aubergine — raw'), findsNothing);
    expect(find.text('Aubergine — cooked'), findsNothing);
  });

  testWidgets('Searching "eggs" (plural) matches eggs cleanly',
      (tester) async {
    await tester.pumpWidget(nutrition.app(FoodLibraryView(
      initialFoods: sampleFoods,
      onMealAdded: () {},
    )));
    await tester.pumpAndSettle();

    // Type "eggs"
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'eggs');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Egg — raw'), findsOneWidget);
    expect(find.text('Boiled egg'), findsOneWidget);
    expect(find.text('Aubergine — raw'), findsNothing);
  });

  testWidgets('Searching "berry" matches plural Blueberries',
      (tester) async {
    await tester.pumpWidget(nutrition.app(FoodLibraryView(
      initialFoods: sampleFoods,
      onMealAdded: () {},
    )));
    await tester.pumpAndSettle();

    // Type "berry"
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'berry');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Blueberries'), findsOneWidget);
  });
}
