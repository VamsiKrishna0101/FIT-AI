import '../../../core/navigation/onboarding_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';
import 'weekly_plan_view.dart';
import 'weekly_plan_generation_view.dart';

class WeeklyPlanCard extends StatefulWidget {
  final bool isActive;
  final WeeklyPlanRepository? repository;
  final Future<void> Function()? onReturn;
  final bool compact;

  const WeeklyPlanCard({
    super.key,
    this.isActive = true,
    this.repository,
    this.onReturn,
    this.compact = false,
  });

  @override
  State<WeeklyPlanCard> createState() => _WeeklyPlanCardState();
}

class _WeeklyPlanCardState extends State<WeeklyPlanCard>
    with WidgetsBindingObserver {
  late final _repository = widget.repository ?? WeeklyPlanRepository();
  Map<String, dynamic>? _availability;
  bool _loading = true;
  bool _opening = false;
  int _request = 0;
  String? _owner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(WeeklyPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final owner = await CacheScope.userId();

    if (!mounted || request != _request) return;

    setState(() {
      if (_owner != owner) _availability = null;
      _owner = owner;
      _loading = true;
    });

    Map<String, dynamic>? availability;

    try {
      availability = await _repository.availability();
    } catch (_) {
      // The planner screen can show the error and let the user retry.
    }

    final currentOwner = await CacheScope.userId();

    if (!mounted || request != _request || currentOwner != owner) return;

    setState(() {
      _availability = availability;
      _loading = false;
    });
  }

  Future<void> _openPlan() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await _openPlanRoute();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openPlanRoute() async {
    final pending = _availability?['pendingRun'];
    if (pending is Map) {
      final run = Map<String, dynamic>.from(pending);
      final progressRoute = AppPageRoute<Map<String, dynamic>>(
          page: WeeklyPlanGenerationView(
              repository: _repository,
              initialRun: run,
              weekStart:
                  DateTime.tryParse('${run['weekStart']}') ?? DateTime.now()));
      final result = await Navigator.of(context).push(progressRoute);
      await progressRoute.completed;
      if (!mounted) return;
      if (result?['status'] == 'COMPLETED' && result?['plan'] is Map) {
        final planRoute = AppPageRoute<void>(
            page: WeeklyPlanView(
                repository: _repository,
                initialPlanId: (result!['plan'] as Map)['id'] as String?));
        await Navigator.of(context).push(planRoute);
        await planRoute.completed;
      }
      if (mounted) await _load();
      if (mounted) await widget.onReturn?.call();
      return;
    }
    final route = AppPageRoute<void>(
      page: WeeklyPlanView(repository: _repository),
    );
    await Navigator.of(context).push(route);
    await route.completed;

    if (!mounted) return;
    await _load();
    if (mounted) await widget.onReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = _availability?['lastPlanId'] != null;
    final pending = _availability?['pendingRun'] is Map;
    final nextDate = DateTime.tryParse(
      _availability?['nextGenerationAt'] as String? ?? '',
    )?.toLocal();

    final label = pending
        ? 'View plan progress'
        : hasPlan
            ? 'View weekly plan'
            : _availability?['canGenerate'] == true
                ? 'Generate weekly plan'
                : 'Open weekly planner';

    String description =
        'Based on your recent workouts and saved measurements.';

    if (pending) {
      description = 'Your next plan is being prepared.';
    } else if (_availability?['cooldownActive'] == true && nextDate != null) {
      description =
          'Next plan available ${DateFormat.yMMMd().add_jm().format(nextDate)}';
    }

    if (widget.compact) {
      return TickerMode(
        enabled: widget.isActive,
        child: Material(
          color: FitnessTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: FitnessTheme.line, width: .7)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _loading || _opening ? null : _openPlan,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const FitnessText('Weekly plan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 5),
                      FitnessText(
                          pending || _availability?['cooldownActive'] == true
                              ? description
                              : label,
                          style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: FitnessTheme.muted)),
                    ])),
                const SizedBox(width: 12),
                if (_loading || _opening)
                  const CupertinoActivityIndicator(radius: 8)
                else
                  const Icon(CupertinoIcons.chevron_right,
                      size: 12, color: FitnessTheme.muted),
              ]),
            ),
          ),
        ),
      );
    }
    return TickerMode(
        enabled: widget.isActive,
        child: FitnessCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FitnessText('Your weekly plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FitnessText(description,
                  style: const TextStyle(
                      fontSize: 12, color: FitnessTheme.muted, height: 1.4)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading || _opening ? null : _openPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: FitnessTheme.silver,
                    foregroundColor: FitnessTheme.canvas,
                    disabledBackgroundColor: const Color(0xFF363636),
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading || _opening
                      ? const CupertinoActivityIndicator(color: Colors.white70)
                      : FitnessText(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ));
  }
}
