import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/nutrition_diet_models.dart';
import 'food_art.dart';

/// Compact meal slots keep food logging visible even before the first meal.
class NutritionMealDiary extends StatelessWidget {
  const NutritionMealDiary({
    super.key,
    required this.logs,
    required this.readOnly,
    required this.onAdd,
    required this.onDetail,
  });

  final List<UserMealLogItemModel> logs;
  final bool readOnly;
  final ValueChanged<String> onAdd;
  final ValueChanged<UserMealLogItemModel> onDetail;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final slot in const ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealSlot(
                key: ValueKey('diary-$slot'),
                label: switch (slot) {
                  'BREAKFAST' => 'Breakfast',
                  'LUNCH' => 'Lunch',
                  'DINNER' => 'Dinner',
                  _ => 'Snacks',
                },
                meals: logs.where((meal) {
                  final type = meal.mealType.toUpperCase();
                  return slot == 'SNACK'
                      ? !const ['BREAKFAST', 'LUNCH', 'DINNER'].contains(type)
                      : type == slot;
                }).toList(),
                readOnly: readOnly,
                onAdd: () => onAdd(slot),
                onDetail: onDetail,
              ),
            ),
        ],
      );
}

class _MealSlot extends StatelessWidget {
  const _MealSlot({
    super.key,
    required this.label,
    required this.meals,
    required this.readOnly,
    required this.onAdd,
    required this.onDetail,
  });

  final String label;
  final List<UserMealLogItemModel> meals;
  final bool readOnly;
  final VoidCallback onAdd;
  final ValueChanged<UserMealLogItemModel> onDetail;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side:
              BorderSide(color: Colors.white.withValues(alpha: .09), width: .7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // An empty slot is one large, accessible add target.
            InkWell(
              onTap: meals.isEmpty && !readOnly ? onAdd : null,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    16, meals.isEmpty ? 7 : 2, 8, meals.isEmpty ? 7 : 0),
                child: Row(children: [
                  Expanded(
                    child: FitnessText(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: meals.isEmpty
                                ? FitnessTheme.silver
                                : FitnessTheme.muted)),
                  ),
                  if (meals.isEmpty)
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FitnessText(readOnly ? 'Not logged' : 'Add food',
                            maxLines: 2,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: FitnessTheme.muted, fontSize: 11)),
                      ),
                    ),
                  if (!readOnly)
                    meals.isEmpty
                        ? const ExcludeSemantics(
                            child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(CupertinoIcons.add,
                                    size: 17, color: FitnessTheme.silver)))
                        : IconButton(
                            onPressed: onAdd,
                            tooltip:
                                '${fitnessText(context, 'Add food')} · ${fitnessText(context, label)}',
                            constraints: const BoxConstraints(
                                minWidth: 44, minHeight: 44),
                            icon: const Icon(CupertinoIcons.add,
                                size: 17, color: FitnessTheme.silver)),
                ]),
              ),
            ),
            for (var i = 0; i < meals.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 80, end: 16),
                  child: Divider(height: 1, color: Color(0xFF292929)),
                ),
              _FoodRow(meal: meals[i], onTap: () => onDetail(meals[i])),
            ],
            if (meals.isNotEmpty) const SizedBox(height: 6),
          ],
        ),
      );
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.meal, required this.onTap});

  final UserMealLogItemModel meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(context).toLanguageTag(),
        decimalDigits: 0);
    final amount = NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(context).toLanguageTag(),
        decimalDigits: meal.servings * meal.food.servingSize % 1 == 0 ? 0 : 1);
    final portion =
        '${amount.format(meal.servings * meal.food.servingSize)} ${fitnessText(context, meal.food.servingUnit)}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(children: [
          ExcludeSemantics(child: FoodArt(food: meal.food, size: 52)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(portion,
                    style: const TextStyle(
                        fontSize: 11, height: 1.35, color: FitnessTheme.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(number.format(meal.calories),
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: FitnessTheme.silver,
                    fontWeight: FontWeight.w500)),
            const Text('kcal',
                style: TextStyle(
                    fontSize: 10, height: 1.5, color: FitnessTheme.muted)),
          ]),
        ]),
      ),
    );
  }
}
