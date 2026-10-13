import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../repositories/settings_repository.dart';
import 'settings_components.dart';

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
  bool _loading = true, _saving = false, _loadFailed = false;
  String? _error;
  String? _owner;
  String _gender = 'OTHER', _goal = 'BUILD_MUSCLE', _experience = 'BEGINNER';
  String _diet = 'NO_PREFERENCE';

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
          }
        : <String, dynamic>{
            'name': _name.text.trim(),
            'age': double.parse(_age.text).round(),
            'height': double.parse(_height.text),
            'weight': double.parse(_weight.text),
            if (_targetWeight.text.trim().isNotEmpty)
              'targetWeight': double.parse(_targetWeight.text),
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
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          enabled: !_saving,
          maxLines: maxLines,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(labelText: fitnessText(context, label)),
          validator: validator,
        ),
      );

  Widget _choices(String label, String selected, Map<String, String> choices,
          ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: choices.containsKey(selected) ? selected : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: fitnessText(context, label)),
          borderRadius: BorderRadius.circular(18),
          items: choices.entries
              .map((choice) => DropdownMenuItem(
                  value: choice.key, child: FitnessText(choice.value)))
              .toList(),
          onChanged:
              _saving ? null : (value) => setState(() => onChanged(value!)),
        ),
      );

  String? _number(String? text, double min, double max,
      {bool whole = false, bool optional = false}) {
    if (optional && (text == null || text.trim().isEmpty)) return null;
    final value = double.tryParse(text ?? '');
    if (value == null ||
        !value.isFinite ||
        value < min ||
        value > max ||
        (whole && value != value.roundToDouble())) {
      return 'Enter ${whole ? 'a whole number' : 'a value'} from ${min.toInt()} to ${max.toInt()}.';
    }
    return null;
  }

  String? _foodValidation(String? text) {
    final foods = _foodList(text ?? '');
    return foods.length > 20 || foods.any((food) => food.length > 60)
        ? 'Use up to 20 foods, with no more than 60 characters each.'
        : null;
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: widget.nutrition ? 'Nutrition preferences' : 'Personal details',
        subtitle: widget.nutrition
            ? 'Food choices that fit your life.'
            : 'The details behind your personal plan.',
        bottom: _loading || _loadFailed
            ? null
            : LiquidChromeButton(
                title: 'Save changes',
                isLoading: _saving,
                onPressed: _saving ? null : _save),
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
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
                            maxLines: 2, validator: _foodValidation),
                        _field('Foods you avoid or dislike', _dislikes,
                            maxLines: 2, validator: _foodValidation),
                        const SettingsNotice(
                            'Separate foods with commas. These preferences guide future recommendations.'),
                      ] else ...[
                        _field('Name', _name,
                            validator: (text) => text == null ||
                                    text.trim().length < 2 ||
                                    text.trim().length > 50
                                ? 'Use 2–50 characters.'
                                : null),
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
                        _field('Height (cm)', _height,
                            number: true,
                            validator: (text) => _number(text, 120, 230)),
                        _field('Current weight (kg)', _weight,
                            number: true,
                            validator: (text) => _number(text, 30, 250)),
                        _field('Target weight (kg)', _targetWeight,
                            number: true,
                            validator: (text) =>
                                _number(text, 30, 250, optional: true)),
                        _choices(
                            'Fitness goal',
                            _goal,
                            const {
                              'BUILD_MUSCLE': 'Build muscle',
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
                        const SettingsNotice(
                            'Updates guide future plans. Your logged workouts and measurements stay intact.'),
                      ],
                    ])),
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
      _dislikes
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
