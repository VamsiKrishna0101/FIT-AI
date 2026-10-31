import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/nutrition/components/meal_food_picker.dart';
import 'package:setcraft/features/nutrition/components/planned_meals_section.dart';
import 'package:setcraft/features/nutrition/models/nutrition_diet_models.dart';
import 'package:setcraft/features/nutrition/views/food_routine_view.dart';
import 'package:setcraft/features/nutrition/views/saved_meal_editor_view.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'nutrition_view_test.dart' show app, capture;

const meal = NutritionFoodItemModel(
    id: 'meal-1',
    name: 'My breakfast',
    category: 'MEAL',
    servingSize: 1,
    servingUnit: 'portion',
    caloriesPerServing: 400,
    proteinPerServing: 30,
    carbsPerServing: 40,
    fatPerServing: 12);

void phone(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> open(WidgetTester tester, Widget page, {double scale = 1}) async {
  final navigator = Navigator(onGenerateRoute: (_) {
    return MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: Builder(builder: (context) {
              return TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => page)),
                child: const Text('Open'),
              );
            })));
  });
  await tester.pumpWidget(app(navigator, scale: scale));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Map<String, dynamic> planned(String status) => {
      'settings': {'mode': 'ROUTINE'},
      'meals': [
        {
          'key': 'routine:one',
          'mealType': 'BREAKFAST',
          'name': 'My breakfast',
          'source': 'ROUTINE',
          'status': status,
          'entries': [
            {
              'name': 'Oats and yogurt',
              'servingSize': 1,
              'servingUnit': 'portion',
              'servings': 1,
              'calories': 400,
              'protein': 30
            }
          ]
        }
      ]
    };

void main() {
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });

  testWidgets(
      'A named custom meal saves without a photo and accepts zero macros',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? saved;
    await open(tester, SavedMealEditorView(save: (body) async {
      saved = body;
      return meal;
    }));
    expect(find.text('Your meal, your way'), findsNothing);
    expect(find.text('New meal'), findsOneWidget);
    await capture(tester, 'build/new-meal-preview.png');
    expect(find.text('Add photo'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'My breakfast');
    await tester.tap(find.text('Enter nutrition'));
    await tester.pumpAndSettle();
    await capture(tester, 'build/meal-nutrition-preview.png');
    final fields = find.byType(TextField);
    for (var n = 1; n <= 4; n++) {
      await tester.ensureVisible(fields.at(n));
      await tester.enterText(fields.at(n), n == 1 ? '400' : '0');
    }
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(saved?['name'], 'My breakfast');
    expect(saved?['manual'],
        {'calories': 400.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0});
    expect(saved?.containsKey('image'), false);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'A name alone never invents nutrition and the form fits a narrow screen',
      (tester) async {
    phone(tester, width: 360);
    var calls = 0;
    await open(tester, SavedMealEditorView(save: (_) async {
      calls++;
      return meal;
    }), scale: 1.3);
    await tester.enterText(find.byType(TextField).first, 'My dinner');
    await tester.tap(find.text('Enter nutrition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Enter all four nutrition values. Use 0 if needed.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await capture(tester, 'build/custom-meal-preview.png');
  });

  testWidgets('Saving locks the form and failed entries can be retried intact',
      (tester) async {
    phone(tester);
    final pending = Completer<NutritionFoodItemModel>();
    var calls = 0;
    await open(tester, SavedMealEditorView(save: (_) async {
      calls++;
      if (calls == 1) return pending.future;
      return meal;
    }));
    await tester.enterText(find.byType(TextField).first, 'My lunch');
    await tester.tap(find.text('Enter nutrition'));
    await tester.pumpAndSettle();
    for (var index = 1; index <= 4; index++) {
      await tester.ensureVisible(find.byType(TextField).at(index));
      await tester.enterText(
          find.byType(TextField).at(index), index == 1 ? '400' : '20');
    }
    await tester.tap(find.text('Save meal'));
    await tester.tap(find.text('Save meal'));
    await tester.pump();
    expect(calls, 1);
    expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        true);
    await tester.pageBack();
    await tester.pump();
    expect(find.byType(SavedMealEditorView), findsOneWidget);
    pending.completeError(Exception('Could not save. Please try again.'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Please try again.').hitTestable(),
        findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'My lunch');
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Routine requires days and positive portions before saving',
      (tester) async {
    phone(tester);
    Map<String, dynamic>? saved;
    await open(
        tester,
        MealRoutineEditorView(
            meals: const [meal],
            save: (body) async {
              saved = body;
            }));
    await capture(tester, 'build/meal-routine-preview.png');
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('MON'));
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.enterText(find.byType(TextField).first, '1.5');
    await tester.tap(find.text('Save routine'));
    await tester.pumpAndSettle();
    expect(saved?['days'], ['MONDAY']);
    expect(saved?['servings'], 1.5);
    expect(saved?['nutritionId'], meal.id);
    expect(saved?['paused'], false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Planned meals stay separate and repeated taps submit once',
      (tester) async {
    phone(tester);
    final pending = Completer<void>();
    var status = 'PENDING', calls = 0;
    await tester.pumpWidget(app(FitnessTheme(
        child: Scaffold(
            body: ListView(padding: const EdgeInsets.all(20), children: [
      PlannedMealsSection(
          date: DateTime.now(),
          loader: () async => planned(status),
          action: (key, action, replacement) async {
            calls++;
            await pending.future;
            status = action;
          })
    ])))));
    await tester.pumpAndSettle();
    expect(find.text('Planned for you'), findsOneWidget);
    expect(find.text('Log meal'), findsOneWidget);
    await capture(tester, 'build/planned-meals-preview.png');
    await tester.tap(find.text('Log meal'));
    await tester.tap(find.text('Log meal'));
    await tester.pump();
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Log meal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Future meal cannot be logged; skipping and restoring are explicit',
      (tester) async {
    phone(tester, width: 360);
    var status = 'PENDING';
    final actions = <String>[];
    await tester.pumpWidget(app(
        Scaffold(
            body: ListView(padding: const EdgeInsets.all(20), children: [
          PlannedMealsSection(
              date: DateTime.now().add(const Duration(days: 1)),
              loader: () async => planned(status),
              action: (_, action, __) async {
                actions.add(action);
                status = action == 'RESET' ? 'PENDING' : action;
              })
        ])),
        scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.ensureVisible(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(actions, ['SKIPPED']);
    await tester.ensureVisible(find.text('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(actions, ['SKIPPED', 'RESET']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food amount validates input and converts grams to servings',
      (tester) async {
    phone(tester);
    double? amount;
    const food = NutritionFoodItemModel(
        id: 'oats',
        name: 'Oats',
        category: 'CARB_SOURCE',
        servingSize: 100,
        servingUnit: 'g',
        caloriesPerServing: 380,
        proteinPerServing: 13,
        carbsPerServing: 60,
        fatPerServing: 7);
    await tester.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  amount = await showDialog<double>(
                      context: context,
                      builder: (_) => const MealFoodAmountDialog(food: food));
                },
                child: const Text('Amount'))))));
    await tester.tap(find.text('Amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();
    expect(amount, isNull);
    expect(find.textContaining('Enter an amount greater than zero'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();
    expect(amount, .5);
    expect(tester.takeException(), isNull);
  });
}
