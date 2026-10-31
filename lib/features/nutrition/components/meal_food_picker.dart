import 'package:flutter/material.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import 'nutrition_entry_fields.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../models/nutrition_diet_models.dart';
import '../views/food_library_view.dart';

Future<(NutritionFoodItemModel, double)?> pickMealFood(
    BuildContext context) async {
  NutritionFoodItemModel? selected;
  final route = AppPageRoute<void>(
      page: FoodLibraryView(
          onMealAdded: () {}, onFoodSelected: (food) => selected = food));
  await Navigator.of(context).push(route);
  await route.completed;
  if (!context.mounted || selected == null) return null;
  final food = selected!;
  final servings = await showDialog<double>(
      context: context, builder: (_) => MealFoodAmountDialog(food: food));
  if (!context.mounted || servings == null) return null;
  return (food, servings);
}

class MealFoodAmountDialog extends StatefulWidget {
  final NutritionFoodItemModel food;
  const MealFoodAmountDialog({super.key, required this.food});
  @override
  State<MealFoodAmountDialog> createState() => _MealFoodAmountDialogState();
}

class _MealFoodAmountDialogState extends State<MealFoodAmountDialog> {
  late final TextEditingController _amount;
  String? _error;
  @override
  void initState() {
    super.initState();
    final food = widget.food;
    _amount = TextEditingController(
        text: (food.previewFactor *
                food.servingSize /
                (food.preferredPortion?.gramsPerUnit ?? 1))
            .toStringAsFixed(1)
            .replaceFirst(RegExp(r'\.0$'), ''));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final food = widget.food;
    final amount = inputNumber(_amount.text);
    final factor = amount == null
        ? 0.0
        : amount *
            (food.preferredPortion?.gramsPerUnit ?? 1) /
            food.servingSize;
    if (!factor.isFinite || factor <= 0 || factor > 100) {
      setState(() =>
          _error = 'Enter an amount greater than zero, up to 100 servings.');
      return;
    }
    Navigator.pop(context, factor);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: AlertDialog(
        backgroundColor: FitnessTheme.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: FitnessTheme.line, width: .7)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(widget.food.name,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500, height: 1.3)),
        content: NutritionEntryLabel(
            label: 'Amount eaten',
            child: TextField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _submit(),
                decoration: nutritionEntryDecoration(
                        unit: fitnessText(
                            context,
                            widget.food.preferredPortion?.label ??
                                widget.food.servingUnit))
                    .copyWith(errorText: _error))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const FitnessText('Cancel')),
          FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  backgroundColor: FitnessTheme.silver,
                  foregroundColor: FitnessTheme.canvas,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const FitnessText('Add to meal',
                  style: TextStyle(fontSize: 13))),
        ],
      ));
}
