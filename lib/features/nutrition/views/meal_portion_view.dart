import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/components/motion.dart';
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
  bool _busy = false, _pickingPhoto = false, _isMeal = false;
  Uint8List? _photo;
  FoodPortion? _measure;

  List<FoodPortion> get _measures {
    final food = widget.food;
    if (food == null) return [];
    return [
      FoodPortion(
          unit: food.servingUnit, label: food.servingUnit, gramsPerUnit: 1),
      ...food.portions,
    ];
  }

  bool get _measured =>
      !_custom &&
      (_measure?.unit == 'g' ||
          _measure?.unit == 'ml' ||
          widget.food!.portions.isNotEmpty);
  String get _quantityUnit => _measure?.unit ?? 'g';
  String? _error;
  bool get _custom => widget.food == null;
  double get _factor => _custom || !_measured
      ? (inputNumber(_quantity.text) ?? 0)
      : (inputNumber(_quantity.text) ?? 0) *
          (_measure?.gramsPerUnit ?? 1) /
          widget.food!.servingSize;
  @override
  void initState() {
    super.initState();
    _slot = widget.initialMealType;
    if (!_custom) {
      _measure = _measures.firstWhere(
          (p) => p.unit == widget.food!.defaultPortionUnit,
          orElse: () => _measures.first);
    }
    _quantity.text = _custom || !_measured
        ? '1'
        : _quantityUnit == 'ml'
            ? '250'
            : _quantityUnit == 'g'
                ? widget.food!.servingSize.toStringAsFixed(0)
                : '1';
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
    if (_busy || _pickingPhoto) return;
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
        'category': _isMeal ? 'MEAL' : 'OTHER',
        if (_photo != null)
          'photo': {
            'mimeType': _photo![0] == 137 ? 'image/png' : 'image/jpeg',
            'base64': base64Encode(_photo!),
          },
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
                    title: FitnessText(_custom ? 'Create food' : 'Your portion',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600))),
                bottomNavigationBar: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: FitnessSubmit(
                            label: 'Log meal',
                            busy: _busy || _pickingPhoto,
                            onPressed: _save))),
                body: MotionEntrance(
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
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
                                    '${foodPortionLabel(context, food)} · ${(food.caloriesPerServing * food.previewFactor).round()} kcal',
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
                    _photoInput(),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const FitnessText('Save as a meal',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const FitnessText('Reuse it from My meals.',
                            style: TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                        value: _isMeal,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _isMeal = value)),
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
                      label: _measured ? 'Amount eaten' : 'Servings eaten',
                      controller: _quantity,
                      numeric: true,
                      unit: _measured
                          ? fitnessText(
                              context, _measure?.label ?? _quantityUnit)
                          : null),
                  const SizedBox(height: 12),
                  if (_measures.length > 1) ...[
                    DropdownButtonFormField<String>(
                        initialValue: _quantityUnit,
                        decoration: InputDecoration(
                            labelText: fitnessText(context, 'Unit')),
                        items: _measures
                            .map((p) => DropdownMenuItem(
                                value: p.unit, child: FitnessText(p.label)))
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (unit) => setState(() {
                                  _measure = _measures
                                      .firstWhere((p) => p.unit == unit);
                                  _quantity.text = unit == 'g'
                                      ? '100'
                                      : unit == 'ml'
                                          ? '250'
                                          : '1';
                                })),
                    const SizedBox(height: 12),
                  ],
                  if (_measured)
                    Wrap(spacing: 8, children: [
                      for (final amount in _quantityUnit == 'g'
                          ? [50, 100, 150, 200]
                          : _quantityUnit == 'ml'
                              ? [100, 200, 250, 500]
                              : [1, 2, 3])
                        ActionChip(
                            label: Text(
                                '$amount ${fitnessText(context, _measure?.label ?? _quantityUnit)}'),
                            onPressed:
                                _busy ? null : () => _quantity.text = '$amount')
                    ]),
                  if (_measure != null && !['g', 'ml'].contains(_quantityUnit))
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FitnessText(
                            'One {unit} is {grams} g of edible food.',
                            values: {
                              'unit': fitnessText(context, _measure!.label),
                              'grams': _measure!.gramsPerUnit.toStringAsFixed(1)
                            },
                            style: const TextStyle(
                                fontSize: 12, color: FitnessTheme.muted))),
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
                  if (food?.sourceName?.startsWith('USDA_') == true)
                    const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: FitnessText(
                            'Source: USDA FoodData Central. Reference values; check your package label.',
                            style: TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                height: 1.5))),
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
                ])))));
  }

  Future<void> _pickPhoto() async {
    if (_busy || _pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 480,
          maxHeight: 480,
          imageQuality: 70);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length < 16 ||
          bytes.length > 180000 ||
          !(bytes[0] == 137 || bytes[0] == 255 && bytes[1] == 216)) {
        setState(() => _error = 'Please choose a smaller JPG or PNG photo.');
        return;
      }
      setState(() {
        _photo = bytes;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Widget _photoInput() => Row(children: [
        if (_photo != null) ...[
          ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(_photo!,
                  width: 68, height: 68, fit: BoxFit.cover)),
          const SizedBox(width: 12),
        ],
        Expanded(
            child: OutlinedButton.icon(
                onPressed: _busy || _pickingPhoto ? null : _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: FitnessText(
                    _photo == null ? 'Add photo (optional)' : 'Change photo',
                    style: const TextStyle(fontSize: 12)))),
        if (_photo != null)
          IconButton(
              tooltip: fitnessText(context, 'Remove photo'),
              onPressed: _busy ? null : () => setState(() => _photo = null),
              icon: const Icon(Icons.close, size: 18)),
      ]);

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
