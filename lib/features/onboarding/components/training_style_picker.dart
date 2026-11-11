import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../components/onboarding_scaffold.dart';
import '../models/training_style.dart';
import 'onboarding_coach.dart';

const trainingStyleLabels = {
  'AUTO': 'Recommended',
  'FULL_BODY': 'Full body',
  'UPPER_LOWER': 'Upper / lower',
  'PUSH_PULL_LEGS': 'Push / pull / legs',
  'MUSCLE_FOCUSED': 'Targeted splits',
  'CUSTOM': 'Custom',
};

const _quickPresets = <String, List<String>>{
  'Chest + Back': ['chest', 'back'],
  'Legs + Core': ['legs', 'core'],
  'Shoulders + Arms': ['shoulders', 'biceps', 'triceps'],
  'Push': ['chest', 'shoulders', 'triceps'],
  'Pull': ['back', 'biceps'],
  'Full Body': ['chest', 'back', 'legs'],
};

const availableMuscles = <String, String>{
  'chest': 'Chest',
  'back': 'Back',
  'legs': 'Legs',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'core': 'Core',
};

class TrainingStylePicker extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<String> onChanged;
  final Widget? customDayEditor;

  const TrainingStylePicker({
    super.key,
    required this.draft,
    required this.onChanged,
    this.customDayEditor,
  });

  @override
  State<TrainingStylePicker> createState() => _TrainingStylePickerState();
}

class _TrainingStylePickerState extends State<TrainingStylePicker> {
  int _activeDayIndex = 0;

  String _dayAbbr(String day) =>
      day[0] + day.substring(1, 3).toLowerCase();

  String _muscleLabel(String key) {
    return availableMuscles[key] ??
        (key.isEmpty ? '' : key[0].toUpperCase() + key.substring(1));
  }

  String _splitDayDetail(String style, int index) {
    switch (style) {
      case 'FULL_BODY':
        return const [
          'Chest + Back',
          'Legs + Shoulders',
          'Arms + Core',
          'Full Body',
          'Chest + Back',
          'Legs + Core',
        ][index % 6];
      case 'UPPER_LOWER':
        return index.isEven ? 'Chest + Back' : 'Legs + Core';
      case 'PUSH_PULL_LEGS':
        return const [
          'Push (Chest + Shoulders)',
          'Pull (Back + Arms)',
          'Legs + Core',
        ][index % 3];
      case 'MUSCLE_FOCUSED':
        return const [
          'Chest + Triceps',
          'Back + Biceps',
          'Legs + Core',
          'Shoulders + Arms',
        ][index % 4];
      default:
        return 'Full Body';
    }
  }

  String _daySummary(String day) {
    final muscles = widget.draft.customTrainingSplit[day];
    if (muscles == null || muscles.isEmpty) return 'Select';
    for (final entry in _quickPresets.entries) {
      if (entry.value.length == muscles.length &&
          entry.value.every(muscles.contains)) {
        return entry.key;
      }
    }
    return muscles.map((m) => _muscleLabel(m)).take(2).join('+');
  }

  List<String> _defaultMusclesForDay(int index) {
    const defaults = [
      ['chest', 'back'],
      ['legs', 'core'],
      ['shoulders', 'biceps', 'triceps'],
      ['chest', 'back', 'legs'],
      ['chest', 'triceps'],
      ['legs', 'core'],
    ];
    return defaults[index % defaults.length];
  }

  Widget _presetChip(String day, String label, List<String> muscles) {
    final current = widget.draft.customTrainingSplit[day] ?? [];
    final isSelected = current.length == muscles.length &&
        current.every(muscles.contains);

    return GestureDetector(
      onTap: () {
        OnboardingCoach.select();
        setState(() {
          widget.draft.customTrainingSplit = {
            ...widget.draft.customTrainingSplit,
            day: [...muscles],
          };
        });
        widget.onChanged(widget.draft.trainingSplit);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1F22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF2C2E31),
            width: 0.8,
          ),
        ),
        child: FitnessText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
          ),
        ),
      ),
    );
  }

  Widget _muscleChip(String day, String key, String label) {
    final current = widget.draft.customTrainingSplit[day] ?? [];
    final isSelected = current.contains(key);

    return GestureDetector(
      onTap: () {
        OnboardingCoach.select();
        setState(() {
          final list = [...current];
          if (isSelected) {
            list.remove(key);
          } else {
            list.add(key);
          }
          widget.draft.customTrainingSplit = {
            ...widget.draft.customTrainingSplit,
            day: list.isEmpty ? [key] : list,
          };
        });
        widget.onChanged(widget.draft.trainingSplit);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF18191B),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF27292C),
            width: 0.8,
          ),
        ),
        child: FitnessText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = TrainingStylePreview(widget.draft);
    final count = preview.count;
    final recommended = preview.recommended;
    final current = widget.draft.trainingSplit == 'AUTO'
        ? recommended
        : widget.draft.trainingSplit;
    final isBeginner = widget.draft.experienceLevel == 'BEGINNER';
    final selectedDays = preview.selectedDays;

    if (_activeDayIndex >= selectedDays.length) {
      _activeDayIndex = 0;
    }

    final options = [
      (
        'FULL_BODY',
        'Full body',
        recommended == 'FULL_BODY'
            ? (isBeginner ? 'Recommended for beginners' : 'Recommended')
            : null
      ),
      (
        'UPPER_LOWER',
        'Upper / lower',
        recommended == 'UPPER_LOWER' ? 'Recommended' : null
      ),
      if (count >= 3)
        (
          'PUSH_PULL_LEGS',
          'Push / pull / legs',
          recommended == 'PUSH_PULL_LEGS' ? 'Recommended' : null
        ),
      ('MUSCLE_FOCUSED', 'Targeted splits', null),
      ('CUSTOM', 'Custom', 'Build your own routine'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final opt in options) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnboardingChoice(
              title: opt.$2,
              subtitle: opt.$3,
              selected: current == opt.$1,
              onTap: () {
                setState(() {
                  if (opt.$1 == 'CUSTOM') {
                    if (widget.draft.customTrainingSplit.isEmpty) {
                      widget.draft.customTrainingSplit = {
                        for (int d = 0; d < selectedDays.length; d++)
                          selectedDays[d]: _defaultMusclesForDay(d),
                      };
                    }
                  } else {
                    widget.draft.customTrainingSplit = {};
                  }
                });
                widget.onChanged(opt.$1);
              },
            ),
          ),
          if (current == opt.$1)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
              child: opt.$1 == 'CUSTOM'
                  ? _buildCustomBuilder(selectedDays)
                  : _buildPresetSchedule(opt.$1, selectedDays),
            ),
        ],
      ],
    );
  }

  Widget _buildPresetSchedule(String style, List<String> days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28292C), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < days.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < days.length - 1 ? 8 : 0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222326),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FitnessText(
                      _dayAbbr(days[i]),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FitnessText(
                      _splitDayDetail(style, i),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomBuilder(List<String> days) {
    if (days.isEmpty) return const SizedBox.shrink();
    final activeDay = days[_activeDayIndex];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28292C), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day selector row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int d = 0; d < days.length; d++) ...[
                  if (d > 0) const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      OnboardingCoach.select();
                      setState(() => _activeDayIndex = d);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeDayIndex == d
                            ? Colors.white
                            : const Color(0xFF222326),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activeDayIndex == d
                              ? Colors.white
                              : const Color(0xFF2E3034),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FitnessText(
                            _dayAbbr(days[d]),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _activeDayIndex == d
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FitnessText(
                            _daySummary(days[d]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _activeDayIndex == d
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const FitnessText(
            'Quick focus',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _quickPresets.entries)
                _presetChip(activeDay, preset.key, preset.value),
            ],
          ),
          const SizedBox(height: 14),
          const FitnessText(
            'Target muscles',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final muscle in availableMuscles.entries)
                _muscleChip(activeDay, muscle.key, muscle.value),
            ],
          ),
        ],
      ),
    );
  }
}
