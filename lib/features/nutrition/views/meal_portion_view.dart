import 'package:flutter/material.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/food_art.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';

class MealPortionView extends StatefulWidget {
  final NutritionFoodItemModel? food;
  final String initialMealType;
  final Future<bool> Function(Map<String, dynamic> payload)? saveMeal;
  const MealPortionView(
      {super.key, this.food, this.initialMealType = 'LUNCH', this.saveMeal});
  @override
  State<MealPortionView> createState() => _MealPortionViewState();
}

class _MealPortionViewState extends State<MealPortionView> {
  final _quantity = TextEditingController(),
      _name = TextEditingController(),
      _size = TextEditingController(),
      _calories = TextEditingController(),
      _protein = TextEditingController(),
      _carbs = TextEditingController(),
      _fat = TextEditingController();
  String _unit = 'g';
  late String _slot;
  bool _grams = true, _busy = false;
  String? _error;
  bool get _custom => widget.food == null;
  double get _factor =>
      (inputNumber(_quantity.text) ?? 0) /
      (_grams && !_custom ? widget.food!.servingSize : 1);
  @override
  void initState() {
    super.initState();
    _slot = widget.initialMealType;
    _grams = widget.food?.servingUnit == 'g';
    _quantity.text = _grams ? widget.food!.servingSize.toStringAsFixed(0) : '1';
    _quantity.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _quantity,
      _name,
      _size,
      _calories,
      _protein,
      _carbs,
      _fat
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final quantity = inputNumber(_quantity.text);
    if (quantity == null || quantity <= 0 || _factor > 100) {
      setState(() => _error = 'Enter a valid quantity.');
      return;
    }
    Map<String, dynamic>? custom;
    if (_custom) {
      final values = [_calories, _protein, _carbs, _fat]
          .map((c) => inputNumber(c.text))
          .toList();
      final size = inputNumber(_size.text);
      if (_name.text.trim().length < 2 ||
          _name.text.trim().length > 100 ||
          size == null ||
          size <= 0 ||
          values.any((v) => v == null || v < 0)) {
        setState(() => _error =
            'Add a food name, portion size and all four nutrition values. Enter 0 where appropriate.');
        return;
      }
      custom = {
        'name': _name.text.trim(),
        'servingSize': size,
        'servingUnit': _unit,
        'calories': values[0],
        'protein': values[1],
        'carbs': values[2],
        'fat': values[3]
      };
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    bool ok;
    try {
      ok = widget.saveMeal != null
          ? await widget.saveMeal!({
              'mealType': _slot,
              'servings': _factor,
              if (custom != null) 'customFood': custom,
              if (!_custom) 'nutritionId': widget.food!.id
            })
          : await NutritionRepository.shared.logMeal(
              mealType: _slot,
              servings: _factor,
              nutritionId: widget.food?.id,
              customFood: custom);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = 'Could not save. Your entry is still here. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    return FitnessTheme(
        child: PopScope(
            canPop: !_busy,
            child: Scaffold(
                appBar: AppBar(
                    backgroundColor: FitnessTheme.canvas,
                    surfaceTintColor: Colors.transparent,
                    title: FitnessText(_custom ? 'Custom meal' : 'Your portion',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600))),
                bottomNavigationBar: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: FitnessSubmit(
                            label: 'Log meal', busy: _busy, onPressed: _save))),
                body: ListView(padding: const EdgeInsets.all(20), children: [
                  if (food != null) ...[
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FoodArt(food: food, size: 80),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(food.name,
                                    style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3)),
                                const SizedBox(height: 7),
                                Text(
                                    '${food.servingSize.toStringAsFixed(0)} ${food.servingUnit} · ${food.caloriesPerServing.round()} kcal',
                                    style: const TextStyle(
                                        color: FitnessTheme.muted,
                                        fontSize: 12)),
                              ]))
                        ]),
                    const SizedBox(height: 28),
                  ],
                  DropdownButtonFormField<String>(
                      initialValue: _slot,
                      decoration:
                          const InputDecoration(label: FitnessText('Meal')),
                      items: ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK']
                          .map((s) => DropdownMenuItem(
                              value: s, child: FitnessText(mealSlotLabel(s))))
                          .toList(),
                      onChanged:
                          _busy ? null : (v) => setState(() => _slot = v!)),
                  const SizedBox(height: 20),
                  if (_custom) ...[
                    const FitnessText('Nutrition per portion',
                        style:
                            TextStyle(color: FitnessTheme.muted, fontSize: 13)),
                    const SizedBox(height: 12),
                    FitnessInput(label: 'Food name', controller: _name),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: FitnessInput(
                              label: 'Portion size',
                              controller: _size,
                              numeric: true)),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _unit,
                              items: ['g', 'ml', 'portion']
                                  .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u,
                                          style:
                                              const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: _busy
                                  ? null
                                  : (v) => setState(() => _unit = v!)))
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: FitnessInput(
                              label: 'Calories',
                              controller: _calories,
                              numeric: true,
                              unit: 'kcal')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FitnessInput(
                              label: 'Protein',
                              controller: _protein,
                              numeric: true,
                              unit: 'g'))
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: FitnessInput(
                              label: 'Carbs',
                              controller: _carbs,
                              numeric: true,
                              unit: 'g')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FitnessInput(
                              label: 'Fat',
                              controller: _fat,
                              numeric: true,
                              unit: 'g'))
                    ]),
                    const SizedBox(height: 20),
                  ],
                  FitnessInput(
                      label: _grams && !_custom
                          ? 'Amount eaten'
                          : 'Servings eaten',
                      controller: _quantity,
                      numeric: true,
                      unit: _grams && !_custom ? 'g' : null),
                  const SizedBox(height: 12),
                  if (_grams && !_custom)
                    Wrap(spacing: 8, children: [
                      for (final grams in [50, 100, 150, 200])
                        ActionChip(
                            label: Text('$grams g'),
                            onPressed:
                                _busy ? null : () => _quantity.text = '$grams')
                    ]),
                  const SizedBox(height: 24),
                  if (food != null)
                    FitnessCard(
                        child: Column(children: [
                      _value('Calories',
                          '${(food.caloriesPerServing * _factor).round()} kcal'),
                      _value('Protein',
                          '${(food.proteinPerServing * _factor).toStringAsFixed(1)} g'),
                      _value('Carbs',
                          '${(food.carbsPerServing * _factor).toStringAsFixed(1)} g'),
                      _value('Fat',
                          '${(food.fatPerServing * _factor).toStringAsFixed(1)} g'),
                      _value('Fibre',
                          '${(food.fiberPerServing * _factor).toStringAsFixed(1)} g'),
                    ])),
                  if (_custom)
                    const FitnessText(
                        'Use your package label or recipe. No nutrition values are filled in automatically.',
                        style: TextStyle(
                            fontSize: 12,
                            color: FitnessTheme.muted,
                            height: 1.5)),
                  if (food?.sourceName == 'ANSES_CIQUAL')
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                            'Anses. ${food!.sourceVersion}. Ciqual French food composition table.',
                            style: const TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                height: 1.5))),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FitnessText(_error!,
                            style: const TextStyle(
                                color: FitnessTheme.coral, fontSize: 13))),
                ]))));
  }

  Widget _value(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
            child: FitnessText(label,
                style:
                    const TextStyle(color: FitnessTheme.muted, fontSize: 13))),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
      ]));
}

String mealSlotLabel(String slot) => switch (slot) {
      'BREAKFAST' => 'Breakfast',
      'LUNCH' => 'Lunch',
      'DINNER' => 'Dinner',
      _ => 'Snacks'
    };
