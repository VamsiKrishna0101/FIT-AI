import '../../../core/navigation/onboarding_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';
import 'weekly_plan_view.dart';

class WeeklyPlanCard extends StatefulWidget {
  final bool isActive;
  final WeeklyPlanRepository? repository;
  final Future<void> Function()? onReturn;

  const WeeklyPlanCard({
    super.key,
    this.isActive = true,
    this.repository,
    this.onReturn,
  });

  @override
  State<WeeklyPlanCard> createState() => _WeeklyPlanCardState();
}

class _WeeklyPlanCardState extends State<WeeklyPlanCard>
    with WidgetsBindingObserver {
  late final _repository = widget.repository ?? WeeklyPlanRepository();
  Map<String, dynamic>? _availability;
  bool _loading = true;
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
        : _availability?['canGenerate'] == true
            ? 'Generate weekly plan'
            : hasPlan
                ? 'View weekly plan'
                : 'Open weekly planner';

    String description =
        'Based on your recent workouts and saved measurements.';

    if (pending) {
      description = 'Your next plan is being prepared.';
    } else if (_availability?['cooldownActive'] == true && nextDate != null) {
      description =
          'Next plan available ${DateFormat.yMMMd().add_jm().format(nextDate)}';
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
                  onPressed: _loading ? null : _openPlan,
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
                  child: _loading
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
