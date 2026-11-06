import '../../body_scan/models/body_measurement_baseline.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/content_transition.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';
import 'weekly_plan_generation_view.dart';
import '../../notifications/views/notification_settings_view.dart';
import 'weekly_plan_history_view.dart';
import 'widgets/weekly_plan_schedule.dart';
import '../../body_scan/models/body_assessment_models.dart';
import '../../body_scan/views/body_entry_view.dart';
import 'widgets/plan_schedule_sheet.dart';
import '../../profile/views/ai_sharing_consent.dart';

class WeeklyPlanView extends StatefulWidget {
  final WeeklyPlanRepository? repository;
  final String? initialPlanId;
  final bool fromOnboarding;
  final bool startGenerationOnOpen;
  final DateTime? initialStartDate;
  final Future<bool> Function(BuildContext) requestAiConsent;
  const WeeklyPlanView(
      {super.key,
      this.repository,
      this.initialPlanId,
      this.requestAiConsent = ensureAiSharingConsent,
      this.fromOnboarding = false,
      this.startGenerationOnOpen = false,
      this.initialStartDate});

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
  bool _autoGenerationStarted = false;
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
    _week = DateUtils.dateOnly(widget.initialStartDate ?? DateTime.now());
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

      if (widget.startGenerationOnOpen && !_autoGenerationStarted) {
        _autoGenerationStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _canGenerate && !_running) unawaited(_generate());
        });
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
          sheetAnimationStyle: DSMotion.sheetStyle(context),
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
      final body = await _repo.bodyOverview();
      if (!await _sameOwner()) return;
      if (!WeeklyPlanRepository.hasEnteredMeasurements(body, DateTime.now())) {
        if (!await _measurementsBeforePlanning(body)) return;
        if (!await _sameOwner()) return;
        final updated = await _repo.bodyOverview();
        if (!WeeklyPlanRepository.hasEnteredMeasurements(
            updated, DateTime.now())) {
          throw StateError(
              'Complete your measurements before creating your plan.');
        }
      }
      final start = schedule.start;
      if (!mounted ||
          !await widget.requestAiConsent(context) ||
          !await _sameOwner()) {
        return;
      }
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
    final route = AppPageRoute<bool>(
        page: BodyEntryView(
      baseline: BodyMeasurementBaseline(body),
      requireBaseline: true,
    ));
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    return saved == true && await _sameOwner();
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
        requestAiConsent: widget.requestAiConsent,
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    _progressOpen = false;
    if (!await _sameOwner()) return;
    if (result != null) {
      setState(() {
        _run = result;
        if (result['status'] == 'COMPLETED' && result['plan'] is Map) {
          _loading = true;
          _selectPlan(Map<String, dynamic>.from(result['plan'] as Map));
        }
      });
    }
    await _load();
    if (mounted && result?['status'] == 'COMPLETED') {
      await offerNotificationReminders(context);
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
            curve: DSMotion.effects);
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
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.chevron_left,
                    size: 20, color: FitnessTheme.silver))
            : null,
        title: const FitnessText('Weekly plan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        backgroundColor: FitnessTheme.canvas,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
              onPressed: _busy ? null : _openHistory,
              child: const FitnessText('History',
                  style: TextStyle(color: FitnessTheme.silver, fontSize: 12)))
        ],
      ),
      backgroundColor: FitnessTheme.canvas,
      body: DecoratedBox(
          decoration: const BoxDecoration(color: FitnessTheme.canvas),
          child: RefreshIndicator(
              color: Colors.white,
              backgroundColor: FitnessTheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: ContentTransition(
                    key: ValueKey(_owner),
                    child: _loading && payload == null
                        ? const LoadingPlaceholder(
                            key: ValueKey('plan-loading'))
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
                                      'Choose your days. Build a week around you.',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          height: 1.5)),
                                  const SizedBox(height: 24),
                                  if (_canGenerate)
                                    FitnessSubmit(
                                        label: 'Generate weekly plan',
                                        busy: _busy,
                                        onPressed: _loading ? null : _generate),
                                ],
                                if (payload != null) ...[
                                  SizedBox(key: _planKey, height: 0),
                                  _pageHeading(
                                      payload, status, start, end, locale),
                                  _planDetails(payload, nextGeneration, locale),
                                  const SizedBox(height: 14),
                                  WeeklyPlanSchedule(
                                      key: ValueKey(_selected!['id']),
                                      active: _selected?['status'] == 'ACTIVE',
                                      fromOnboarding: widget.fromOnboarding,
                                      payload: payload),
                                  if (_selected?['status'] == 'DRAFT' &&
                                      _selected?['synthetic'] != true &&
                                      !pastWeek)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: FitnessSubmit(
                                            label: 'Use this weekly plan',
                                            busy: _busy,
                                            onPressed: _activate)),
                                  if (pastWeek &&
                                      _selected?['status'] == 'DRAFT')
                                    const Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: FitnessText(
                                            'Past week · saved for review',
                                            style: TextStyle(
                                                color: FitnessTheme.muted,
                                                fontSize: 12))),
                                ],
                                if (_run?['status'] == 'FAILED' &&
                                    !_cooldownActive)
                                  TextButton(
                                      onPressed: _busy ? null : _openProgress,
                                      child:
                                          const FitnessText('Retry planning')),
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
              ))),
    ));
  }

  Widget _pageHeading(Map<String, dynamic> payload, String status,
          DateTime? start, DateTime? end, String locale) =>
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const FitnessText('Your week',
              style: TextStyle(
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.65)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (start != null && end != null)
                  Text(
                      '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}',
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(8)),
                    child: FitnessText(
                        payload['synthetic'] == true ? 'TEST PLAN' : status,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500))),
              ]),
        ]),
      );

  Widget _surface({required Widget child}) => FitnessCard(child: child);

  Widget _planDetails(Map<String, dynamic> payload, DateTime? nextGeneration,
          String locale) =>
      FitnessCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: const ValueKey('weekly-plan-why'),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: FitnessTheme.muted,
          collapsedIconColor: FitnessTheme.muted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const FitnessText('Why this plan',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FitnessTheme.silver)),
          children: [
            if (payload['summary'] case final String summary
                when summary.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FitnessText(summary,
                      style: const TextStyle(
                          fontSize: 12,
                          color: FitnessTheme.muted,
                          height: 1.5))),
            ..._planReasons(payload),
            for (final warning in payload['warnings'] as List? ?? [])
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitnessText('$warning',
                      style: const TextStyle(
                          fontSize: 12,
                          color: FitnessTheme.muted,
                          height: 1.5))),
            if (_cooldownActive && nextGeneration != null)
              FitnessText(
                  'Next plan available ${DateFormat.yMMMd(locale).add_jm().format(nextGeneration)}',
                  style: const TextStyle(
                      fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
            if (_canGenerate && !_running)
              TextButton(
                  onPressed: _busy ? null : _generate,
                  child: const FitnessText('Create next plan')),
          ],
        ),
      );

  List<Widget> _planReasons(Map<String, dynamic> payload) {
    final seen = <String>{};
    final reasons = <Widget>[];
    for (final day in (payload['workouts'] as List? ?? []).whereType<Map>()) {
      for (final exercise
          in (day['exercises'] as List? ?? []).whereType<Map>()) {
        final reason = '${exercise['reason'] ?? ''}'.trim();
        final name =
            '${exercise['displayName'] ?? exercise['name'] ?? day['name'] ?? ''}';
        if (reason.isEmpty || !seen.add('$name:$reason')) continue;
        reasons.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (name.isNotEmpty) ...[
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
            ],
            FitnessText(reason,
                style: const TextStyle(
                    fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
          ]),
        ));
      }
    }
    return reasons;
  }
}
