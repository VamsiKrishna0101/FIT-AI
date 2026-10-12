import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final week = DateTime.tryParse(_run['weekStart'] as String? ?? '') ??
        widget.weekStart;
    final lastDay = week.add(const Duration(days: 6));
    final headline = _complete
        ? 'Your week is ready'
        : _failed
            ? 'Planning paused'
            : 'Building your week';

    return FitnessTheme(
        child: Scaffold(
      backgroundColor: const Color(0xFF0B1110),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const FitnessText('Weekly plan', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FitnessText('MADE FOR YOU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: planGlow,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  FitnessText(headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: -.8,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 9),
                  Text(
                      '${DateFormat.MMMd().format(week)} – ${DateFormat.MMMd().format(lastDay)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: FitnessTheme.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: PlanParticleOrb(
                        percent: _percent,
                        animating: _foreground &&
                            !_failed &&
                            !_complete &&
                            !_unavailable),
                  )),
                  const SizedBox(height: 8),
                  Semantics(
                      liveRegion: true,
                      child: FitnessText(
                        _complete
                            ? 'Workouts and food, ready to review'
                            : _failed
                                ? 'We couldn’t finish this plan. Try again.'
                                : _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      )),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .035),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .075)),
                    ),
                    child: Column(children: [
                      _step('Review history', 'history'),
                      _step('Build workouts', 'workouts'),
                      _step('Plan food', 'nutrition'),
                      _step('Check and save', 'saved'),
                    ]),
                  ),
                  if (_connectionError != null) ...[
                    const SizedBox(height: 16),
                    Text(_connectionError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 12,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                  if (_complete)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_run),
                      style: _buttonStyle,
                      child: const FitnessText('View weekly plan'),
                    )
                  else if (_failed && _run['canRetry'] != false)
                    FilledButton(
                      onPressed: _retrying ? null : _retry,
                      style: _buttonStyle,
                      child: FitnessText(
                          _retrying ? 'Retrying…' : 'Retry planning'),
                    ),
                  if (!_complete)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_run),
                      child: FitnessText(
                          _failed || _unavailable
                              ? 'Back to planner'
                              : 'Continue in background',
                          style: const TextStyle(color: FitnessTheme.silver)),
                    ),
                  if (!_complete && !_failed && !_unavailable)
                    const FitnessText(
                        'You can leave. Your plan will be saved when it’s ready.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 11,
                            height: 1.5)),
                ]),
          )),
    ));
  }

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
        backgroundColor: FitnessTheme.silver,
        foregroundColor: FitnessTheme.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      );

  Widget _step(String title, String key) {
    final done = _complete || _steps.contains(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: done ? planGlow : FitnessTheme.muted, size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: FitnessText(title,
                style: TextStyle(
                    fontSize: 13,
                    color: done ? FitnessTheme.silver : FitnessTheme.muted))),
      ]),
    );
  }
}
