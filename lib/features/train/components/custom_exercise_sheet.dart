import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/localization/fitness_copy.dart';
import '../repositories/workout_repository.dart';

class AddExerciseSheet extends StatefulWidget {
  final VoidCallback onExerciseAdded;
  final bool startCustom;
  const AddExerciseSheet(
      {super.key, required this.onExerciseAdded, this.startCustom = false});
  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _description = TextEditingController();
  final _sets = TextEditingController(text: '3'),
      _reps = TextEditingController(text: '10'),
      _weight = TextEditingController(text: '0'),
      _rest = TextEditingController(text: '60');
  String? _muscle;
  String _equipment = 'Bodyweight', _difficulty = 'BEGINNER';
  bool _saving = false;
  @override
  void dispose() {
    for (final field in [_name, _description, _sets, _reps, _weight, _rest]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await WorkoutRepository.shared.addWorkoutItem(
        customExercise: {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'category': 'Strength',
          'bodyPart': _muscle!,
          'target': _muscle!,
          'equipment': _equipment,
          'difficulty': _difficulty,
          'instructions': <String>[],
        },
        targetSets: int.parse(_sets.text),
        targetReps: _reps.text.trim(),
        targetWeight: double.parse(_weight.text.replaceAll(',', '.')),
        restSeconds: int.parse(_rest.text));
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      widget.onExerciseAdded();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(fitnessText(context, 'Could not save. Please try again.'))));
    }
  }

  Widget _field(String label, TextEditingController controller,
          {int maxLines = 1,
          int? maxLength,
          bool numeric = false,
          String? Function(String?)? validate}) =>
      TextFormField(
          controller: controller,
          enabled: !_saving,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          validator: validate,
          decoration: InputDecoration(
              labelText: fitnessText(context, label),
              filled: true,
              fillColor: const Color(0xFF202020),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none)));
  String? _number(String? value,
      {bool integer = false, double max = 500, double min = 0}) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null ||
            number < min ||
            number > max ||
            (integer && int.tryParse(value ?? '') == null)
        ? fitnessText(context, 'Enter a valid value')
        : null;
  }

  Widget _choice(String label, String? value, List<String> choices,
          ValueChanged<String?> changed, {bool required = false}) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: fitnessText(context, label),
              filled: true,
              fillColor: const Color(0xFF202020),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none)),
          dropdownColor: const Color(0xFF202020),
          items: choices
              .map((item) => DropdownMenuItem(
                  value: item, child: Text(fitnessText(context, item))))
              .toList(),
          validator: (selected) => required && selected == null
              ? fitnessText(context, 'Choose muscle')
              : null,
          onChanged: _saving ? null : changed);
  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.sizeOf(context).height * .88,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
            top: false,
            child: Form(
                key: _form,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(4)))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: Text(fitnessText(context, 'Custom exercise'),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.5))),
                        IconButton(
                            tooltip: fitnessText(context, 'Cancel'),
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(CupertinoIcons.xmark))
                      ]),
                      const SizedBox(height: 18),
                      _field('Exercise name', _name,
                          maxLength: 100,
                          validate: (value) => (value?.trim().length ?? 0) < 2
                              ? fitnessText(context, 'Enter an exercise name')
                              : null),
                      const SizedBox(height: 14),
                      _choice(
                          'Target muscles',
                          _muscle,
                          [
                            'Chest',
                            'Back',
                            'Legs',
                            'Shoulders',
                            'Arms',
                            'Core',
                            'Cardio',
                            'Neck'
                          ],
                          (value) => setState(() => _muscle = value),
                          required: true),
                      const SizedBox(height: 14),
                      _choice(
                          'Equipment',
                          _equipment,
                          [
                            'Bodyweight',
                            'Dumbbells',
                            'Barbells',
                            'Machine',
                            'Cable',
                            'Other'
                          ],
                          (value) => setState(() => _equipment = value!)),
                      const SizedBox(height: 14),
                      _choice(
                          'Difficulty',
                          _difficulty,
                          ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
                          (value) => setState(() => _difficulty = value!)),
                      const SizedBox(height: 14),
                      _field('Description', _description,
                          maxLines: 3, maxLength: 500),
                      const SizedBox(height: 22),
                      Text(fitnessText(context, 'Your targets'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _field('Sets', _sets,
                                numeric: true,
                                validate: (v) => _number(v,
                                    integer: true, min: 1, max: 20))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Reps', _reps,
                                validate: (v) => v?.trim().isEmpty != false
                                    ? fitnessText(
                                        context, 'Enter a valid value')
                                    : null))
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _field('Load (kg)', _weight,
                                numeric: true, validate: _number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Rest (seconds)', _rest,
                                numeric: true,
                                validate: (v) =>
                                    _number(v, integer: true, max: 600)))
                      ]),
                      const SizedBox(height: 22),
                      FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE2E2E2),
                              foregroundColor: const Color(0xFF111111),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18))),
                          child: _saving
                              ? const CupertinoActivityIndicator()
                              : Text(fitnessText(context, 'Create exercise'))),
                    ]))),
      );
}
