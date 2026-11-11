import '../viewmodels/onboarding_controller.dart';
import '../../../core/theme/ds_motion.dart';
import 'package:setcraft/core/localization/fitness_copy.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
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
import 'lifestyle_nutrition_limitations_view.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/navigation/prepare_authenticated_home.dart';
import '../components/onboarding_scaffold.dart';
import '../components/onboarding_focus_body.dart';
import '../components/onboarding_coach.dart';

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
  static const _minimumDaysMessage =
      'Select at least 2 training days to continue.';
  static const _restDayMessage = 'Keep at least one rest day in your week.';
  String? get _trainingDaysError {
    if (_draft.trainingDays.length < 2) return _minimumDaysMessage;
    if (_draft.trainingDays.length > 6) return _restDayMessage;
    return null;
  }

  bool get _showActionError => !widget.editProfile && _part == 1;

  OnboardingDraft _draft = OnboardingDraft();
  late final OnboardingController? _controller =
      widget.editProfile ? null : widget.controller ?? OnboardingController();
  final _notes = TextEditingController();
  bool _loading = true, _saving = false, _loadFailed = false;
  int _part = 0;
  String? _error;
  String? _profileUser;
  @override
  void initState() {
    super.initState();
    _notes.addListener(_formChanged);
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
        _draft = OnboardingDraft.fromJson(j);
      } else {
        if (!_controller!.ready) await _controller!.initialize();
        _draft = _controller!.draft;
      }
      if (!mounted) return;
      _notes.text = _draft.customLimitations ?? '';
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
    _controller?.checkpoint();
  }

  Future<void> _save() async {
    if (_saving || _loading || _loadFailed) return;
    if (widget.editProfile && await CacheScope.userId() != _profileUser) {
      if (mounted) {
        setState(
            () => _error = 'Your session changed. Reopen your preferences.');
      }
      return;
    }
    String? error = _trainingDaysError;
    if (error == null &&
        _draft.trainingSplit == 'PUSH_PULL_LEGS' &&
        (_draft.trainingDays.isNotEmpty
                ? _draft.trainingDays.length
                : int.tryParse(
                        _draft.daysPerWeek?.replaceAll(RegExp(r'[^0-9]'), '') ??
                            '') ??
                    3) <
            3) {
      error = 'Choose at least three days for push / pull / legs.';
    }
    if (error != null) {
      setState(() {
        _error = error;
        if (!widget.editProfile) {
          _part = error!.contains('push / pull / legs') ? 2 : 1;
        }
      });
      return;
    }
    _draft.customLimitations = _notes.text.trim();
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

  Future<void> _advance() async {
    if (widget.editProfile) {
      await _save();
      return;
    }
    if (_part == 2 && _trainingDaysError != null) {
      _chooseTrainingDays();
      return;
    }
    String? error;
    if (_part == 1) {
      error = _trainingDaysError;
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
    }
    FocusScope.of(context).unfocus();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_part < 2) {
      setState(() {
        _error = null;
        _part++;
      });
      return;
    }
    // _part == 2: completed workout split! Continue to Fuel & Recovery step
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final count = _draft.trainingDays.length;
      if (count >= 2) {
        _draft.daysPerWeek = count >= 6 ? 'DAYS_6_PLUS' : 'DAYS_$count';
      }
      _draft.completedStep = 6;
      _controller!.checkpoint();
      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        await OnboardingPageRoute(
                page: LifestyleNutritionLimitationsView(
                    controller: _controller!))
            .open(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _chooseTrainingDays() {
    setState(() {
      _part = 1;
      _error = _trainingDaysError;
    });
  }

  void _selectTrainingStyle(String value) {
    _change(() => _draft.trainingSplit = value);
  }

  Widget _dayPill(String day) {
    final selected = _draft.trainingDays.contains(day);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: DSMotion.press,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? FitnessTheme.silver : const Color(0xFF1B1C1E),
          border: Border.all(
            color: selected ? FitnessTheme.silver : const Color(0xFF2C2E31),
            width: selected ? 1.0 : 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              OnboardingCoach.select();
              _change(() {
                final values = [..._draft.trainingDays];
                if (selected) {
                  values.remove(day);
                } else {
                  values.add(day);
                }
                _draft.trainingDays = values;
                if (_error == _minimumDaysMessage ||
                    _error == _restDayMessage) {
                  _error = _trainingDaysError;
                }
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FitnessText(
                  day[0],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                FitnessText(
                  day.substring(1, 3).toLowerCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? const Color(0xFF333333)
                        : const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeChoice(String value, String label) {
    final selected = (_draft.preferredTime ?? 'ANY') == value;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: DSMotion.press,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? FitnessTheme.silver : const Color(0xFF1B1C1E),
          border: Border.all(
            color: selected ? FitnessTheme.silver : const Color(0xFF2C2E31),
            width: .8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              OnboardingCoach.select();
              _change(() => _draft.preferredTime = value);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FitnessText(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainingDayChoices() => Row(
        children: [
          for (int i = 0; i < _days.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _dayPill(_days[i])),
          ],
        ],
      );

  @override
  void dispose() {
    if (!widget.editProfile && widget.controller == null) {
      _controller?.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        step: 6,
        totalSteps: 7,
        sectionLabel: 'Workout split',
        showProgress: !widget.editProfile,
        showCoach: !widget.editProfile,
        part: _part,
        parts: widget.editProfile ? 4 : 3,
        canPop: widget.editProfile || _part == 0,
        title: widget.editProfile
            ? 'Training preferences'
            : const [
                'What do you want to focus on?',
                'Select your workout days',
                'Workout split',
              ][_part],
        subtitle: widget.editProfile
            ? 'Your priorities, your schedule, your way to train'
            : const [
                'Choose as many as you like',
                'Pick the days that fit your weekly routine',
                'Choose how you want to train',
              ][_part],
        actionTitle: widget.editProfile
            ? 'Save preferences'
            : 'Continue',
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
        actionMessage: _showActionError ? _error : null,
        onContinue: _loading || _saving || _loadFailed ? null : _advance,
        children: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CupertinoActivityIndicator()))
          else ...[
            if (_error != null && !_showActionError)
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
                  plain: !widget.editProfile,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (widget.editProfile) ...[
                      const _Heading(
                          'Your week', 'Choose at least two training days.'),
                      const SizedBox(height: 12),
                    ],
                    _trainingDayChoices(),
                    const SizedBox(height: 28),
                    FitnessText(
                      fitnessText(context, 'Preferred workout time'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                        color: FitnessTheme.silver,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _timeChoice('ANY', 'Whenever works'),
                        _timeChoice('MORNING', 'Morning'),
                        _timeChoice('AFTERNOON', 'Afternoon'),
                        _timeChoice('EVENING', 'Evening'),
                      ],
                    ),
                  ])),
            ],
            if (widget.editProfile || _part == 2) ...[
              const SizedBox(height: 14),
              _PreferenceCard(
                plain: !widget.editProfile,
                child: TrainingStylePicker(
                    draft: _draft,
                    onChanged: _selectTrainingStyle),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF191A1D),
                        counterText: '',
                        hintText: fitnessText(context,
                            'Lower back pain, avoid barbell squats, bad shoulder'),
                        hintStyle: const TextStyle(
                            color: Color(0xFF666666), fontSize: 13),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF28292C), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF28292C), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.white, width: 1.0),
                        ),
                      ),
                    ),
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
                        OnboardingCoach.select();
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
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _open
                      ? const Color(0xFF2C2E31)
                      : const Color(0xFF222326),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FitnessText(
                  _open
                      ? 'Close'
                      : widget.controllers.any((c) => c.text.trim().isNotEmpty)
                          ? 'Edit'
                          : 'Add',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _open ? Colors.white : const Color(0xFFAAAAAA),
                  ),
                ),
              ),
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
