import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/models/nutrition_diet_models.dart';
import 'package:setcraft/features/nutrition/utils/food_search_helper.dart';

void main() {
  group('FoodSearchHelper query normalization', () {
    test('normalizes egg queries', () {
      expect(FoodSearchHelper.normalizeForCatalogQuery('egg'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('eggs'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('EGGS'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('  eggs  '), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('whole egg'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('whole eggs'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('raw egg'), 'egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('boiled eggs'), 'boiled egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('hard boiled egg'), 'boiled egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('hard boiled eggs'), 'boiled egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('scrambled eggs'), 'scrambled egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('sunny side up'), 'fried egg');
      expect(FoodSearchHelper.normalizeForCatalogQuery('egg whites'), 'egg white');
    });

    test('normalizes common foods and plurals', () {
      expect(FoodSearchHelper.normalizeForCatalogQuery('apples'), 'apple');
      expect(FoodSearchHelper.normalizeForCatalogQuery('bananas'), 'banana');
      expect(FoodSearchHelper.normalizeForCatalogQuery('potatoes'), 'potato');
      expect(FoodSearchHelper.normalizeForCatalogQuery('tomatoes'), 'tomato');
      expect(FoodSearchHelper.normalizeForCatalogQuery('strawberries'), 'strawberry');
      expect(FoodSearchHelper.normalizeForCatalogQuery('blueberries'), 'blueberry');
      expect(FoodSearchHelper.normalizeForCatalogQuery('oatmeal'), 'oat');
      expect(FoodSearchHelper.normalizeForCatalogQuery('oats'), 'oat');
      expect(FoodSearchHelper.normalizeForCatalogQuery('pb'), 'peanut butter');
      expect(FoodSearchHelper.normalizeForCatalogQuery('yoghurt'), 'yogurt');
      expect(FoodSearchHelper.normalizeForCatalogQuery('eggplant'), 'aubergine');
      expect(FoodSearchHelper.normalizeForCatalogQuery('eggplants'), 'aubergine');
    });
  });

  group('FoodSearchHelper word matching & ranking', () {
    final eggRaw = const NutritionFoodItemModel(
      id: 'egg-raw',
      name: 'Egg — raw',
      category: 'DAIRY_EGGS',
      servingSize: 50,
      servingUnit: 'g',
      caloriesPerServing: 72,
      proteinPerServing: 6.3,
      carbsPerServing: 0.4,
      fatPerServing: 4.8,
      fiberPerServing: 0,
    );

    final boiledEgg = const NutritionFoodItemModel(
      id: 'egg-boiled',
      name: 'Boiled egg',
      category: 'DAIRY_EGGS',
      servingSize: 50,
      servingUnit: 'g',
      caloriesPerServing: 78,
      proteinPerServing: 6.3,
      carbsPerServing: 0.6,
      fatPerServing: 5.3,
      fiberPerServing: 0,
    );

    final scrambledEgg = const NutritionFoodItemModel(
      id: 'egg-scrambled',
      name: 'Scrambled egg',
      category: 'DAIRY_EGGS',
      servingSize: 100,
      servingUnit: 'g',
      caloriesPerServing: 148,
      proteinPerServing: 10.0,
      carbsPerServing: 1.6,
      fatPerServing: 11.0,
      fiberPerServing: 0,
    );

    final aubergine = const NutritionFoodItemModel(
      id: 'veg-aubergine',
      name: 'Aubergine',
      category: 'VEGETABLES',
      servingSize: 100,
      servingUnit: 'g',
      caloriesPerServing: 25,
      proteinPerServing: 1.0,
      carbsPerServing: 5.9,
      fatPerServing: 0.2,
      fiberPerServing: 3.0,
    );

    final allFoods = [aubergine, eggRaw, scrambledEgg, boiledEgg];

    test('searching "egg" ranks Egg — raw #1 and excludes Aubergine', () {
      final results = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'egg');
      expect(results.length, 3);
      expect(results[0].name, 'Egg — raw');
      expect(results.map((f) => f.name), isNot(contains('Aubergine')));
    });

    test('searching "eggs" ranks Egg — raw #1 and excludes Aubergine', () {
      final results = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'eggs');
      expect(results.length, 3);
      expect(results[0].name, 'Egg — raw');
      expect(results.map((f) => f.name), isNot(contains('Aubergine')));
    });

    test('searching "boiled egg" or "boiled eggs" ranks Boiled egg #1', () {
      final r1 = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'boiled egg');
      expect(r1.first.name, 'Boiled egg');

      final r2 = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'boiled eggs');
      expect(r2.first.name, 'Boiled egg');
    });

    test('Aubergine matches when searching "aubergine" or "eggplant"', () {
      final r1 = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'aubergine');
      expect(r1.first.name, 'Aubergine');

      final r2 = FoodSearchHelper.filterAndRank(foods: allFoods, query: 'eggplant');
      expect(r2.first.name, 'Aubergine');
    });
  });
}
