import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/fitness_copy.dart';
import 'package:flutter/cupertino.dart';
import '../components/nutrition_entry_fields.dart';
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
  final DateTime? date;
  final Future<bool> Function(Map<String, dynamic> payload)? saveMeal;
  const MealPortionView(
      {super.key,
      this.food,
      this.initialMealType = 'LUNCH',
      this.saveMeal,
      this.date});
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
  String _unit = 'portion';
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
    if (_custom) _size.text = '1';
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
      final message =
          _name.text.trim().length < 2 || _name.text.trim().length > 100
              ? 'Use 2–100 characters for the name.'
              : size == null || size <= 0
                  ? 'Enter a portion size greater than zero.'
                  : values.any((value) => value == null || value < 0)
                      ? 'Enter all four nutrition values. Use 0 if needed.'
                      : null;
      if (message != null) {
        setState(() => _error = message);
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
              if (widget.date != null) ...{
                'day': widget.date!.day.toString(),
                'month': widget.date!.month.toString(),
                'year': widget.date!.year.toString(),
              },
              'mealType': _slot,
              'servings': _factor,
              if (custom != null) 'customFood': custom,
              if (!_custom) 'nutritionId': widget.food!.id
            })
          : await NutritionRepository.shared.logMeal(
              date: widget.date,
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

  Widget _dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> changed) =>
      NutritionEntryLabel(
          label: label,
          child: DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              dropdownColor: FitnessTheme.surface,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(CupertinoIcons.chevron_down,
                  size: 12, color: FitnessTheme.muted),
              decoration: nutritionEntryDecoration(),
              style: TextStyle(
                  fontSize: 15,
                  color: FitnessTheme.silver,
                  fontFamily: Theme.of(context).platform == TargetPlatform.iOS
                      ? 'CupertinoSystemText'
                      : 'Inter'),
              items: options.entries
                  .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: FitnessText(entry.value,
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => changed(value));
                    }));

  Widget _field(String label, TextEditingController controller,
          {bool numeric = true, String? unit}) =>
      NutritionEntryField(
          label: label,
          controller: controller,
          numeric: numeric,
          unit: unit,
          enabled: !_busy);

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final logTo = _dropdown(
        'Log to',
        _slot,
        {
          for (final slot in ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'])
            slot: mealSlotLabel(slot)
        },
        (value) => _slot = value);
    return FitnessTheme(
        child: PopScope(
            canPop: !_busy && !_pickingPhoto,
            child: Scaffold(
                backgroundColor: FitnessTheme.canvas,
                appBar: AppBar(
                    centerTitle: true,
                    backgroundColor: FitnessTheme.canvas,
                    surfaceTintColor: Colors.transparent,
                    title: FitnessText(_custom ? 'Quick entry' : 'Your portion',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500))),
                bottomNavigationBar: NutritionEntryFooter(
                    label: 'Log meal',
                    busy: _busy || _pickingPhoto,
                    error: _error,
                    onPressed: _save),
                body: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    children: [
                      if (widget.date != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                                DateFormat.yMMMMEEEEd(
                                        Localizations.localeOf(context)
                                            .toLanguageTag())
                                    .format(widget.date!),
                                style: const TextStyle(
                                    color: FitnessTheme.muted, fontSize: 12))),
                      if (food != null) ...[
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FoodArt(food: food, size: 72),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(food.name,
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3)),
                                    const SizedBox(height: 7),
                                    Text(foodPortionLabel(context, food),
                                        style: const TextStyle(
                                            color: FitnessTheme.muted,
                                            fontSize: 12,
                                            height: 1.4)),
                                  ]))
                            ]),
                        const SizedBox(height: 28),
                        logTo,
                        const SizedBox(height: 20),
                      ],
                      if (_custom) ...[
                        _field('Food or meal name', _name, numeric: false),
                        const SizedBox(height: 20),
                        NutritionEntryGrid(children: [
                          _field('Portion size', _size),
                          _dropdown(
                              'Unit',
                              _unit,
                              const {
                                'g': 'g',
                                'ml': 'ml',
                                'portion': 'portion'
                              },
                              (value) => _unit = value),
                        ]),
                        const SizedBox(height: 28),
                        const FitnessText('Nutrition per portion',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        NutritionEntryGrid(children: [
                          _field('Calories', _calories, unit: 'kcal'),
                          _field('Protein', _protein, unit: 'g'),
                          _field('Carbs', _carbs, unit: 'g'),
                          _field('Fat', _fat, unit: 'g'),
                        ]),
                        const SizedBox(height: 16),
                        _photoInput(),
                        SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const FitnessText('Save in My meals',
                                style: TextStyle(fontSize: 13)),
                            activeTrackColor: FitnessTheme.silver,
                            activeThumbColor: FitnessTheme.canvas,
                            inactiveTrackColor: FitnessTheme.surface,
                            inactiveThumbColor: FitnessTheme.muted,
                            value: _isMeal,
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _isMeal = value)),
                        const SizedBox(height: 20),
                        NutritionEntryGrid(children: [
                          logTo,
                          _field('Servings eaten', _quantity),
                        ]),
                      ] else ...[
                        NutritionEntryGrid(children: [
                          _field(_measured ? 'Amount eaten' : 'Servings eaten',
                              _quantity,
                              unit: _measures.length > 1
                                  ? null
                                  : _measured
                                      ? fitnessText(context,
                                          _measure?.label ?? _quantityUnit)
                                      : null),
                          if (_measures.length > 1)
                            _dropdown('Unit', _quantityUnit, {
                              for (final p in _measures) p.unit: p.label
                            }, (unit) {
                              _measure =
                                  _measures.firstWhere((p) => p.unit == unit);
                              _quantity.text = unit == 'g'
                                  ? '100'
                                  : unit == 'ml'
                                      ? '250'
                                      : '1';
                            }),
                        ]),
                        const SizedBox(height: 12),
                        if (_measured)
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            for (final amount in _quantityUnit == 'g'
                                ? [50, 100, 150, 200]
                                : _quantityUnit == 'ml'
                                    ? [100, 200, 250, 500]
                                    : [1, 2, 3])
                              ActionChip(
                                  label: Text(
                                      '$amount ${fitnessText(context, _measure?.label ?? _quantityUnit)}'),
                                  onPressed: _busy
                                      ? null
                                      : () => _quantity.text = '$amount')
                          ]),
                        if (_measure != null &&
                            !['g', 'ml'].contains(_quantityUnit))
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: FitnessText(
                                  'One {unit} is {grams} g of edible food.',
                                  values: {
                                    'unit':
                                        fitnessText(context, _measure!.label),
                                    'grams': _measure!.gramsPerUnit
                                        .toStringAsFixed(1)
                                  },
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: FitnessTheme.muted))),
                        const SizedBox(height: 24),
                        FitnessCard(
                            child: Column(children: [
                          _value('Calories',
                              '${(food!.caloriesPerServing * _factor).round()} kcal'),
                          _value('Protein',
                              '${(food.proteinPerServing * _factor).toStringAsFixed(1)} g'),
                          _value('Carbs',
                              '${(food.carbsPerServing * _factor).toStringAsFixed(1)} g'),
                          _value('Fat',
                              '${(food.fatPerServing * _factor).toStringAsFixed(1)} g'),
                          _value('Fibre',
                              '${(food.fiberPerServing * _factor).toStringAsFixed(1)} g'),
                        ])),
                      ],
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
                      if (food?.imageCreditsUrl != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                                onPressed: () async {
                                  final url =
                                      Uri.tryParse(food!.imageCreditsUrl!);
                                  if (url == null || url.scheme != 'https') {
                                    return;
                                  }
                                  try {
                                    if (await launchUrl(url,
                                        mode: LaunchMode.externalApplication)) {
                                      return;
                                    }
                                  } catch (_) {}
                                  if (mounted) {
                                    setState(() => _error =
                                        'Photo credits could not be opened. Please try again.');
                                  }
                                },
                                child: const FitnessText('Photo credits',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: FitnessTheme.muted)))),
                    ]))));
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
            child: TextButton.icon(
                onPressed: _busy || _pickingPhoto ? null : _pickPhoto,
                icon: const Icon(CupertinoIcons.camera, size: 17),
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
