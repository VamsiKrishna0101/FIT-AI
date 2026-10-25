import '../../../core/theme/ds_motion.dart';
import '../../../core/components/content_transition.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';
import 'weekly_plan_generation_view.dart';
import 'weekly_plan_history_view.dart';
import 'widgets/weekly_plan_schedule.dart';
import '../../body_scan/models/body_assessment_models.dart';
import '../../body_scan/views/body_entry_view.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../notifications/views/notification_settings_view.dart';
import 'widgets/plan_schedule_sheet.dart';

class WeeklyPlanView extends StatefulWidget {
  final WeeklyPlanRepository? repository;
  final String? initialPlanId;
  final bool fromOnboarding;
  const WeeklyPlanView(
      {super.key,
      this.repository,
      this.initialPlanId,
      this.fromOnboarding = false});

  @override
  State<WeeklyPlanView> createState() => _WeeklyPlanViewState();
}

class _WeeklyPlanViewState extends State<WeeklyPlanView> {
  late final _repo = widget.repository ?? WeeklyPlanRepository();
  Map<String, dynamic>? _selected, _run, _availability;
  GlobalKey _planKey = GlobalKey();
  DateTime _week = DateTime.now();
  bool _loading = true,
      _busy = false,
      _polling = false,
      _choosingSchedule = false;
  String? _error;
  Timer? _timer;
  Timer? _unlockTimer;
  String? _owner;
  bool _progressOpen = false;
  bool get _running => ['QUEUED', 'RUNNING'].contains(_run?['status']);
  bool get _canGenerate => _availability?['canGenerate'] == true;
  bool get _cooldownActive => _availability?['cooldownActive'] == true;
  DateTime? get _nextGeneration =>
      DateTime.tryParse(_availability?['nextGenerationAt'] as String? ?? '')
          ?.toLocal();

  void _selectPlan(Map<String, dynamic>? plan) {
    // Each revealed plan owns its scroll anchor while the previous one fades.
    if (_selected?['id'] != plan?['id']) _planKey = GlobalKey();
    _selected = plan;
  }

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _week = today;
    _load();
  }

  String _message(Object error) {
    final data = error is DioException ? error.response?.data : null;
    return data is Map && data['error'] is String
        ? data['error'] as String
        : 'Could not load your plan. Please try again.';
  }

  Future<bool> _sameOwner() async {
    final owner = await CacheScope.userId();
    final same = mounted && _owner == owner;
    if (!same) {
      _timer?.cancel();
      _unlockTimer?.cancel();
    }
    return same;
  }

  Future<void> _load() async {
    final owner = await CacheScope.userId();

    if (!mounted) return;

    if (_owner != owner) {
      _timer?.cancel();
      _unlockTimer?.cancel();
      setState(() {
        _owner = owner;
        _selectPlan(null);
        _run = null;
        _availability = null;
        _loading = true;
        _error = null;
      });
    }
    try {
      final (availability, plans) =
          await (_repo.availability(), _repo.plans()).wait;
      if (!await _sameOwner()) return;
      final selectedId = _selected?['id'] ??
          widget.initialPlanId ??
          availability['lastPlanId'];
      var selected =
          plans.where((plan) => plan['id'] == selectedId).firstOrNull;
      if (selected == null && selectedId is String) {
        try {
          selected = await _repo.savedPlan(selectedId);
        } on DioException catch (error) {
          // A reset plan can disappear while this screen is still open.
          if (error.response?.statusCode != 404) rethrow;
        }
        if (!await _sameOwner()) return;
      }
      setState(() {
        _availability = availability;
        _selectPlan(selected ?? (plans.isEmpty ? null : plans.first));
        if (availability['pendingRun'] is Map) {
          _run = Map<String, dynamic>.from(availability['pendingRun'] as Map);
        }
        _loading = false;

        final today = DateUtils.dateOnly(DateTime.now());
        if (_canGenerate && _week.isBefore(today)) {
          _week = today;
        }

        if (_run?['status'] != 'FAILED') _error = null;
      });

      if (_running && !_progressOpen) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
      }

      _unlockTimer?.cancel();
      final nextGeneration = _nextGeneration;

      if (_cooldownActive && nextGeneration != null) {
        final remaining = nextGeneration.difference(DateTime.now());

        if (remaining > Duration.zero) {
          _unlockTimer = Timer(remaining + const Duration(seconds: 1), _load);
        }
      }
    } catch (error) {
      if (await _sameOwner()) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_busy || _choosingSchedule || _running || !_canGenerate) return;
    setState(() {
      _choosingSchedule = true;
      _error = null;
    });
    try {
      final preferences = _availability?['schedulePreferences'] as Map?;
      const counts = {
        'DAYS_2': 2,
        'DAYS_3': 3,
        'DAYS_4': 4,
        'DAYS_5': 5,
        'DAYS_6': 6
      };
      final schedule = await showModalBottomSheet<PlanScheduleSelection>(
          context: context,
          isScrollControlled: true,
          backgroundColor: FitnessTheme.surface,
          builder: (_) => FitnessTheme(
              child: PlanScheduleSheet(
                  initialStart: _week,
                  preferredDays: List<String>.from(
                      preferences?['trainingDays'] as List? ?? []),
                  usualCount: counts[preferences?['daysPerWeek']] ?? 3)));
      if (schedule == null || !await _sameOwner()) return;
      setState(() {
        _week = schedule.start;
        _busy = true;
      });
      BodyOverview? body;
      try {
        body = await _repo.bodyOverview();
      } on DioException catch (error) {
        if ([401, 403].contains(error.response?.statusCode)) rethrow;
        // Measurements are optional; their service must not block training.
      }
      if (!await _sameOwner()) return;
      if (body != null &&
          !WeeklyPlanRepository.hasEnteredMeasurements(body, DateTime.now())) {
        if (!await _measurementsBeforePlanning(body)) return;
        if (!await _sameOwner()) return;
      }
      final start = schedule.start;
      final monday =
          DateTime(start.year, start.month, start.day - start.weekday + 1);
      final run = await _repo.generate(
          weekStart: monday, startDate: start, trainingDates: schedule.dates);
      if (!await _sameOwner()) return;
      setState(() => _run = run);
      await _openProgress();
    } catch (error) {
      if (await _sameOwner()) {
        setState(() => _error = _message(error));
        final data = error is DioException ? error.response?.data : null;

        if (data is Map &&
            ['PLAN_COOLDOWN', 'ALREADY_GENERATING'].contains(data['code'])) {
          await _load();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _choosingSchedule = false;
        });
      }
    }
  }

  Future<bool> _measurementsBeforePlanning(BodyOverview body) async {
    final action = await showModalBottomSheet<String>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 24, 12, 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .15)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF282A2C), Color(0xFF141516)],
            ),
          ),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(CupertinoIcons.person_crop_rectangle,
                    size: 32, color: FitnessTheme.silver),
                const Spacer(),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(CupertinoIcons.xmark, size: 18)),
              ]),
              const SizedBox(height: 20),
              const FitnessText('Add measurements (optional)',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.6,
                      height: 1.15)),
              const SizedBox(height: 12),
              const FitnessText(
                  'Entered measurements help you track changes. Your training history, equipment and goals guide exercises, weights and reps.',
                  style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
              const SizedBox(height: 12),
              const FitnessText(
                  'No photos needed. You can add measurements later.',
                  style: TextStyle(color: FitnessTheme.silver, fontSize: 12)),
              const SizedBox(height: 24),
              LiquidChromeButton(
                  title: 'Add measurements',
                  onPressed: () => Navigator.pop(sheetContext, 'measure')),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(sheetContext, 'continue'),
                  child: const FitnessText('Continue without measurements',
                      style: TextStyle(color: FitnessTheme.silver))),
            ],
          )),
        ),
      ),
    );

    if (!await _sameOwner()) return false;
    if (action == 'continue') return true;
    if (action != 'measure') return false;
    if (!mounted) return false;

    final route = AppPageRoute<bool>(
        page: BodyEntryView(
      profileWeight: (body.profile?['weight'] as num?)?.toDouble(),
    ));
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    return saved == true;
  }

  Future<void> _poll() async {
    if (_polling || _run == null || _progressOpen) return;
    _polling = true;
    try {
      final run = await _repo.run(_run!['id'] as String);
      if (!await _sameOwner()) return;
      if (_progressOpen) return;
      setState(() {
        _run = run;
        if (run['plan'] is Map) {
          _selectPlan(Map<String, dynamic>.from(run['plan'] as Map));
        }
        if (run['status'] == 'FAILED') {
          _error = _failureMessage(run['errorCode'] as String?);
        }
      });
      if (!_running) {
        _timer?.cancel();
        await _load();
        if (_run?['status'] == 'COMPLETED' && mounted && await _sameOwner()) {
          if (mounted) await offerNotificationReminders(context);
        }
      }
    } catch (error) {
      if (await _sameOwner()) setState(() => _error = _message(error));
    } finally {
      _polling = false;
    }
  }

  Future<void> _openProgress() async {
    if (_progressOpen || _run == null) return;
    _progressOpen = true;
    _timer?.cancel();
    final route = AppPageRoute<Map<String, dynamic>>(
      page: WeeklyPlanGenerationView(
        repository: _repo,
        initialRun: _run!,
        weekStart: _week,
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    _progressOpen = false;
    if (!await _sameOwner()) return;
    if (result != null) setState(() => _run = result);
    await _poll();
    await _load();
    if (_run?['status'] == 'COMPLETED' && mounted && await _sameOwner()) {
      if (mounted) await offerNotificationReminders(context);
    }
  }

  Future<void> _openHistory() async {
    final route = AppPageRoute<Map<String, dynamic>>(
      page: WeeklyPlanHistoryView(repository: _repo),
    );
    final plan = await Navigator.of(context).push(route);
    await route.completed;
    if (!await _sameOwner() || plan == null) return;
    setState(() => _selectPlan(plan));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final planContext = _planKey.currentContext;
      if (planContext != null) {
        Scrollable.ensureVisible(planContext,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DSMotion.regular,
            curve: Curves.easeOutCubic);
      }
    });
  }

  String _failureMessage(String? code) => switch (code) {
        'STALE_PLAN' =>
          'Your history or preferences changed. Generate an updated plan.',
        'WORKFLOW_UPDATED' => 'The planner was updated. Generate a new plan.',
        'CATALOG_CHANGED' =>
          'The exercise or food library changed. Generate a new plan.',
        'PLAN_COOLDOWN' =>
          'Your weekly plan is already saved. Check the next available date below.',
        'CATALOG_GAP' =>
          'Your equipment needs more reviewed exercise options. Update your preferences.',
        'MODEL_RATE_LIMIT' => 'Planning is busy right now. Retry shortly.',
        'MODEL_NOT_CONFIGURED' ||
        'MODEL_UNAVAILABLE' =>
          'Weekly planning is unavailable right now.',
        _ =>
          'A complete plan could not be validated. Your current schedule is unchanged.',
      };

  Future<void> _activate() async {
    if (_busy || _selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.activate(_selected!['id'] as String);
      if (!await _sameOwner()) return;
      if (!mounted) return;
      setState(() => _selected!['status'] = 'ACTIVE');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: FitnessText('Your weekly plan is ready')));
    } catch (error) {
      if (await _sameOwner()) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unlockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = _selected?['payload'] is Map
        ? Map<String, dynamic>.from(_selected!['payload'] as Map)
        : null;
    final start = DateTime.tryParse(_selected?['weekStart'] as String? ?? '');
    final end =
        start == null ? null : DateTime(start.year, start.month, start.day + 6);
    final pastWeek = end?.isBefore(DateUtils.dateOnly(DateTime.now())) == true;
    final nextGeneration = _nextGeneration;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = switch (_selected?['status']) {
      'ACTIVE' => 'Active plan',
      'ARCHIVED' => 'Archived plan',
      _ => 'Saved plan',
    };
    return FitnessTheme(
        child: Scaffold(
      appBar: AppBar(
        title: const FitnessText('Your weekly plan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: FitnessTheme.canvas,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
              onPressed: _busy ? null : _openHistory,
              child: const FitnessText('History',
                  style: TextStyle(color: FitnessTheme.silver, fontSize: 12)))
        ],
      ),
      body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: ContentTransition(
                key: ValueKey(_owner),
                child: _loading && payload == null
                    ? const LoadingPlaceholder(key: ValueKey('plan-loading'))
                    : Column(
                        key: ValueKey(_selected?['id'] ?? 'plan-empty'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            if (_running) ...[
                              _surface(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    const FitnessText(
                                        'Your next plan is being prepared.',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    FitnessSubmit(
                                        label: 'View plan progress',
                                        onPressed:
                                            _busy ? null : _openProgress),
                                  ])),
                              const SizedBox(height: 20),
                            ],
                            if (payload == null && !_running) ...[
                              const FitnessText('Your next workouts',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.7)),
                              const SizedBox(height: 10),
                              const FitnessText(
                                  'Choose your start date and training days. We’ll build your workouts and food plan around them.',
                                  style: TextStyle(
                                      color: FitnessTheme.muted, height: 1.5)),
                              const SizedBox(height: 24),
                              if (_canGenerate)
                                FitnessSubmit(
                                    label: 'Generate weekly plan',
                                    busy: _busy,
                                    onPressed: _loading ? null : _generate),
                            ],
                            if (payload != null) ...[
                              SizedBox(key: _planKey, height: 0),
                              if (start != null && end != null)
                                Text(
                                    '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}',
                                    style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.5)),
                              const SizedBox(height: 6),
                              Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    FitnessText(
                                        payload['synthetic'] == true
                                            ? 'TEST PLAN'
                                            : status,
                                        style: const TextStyle(
                                            color: FitnessTheme.muted,
                                            fontSize: 12)),
                                    if (_canGenerate && !_running)
                                      TextButton(
                                          onPressed: _busy ? null : _generate,
                                          child: const FitnessText(
                                              'Create next plan',
                                              style: TextStyle(
                                                  color: FitnessTheme.silver,
                                                  fontSize: 12))),
                                  ]),
                              if (_cooldownActive && nextGeneration != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: FitnessText(
                                        'Next plan available ${DateFormat.yMMMd(locale).add_jm().format(nextGeneration)}',
                                        style: const TextStyle(
                                            color: FitnessTheme.muted,
                                            fontSize: 11,
                                            height: 1.4))),
                              const SizedBox(height: 20),
                              WeeklyPlanSchedule(
                                  key: ValueKey(_selected!['id']),
                                  active: _selected?['status'] == 'ACTIVE',
                                  fromOnboarding: widget.fromOnboarding,
                                  payload: payload),
                              if ((payload['warnings'] as List? ?? [])
                                  .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      title: const FitnessText('Plan notes',
                                          style: TextStyle(
                                              color: FitnessTheme.muted,
                                              fontSize: 13)),
                                      children: [
                                        for (final warning
                                            in payload['warnings'] as List)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: FitnessText('$warning',
                                                  style: const TextStyle(
                                                      color: FitnessTheme.muted,
                                                      fontSize: 12,
                                                      height: 1.5)))
                                      ],
                                    )),
                              ],
                              if (_selected?['status'] == 'DRAFT' &&
                                  _selected?['synthetic'] != true &&
                                  !pastWeek)
                                Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: FitnessSubmit(
                                        label: 'Use this weekly plan',
                                        busy: _busy,
                                        onPressed: _activate)),
                              if (pastWeek && _selected?['status'] == 'DRAFT')
                                const Padding(
                                    padding: EdgeInsets.only(top: 16),
                                    child: FitnessText(
                                        'Past week · saved for review',
                                        style: TextStyle(
                                            color: FitnessTheme.muted,
                                            fontSize: 12))),
                            ],
                            if (_run?['status'] == 'FAILED' && !_cooldownActive)
                              TextButton(
                                  onPressed: _busy ? null : _openProgress,
                                  child: const FitnessText('Retry planning')),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(children: [
                                    FitnessText(_error!,
                                        style: const TextStyle(
                                            color: FitnessTheme.coral)),
                                    TextButton(
                                        onPressed: _busy ? null : _load,
                                        child: const FitnessText('Retry')),
                                  ])),
                          ])),
          )),
    ));
  }

  Widget _surface({required Widget child}) => FitnessCard(child: child);
}
