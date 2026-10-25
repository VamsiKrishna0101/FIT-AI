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
import '../components/training_style_picker.dart';
import '../../auth/views/auth_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/navigation/prepare_authenticated_home.dart';
import '../components/onboarding_scaffold.dart';
import '../components/onboarding_focus_body.dart';
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
  int _part = 0;
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
    if (_saving || _loading || _loadFailed) return;
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
      setState(() {
        _error = error;
        if (!widget.editProfile) {
          _part = error!.contains('budget') || error.contains('food names')
              ? 3
              : error.contains('push / pull / legs') ||
                      error.contains('add muscles')
                  ? 2
                  : 1;
        }
      });
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
          await _controller!.flush();
          final token = await SecureSessionStore.shared.accessToken;
          if (!mounted) return;
          if (token == null || token.isEmpty) {
            await OnboardingPageRoute<void>(
                    page: AuthView(controller: _controller!))
                .open(context);
          } else {
            await AuthRepository().completeMissingProfile(_draft);
            _controller!.finish();
            final destination = await prepareAuthenticatedHome();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil<void>(
                OnboardingPageRoute<void>(page: destination), (_) => false);
          }
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

  void _toggleMuscle(String muscle) => _change(() {
        // An empty list is the balanced full-body choice. A first explicit tap
        // starts a focused selection, matching the buttons above the illustration.
        final selected = _draft.focusMuscles.toSet();
        if (!selected.add(muscle)) selected.remove(muscle);
        _draft.focusMuscles = selected.toList();
      });

  void _advance() {
    if (widget.editProfile || _part == 3) {
      _save();
      return;
    }
    String? error;
    if (_part == 1 && _draft.trainingDays.length == 1) {
      error = 'Choose at least two training days, or leave your week flexible.';
    } else if (_part == 1 && _draft.trainingDays.length > 6) {
      error = 'Keep at least one rest day in your week.';
    } else if (_part == 2 &&
        _draft.trainingSplit == 'PUSH_PULL_LEGS' &&
        (_draft.trainingDays.isNotEmpty
                ? _draft.trainingDays.length
                : int.tryParse(
                        _draft.daysPerWeek?.replaceAll(RegExp(r'[^0-9]'), '') ??
                            '') ??
                    3) <
            3) {
      error = 'Choose at least three days for push / pull / legs.';
    } else if (_part == 2 &&
        _draft.trainingSplit == 'CUSTOM' &&
        (_draft.trainingDays.length < 2 ||
            _draft.trainingDays.any((day) =>
                _draft.customTrainingSplit[day]?.isNotEmpty != true))) {
      error = 'Choose your training days and add muscles to each day.';
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = error;
      if (error == null) _part++;
    });
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
        sectionLabel: 'Almost ready',
        showProgress: !widget.editProfile,
        part: _part,
        parts: 4,
        canPop: widget.editProfile || _part == 0,
        title: widget.editProfile
            ? 'Training preferences'
            : const [
                'What do you want to focus on?',
                'Which days work for you?',
                'Your training style',
                'Final details',
              ][_part],
        subtitle: widget.editProfile
            ? 'Your priorities, your schedule, your way to train.'
            : const [
                'Choose as many as you like',
                'Choose at least two days, or keep your schedule flexible.',
                '',
                'Optional',
              ][_part],
        actionTitle: widget.editProfile
            ? 'Save preferences'
            : _part < 3
                ? 'Continue'
                : 'Build my plan',
        onBack: () {
          if (!widget.editProfile && _part > 0) {
            setState(() {
              _part--;
              _error = null;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
        loading: _saving,
        onContinue: _loading || _saving || _loadFailed ? null : _advance,
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
            if (widget.editProfile || _part == 0)
              _PreferenceCard(
                  plain: !widget.editProfile,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.editProfile)
                          _Heading(
                              'Your focus',
                              fitnessText(
                                  context,
                                  _draft.focusMuscles.isEmpty
                                      ? 'Balanced across all muscles'
                                      : '{count} muscles selected',
                                  values: {
                                    'count': _draft.focusMuscles.length
                                  })),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          KeyedSubtree(
                              key: const ValueKey('focus-full-body'),
                              child: _chip(
                                  'Full body',
                                  _draft.focusMuscles.isEmpty,
                                  (_) =>
                                      _change(() => _draft.focusMuscles = []))),
                          for (final group in const <String, List<String>>{
                            'Chest': ['chest'],
                            'Back': ['upper_back', 'lats', 'lower_back'],
                            'Arms': ['biceps', 'triceps', 'forearms'],
                            'Shoulders': ['shoulders'],
                            'Core': ['core'],
                            'Legs': ['quads', 'hamstrings', 'calves'],
                            'Glutes': ['glutes'],
                          }.entries)
                            _chip(
                                group.key,
                                group.value.every(_draft.focusMuscles.contains),
                                (selected) => _change(() {
                                      final ids = _draft.focusMuscles.toSet();
                                      if (selected) {
                                        ids.addAll(group.value);
                                      } else {
                                        ids.removeAll(group.value);
                                      }
                                      _draft.focusMuscles = ids.toList();
                                    })),
                        ]),
                        const SizedBox(height: 20),
                        OnboardingFocusBody(
                            height: widget.editProfile ? 300 : 340,
                            onSelected: _toggleMuscle,
                            selected: _draft.focusMuscles.isEmpty
                                ? trainingMuscles.keys.toSet()
                                : _draft.focusMuscles.toSet(),
                            female: _draft.gender == 'FEMALE'),
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: const FitnessText(
                                'Choose individual muscles',
                                style: TextStyle(
                                    fontSize: 13, color: FitnessTheme.muted)),
                            children: [
                              Wrap(spacing: 7, runSpacing: 8, children: [
                                for (final entry in trainingMuscles.entries)
                                  _chip(
                                      entry.value,
                                      _draft.focusMuscles.contains(entry.key),
                                      (_) => _toggleMuscle(entry.key)),
                              ])
                            ]),
                      ])),
            if (widget.editProfile || _part == 1) ...[
              const SizedBox(height: 14),
              _PreferenceCard(
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
                              value: 'ANY',
                              child: FitnessText('Whenever works')),
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
            ],
            if (widget.editProfile || _part == 2) ...[
              const SizedBox(height: 14),
              _PreferenceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrainingStylePicker(
                        draft: _draft,
                        onChanged: (value) =>
                            _change(() => _draft.trainingSplit = value)),
                    if (_draft.trainingSplit == 'CUSTOM') ...[
                      const SizedBox(height: 16),
                      for (final day
                          in _days.where(_draft.trainingDays.contains)) ...[
                        const SizedBox(height: 16),
                        FitnessText(day[0] + day.substring(1).toLowerCase(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
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
                          child: FitnessText(
                              'Choose your days in Your week above.'),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            if (widget.editProfile || _part == 3) ...[
              const SizedBox(height: 14),
              _OptionalPreferenceCard(
                  key: const ValueKey('movement-notes-section'),
                  title: 'Movement notes',
                  controllers: [
                    _notes
                  ],
                  children: [
                    TextField(
                        controller: _notes,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                            counterText: '',
                            hintText:
                                fitnessText(context, 'Movements to avoid')))
                  ]),
              const SizedBox(height: 14),
              _OptionalPreferenceCard(
                  key: ValueKey(
                      'food-preferences-${_error?.contains('budget') == true || _error?.contains('food names') == true}'),
                  title: 'Food preferences',
                  controllers: [_allergies, _dislikes, _budget],
                  expand: _error?.contains('budget') == true ||
                      _error?.contains('food names') == true,
                  children: [
                    TextField(
                        controller: _allergies,
                        maxLength: 500,
                        decoration: InputDecoration(
                            counterText: '',
                            labelText: fitnessText(context, 'Food allergies'),
                            hintText: fitnessText(
                                context, 'Separate foods with commas'))),
                    const SizedBox(height: 10),
                    TextField(
                        controller: _dislikes,
                        maxLength: 500,
                        decoration: InputDecoration(
                            counterText: '',
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
                  ]),
            ],
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
              borderRadius: BorderRadius.circular(28),
              color: selected ? FitnessTheme.silver : const Color(0xFF282A2C),
              border: Border.all(
                  color:
                      selected ? FitnessTheme.silver : const Color(0xFF3C3E40),
                  width: .8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
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

class _OptionalPreferenceCard extends StatefulWidget {
  final String title;
  final List<TextEditingController> controllers;
  final List<Widget> children;
  final bool expand;
  const _OptionalPreferenceCard(
      {super.key,
      required this.title,
      required this.controllers,
      required this.children,
      this.expand = false});
  @override
  State<_OptionalPreferenceCard> createState() =>
      _OptionalPreferenceCardState();
}

class _OptionalPreferenceCardState extends State<_OptionalPreferenceCard> {
  late bool _open = widget.expand;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge(widget.controllers),
        builder: (context, _) => _PreferenceCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: widget.expand,
              maintainState: true,
              onExpansionChanged: (open) => setState(() => _open = open),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: FitnessText(widget.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: FitnessText(
                  _open
                      ? 'Close'
                      : widget.controllers.any((c) => c.text.trim().isNotEmpty)
                          ? 'Edit'
                          : 'Add',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              children: widget.children,
            )),
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

class _PreferenceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool plain;
  const _PreferenceCard(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      this.plain = false});
  @override
  Widget build(BuildContext context) => plain
      ? child
      : FitnessCard(
          padding: padding,
          child: Material(type: MaterialType.transparency, child: child));
}
