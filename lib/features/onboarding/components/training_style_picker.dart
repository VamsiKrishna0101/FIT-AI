import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/training_style.dart';

const trainingStyleLabels = {
  'AUTO': 'Recommended plan',
  'FULL_BODY': 'Full body sessions',
  'UPPER_LOWER': 'Chest & back / legs',
  'PUSH_PULL_LEGS': 'Chest / back / legs',
  'MUSCLE_FOCUSED': 'Muscle focus days',
  'CUSTOM': 'Choose each day',
};

class TrainingStylePicker extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<String> onChanged;
  final Widget? customDayEditor;
  const TrainingStylePicker(
      {super.key,
      required this.draft,
      required this.onChanged,
      this.customDayEditor});

  @override
  State<TrainingStylePicker> createState() => _TrainingStylePickerState();
}

class _TrainingStylePickerState extends State<TrainingStylePicker> {
  final _alternatives = ExpansibleController();

  @override
  void dispose() {
    _alternatives.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final preview = TrainingStylePreview(draft);
    final groups = preview.groups;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText(
          draft.trainingSplit == 'AUTO'
              ? 'Recommended for you'
              : 'Training style',
          style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      const SizedBox(height: 10),
      FitnessText(trainingStyleLabels[preview.resolved] ?? 'Your weekly plan',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -.5)),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 6, children: [
        FitnessText('{count} training days',
            values: {'count': preview.count},
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        FitnessText('{minutes} min',
            values: {'minutes': preview.minutes},
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      ]),
      if (preview.resolved == 'CUSTOM' && widget.customDayEditor != null) ...[
        const SizedBox(height: 18),
        widget.customDayEditor!,
      ],
      if (preview.resolved != 'CUSTOM') ...[
        const SizedBox(height: 18),
        for (var i = 0; i < preview.selectedDays.length; i++)
          Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFF353535), width: .5))),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 58,
                    child: draft.trainingDays.isEmpty
                        ? FitnessText('Day {number}',
                            values: {'number': i + 1},
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: FitnessTheme.muted))
                        : FitnessText(
                            preview.selectedDays[i][0] +
                                preview.selectedDays[i]
                                    .substring(1, 3)
                                    .toLowerCase(),
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: FitnessTheme.muted))),
                Expanded(
                    child: Text(
                        groups[i].isEmpty
                            ? fitnessText(context, 'Choose muscles')
                            : groups[i]
                                .map((m) => fitnessText(context,
                                    m[0].toUpperCase() + m.substring(1)))
                                .join(' + '),
                        style: const TextStyle(fontSize: 13, height: 1.5))),
              ])),
      ],
      if (preview.incompleteCustom) ...[
        const SizedBox(height: 14),
        const FitnessText('Include chest, back and legs across your week',
            style: TextStyle(
                fontSize: 12, height: 1.5, color: FitnessTheme.muted)),
      ],
      const SizedBox(height: 8),
      ExpansionTile(
        controller: _alternatives,
        key: const ValueKey('training-style-alternatives'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        title: const FitnessText('Change training style',
            style: TextStyle(fontSize: 13)),
        children: [
          for (final entry in trainingStyleLabels.entries)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                    selected: draft.trainingSplit == entry.key,
                    button: true,
                    child: Material(
                        color: draft.trainingSplit == entry.key
                            ? const Color(0xFF363636)
                            : const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                            key: ValueKey('training-style-${entry.key}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              _alternatives.collapse();
                              widget.onChanged(entry.key);
                            },
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 15),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FitnessText(entry.value,
                                        style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            fontWeight:
                                                draft.trainingSplit == entry.key
                                                    ? FontWeight.w600
                                                    : FontWeight.w400)))))))),
        ],
      ),
    ]);
  }
}
