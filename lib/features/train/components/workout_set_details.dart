import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';

class WorkoutSetDetails {
  const WorkoutSetDetails({this.effort, this.weight = '', this.delete = false});
  final double? effort;
  final String weight;
  final bool delete;
}

class WorkoutSetDetailsSheet extends StatefulWidget {
  const WorkoutSetDetailsSheet(
      {super.key,
      required this.number,
      required this.bodyweight,
      required this.canDelete,
      this.effort,
      this.weight = ''});
  final int number;
  final bool bodyweight, canDelete;
  final double? effort;
  final String weight;
  @override
  State<WorkoutSetDetailsSheet> createState() => _WorkoutSetDetailsSheetState();
}

class _WorkoutSetDetailsSheetState extends State<WorkoutSetDetailsSheet> {
  late double? _effort = widget.effort;
  late final _weight = TextEditingController(text: widget.weight);
  late bool _addedLoad =
      (double.tryParse(widget.weight.replaceAll(',', '.')) ?? 0) > 0;
  String? _error;
  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  void _apply() {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (widget.bodyweight &&
        _addedLoad &&
        (weight == null || !weight.isFinite || weight <= 0 || weight > 1000)) {
      setState(
          () => _error = 'Enter the weight you lifted before saving this set.');
      return;
    }
    Navigator.pop(
        context,
        WorkoutSetDetails(
            effort: _effort,
            weight: widget.bodyweight && !_addedLoad ? '' : _weight.text));
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: SafeArea(
          top: false,
          child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .85),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      fitnessText(context, 'Set {number}',
                                          values: {'number': widget.number}),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500))),
                              CloseButton(
                                  onPressed: () => Navigator.pop(context)),
                            ]),
                            const SizedBox(height: 18),
                            Text(fitnessText(context, 'How hard was that set?'),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(
                                fitnessText(context,
                                    'Optional · 1 is very easy, 10 is maximum effort.'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: DSColors.muted)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<double>(
                                key: ValueKey('set-effort-rating-$_effort'),
                                initialValue: _effort,
                                isExpanded: true,
                                dropdownColor: DSColors.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                icon: const Icon(CupertinoIcons.chevron_down,
                                    size: 12),
                                hint: Text(fitnessText(context, 'Not rated')),
                                items: [
                                  for (var value = 2; value <= 20; value++)
                                    DropdownMenuItem(
                                        value: value / 2,
                                        child: Text('${value / 2} / 10'))
                                ],
                                onChanged: (value) =>
                                    setState(() => _effort = value)),
                            if (_effort != null)
                              Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                      onPressed: () =>
                                          setState(() => _effort = null),
                                      child: Text(fitnessText(
                                          context, 'Clear rating')))),
                            if (widget.bodyweight) ...[
                              const SizedBox(height: 16),
                              SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      fitnessText(context, 'Add weight'),
                                      style: const TextStyle(fontSize: 14)),
                                  activeTrackColor: DSColors.silver,
                                  activeThumbColor: DSColors.bg,
                                  inactiveTrackColor: DSColors.bgCard,
                                  inactiveThumbColor: DSColors.muted,
                                  value: _addedLoad,
                                  onChanged: (value) =>
                                      setState(() => _addedLoad = value)),
                              if (_addedLoad)
                                TextField(
                                    key: const ValueKey('set-added-weight'),
                                    controller: _weight,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText: fitnessText(
                                            context, 'Added weight (kg)'),
                                        errorText: _error == null
                                            ? null
                                            : fitnessText(context, _error!))),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: _apply,
                                style: FilledButton.styleFrom(
                                    backgroundColor: DSColors.silver,
                                    foregroundColor: DSColors.bg,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(fitnessText(context, 'Done'))),
                            if (widget.canDelete)
                              TextButton(
                                  onPressed: () => Navigator.pop(context,
                                      const WorkoutSetDetails(delete: true)),
                                  child: Text(
                                      fitnessText(context, 'Delete set'),
                                      style: const TextStyle(
                                          color: DSColors.muted))),
                          ]))))));
}
