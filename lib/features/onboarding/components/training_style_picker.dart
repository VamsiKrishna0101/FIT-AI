import 'onboarding_scaffold.dart';
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
  final bool compact;
  const TrainingStylePicker(
      {super.key,
      required this.draft,
      required this.onChanged,
      this.customDayEditor,
      this.compact = false});

  @override
  State<TrainingStylePicker> createState() => _TrainingStylePickerState();
}

class _TrainingStylePickerState extends State<TrainingStylePicker> {
  final _alternatives = ExpansibleController();
  bool _showWeek = false;
  bool _showStyles = false;

  @override
  void dispose() {
    _alternatives.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final preview = TrainingStylePreview(draft);
    if (widget.compact) return _compact(preview);
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
        for (var i = 0;
            i <
                (widget.compact && !_showWeek
                    ? preview.selectedDays.length.clamp(0, 2)
                    : preview.selectedDays.length);
            i++)
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
      if (widget.compact &&
          preview.resolved != 'CUSTOM' &&
          preview.selectedDays.length > 2)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: () => setState(() => _showWeek = !_showWeek),
                child: FitnessText(_showWeek ? 'Show less' : 'View full week',
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.silver)))),
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

  Widget _compact(TrainingStylePreview preview) {
    final draft = widget.draft;
    final alternatives = trainingStyleLabels.keys
        .where((key) => key != 'AUTO' && key != preview.recommended)
        .toList();
    // A restored manual choice stays visible even before more styles are opened.
    if (draft.trainingSplit != 'AUTO' &&
        trainingStyleLabels.containsKey(draft.trainingSplit)) {
      alternatives.remove(draft.trainingSplit);
      alternatives.insert(0, draft.trainingSplit);
    }
    final visible = [
      'AUTO',
      ...(_showStyles ? alternatives : alternatives.take(2))
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final key in visible)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OnboardingChoice(
                key: ValueKey('training-style-$key'),
                title: trainingStyleLabels[
                    key == 'AUTO' ? preview.recommended : key]!,
                subtitle: key == 'AUTO' ? 'Recommended for you' : null,
                selected: draft.trainingSplit == key,
                onTap: () => widget.onChanged(key))),
      Align(
          alignment: Alignment.centerRight,
          child: TextButton(
              key: const ValueKey('training-style-more'),
              onPressed: () => setState(() => _showStyles = !_showStyles),
              child: FitnessText(
                  _showStyles ? 'Show less' : 'More training styles',
                  style: const TextStyle(
                      fontSize: 13, color: FitnessTheme.silver)))),
      if (preview.resolved == 'CUSTOM' && widget.customDayEditor != null)
        widget.customDayEditor!
      else
        ExpansionTile(
            key: const ValueKey('training-week-preview'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const FitnessText('Preview your week',
                style: TextStyle(fontSize: 13)),
            children: [
              for (var i = 0; i < preview.selectedDays.length; i++)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 58,
                              child: draft.trainingDays.isEmpty
                                  ? FitnessText('Day {number}',
                                      values: {'number': i + 1},
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: FitnessTheme.muted))
                                  : FitnessText(
                                      preview.selectedDays[i][0] +
                                          preview.selectedDays[i]
                                              .substring(1, 3)
                                              .toLowerCase(),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: FitnessTheme.muted))),
                          Expanded(
                              child: Text(
                                  preview.groups[i]
                                      .map((m) => fitnessText(context,
                                          m[0].toUpperCase() + m.substring(1)))
                                      .join(' + '),
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.5))),
                        ])),
            ]),
    ]);
  }
}
