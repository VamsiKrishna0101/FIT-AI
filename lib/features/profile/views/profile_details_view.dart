import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/profile_avatar.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../repositories/settings_repository.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';

/// Each editor sends only its own fields, preserving the rest of the profile.
class ProfileDetailsView extends StatefulWidget {
  final bool nutrition;
  final SettingsRepository? repository;
  const ProfileDetailsView(
      {super.key, this.nutrition = false, this.repository});

  @override
  State<ProfileDetailsView> createState() => _ProfileDetailsViewState();
}

class _ProfileDetailsViewState extends State<ProfileDetailsView> {
  late final _repository = widget.repository ?? SettingsRepository();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();
  final _customDiet = TextEditingController();
  final _allergies = TextEditingController();
  final _dislikes = TextEditingController();
  final _budget = TextEditingController();
  bool _loading = true, _saving = false, _loadFailed = false;
  String? _error;
  String? _owner;
  String _gender = 'OTHER', _goal = 'BUILD_MUSCLE', _experience = 'BEGINNER';
  String _diet = 'NO_PREFERENCE';
  String _budgetCurrency = 'EUR';
  bool _budgetChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _loadFailed = false;
    });
    try {
      final owner = await CacheScope.userId();
      final data = await _repository.profile();
      if (!mounted) return;
      if (await CacheScope.userId() != owner) {
        throw StateError('Your session changed. Reopen Settings.');
      }
      _owner = owner;
      _name.text = data['name']?.toString() ?? '';
      _age.text = data['age']?.toString() ?? '';
      _height.text = data['height']?.toString() ?? '';
      _weight.text = data['weight']?.toString() ?? '';
      _targetWeight.text = data['targetWeight']?.toString() ?? '';
      _gender = data['gender'] as String? ?? 'OTHER';
      _goal = data['workingToward'] as String? ?? 'BUILD_MUSCLE';
      _experience = data['experience'] as String? ?? 'BEGINNER';
      _diet = data['eatingStyle'] as String? ?? 'NO_PREFERENCE';
      _customDiet.text = data['customEatingStyle'] as String? ?? '';
      _allergies.text = (data['foodAllergies'] as List? ?? []).join(', ');
      _dislikes.text = (data['dislikedFoods'] as List? ?? []).join(', ');
      _budget.text = data['foodBudgetAmount']?.toString() ?? '';
      _budgetCurrency = data['foodBudgetCurrency'] as String? ??
          switch (data['countryCode']) {
            'GB' => 'GBP',
            'CH' => 'CHF',
            'SE' => 'SEK',
            'NO' => 'NOK',
            'DK' => 'DKK',
            'IN' => 'INR',
            'US' => 'USD',
            _ => 'EUR',
          };
      setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
          _error = BodyAssessmentRepository.message(error);
        });
      }
    }
  }

  List<String> _foodList(String text) => text
      .split(',')
      .map((food) => food.trim())
      .where((food) => food.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final changes = widget.nutrition
        ? <String, dynamic>{
            'eatingStyle': _diet,
            'customEatingStyle':
                _diet == 'OTHER' ? _customDiet.text.trim() : null,
            'foodAllergies': _foodList(_allergies.text),
            'dislikedFoods': _foodList(_dislikes.text),
            if (_budgetChanged) ...{
              'foodBudgetAmount': _budget.text.trim().isEmpty
                  ? null
                  : double.parse(_budget.text.trim().replaceAll(',', '.')),
              'foodBudgetCurrency':
                  _budget.text.trim().isEmpty ? null : _budgetCurrency,
              'weeklyFoodBudget': null,
            },
          }
        : <String, dynamic>{
            'name': _name.text.trim(),
            'age': double.parse(_age.text.replaceAll(',', '.')).round(),
            'height': double.parse(_height.text.replaceAll(',', '.')),
            'weight': double.parse(_weight.text.replaceAll(',', '.')),
            if (_targetWeight.text.trim().isNotEmpty)
              'targetWeight':
                  double.parse(_targetWeight.text.replaceAll(',', '.')),
            'gender': _gender,
            'workingToward': _goal,
            'experience': _experience,
          };
    try {
      if (await CacheScope.userId() != _owner) {
        throw StateError('Your session changed. Reopen Settings.');
      }
      await _repository.saveProfile(changes);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? minLines,
    String? hint,
    ValueChanged<String>? onChanged,
  }) =>
      TextFormField(
        key: ValueKey('profile-field-$label'),
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
        textCapitalization: controller == _name
            ? TextCapitalization.words
            : TextCapitalization.none,
        autofillHints: controller == _name ? const [AutofillHints.name] : null,
        style: const TextStyle(fontSize: 14, color: FitnessTheme.silver),
        cursorColor: FitnessTheme.silver,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: _decoration(label).copyWith(
            hintText: hint == null ? null : fitnessText(context, hint)),
        validator: (value) {
          final error = validator?.call(value);
          return error == null ? null : fitnessText(context, error);
        },
      );

  Widget _choices(String label, String selected, Map<String, String> choices,
          ValueChanged<String> onChanged) =>
      SettingsDropdown(
          key: ValueKey('profile-choice-$label'),
          label: label,
          value: selected,
          choices: choices,
          onChanged:
              _saving ? null : (value) => setState(() => onChanged(value)));

  InputDecoration _decoration(String label) =>
      settingsFieldDecoration(context, label);

  Widget _section(String title, List<Widget> children) =>
      SettingsEditorSection(title: title, children: children);

  Widget _pair(Widget first, Widget second) =>
      SettingsFieldPair(first: first, second: second);

  Widget _identity() => ValueListenableBuilder<TextEditingValue>(
        valueListenable: _name,
        builder: (context, value, _) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FitnessCard(
              child: Row(children: [
            ProfileAvatar(name: value.text, size: 46, label: 'Profile'),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  value.text.trim().isEmpty
                      ? const FitnessText('Your profile',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500))
                      : Text(value.text.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -.4)),
                  const SizedBox(height: 5),
                  const FitnessText('Your profile',
                      style:
                          TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                ])),
          ])),
        ),
      );

  String? _number(String? text, double min, double max,
      {bool whole = false, bool optional = false}) {
    if (optional && (text == null || text.trim().isEmpty)) return null;
    final value = double.tryParse((text ?? '').replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        value < min ||
        value > max ||
        (whole && value != value.roundToDouble())) {
      return fitnessText(
          context,
          whole
              ? 'Enter a whole number from {min} to {max}.'
              : 'Enter a value from {min} to {max}.',
          values: {'min': min.toInt(), 'max': max.toInt()});
    }
    return null;
  }

  String? _foodValidation(String? text) {
    final foods = _foodList(text ?? '');
    return foods.length > 20 || foods.any((food) => food.length > 60)
        ? 'Use up to 20 foods, with no more than 60 characters each.'
        : null;
  }

  String? _budgetValidation(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value == null || !value.isFinite || value <= 0 || value > 100000
        ? 'Enter a valid weekly budget, or leave it blank.'
        : null;
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: widget.nutrition ? 'Nutrition' : 'Edit profile',
        centerTitle: true,
        subtitle: '',
        bottom: _loading || _loadFailed
            ? null
            : SettingsSaveButton(
                buttonKey: const ValueKey('profile-save'),
                saving: _saving,
                onPressed: _save),
        children: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CupertinoActivityIndicator()))
          else if (_loadFailed) ...[
            SettingsNotice(_error!, error: true),
            TextButton(onPressed: _load, child: const FitnessText('Try again')),
          ] else
            Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) SettingsNotice(_error!, error: true),
                    if (widget.nutrition) ...[
                      _section('Food preferences', [
                        _choices(
                            'Eating style',
                            _diet,
                            const {
                              'NO_PREFERENCE': 'No preference',
                              'NON_VEGETARIAN': 'Non-vegetarian',
                              'VEGETARIAN': 'Vegetarian',
                              'VEGAN': 'Vegan',
                              'OTHER': 'Other',
                            },
                            (value) => _diet = value),
                        if (_diet == 'OTHER')
                          _field('Describe your eating style', _customDiet,
                              validator: (text) => text == null ||
                                      text.trim().isEmpty ||
                                      text.trim().length > 80
                                  ? 'Use 1–80 characters.'
                                  : null),
                        _field('Food allergies', _allergies,
                            minLines: 1,
                            maxLines: 3,
                            hint: 'None',
                            validator: _foodValidation),
                        _field('Foods you avoid or dislike', _dislikes,
                            minLines: 1,
                            maxLines: 3,
                            hint: 'None',
                            validator: _foodValidation),
                      ]),
                      const SettingsNotice('Separate foods with commas.'),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _budget,
                        builder: (context, value, _) => SettingsDisclosure(
                          key: const ValueKey('nutrition-budget'),
                          title: 'Weekly budget',
                          summary: value.text.trim().isEmpty
                              ? 'Optional'
                              : '$_budgetCurrency ${value.text.trim()}',
                          children: [
                            _field('Amount', _budget,
                                number: true,
                                hint: 'Optional',
                                validator: _budgetValidation,
                                onChanged: (_) => _budgetChanged = true),
                            _choices('Currency', _budgetCurrency, const {
                              'GBP': 'GBP',
                              'EUR': 'EUR',
                              'CHF': 'CHF',
                              'SEK': 'SEK',
                              'NOK': 'NOK',
                              'DKK': 'DKK',
                              'USD': 'USD',
                              'INR': 'INR',
                            }, (value) {
                              _budgetCurrency = value;
                              _budgetChanged = true;
                            }),
                          ],
                        ),
                      ),
                    ] else ...[
                      _identity(),
                      _section('Personal details', [
                        _field('Name', _name,
                            validator: (text) => text == null ||
                                    text.trim().length < 2 ||
                                    text.trim().length > 50
                                ? 'Use 2–50 characters.'
                                : null),
                        _pair(
                          _field('Age', _age,
                              number: true,
                              validator: (text) =>
                                  _number(text, 13, 100, whole: true)),
                          _choices(
                              'Gender',
                              _gender,
                              const {
                                'MALE': 'Male',
                                'FEMALE': 'Female',
                                'OTHER': 'Other'
                              },
                              (value) => _gender = value),
                        ),
                      ]),
                      _section('Measurements', [
                        _pair(
                          _field('Height (cm)', _height,
                              number: true,
                              validator: (text) => _number(text, 120, 230)),
                          _field('Current weight (kg)', _weight,
                              number: true,
                              validator: (text) => _number(text, 30, 250)),
                        ),
                        _field('Target weight (kg)', _targetWeight,
                            number: true,
                            hint: 'Optional',
                            validator: (text) =>
                                _number(text, 30, 250, optional: true)),
                      ]),
                      _section('Training', [
                        _choices(
                            'Fitness goal',
                            _goal,
                            const {
                              'BUILD_MUSCLE': 'Build muscle',
                              'GET_STRONGER': 'Get stronger',
                              'LOSE_BODY_FAT': 'Lose body fat',
                              'LOSE_WEIGHT': 'Lose weight',
                              'GET_FITTER': 'Get fitter',
                              'BUILD_CONSISTENCY': 'Build consistency',
                            },
                            (value) => _goal = value),
                        _choices(
                            'Experience',
                            _experience,
                            const {
                              'BEGINNER': 'Beginner',
                              'INTERMEDIATE': 'Intermediate',
                              'ADVANCED': 'Advanced'
                            },
                            (value) => _experience = value),
                      ]),
                      const SettingsNotice(
                          'Updates guide future plans. Your logged workouts and measurements stay intact.'),
                    ],
                  ]),
            ),
        ],
      );

  @override
  void dispose() {
    for (final controller in [
      _name,
      _age,
      _height,
      _weight,
      _targetWeight,
      _customDiet,
      _allergies,
      _dislikes,
      _budget,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
