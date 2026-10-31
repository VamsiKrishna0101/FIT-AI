import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/nutrition_diet_models.dart';
import 'food_art.dart';

class FoodLibraryCard extends StatelessWidget {
  const FoodLibraryCard({super.key, required this.food, required this.onTap});
  final NutritionFoodItemModel food;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final number =
        NumberFormat('0.#', Localizations.localeOf(context).toLanguageTag());
    final protein = fitnessText(context, '{amount} g protein', values: {
      'amount': number.format(food.proteinPerServing * food.previewFactor)
    });
    final calories = NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag())
        .format((food.caloriesPerServing * food.previewFactor).round());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Material(
        color: DSColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DSColors.border, width: .7)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  ExcludeSemantics(child: FoodArt(food: food, size: 64)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Text(food.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('${foodPortionLabel(context, food)} · $protein',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: DSColors.muted)),
                      ])),
                  const SizedBox(width: 12),
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(calories,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: DSColors.silver)),
                        const SizedBox(height: 3),
                        const Text('kcal',
                            style:
                                TextStyle(fontSize: 10, color: DSColors.muted)),
                      ]),
                ]))),
      ),
    );
  }
}
