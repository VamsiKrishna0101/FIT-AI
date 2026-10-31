import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/exercise_catalog_page.dart';
import '../models/exercise_library_copy.dart';

class ExerciseFilterSelection {
  final String? bodyPart, equipment, mediaGender;
  const ExerciseFilterSelection(
      this.bodyPart, this.equipment, this.mediaGender);
}

class ExerciseFiltersSheet extends StatefulWidget {
  const ExerciseFiltersSheet(
      {super.key,
      required this.bodyParts,
      required this.equipmentOptions,
      required this.initial});
  final List<ExerciseFilterOption> bodyParts, equipmentOptions;
  final ExerciseFilterSelection initial;
  @override
  State<ExerciseFiltersSheet> createState() => _ExerciseFiltersSheetState();
}

class _ExerciseFiltersSheetState extends State<ExerciseFiltersSheet> {
  late String? _bodyPart = widget.initial.bodyPart;
  late String? _equipment = widget.initial.equipment;
  late String? _mediaGender = widget.initial.mediaGender;
  String copy(String text) => exerciseLibraryText(context, text);

  Widget _choice(String label, String? value,
      List<ExerciseFilterOption> options, ValueChanged<String?> onChanged) {
    final choices = [
      const ExerciseFilterOption('', 'All'),
      if (value != null && !options.any((option) => option.value == value))
        ExerciseFilterOption(value, value),
      ...options
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(copy(label),
          style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey('filter-$label-$value'),
        initialValue: value ?? '',
        isExpanded: true,
        dropdownColor: FitnessTheme.surface,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(CupertinoIcons.chevron_down,
            size: 12, color: FitnessTheme.silver),
        decoration: InputDecoration(
            filled: true,
            fillColor: FitnessTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: FitnessTheme.line, width: .7)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: FitnessTheme.line, width: .7)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
        style: TextStyle(
            fontSize: 14,
            color: FitnessTheme.silver,
            fontFamily: Theme.of(context).platform == TargetPlatform.iOS
                ? 'CupertinoSystemText'
                : 'Inter'),
        items: choices
            .map((option) => DropdownMenuItem(
                value: option.value,
                child:
                    Text(copy(option.label), overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (value) =>
            setState(() => onChanged(value == '' ? null : value)),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 18, end: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(copy('Filters'),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -.5))),
                      CloseButton(onPressed: () => Navigator.pop(context)),
                    ])),
                Flexible(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _choice(
                                  'Muscle group',
                                  _bodyPart,
                                  widget.bodyParts,
                                  (value) => _bodyPart = value),
                              const SizedBox(height: 18),
                              _choice(
                                  'Equipment',
                                  _equipment,
                                  widget.equipmentOptions,
                                  (value) => _equipment = value),
                              const SizedBox(height: 24),
                              Text(copy('Demonstration'),
                                  style: const TextStyle(
                                      fontSize: 11, color: FitnessTheme.muted)),
                              const SizedBox(height: 10),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final entry in const {
                                  '': 'Profile',
                                  'male': 'Male',
                                  'female': 'Female'
                                }.entries)
                                  ChoiceChip(
                                      key: ValueKey('demo-filter-${entry.key}'),
                                      label: Text(copy(entry.value)),
                                      selected:
                                          (_mediaGender ?? '') == entry.key,
                                      showCheckmark: false,
                                      selectedColor: FitnessTheme.silver,
                                      labelStyle: TextStyle(
                                          fontSize: 12,
                                          color:
                                              (_mediaGender ?? '') == entry.key
                                                  ? FitnessTheme.canvas
                                                  : FitnessTheme.silver),
                                      onSelected: (_) => setState(() =>
                                          _mediaGender = entry.key.isEmpty
                                              ? null
                                              : entry.key)),
                              ]),
                            ]))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                              onPressed: () => Navigator.pop(
                                  context,
                                  ExerciseFilterSelection(
                                      _bodyPart, _equipment, _mediaGender)),
                              style: FilledButton.styleFrom(
                                  backgroundColor: FitnessTheme.silver,
                                  foregroundColor: FitnessTheme.canvas,
                                  minimumSize: const Size(double.infinity, 50),
                                  padding: const EdgeInsets.all(14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text(copy('Apply filters'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600))),
                          TextButton(
                              onPressed: () => setState(() {
                                    _bodyPart = null;
                                    _equipment = null;
                                    _mediaGender = null;
                                  }),
                              child: Text(copy('Reset filters'),
                                  style: const TextStyle(
                                      color: FitnessTheme.muted,
                                      fontSize: 12))),
                        ])),
              ]),
        ),
      ));
}
