import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';
import 'widgets/plan_particle_orb.dart';

class WeeklyPlanGenerationView extends StatefulWidget {
  final WeeklyPlanRepository repository;
  final Map<String, dynamic> initialRun;
  final DateTime weekStart;

  const WeeklyPlanGenerationView({
    super.key,
    required this.repository,
    required this.initialRun,
    required this.weekStart,
  });

  @override
  State<WeeklyPlanGenerationView> createState() =>
      _WeeklyPlanGenerationViewState();
}

class _WeeklyPlanGenerationViewState extends State<WeeklyPlanGenerationView>
    with WidgetsBindingObserver {
  late Map<String, dynamic> _run = widget.initialRun;
  Timer? _timer;
  String? _owner;
  String? _connectionError;
  bool _polling = false;
  bool _retrying = false;
  bool _foreground = true;
  bool _unavailable = false;

  bool get _complete => _run['status'] == 'COMPLETED' && _run['plan'] is Map;
  bool get _failed => _run['status'] == 'FAILED';
  int get _percent {
    if (_complete) return 100;
    final progress = _run['progress'];
    final percent = progress is Map ? progress['percent'] : null;
    return percent is num ? percent.toInt().clamp(0, 99) : 0;
  }

  Set<String> get _steps {
    final progress = _run['progress'];
    final steps = progress is Map ? progress['completedSteps'] : null;
    return steps is List ? steps.whereType<String>().toSet() : {};
  }

  String get _status => switch (_run['stage']) {
        'retrying' => 'Reconnecting and retrying automatically',
        'specialists' => 'Choosing exercises for each muscle group',
        'workout_prescriptions' => 'Balancing your sets, reps and weights',
        'nutrition' => 'Matching food to your training week',
        'validation' => 'Checking your workouts and meals',
        'saving' => 'Saving your weekly plan',
        _ => 'Reviewing your saved history',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    _owner = await CacheScope.userId();
    if (!mounted) return;
    await _poll();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (mounted && _foreground && !_complete && !_failed && !_unavailable) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    }
  }

  Future<bool> _sameOwner() async {
    final owner = await CacheScope.userId();
    if (!mounted) return false;
    if (owner != _owner) {
      _timer?.cancel();
      Navigator.of(context).pop();
      return false;
    }
    return true;
  }

  Future<void> _poll() async {
    if (_polling || !_foreground || _unavailable) return;
    _polling = true;
    try {
      final run = await widget.repository.run(_run['id'] as String);
      if (!await _sameOwner()) return;
      setState(() {
        _run = run;
        _connectionError = null;
      });
      if (_complete || _failed) _timer?.cancel();
    } catch (error) {
      if (!await _sameOwner()) return;
      final status = error is DioException ? error.response?.statusCode : null;
      if (status == 401 || status == 403 || status == 404) {
        _timer?.cancel();
        _unavailable = true;
        setState(() => _connectionError =
            'This plan is unavailable. Return to your planner.');
      } else {
        setState(() => _connectionError =
            'Reconnecting… We’ll check for updates shortly.');
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final run = await widget.repository.retry(_run['id'] as String);
      if (!await _sameOwner()) return;
      setState(() {
        _run = run;
        _connectionError = null;
      });
      await _poll();
      _schedule();
    } catch (error) {
      if (!await _sameOwner()) return;
      final data = error is DioException ? error.response?.data : null;
      setState(() => _connectionError = data is Map && data['error'] is String
          ? data['error'] as String
          : 'Could not retry. Please try again.');
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!mounted) return;
    setState(() {});
    if (_foreground) {
      _poll();
      _schedule();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _failure => switch (_run['errorCode']) {
        'STALE_PLAN' =>
          'Your history or preferences changed. Generate an updated plan.',
        'MODEL_RATE_LIMIT' => 'Planning is busy right now. Retry shortly.',
        'WORKFLOW_UPDATED' => 'The planner was updated. Generate a new plan.',
        'CATALOG_CHANGED' =>
          'The exercise or food library changed. Generate a new plan.',
        'PLAN_COOLDOWN' =>
          'Your weekly plan is already saved. Return to your planner.',
        'RETRY_EXHAUSTED' =>
          'Planning is unavailable right now. Please return to your planner.',
        'PREMIUM_REQUIRED' ||
        'SUBSCRIPTION_REQUIRED' =>
          'Check your membership before planning again.',
        'INVALID_SPLIT' ||
        'STARTER_REVIEW_REQUIRED' ||
        'PROFILE_INCOMPLETE' =>
          'Review your training preferences before planning again.',
        _ => _run['canRetry'] == true
            ? 'We couldn’t finish this plan. Try again.'
            : 'We couldn’t finish this plan. Please return to your planner.',
      };

  @override
  Widget build(BuildContext context) {
    final week = DateTime.tryParse(_run['weekStart'] as String? ?? '') ??
        widget.weekStart;
    final lastDay = week.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final headline = _complete
        ? 'Your week is ready'
        : _failed
            ? 'Planning paused'
            : 'Building your week';

    return FitnessTheme(
        child: Scaffold(
      backgroundColor: DSColors.bg,
      appBar: AppBar(
        backgroundColor: DSColors.bg,
        surfaceTintColor: Colors.transparent,
        title: const FitnessText('Weekly plan',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: DSColors.muted)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                '${DateFormat.MMMd(locale).format(week)} – ${DateFormat.MMMd(locale).format(lastDay)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: DSColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            FitnessText(headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: PlanParticleOrb(
                  percent: _percent,
                  animating:
                      _foreground && !_failed && !_complete && !_unavailable),
            )),
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: FitnessText(
                _unavailable
                    ? 'This plan is unavailable. Return to your planner.'
                    : _complete
                        ? 'Your training week is ready to open'
                        : _failed
                            ? _failure
                            : _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: DSColors.silver),
              ),
            ),
            const SizedBox(height: 22),
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const FitnessText('Planning details',
                    style: TextStyle(fontSize: 12, color: DSColors.muted)),
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: DSColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DSColors.border, width: .7)),
                    child: Column(children: [
                      _step('Review history', 'history', 1),
                      const Divider(height: 1, color: DSColors.border),
                      _step('Build workouts', 'workouts', 2),
                      const Divider(height: 1, color: DSColors.border),
                      _step('Plan food', 'nutrition', 3),
                      const Divider(height: 1, color: DSColors.border),
                      _step('Check and save', 'saved', 4),
                    ]),
                  )
                ]),
            if (_connectionError != null && !_unavailable) ...[
              const SizedBox(height: 16),
              FitnessText(_connectionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: DSColors.muted, fontSize: 12, height: 1.5)),
            ],
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_complete)
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop(_run),
                      style: _buttonStyle,
                      child: const FitnessText('View weekly plan'))
                else if (_failed && _run['canRetry'] != false)
                  FilledButton(
                      onPressed: _retrying ? null : _retry,
                      style: _buttonStyle,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_retrying) ...[
                              const CupertinoActivityIndicator(
                                  radius: 8, color: DSColors.bg),
                              const SizedBox(width: 10),
                            ],
                            FitnessText(
                                _retrying ? 'Retrying…' : 'Retry planning'),
                          ])),
                if (!_complete)
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(_run),
                      child: FitnessText(
                          _failed || _unavailable
                              ? 'Back to planner'
                              : 'Continue in background',
                          style: const TextStyle(
                              color: DSColors.silver, fontSize: 13))),
                if (!_complete && !_failed && !_unavailable)
                  const FitnessText(
                      'You can leave. Your plan will be saved when it’s ready.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: DSColors.muted, fontSize: 11, height: 1.5)),
              ]),
        ),
      ),
    ));
  }

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
        backgroundColor: DSColors.silver,
        foregroundColor: DSColors.bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  Widget _step(String title, String key, int number) {
    const keys = ['history', 'workouts', 'nutrition', 'saved'];
    final done = _complete || _steps.contains(key);
    final active = !done && keys.take(number - 1).every(_steps.contains);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(children: [
        SizedBox(
          width: 22,
          height: 22,
          child: done
              ? const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: DSColors.silver, size: 18)
              : active && !_failed && !_unavailable && _foreground
                  ? const CupertinoActivityIndicator(
                      radius: 8, color: Colors.white)
                  : Center(
                      child: Text('$number',
                          style: const TextStyle(
                              color: DSColors.muted, fontSize: 11))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: FitnessText(title,
                style: TextStyle(
                    fontSize: 13,
                    color: done || active ? DSColors.silver : DSColors.muted))),
      ]),
    );
  }
}
