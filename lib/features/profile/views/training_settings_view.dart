import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../../onboarding/models/equipment_copy.dart';
import '../../onboarding/models/equipment_models.dart';
import '../repositories/settings_repository.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';
import 'equipment_settings_view.dart';

const _weekdays = {
  'MONDAY': 'Mon',
  'TUESDAY': 'Tue',
  'WEDNESDAY': 'Wed',
  'THURSDAY': 'Thu',
  'FRIDAY': 'Fri',
  'SATURDAY': 'Sat',
  'SUNDAY': 'Sun',
};
const _splits = {
  'AUTO': 'Recommended',
  'FULL_BODY': 'Full body',
  'UPPER_LOWER': 'Upper / lower',
  'PUSH_PULL_LEGS': 'Push / pull / legs',
  'MUSCLE_FOCUSED': 'Muscle focused',
  'CUSTOM': 'Custom',
};
const _dayMuscles = {
  'chest': 'Chest',
  'back': 'Back',
  'legs': 'Legs',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'core': 'Core',
};
const _focusMuscles = {
  'chest': 'Chest',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearms': 'Forearms',
  'upper_back': 'Upper back',
  'lats': 'Lats',
  'lower_back': 'Lower back',
  'core': 'Core',
  'glutes': 'Glutes',
  'quads': 'Quads',
  'hamstrings': 'Hamstrings',
  'calves': 'Calves',
};
const _limitations = {
  'SHOULDER': 'Shoulder',
  'KNEE': 'Knee',
  'BACK': 'Back',
  'WRIST': 'Wrist',
  'HIP': 'Hip',
  'OTHER': 'Other',
};

/// A single settings editor, independent of the multi-step onboarding flow.
class TrainingSettingsView extends StatefulWidget {
  final SettingsRepository? repository;
  const TrainingSettingsView({super.key, this.repository});

  @override
  State<TrainingSettingsView> createState() => _TrainingSettingsViewState();
}

class _TrainingSettingsViewState extends State<TrainingSettingsView> {
  late final _repository = widget.repository ?? SettingsRepository();
  final _notes = TextEditingController();
  final _scheduleKey = GlobalKey();
  Set<String> _days = {},
      _equipment = {},
      _focus = {},
      _limitationsSelected = {};
  Map<String, Set<String>> _customSplit = {};
  String _split = 'AUTO', _time = 'ANY';
  String? _duration, _owner, _error;
  bool _loading = true, _loadFailed = false, _saving = false;
  bool _limitationsChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Set<String> _strings(dynamic value) =>
      value is List ? value.whereType<String>().toSet() : {};

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final owner = await CacheScope.userId();
      final data = await _repository.profile();
      if (await CacheScope.userId() != owner) {
        throw StateError('Your session changed. Reopen Settings.');
      }
      if (!mounted) return;
      _owner = owner;
      _days =
          _strings(data['trainingDays']).intersection(_weekdays.keys.toSet());
      _split = data['trainingSplit'] as String? ?? 'AUTO';
      _time = data['preferredTime'] as String? ?? 'ANY';
      _duration = data['workoutDuration'] as String?;
      _equipment =
          EquipmentCatalog.normalizeIds(_strings(data['equipmentIds'])).toSet();
      _focus = _strings(data['focusMuscles']);
      _limitationsSelected = _strings(data['limitations'])..remove('NONE');
      _notes.text = data['customLimitations'] as String? ?? '';
      _customSplit = {
        for (final entry in (data['customTrainingSplit'] as Map? ?? {}).entries)
          entry.key.toString(): _strings(entry.value),
      };
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _error = BodyAssessmentRepository.message(error);
      });
    }
  }

  void _change(VoidCallback update) {
    if (_saving) return;
    setState(() {
      update();
      _error = null;
    });
  }

  void _toggle(Set<String> values, String value) {
    if (!values.add(value)) values.remove(value);
  }

  Future<void> _save() async {
    if (_loading || _loadFailed || _saving) return;
    String? error;
    if (_days.length < 2) {
      error = 'Choose at least two training days.';
    } else if (_days.length > 6) {
      error = 'Keep at least one rest day in your week.';
    } else if (_split == 'PUSH_PULL_LEGS' && _days.length < 3) {
      error = 'Choose at least three days for push / pull / legs.';
    } else if (_split == 'CUSTOM' &&
        _days.any((day) => _customSplit[day]?.isNotEmpty != true)) {
      error = 'Choose at least one muscle group for each training day.';
    } else if (_notes.text.trim().length > 500) {
      error = 'Use no more than 500 characters for movement notes.';
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (error != null) {
      setState(() => _error = error);
      final target = _scheduleKey.currentContext;
      if (target != null) await Scrollable.ensureVisible(target);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final days = _weekdays.keys.where(_days.contains).toList();
    final changes = <String, dynamic>{
      'trainingDays': days,
      'daysPerWeek': days.length == 6 ? 'DAYS_6_PLUS' : 'DAYS_${days.length}',
      'trainingSplit': _split,
      'preferredTime': _time,
      'customTrainingSplit': {
        for (final day in days)
          if (_customSplit[day]?.isNotEmpty == true)
            day: _dayMuscles.keys.where(_customSplit[day]!.contains).toList(),
      },
      'focusMuscles': _focus.toList(),
      'customLimitations':
          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      if (_duration != null) 'workoutDuration': _duration,
      if (_limitationsChanged)
        'limitations': _limitationsSelected.isEmpty
            ? ['NONE']
            : _limitationsSelected.toList(),
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

  SettingsDropdown _choice(String label, String? value,
          Map<String, String> choices, ValueChanged<String> onChanged) =>
      SettingsDropdown(
          key: ValueKey('training-choice-$label'),
          label: label,
          value: value,
          choices: choices,
          onChanged:
              _saving ? null : (value) => _change(() => onChanged(value)));

  Widget _chip(String key, String label, bool selected, VoidCallback update) =>
      SettingsChoiceChip(
          key: ValueKey(key),
          label: label,
          selected: selected,
          onTap: _saving ? null : () => _change(update));

  Widget _dayChoices() => LayoutBuilder(builder: (context, bounds) {
        if (bounds.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(12) > 16) {
          return Wrap(spacing: 7, runSpacing: 2, children: [
            for (final day in _weekdays.entries)
              _chip('training-day-${day.key}', day.value,
                  _days.contains(day.key), () => _toggle(_days, day.key)),
          ]);
        }
        return Row(children: [
          for (final day in _weekdays.entries)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: day.key == 'SUNDAY' ? 0 : 4),
                child: Semantics(
                  button: true,
                  selected: _days.contains(day.key),
                  enabled: !_saving,
                  label: fitnessText(
                      context, day.key[0] + day.key.substring(1).toLowerCase()),
                  onTap: _saving
                      ? null
                      : () => _change(() => _toggle(_days, day.key)),
                  excludeSemantics: true,
                  child: Material(
                    key: ValueKey('training-day-${day.key}'),
                    color: _days.contains(day.key)
                        ? Colors.white
                        : DSColors.bgElevated,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            width: .7,
                            color: _days.contains(day.key)
                                ? Colors.white
                                : FitnessTheme.line)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _saving
                          ? null
                          : () => _change(() => _toggle(_days, day.key)),
                      child: SizedBox(
                          height: 44,
                          child: Center(
                              child: FitnessText(day.value,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _days.contains(day.key)
                                          ? FitnessTheme.canvas
                                          : FitnessTheme.muted)))),
                    ),
                  ),
                ),
              ),
            ),
        ]);
      });

  String _equipmentLabel(String id) =>
      EquipmentCopy.item(LanguageManager.shared.currentLanguage, id);

  String get _equipmentSummary {
    if (_equipment.isEmpty) return 'Choose your equipment';
    final names = _equipment.map(_equipmentLabel).toList();
    return names.length <= 2
        ? names.join(' · ')
        : '${names.take(2).join(' · ')} +${names.length - 2}';
  }

  Future<void> _editEquipment() async {
    final selected = await Navigator.push<List<String>>(
        context,
        AppPageRoute<List<String>>(
            page: EquipmentSettingsView(repository: _repository)));
    if (mounted && selected != null) {
      setState(() => _equipment = selected.toSet());
    }
  }

  Widget _equipmentRow() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FitnessCard(
          key: const ValueKey('training-equipment'),
          padding: EdgeInsets.zero,
          child: SettingsRow(
              title: 'Equipment',
              subtitle: _equipmentSummary,
              onTap: _saving ? null : _editEquipment),
        ),
      );

  Widget _customDays() => Column(children: [
        for (final day in _weekdays.keys.where(_days.contains))
          ExpansionTile(
            key: ValueKey('training-custom-$day'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            shape: const Border(),
            collapsedShape: const Border(),
            title: FitnessText(day[0] + day.substring(1).toLowerCase(),
                style: const TextStyle(fontSize: 14)),
            subtitle: Text(
                (_customSplit[day]?.isEmpty ?? true)
                    ? fitnessText(context, 'Choose muscle groups')
                    : _customSplit[day]!
                        .map((muscle) =>
                            fitnessText(context, _dayMuscles[muscle] ?? muscle))
                        .join(' · '),
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 7, runSpacing: 2, children: [
                    for (final muscle in _dayMuscles.entries)
                      _chip(
                          'training-custom-$day-${muscle.key}',
                          muscle.value,
                          _customSplit[day]?.contains(muscle.key) == true,
                          () => _toggle(_customSplit.putIfAbsent(day, () => {}),
                              muscle.key)),
                  ])),
            ],
          ),
      ]);

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'Training',
        centerTitle: true,
        subtitle: '',
        bottom: _loading || _loadFailed
            ? null
            : SettingsSaveButton(
                buttonKey: const ValueKey('training-save'),
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
          ] else ...[
            if (_error != null) SettingsNotice(_error!, error: true),
            SettingsEditorSection(
                key: _scheduleKey,
                title: 'Your week',
                children: [
                  _dayChoices(),
                  _choice('Training split', _split, _splits,
                      (value) => _split = value),
                  if (_split == 'CUSTOM') _customDays(),
                  SettingsFieldPair(
                    first: _choice(
                        'Session length',
                        _duration,
                        const {
                          'MIN_20': '20 min',
                          'MIN_30': '30 min',
                          'MIN_45': '45 min',
                          'MIN_60_PLUS': '60+ min',
                        },
                        (value) => _duration = value),
                    second: _choice(
                        'Preferred time',
                        _time,
                        const {
                          'ANY': 'Any time',
                          'MORNING': 'Morning',
                          'AFTERNOON': 'Afternoon',
                          'EVENING': 'Evening',
                        },
                        (value) => _time = value),
                  ),
                ]),
            _equipmentRow(),
            SettingsDisclosure(
              key: const ValueKey('training-focus'),
              title: 'Muscle focus',
              summary: _focus.isEmpty
                  ? 'Balanced across all muscles'
                  : fitnessText(context, '{count} muscles selected',
                      values: {'count': _focus.length}),
              children: [
                Wrap(spacing: 7, runSpacing: 2, children: [
                  _chip('training-focus-balanced', 'Balanced', _focus.isEmpty,
                      _focus.clear),
                  for (final muscle in _focusMuscles.entries)
                    _chip(
                        'training-focus-${muscle.key}',
                        muscle.value,
                        _focus.contains(muscle.key),
                        () => _toggle(_focus, muscle.key)),
                ]),
              ],
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _notes,
              builder: (context, value, _) => SettingsDisclosure(
                key: const ValueKey('training-movement'),
                title: 'Movement needs',
                summary: value.text.trim().isNotEmpty
                    ? value.text.trim()
                    : _limitationsSelected.isEmpty
                        ? 'No limitations'
                        : _limitationsSelected
                            .map((id) =>
                                fitnessText(context, _limitations[id] ?? id))
                            .join(' · '),
                children: [
                  Wrap(spacing: 7, runSpacing: 2, children: [
                    _chip('training-limitations-none', 'None',
                        _limitationsSelected.isEmpty, () {
                      _limitationsChanged = true;
                      _limitationsSelected.clear();
                    }),
                    for (final limitation in _limitations.entries)
                      _chip(
                          'training-limitations-${limitation.key}',
                          limitation.value,
                          _limitationsSelected.contains(limitation.key), () {
                        _limitationsChanged = true;
                        _toggle(_limitationsSelected, limitation.key);
                      }),
                  ]),
                  TextFormField(
                    key: const ValueKey('training-notes'),
                    controller: _notes,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    style: const TextStyle(
                        fontSize: 14, color: FitnessTheme.silver),
                    decoration: settingsFieldDecoration(
                            context, 'Movement notes',
                            hint: 'Movements to avoid')
                        .copyWith(counterText: ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const SettingsNotice('Changes apply to your next generated plan.'),
          ],
        ],
      );
}
