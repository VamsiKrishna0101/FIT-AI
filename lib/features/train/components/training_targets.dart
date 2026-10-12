import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/workout_exercise_models.dart';

Future<Map<String, dynamic>?> editTrainingTargets(
    BuildContext context, TodayPlanItemModel item) async {
  final form = GlobalKey<FormState>();
  final sets = TextEditingController(text: '${item.targetSets}');
  final reps = TextEditingController(text: item.targetReps);
  final load = TextEditingController(text: '${item.targetWeight}');
  final rest = TextEditingController(text: '${item.restSeconds}');
  final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String copy(String value) => fitnessText(context, value);
        Widget field(String label, TextEditingController controller,
                String? Function(String?) validate,
                {bool decimal = false, bool text = false}) =>
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                    controller: controller,
                    keyboardType: text
                        ? TextInputType.text
                        : TextInputType.numberWithOptions(decimal: decimal),
                    decoration: InputDecoration(labelText: copy(label)),
                    validator: validate));
        String? range(String? value, int min, int max) {
          final number = int.tryParse(value ?? '');
          return number == null || number < min || number > max
              ? '$min–$max'
              : null;
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: Text(copy('Edit targets')),
          content: SingleChildScrollView(
              child: Form(
                  key: form,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    field('Sets', sets, (value) => range(value, 1, 30)),
                    field(
                        'Reps',
                        reps,
                        (value) => value == null ||
                                value.trim().isEmpty ||
                                value.length > 24
                            ? copy('Enter valid reps and load.')
                            : null,
                        text: true),
                    field('Weight (kg)', load, (value) {
                      final number =
                          double.tryParse((value ?? '').replaceAll(',', '.'));
                      return number == null || number < 0 || number > 1000
                          ? '0–1000'
                          : null;
                    }, decimal: true),
                    field('Rest (seconds)', rest,
                        (value) => range(value, 0, 1800)),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(copy('Cancel'))),
            TextButton(
                onPressed: () {
                  if (form.currentState?.validate() != true) return;
                  Navigator.pop(context, {
                    'targetSets': int.parse(sets.text),
                    'targetReps': reps.text.trim(),
                    'targetWeight':
                        double.parse(load.text.replaceAll(',', '.')),
                    'restSeconds': int.parse(rest.text)
                  });
                },
                child: Text(copy('Save')))
          ],
        );
      });
  Future<void>.delayed(const Duration(milliseconds: 300), () {
    sets.dispose();
    reps.dispose();
    load.dispose();
    rest.dispose();
  });
  return result;
}
