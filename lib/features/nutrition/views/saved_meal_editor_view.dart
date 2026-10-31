import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/fitness_form.dart' show inputNumber;
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/meal_food_picker.dart';
import '../components/food_art.dart';
import '../components/nutrition_entry_fields.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/food_planning_repository.dart';

class SavedMealEditorView extends StatefulWidget {
  final Future<NutritionFoodItemModel> Function(Map<String, dynamic>)? save;
  const SavedMealEditorView({super.key, this.save});
  @override
  State<SavedMealEditorView> createState() => _SavedMealEditorViewState();
}

class _SavedMealEditorViewState extends State<SavedMealEditorView> {
  final _name = TextEditingController();
  final _fields = List.generate(5, (_) => TextEditingController());
  final _foods = <(NutritionFoodItemModel, double)>[];
  bool _manual = false, _busy = false, _adding = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy || _adding) return;
    setState(() => _adding = true);
    final entry = await pickMealFood(context);
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (entry != null) _foods.add(entry);
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final values = _fields.map((c) => inputNumber(c.text)).toList();
    final message =
        _name.text.trim().length < 2 || _name.text.trim().length > 100
            ? 'Use 2–100 characters for the name.'
            : !_manual && _foods.isEmpty
                ? 'Add at least one food.'
                : _manual && values.take(4).any((n) => n == null || n < 0)
                    ? 'Enter all four nutrition values. Use 0 if needed.'
                    : _manual &&
                            _fields[4].text.isNotEmpty &&
                            (values[4] == null || values[4]! < 0)
                        ? 'Enter a valid fibre amount.'
                        : null;
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final meal =
          await (widget.save ?? FoodPlanningRepository.shared.saveMeal)({
        'name': _name.text.trim(),
        if (_manual)
          'manual': {
            'calories': values[0],
            'protein': values[1],
            'carbs': values[2],
            'fat': values[3],
            if (values[4] != null) 'fiber': values[4]
          }
        else
          'components': _foods
              .map((f) => {'nutritionId': f.$1.id, 'servings': f.$2})
              .toList(),
      });
      if (mounted) Navigator.pop(context, meal);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double _total(double Function(NutritionFoodItemModel) value) =>
      _foods.fold(0.0, (total, food) => total + value(food.$1) * food.$2);

  Widget _food(int index) {
    final (food, portions) = _foods[index];
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FitnessCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              FoodArt(food: food, size: 48),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Text(
                        '${(food.servingSize * portions).toStringAsFixed(1)} ${food.servingUnit} · ${(food.caloriesPerServing * portions).round()} kcal',
                        style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: FitnessTheme.muted)),
                  ])),
              IconButton(
                  tooltip: fitnessText(context, 'Remove food'),
                  onPressed: _busy
                      ? null
                      : () => setState(() => _foods.removeAt(index)),
                  icon: const Icon(CupertinoIcons.xmark,
                      size: 16, color: FitnessTheme.muted)),
            ])));
  }

  Widget _summaryValue(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(label,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: FitnessTheme.silver)),
      ]);

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
              centerTitle: true,
              backgroundColor: FitnessTheme.canvas,
              surfaceTintColor: Colors.transparent,
              title: const FitnessText('New meal',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
          bottomNavigationBar: NutritionEntryFooter(
              label: 'Save meal',
              busy: _busy,
              error: _error,
              onPressed: _adding ? null : _save),
          body: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                NutritionEntryField(
                    label: 'Meal name', controller: _name, enabled: !_busy),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                        padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                        backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? const Color(0xFF303030)
                                : const Color(0xFF0D0D0D)),
                        foregroundColor:
                            const WidgetStatePropertyAll(FitnessTheme.silver),
                        side: const WidgetStatePropertyAll(
                            BorderSide(color: FitnessTheme.line, width: .7)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: FitnessText('Choose foods',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                      ButtonSegment(
                          value: true,
                          label: FitnessText('Enter nutrition',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12)))
                    ],
                    selected: {_manual},
                    onSelectionChanged: _busy || _adding
                        ? null
                        : (selection) => setState(() {
                              _manual = selection.first;
                              _error = null;
                            })),
                const SizedBox(height: 24),
                if (_manual) ...[
                  const FitnessText('Nutrition per portion',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  NutritionEntryGrid(children: [
                    for (var i = 0; i < _fields.length; i++)
                      NutritionEntryField(
                          label: [
                            'Calories',
                            'Protein',
                            'Carbs',
                            'Fat',
                            'Fibre (optional)'
                          ][i],
                          controller: _fields[i],
                          enabled: !_busy,
                          numeric: true,
                          unit: i == 0 ? 'kcal' : 'g'),
                  ]),
                ] else ...[
                  for (var i = 0; i < _foods.length; i++) _food(i),
                  OutlinedButton.icon(
                      onPressed: _busy || _adding ? null : _add,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: FitnessTheme.silver,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.all(14),
                          side: const BorderSide(
                              color: FitnessTheme.line, width: .7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(CupertinoIcons.plus, size: 17),
                      label: const FitnessText('Add food',
                          style: TextStyle(fontSize: 13))),
                  if (_foods.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const FitnessText('Nutrition per portion',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 14),
                    FitnessCard(
                        child: NutritionEntryGrid(children: [
                      _summaryValue('Calories',
                          '${_total((food) => food.caloriesPerServing).round()} kcal'),
                      _summaryValue('Protein',
                          '${_total((food) => food.proteinPerServing).toStringAsFixed(1)} g'),
                      _summaryValue('Carbs',
                          '${_total((food) => food.carbsPerServing).toStringAsFixed(1)} g'),
                      _summaryValue('Fat',
                          '${_total((food) => food.fatPerServing).toStringAsFixed(1)} g'),
                    ])),
                  ],
                ],
                const SizedBox(height: 24),
                const FitnessText('Saving a meal does not log it as eaten.',
                    style: TextStyle(
                        color: FitnessTheme.muted, fontSize: 11, height: 1.4)),
              ]),
        ),
      ));
}
