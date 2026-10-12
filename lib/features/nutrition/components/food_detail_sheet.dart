import 'package:flutter/material.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';

class FoodDetailSheet extends StatefulWidget {
  final UserMealLogItemModel mealLog;
  final VoidCallback onUpdated;
  const FoodDetailSheet(
      {super.key, required this.mealLog, required this.onUpdated});
  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  bool _busy = false;
  bool _confirm = false;
  String? _error;
  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok =
        await NutritionRepository.shared.deleteMealLog(widget.mealLog.id);
    if (!mounted) return;
    if (ok) {
      widget.onUpdated();
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.mealLog;
    return FitnessTheme(
        child: SafeArea(
            top: false,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.food.name,
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5)),
                      const SizedBox(height: 8),
                      Text(
                          '${meal.servings} × ${meal.food.servingSize.round()} ${meal.food.servingUnit}',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.muted)),
                      const SizedBox(height: 24),
                      FitnessCard(
                          child: Column(children: [
                        for (final pair in [
                          ('Calories', '${meal.calories.round()} kcal'),
                          ('Protein', '${meal.protein.toStringAsFixed(1)} g'),
                          ('Carbs', '${meal.carbs.toStringAsFixed(1)} g'),
                          ('Fat', '${meal.fat.toStringAsFixed(1)} g')
                        ])
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(children: [
                                Expanded(
                                    child: FitnessText(pair.$1,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: FitnessTheme.muted))),
                                Text(pair.$2,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500)),
                              ])),
                      ])),
                      const SizedBox(height: 24),
                      if (AppDataMode.shared.preview)
                        const FitnessText('Preview data',
                            style: TextStyle(
                                color: FitnessTheme.muted, fontSize: 12))
                      else ...[
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FitnessText(_error!,
                                  style: const TextStyle(
                                      color: FitnessTheme.coral))),
                        if (_confirm) ...[
                          const FitnessText('Remove this meal from today?',
                              style: TextStyle(fontSize: 15)),
                          const SizedBox(height: 16),
                          FitnessSubmit(
                              label: 'Remove meal',
                              busy: _busy,
                              onPressed: _delete),
                          Center(
                              child: TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _confirm = false),
                                  child: const FitnessText('Cancel'))),
                        ] else
                          OutlinedButton(
                              onPressed: () => setState(() => _confirm = true),
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  backgroundColor: FitnessTheme.surface,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              child: const FitnessText('Remove meal',
                                  style: TextStyle(color: FitnessTheme.coral))),
                      ],
                    ]))));
  }
}
