import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/workout_exercise_models.dart';

Future<Map<String, dynamic>?> editTrainingTargets(
        BuildContext context, TodayPlanItemModel item) =>
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DSColors.bgCard,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _TargetEditor(item: item),
    );

class _TargetEditor extends StatefulWidget {
  final TodayPlanItemModel item;
  const _TargetEditor({required this.item});

  @override
  State<_TargetEditor> createState() => _TargetEditorState();
}

class _TargetEditorState extends State<_TargetEditor> {
  final _form = GlobalKey<FormState>();
  final _reps = <TextEditingController>[];
  final _weights = <TextEditingController>[];
  final _efforts = <double?>[];
  final _removed = <TextEditingController>[];
  late final TextEditingController _rest;
  bool get _bodyweight =>
      widget.item.setTargets?['weightBasis'] == 'bodyweight' ||
      widget.item.exercise.equipment.toLowerCase() == 'body weight';
  String copy(String text) => fitnessText(context, text);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _rest = TextEditingController(text: '${item.restSeconds}');
    for (var index = 0; index < item.targetSets; index++) {
      final target = item.targetForSet(index + 1);
      _efforts.add((target?['targetRpe'] as num?)?.toDouble());
      _reps.add(TextEditingController(
          text: target == null
              ? item.targetReps
              : target['repsMin'] == target['repsMax']
                  ? '${target['repsMax']}'
                  : '${target['repsMin']}-${target['repsMax']}'));
      final weight = target == null
          ? (item.targetWeight > 0 ? item.targetWeight : null)
          : target['weightKg'];
      _weights
          .add(TextEditingController(text: weight == null ? '' : '$weight'));
    }
  }

  List<int>? _repRange(String text) {
    final parts = text.trim().split(RegExp(r'[-–]'));
    if (parts.isEmpty || parts.length > 2) return null;
    final first = int.tryParse(parts.first.trim());
    final last = int.tryParse(parts.last.trim());
    if (first == null ||
        last == null ||
        first < 1 ||
        last > 1000 ||
        first > last) {
      return null;
    }
    return [first, last];
  }

  void _save() {
    if (_form.currentState?.validate() != true) return;
    final sets = [
      for (var index = 0; index < _reps.length; index++)
        {
          'setNumber': index + 1,
          if (_efforts[index] != null) 'targetRpe': _efforts[index],
          'repsMin': _repRange(_reps[index].text)!.first,
          'repsMax': _repRange(_reps[index].text)!.last,
          'weightKg': _bodyweight
              ? 0.0
              : double.tryParse(_weights[index].text.replaceAll(',', '.')),
        }
    ];
    final anyLoad = sets.any((set) => set['weightKg'] != null);
    Navigator.pop(context, {
      'targetSets': sets.length,
      'targetReps': _reps.first.text.trim(),
      'targetWeight': sets.first['weightKg'] ?? 0,
      'restSeconds': int.parse(_rest.text),
      'setTargets': {
        'weightBasis': _bodyweight
            ? 'bodyweight'
            : !anyLoad
                ? 'establish_starting_load'
                : widget.item.setTargets?['weightBasis'] ?? 'estimated_start',
        'weightUnit': _bodyweight
            ? 'bodyweight'
            : widget.item.setTargets?['weightUnit'] ?? 'as_logged',
        'sets': sets,
      },
    });
  }

  @override
  void dispose() {
    for (final controller in [..._reps, ..._weights, ..._removed, _rest]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                            color: DSColors.muted,
                            borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 20),
                Text(copy('Edit targets'),
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                        color: DSColors.textPrimary)),
                const SizedBox(height: 6),
                Text(widget.item.exercise.displayName,
                    style:
                        const TextStyle(fontSize: 13, color: DSColors.muted)),
                if (widget.item.setTargets?['weightUnit'] == 'per_hand' ||
                    _bodyweight) ...[
                  const SizedBox(height: 8),
                  Text(copy(_bodyweight ? 'Bodyweight' : 'Per hand'),
                      style: const TextStyle(
                          fontSize: 12, color: DSColors.silver)),
                ],
                const SizedBox(height: 22),
                for (var index = 0; index < _reps.length; index++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.only(top: 18, right: 12),
                                child: Text('${index + 1}'.padLeft(2, '0'),
                                    style: const TextStyle(
                                        fontSize: 12, color: DSColors.muted))),
                            Expanded(
                                child: TextFormField(
                              key: ValueKey('target-reps-$index'),
                              controller: _reps[index],
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration:
                                  InputDecoration(labelText: copy('Reps')),
                              validator: (value) =>
                                  _repRange(value ?? '') == null
                                      ? '1–1000'
                                      : null,
                            )),
                            if (!_bodyweight) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                key: ValueKey('target-weight-$index'),
                                controller: _weights[index],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                    labelText: copy('Weight (kg)'),
                                    hintText: '—'),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) return null;
                                  final load = double.tryParse(
                                      value!.replaceAll(',', '.'));
                                  return load == null ||
                                          !load.isFinite ||
                                          load < 0 ||
                                          load > 1000
                                      ? '0–1000'
                                      : null;
                                },
                              )),
                            ],
                            if (_reps.length > 1)
                              IconButton(
                                  tooltip: copy('Remove'),
                                  onPressed: () => setState(() {
                                        _removed.add(_reps.removeAt(index));
                                        _removed.add(_weights.removeAt(index));
                                        _efforts.removeAt(index);
                                      }),
                                  icon: const Icon(CupertinoIcons.minus_circle,
                                      size: 19, color: DSColors.muted)),
                          ])),
                if (_reps.length < 30)
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: DSColors.silver),
                        onPressed: () => setState(() {
                          _reps.add(
                              TextEditingController(text: _reps.last.text));
                          _efforts.add(_efforts.last);
                          _weights.add(
                              TextEditingController(text: _weights.last.text));
                        }),
                        icon: const Icon(CupertinoIcons.plus, size: 15),
                        label: Text(copy('Add set'),
                            style: const TextStyle(fontSize: 13)),
                      )),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _rest,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration:
                        InputDecoration(labelText: copy('Rest (seconds)')),
                    validator: (value) {
                      final rest = int.tryParse(value ?? '');
                      return rest == null || rest < 0 || rest > 1800
                          ? '0–1800'
                          : null;
                    }),
                const SizedBox(height: 22),
                FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        backgroundColor: DSColors.silver,
                        foregroundColor: DSColors.bg,
                        minimumSize: const Size(0, 48)),
                    child: Text(copy('Save'))),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(copy('Cancel'),
                        style: const TextStyle(color: DSColors.muted))),
              ]),
        )),
      ));
}
