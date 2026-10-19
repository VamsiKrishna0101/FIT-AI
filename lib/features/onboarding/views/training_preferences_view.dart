import '../viewmodels/onboarding_controller.dart';
import '../../../core/theme/ds_motion.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_review_view.dart';
import '../components/onboarding_scaffold.dart';
import '../components/onboarding_live_previews.dart';
import 'package:flutter/services.dart';

const trainingMuscles = <String, String>{
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
  'calves': 'Calves'
};
const _days = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY'
];

const _trainingSplits = {
  'AUTO': 'Choose for me',
  'FULL_BODY': 'Full body',
  'UPPER_LOWER': 'Upper / lower',
  'PUSH_PULL_LEGS': 'Push / pull / legs',
  'MUSCLE_FOCUSED': 'Muscle group split',
  'CUSTOM': 'My own combinations',
};

const _splitMuscles = {
  'chest': 'Chest',
  'back': 'Back',
  'legs': 'Legs',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'core': 'Core',
};

/// Final setup step, also available to existing members from Body and Profile.
class TrainingPreferencesView extends StatefulWidget {
  final bool editProfile;
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  const TrainingPreferencesView(
      {super.key, this.editProfile = false, this.onContinue, this.controller});
  @override
  State<TrainingPreferencesView> createState() =>
      _TrainingPreferencesViewState();
}

class _TrainingPreferencesViewState extends State<TrainingPreferencesView> {
  OnboardingDraft _draft = OnboardingDraft();
  late final OnboardingController? _controller =
      widget.editProfile ? null : widget.controller ?? OnboardingController();
  final _notes = TextEditingController(),
      _allergies = TextEditingController(),
      _dislikes = TextEditingController(),
      _budget = TextEditingController();
  bool _loading = true, _saving = false, _loadFailed = false;
  String? _error;
  String? _profileUser;
  @override
  void initState() {
    super.initState();
    for (final field in [_notes, _allergies, _dislikes, _budget]) {
      field.addListener(_formChanged);
    }
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      if (widget.editProfile) {
        final user = await CacheScope.userId();
        final response =
            await ApiClient.shared.get<Map<String, dynamic>>('/api/onboarding');
        if (await CacheScope.userId() != user) return;
        _profileUser = user;
        final j = Map<String, dynamic>.from(response.data!['data'] as Map);
        _draft = OnboardingDraft.fromJson(
            {...j, 'customWeeklyFoodBudget': j['foodBudgetAmount']});
      } else {
        if (!_controller!.ready) await _controller!.initialize();
        _draft = _controller!.draft;
      }
      if (!mounted) return;
      _notes.text = _draft.customLimitations ?? '';
      _allergies.text = _draft.foodAllergies.join(', ');
      _dislikes.text = _draft.dislikedFoods.join(', ');
      _budget.text = _draft.customWeeklyFoodBudget?.toString() ?? '';
      _draft.foodBudgetCurrency ??= switch (_draft.countryCode) {
        'GB' => 'GBP',
        'CH' => 'CHF',
        'SE' => 'SEK',
        'NO' => 'NOK',
        'DK' => 'DKK',
        'IN' => 'INR',
        _ => 'EUR'
      };
      if (!['ANY', 'MORNING', 'AFTERNOON', 'EVENING']
          .contains(_draft.preferredTime)) {
        _draft.preferredTime = 'ANY';
      }
      setState(() {
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
          _error = 'Could not load your preferences. Please retry.';
        });
      }
    }
  }

  void _change(VoidCallback update) {
    setState(update);
    final count = _draft.trainingDays.length;
    if (count >= 2) {
      _draft.daysPerWeek = count >= 6 ? 'DAYS_6_PLUS' : 'DAYS_$count';
    }
    _controller?.checkpoint();
  }

  void _formChanged() {
    if (_loading || widget.editProfile) return;
    _draft.customLimitations = _notes.text.trim();
    _draft.foodAllergies = _list(_allergies.text);
    _draft.dislikedFoods = _list(_dislikes.text);
    final budget = double.tryParse(_budget.text.trim());
    if (_budget.text.trim().isEmpty) {
      _draft.customWeeklyFoodBudget = null;
    } else if (budget != null && budget.isFinite && budget > 0) {
      _draft.customWeeklyFoodBudget = budget;
    }
    _controller?.checkpoint();
  }

  List<String> _list(String value) => value
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList();
  Future<void> _save() async {
    if (widget.editProfile && await CacheScope.userId() != _profileUser) {
      if (mounted) {
        setState(
            () => _error = 'Your session changed. Reopen your preferences.');
      }
      return;
    }
    final allergies = _list(_allergies.text), dislikes = _list(_dislikes.text);
    final amount = _budget.text.trim().isEmpty
        ? null
        : double.tryParse(_budget.text.trim());
    String? error;
    if (_draft.trainingDays.length == 1) {
      error = 'Choose at least two training days, or leave your week flexible.';
    }
    if (_draft.trainingDays.length > 6) {
      error = 'Keep at least one rest day in your week.';
    }
    if (_draft.trainingSplit == 'PUSH_PULL_LEGS' &&
        (_draft.trainingDays.isNotEmpty
                ? _draft.trainingDays.length
                : int.tryParse(
                        _draft.daysPerWeek?.replaceAll(RegExp(r'[^0-9]'), '') ??
                            '') ??
                    3) <
            3) {
      error = 'Choose at least three days for push / pull / legs.';
    }
    if (_draft.trainingSplit == 'CUSTOM' &&
        (_draft.trainingDays.length < 2 ||
            _draft.trainingDays.any((day) =>
                _draft.customTrainingSplit[day]?.isNotEmpty != true))) {
      error = 'Choose your training days and add muscles to each day.';
    }
    if (allergies.length > 20 ||
        dislikes.length > 20 ||
        [...allergies, ...dislikes].any((v) => v.length > 60)) {
      error = 'Use up to 20 short food names in each field.';
    }
    if (_budget.text.trim().isNotEmpty &&
        (amount == null ||
            !amount.isFinite ||
            amount <= 0 ||
            amount > 100000)) {
      error = 'Enter a valid weekly budget, or leave it blank.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _draft.customLimitations = _notes.text.trim();
    _draft.foodAllergies = allergies;
    _draft.dislikedFoods = dislikes;
    _draft.customWeeklyFoodBudget = amount;
    final count = _draft.trainingDays.length;
    if (count >= 2) {
      _draft.daysPerWeek = count >= 6 ? 'DAYS_6_PLUS' : 'DAYS_$count';
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.editProfile) {
        await ApiClient.shared
            .patch<Map<String, dynamic>>('/api/onboarding', data: {
          ..._draft.personalizationPayload(),
          if (_draft.daysPerWeek != null) 'daysPerWeek': _draft.daysPerWeek
        });
        await UserDataCache.shared.invalidate('profile');
        await UserDataCache.shared.invalidate('training_map');
        if (mounted) Navigator.of(context).pop();
      } else {
        _draft.completedStep = 7;
        _controller!.checkpoint();
        if (!mounted) return;
        if (widget.onContinue != null) {
          widget.onContinue!();
        } else {
          await OnboardingPageRoute<void>(
                  page: OnboardingReviewView(controller: _controller!))
              .open(context);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your preferences. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    if (!widget.editProfile && widget.controller == null) {
      _controller?.dispose();
    }
    _notes.dispose();
    _allergies.dispose();
    _dislikes.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        step: 7,
        title: widget.editProfile ? 'Training preferences' : 'Make it yours.',
        subtitle: 'Your priorities, your schedule, your way to train.',
        actionTitle: widget.editProfile ? 'Save preferences' : 'Continue',
        onBack: () => Navigator.of(context).pop(),
        loading: _saving,
        onContinue: _loading || _saving || _loadFailed ? null : _save,
        children: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CupertinoActivityIndicator()))
          else ...[
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FitnessText(_error!,
                      style: const TextStyle(
                          color: FitnessTheme.coral, fontSize: 13))),
            if (_loadFailed)
              TextButton(onPressed: _load, child: const FitnessText('Retry')),
            FitnessCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Heading(
                      'Your focus',
                      fitnessText(context, '{count} of 3 selected · optional',
                          values: {'count': _draft.focusMuscles.length})),
                  const SizedBox(height: 12),
                  OnboardingMusclePreview(
                      selected: _draft.focusMuscles.toSet(),
                      female: _draft.gender == 'FEMALE'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 3,
                    children: [
                      for (final entry in trainingMuscles.entries)
                        _chip(
                            entry.value,
                            _draft.focusMuscles.contains(entry.key),
                            _draft.focusMuscles.contains(entry.key) ||
                                    _draft.focusMuscles.length < 3
                                ? (selected) => _change(() {
                                      final values = [..._draft.focusMuscles];
                                      if (selected) {
                                        values.add(entry.key);
                                      } else {
                                        values.remove(entry.key);
                                      }
                                      _draft.focusMuscles = values;
                                    })
                                : null)
                    ],
                  ),
                ])),
            const SizedBox(height: 14),
            FitnessCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const _Heading('Your week',
                      'Choose at least two days, or keep your schedule flexible.'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 7, runSpacing: 8, children: [
                    for (int i = 0; i < _days.length; i++)
                      _chip(
                          const [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ][i],
                          _draft.trainingDays.contains(_days[i]),
                          (selected) => _change(() {
                                final values = [..._draft.trainingDays];
                                if (selected) {
                                  values.add(_days[i]);
                                } else {
                                  values.remove(_days[i]);
                                }
                                _draft.trainingDays = values;
                              }))
                  ]),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                      initialValue: _draft.preferredTime ?? 'ANY',
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: fitnessText(context, 'Preferred time'),
                          fillColor: const Color(0xFF171819),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16)),
                      dropdownColor: const Color(0xFF252628),
                      borderRadius: BorderRadius.circular(16),
                      icon: const Icon(CupertinoIcons.chevron_down,
                          size: 16, color: FitnessTheme.muted),
                      items: const [
                        DropdownMenuItem(
                            value: 'ANY', child: FitnessText('Whenever works')),
                        DropdownMenuItem(
                            value: 'MORNING', child: FitnessText('Morning')),
                        DropdownMenuItem(
                            value: 'AFTERNOON',
                            child: FitnessText('Afternoon')),
                        DropdownMenuItem(
                            value: 'EVENING', child: FitnessText('Evening'))
                      ],
                      onChanged: (value) =>
                          _change(() => _draft.preferredTime = value)),
                ])),
            const SizedBox(height: 14),
            FitnessCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Heading('Your training style',
                      'Full body, a split, or your own muscle combinations.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.trainingSplit,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: fitnessText(context, 'Training style'),
                        fillColor: const Color(0xFF171819),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16)),
                    dropdownColor: const Color(0xFF252628),
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(CupertinoIcons.chevron_down,
                        size: 16, color: FitnessTheme.muted),
                    items: [
                      for (final entry in _trainingSplits.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: FitnessText(entry.value),
                        ),
                    ],
                    onChanged: (value) => _change(() {
                      _draft.trainingSplit = value ?? 'AUTO';
                    }),
                  ),
                  if (_draft.trainingSplit == 'CUSTOM') ...[
                    const SizedBox(height: 16),
                    const FitnessText(
                        'Select muscles for each training day. Combine any groups, such as Biceps + Triceps.',
                        style:
                            TextStyle(fontSize: 13, color: FitnessTheme.muted)),
                    for (final day
                        in _days.where(_draft.trainingDays.contains)) ...[
                      const SizedBox(height: 16),
                      FitnessText(day[0] + day.substring(1).toLowerCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 3,
                        children: [
                          for (final muscle in _splitMuscles.entries)
                            _chip(
                                muscle.value,
                                _draft.customTrainingSplit[day]
                                        ?.contains(muscle.key) ==
                                    true,
                                (selected) => _change(() {
                                      final muscles = [
                                        ...?_draft.customTrainingSplit[day]
                                      ];
                                      if (selected) {
                                        muscles.add(muscle.key);
                                      } else {
                                        muscles.remove(muscle.key);
                                      }
                                      _draft.customTrainingSplit = {
                                        ..._draft.customTrainingSplit,
                                        day: muscles,
                                      };
                                    })),
                        ],
                      ),
                    ],
                    if (_draft.trainingDays.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child:
                            FitnessText('Choose your days in Your week above.'),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            FitnessCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                    initiallyExpanded: _notes.text.isNotEmpty,
                    title: const FitnessText('Movement notes',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const FitnessText(
                        'Optional · movements you have been advised to avoid',
                        style:
                            TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    children: [
                      TextField(
                          controller: _notes,
                          maxLength: 500,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                              hintText: fitnessText(context,
                                  'Add details about your selected limitations')))
                    ])),
            const SizedBox(height: 14),
            FitnessCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                    initiallyExpanded: _allergies.text.isNotEmpty ||
                        _dislikes.text.isNotEmpty ||
                        _budget.text.isNotEmpty,
                    title: const FitnessText('Food preferences',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const FitnessText(
                        'Optional · saved for future meal personalization',
                        style:
                            TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      TextField(
                          controller: _allergies,
                          maxLength: 500,
                          decoration: InputDecoration(
                              labelText: fitnessText(context, 'Food allergies'),
                              hintText: fitnessText(
                                  context, 'Separate foods with commas'))),
                      const SizedBox(height: 10),
                      TextField(
                          controller: _dislikes,
                          maxLength: 500,
                          decoration: InputDecoration(
                              labelText: fitnessText(
                                  context, 'Foods you avoid or dislike'))),
                      const SizedBox(height: 10),
                      TextField(
                          controller: _budget,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText:
                                  fitnessText(context, 'Weekly food budget'),
                              hintText: fitnessText(context, 'Optional'))),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _draft.foodBudgetCurrency,
                          isExpanded: true,
                          decoration: InputDecoration(
                              labelText: fitnessText(context, 'Currency')),
                          items: [
                            for (final currency in [
                              'GBP',
                              'EUR',
                              'CHF',
                              'SEK',
                              'NOK',
                              'DKK',
                              'USD',
                              'INR'
                            ])
                              DropdownMenuItem(
                                  value: currency, child: FitnessText(currency))
                          ],
                          onChanged: (value) =>
                              _change(() => _draft.foodBudgetCurrency = value)),
                    ])),
          ],
        ],
      );

  Widget _chip(String label, bool selected, ValueChanged<bool>? onSelected) =>
      Semantics(
        key: ValueKey('training-choice-$label'),
        button: true,
        selected: selected,
        enabled: onSelected != null,
        child: Opacity(
          opacity: onSelected == null ? .4 : 1,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DSMotion.press,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? FitnessTheme.silver : const Color(0xFF282A2C),
              border: Border.all(
                  color:
                      selected ? FitnessTheme.silver : const Color(0xFF3C3E40),
                  width: .8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSelected == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onSelected(!selected);
                      },
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (selected) ...[
                        const Icon(Icons.check_rounded,
                            size: 14, color: FitnessTheme.canvas),
                        const SizedBox(width: 5),
                      ],
                      FitnessText(
                        label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? FitnessTheme.canvas
                                : FitnessTheme.silver),
                      ),
                    ])),
              ),
            ),
          ),
        ),
      );
}

class _Heading extends StatelessWidget {
  final String title, subtitle;
  const _Heading(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(title,
            style: const TextStyle(
                fontSize: 11,
                color: FitnessTheme.silver,
                fontWeight: FontWeight.w500,
                letterSpacing: 1)),
        const SizedBox(height: 5),
        FitnessText(subtitle,
            style: const TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.4))
      ]);
}
