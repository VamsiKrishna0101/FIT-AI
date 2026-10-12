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

class WeeklyPlanView extends StatefulWidget {
  final WeeklyPlanRepository? repository;
  const WeeklyPlanView({super.key, this.repository});

  @override
  State<WeeklyPlanView> createState() => _WeeklyPlanViewState();
}

class _WeeklyPlanViewState extends State<WeeklyPlanView> {
  late final _repo = widget.repository ?? WeeklyPlanRepository();
  Map<String, dynamic>? _selected, _run, _availability;
  GlobalKey _planKey = GlobalKey();
  DateTime _week = DateTime.now();
  bool _loading = true, _busy = false, _polling = false;
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
    _week = today.weekday == DateTime.monday
        ? today
        : today.add(Duration(days: 8 - today.weekday));
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
      final selectedId = _selected?['id'] ?? availability['lastPlanId'];
      var selected =
          plans.where((plan) => plan['id'] == selectedId).firstOrNull;
      if (selected == null && _selected != null) {
        selected = await _repo.savedPlan(_selected!['id'] as String);
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
          _week = today.weekday == DateTime.monday
              ? today
              : today.add(Duration(days: 8 - today.weekday));
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
    if (_busy || _running || !_canGenerate) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final run = await _repo.generate(weekStart: _week);
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
      if (mounted) setState(() => _busy = false);
    }
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
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    _progressOpen = false;
    if (!await _sameOwner()) return;
    if (result != null) setState(() => _run = result);
    await _poll();
    await _load();
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
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
      }
    });
  }

  String _failureMessage(String? code) => switch (code) {
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
    final selectedWeek =
        DateTime.tryParse(_selected?['weekStart'] as String? ?? '');
    final pastWeek =
        selectedWeek?.isBefore(DateUtils.dateOnly(DateTime.now())) == true;
    final nextGeneration = _nextGeneration;
    final displayedWeek = _cooldownActive
        ? DateTime.tryParse(_selected?['weekStart'] as String? ?? '') ?? _week
        : _week;
    return FitnessTheme(
        child: Scaffold(
      appBar: AppBar(
          title: const FitnessText('Your weekly plan'),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent),
      body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(children: [
                ContentTransition(
                  key: ValueKey(_owner),
                  child: _loading && payload == null
                      ? const LoadingPlaceholder(key: ValueKey('plan-loading'))
                      : Column(
                          key: ValueKey(_selected?['id'] ?? 'plan-empty'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              FitnessText(
                                  payload == null
                                      ? 'Made for your next week'
                                      : 'Your saved week',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.7)),
                              const SizedBox(height: 10),
                              const FitnessText(
                                  'Review your workouts and food, one day at a time.',
                                  style: TextStyle(
                                      color: FitnessTheme.muted, height: 1.5)),
                              const SizedBox(height: 20),
                              Material(
                                color: Colors.white.withValues(alpha: .035),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(
                                        color: FitnessTheme.line)),
                                child: ListTile(
                                  onTap: _busy ? null : _openHistory,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 5),
                                  leading: const Icon(CupertinoIcons.clock,
                                      color: FitnessTheme.silver, size: 23),
                                  title: const FitnessText('Plan history',
                                      style: TextStyle(fontSize: 15)),
                                  subtitle: const FitnessText(
                                      'Review your saved weeks',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12)),
                                  trailing: const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: FitnessTheme.muted),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (payload != null) ...[
                                SizedBox(key: _planKey, height: 24),
                                const FitnessText('Weekly overview',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.4)),
                                if (selectedWeek != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                      '${DateFormat.yMMMd().format(selectedWeek)} – ${DateFormat.yMMMd().format(selectedWeek.add(const Duration(days: 6)))}',
                                      style: const TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12)),
                                ],
                                const SizedBox(height: 16),
                                if (payload['synthetic'] == true)
                                  const FitnessText(
                                      'TEST PLAN · synthetic history',
                                      style: TextStyle(
                                          color: FitnessTheme.coral,
                                          fontWeight: FontWeight.w600)),
                                if ((payload['warnings'] as List? ?? [])
                                    .isNotEmpty)
                                  ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: const FitnessText('Plan notes',
                                        style: TextStyle(fontSize: 13)),
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
                                                    height: 1.5))),
                                    ],
                                  ),
                                const SizedBox(height: 20),
                                WeeklyPlanSchedule(
                                    key: ValueKey(_selected!['id']),
                                    payload: payload),
                                const SizedBox(height: 20),
                                if (_selected?['status'] == 'DRAFT' &&
                                    _selected?['synthetic'] != true &&
                                    !pastWeek)
                                  FitnessSubmit(
                                      label: 'Use this weekly plan',
                                      busy: _busy,
                                      onPressed: _activate),
                                if (pastWeek && _selected?['status'] == 'DRAFT')
                                  const FitnessText(
                                      'Past week · saved for review',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12)),
                                if (_selected?['status'] == 'ACTIVE')
                                  const FitnessText(
                                      'Active in your training schedule',
                                      style: TextStyle(
                                          color: FitnessTheme.silver)),
                              ],
                              _surface(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title:
                                            const FitnessText('Week beginning'),
                                        subtitle: Text(DateFormat.yMMMd()
                                            .format(displayedWeek)),
                                        trailing:
                                            const Icon(CupertinoIcons.calendar),
                                        onTap: _busy ||
                                                _running ||
                                                !_canGenerate
                                            ? null
                                            : () async {
                                                final date =
                                                    await showDatePicker(
                                                        context: context,
                                                        initialDate: _week,
                                                        firstDate:
                                                            DateTime.now(),
                                                        lastDate: DateTime.now()
                                                            .add(const Duration(
                                                                days: 28)),
                                                        selectableDayPredicate:
                                                            (d) =>
                                                                d.weekday ==
                                                                DateTime
                                                                    .monday);
                                                if (date != null && mounted) {
                                                  setState(() => _week = date);
                                                }
                                              }),
                                    const SizedBox(height: 8),
                                    FitnessSubmit(
                                        label: _running
                                            ? 'View plan progress'
                                            : _cooldownActive
                                                ? 'View weekly plan'
                                                : 'Generate weekly plan',
                                        busy: _busy,
                                        onPressed: _loading
                                            ? null
                                            : _running
                                                ? _openProgress
                                                : _cooldownActive
                                                    ? () {
                                                        final planContext =
                                                            _planKey
                                                                .currentContext;
                                                        if (planContext !=
                                                            null) {
                                                          Scrollable.ensureVisible(
                                                              planContext,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300));
                                                        }
                                                      }
                                                    : _canGenerate
                                                        ? _generate
                                                        : null),
                                    if (_cooldownActive &&
                                        nextGeneration != null) ...[
                                      const SizedBox(height: 10),
                                      FitnessText(
                                          'Next plan available ${DateFormat.yMMMd().add_jm().format(nextGeneration)}',
                                          style: const TextStyle(
                                              color: FitnessTheme.muted,
                                              fontSize: 12,
                                              height: 1.5)),
                                    ],
                                    if (_running)
                                      const Padding(
                                          padding: EdgeInsets.only(top: 12),
                                          child: FitnessText(
                                              'Preparing exercises and food. You can leave this screen; the plan will be saved.',
                                              style: TextStyle(
                                                  color: FitnessTheme.muted,
                                                  fontSize: 12))),
                                    if (_run?['status'] == 'FAILED' &&
                                        !_cooldownActive)
                                      TextButton(
                                          onPressed:
                                              _busy ? null : _openProgress,
                                          child: const FitnessText(
                                              'Retry planning')),
                                  ])),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: FitnessText(_error!,
                                        style: const TextStyle(
                                            color: FitnessTheme.coral))),
                            ]),
                ),
              ]))),
    ));
  }

  Widget _surface({required Widget child}) =>
      FitnessCard(child: Material(color: Colors.transparent, child: child));
}
