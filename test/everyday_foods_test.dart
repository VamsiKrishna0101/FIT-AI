import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/nutrition/models/nutrition_diet_models.dart';
import 'package:fitai_mobile/features/nutrition/views/meal_portion_view.dart';
import 'package:fitai_mobile/features/nutrition/views/food_library_view.dart';
import 'package:fitai_mobile/features/nutrition/models/food_catalog_page.dart';
import 'nutrition_view_test.dart' show app, capture;
import 'food_library_view_test.dart' show phone;

NutritionFoodItemModel everydayFood(String name) {
  final data =
      jsonDecode(File('../backend/data/everyday_foods.json').readAsStringSync())
          as Map;
  final food = Map<String, dynamic>.from(
      (data['foods'] as List).firstWhere((f) => f['name'] == name) as Map);
  food['portions'] = food['sourceDetails']['portions'];
  food['defaultPortionUnit'] = food['sourceDetails']['defaultPortionUnit'];
  return NutritionFoodItemModel.fromJson(food);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });

  test('cached food retains sourced portions and a sensible preview', () {
    final egg =
        NutritionFoodItemModel.fromJson(everydayFood('Boiled egg').toJson());
    expect(egg.preferredPortion!.gramsPerUnit, 50);
    expect(egg.previewFactor, .5);
    expect(egg.previewQuantity, '1 Large egg');
    final milk = everydayFood('Whole milk — 3.25% fat');
    expect(milk.previewQuantity, '250 ml');
    expect(milk.previewFactor, closeTo(2.578319231, .00001));
  });

  testWidgets(
      'two eggs log their edible weight without assuming two 100 g servings',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? saved;
    await tester.pumpWidget(app(MealPortionView(
        food: everydayFood('Boiled egg'),
        saveMeal: (payload) async {
          saved = payload;
          return false;
        })));
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, '1');
    await tester.enterText(field, '2');
    await tester.pump();
    await capture(tester, 'build/everyday-eggs-preview.png');
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(saved!['servings'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('milk volumes use the source density and allow grams instead',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? saved;
    await tester.pumpWidget(app(MealPortionView(
        food: everydayFood('Whole milk — 3.25% fat'),
        saveMeal: (payload) async {
          saved = payload;
          return false;
        })));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '250');
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(saved!['servings'], closeTo(2.578319231, .00001));
    await tester
        .ensureVisible(find.byType(DropdownButtonFormField<String>).last);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('g').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '100');
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(saved!['servings'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('common foods render with all library sections and owner scopes',
      (tester) async {
    phone(tester);
    final sections = <String>[];
    final foods = [
      'Boiled egg',
      'Whole milk — 3.25% fat',
      'Banana',
      'Rolled oats — dry'
    ].map(everydayFood).toList();
    await tester.pumpWidget(app(FoodLibraryView(
        onMealAdded: () {},
        pageLoader: (_, __, ___, ____, _____, source) async {
          sections.add(source);
          return FoodCatalogPage(
              foods: foods, page: 1, total: foods.length, totalPages: 1);
        })));
    await tester.pumpAndSettle();
    await capture(tester, 'build/everyday-library-preview.png');
    for (final label in ['Recent', 'My foods', 'My meals']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(sections, ['LIBRARY', 'RECENT', 'MY_FOODS', 'MY_MEALS']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom meals keep user values and save as a reusable meal',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? saved;
    await tester.pumpWidget(app(MealPortionView(saveMeal: (payload) async {
      saved = payload;
      return false;
    })));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'My breakfast');
    await tester.enterText(fields.at(1), '1');
    await tester.enterText(fields.at(2), '300');
    await tester.enterText(fields.at(3), '20');
    await tester.enterText(fields.at(4), '40');
    await tester.enterText(fields.at(5), '7');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    expect(saved!['customFood']['category'], 'MEAL');
    expect(saved!['customFood']['calories'], 300);
    expect(saved!['customFood']['protein'], 20);
    expect(saved!['servings'], 1);
    expect(tester.takeException(), isNull);
  });
}
