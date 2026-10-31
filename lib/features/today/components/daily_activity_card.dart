import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../models/home_models.dart';
import '../../health/views/health_connection_view.dart';
import '../repositories/today_repository.dart';

HomeHealthMetrics? activityForDate(HomeHealthMetrics? metrics, DateTime date) {
  if (metrics == null ||
      metrics.date != DateFormat('yyyy-MM-dd').format(date) ||
      RegExp('sample|preview|demo', caseSensitive: false)
          .hasMatch(metrics.source)) {
    return null;
  }
  return metrics;
}

class DailyActivityCard extends StatefulWidget {
  final HomeHealthMetrics? metrics;
  final DateTime date;
  final DateTime? now;
  final bool compact, embedded;
  final Future<HomeHealthMetrics?> Function()? onManageHealth;
  const DailyActivityCard(
      {super.key,
      this.metrics,
      required this.date,
      this.now,
      this.onManageHealth,
      this.compact = false,
      this.embedded = false});
  @override
  State<DailyActivityCard> createState() => _DailyActivityCardState();
}

class _DailyActivityCardState extends State<DailyActivityCard> {
  bool _busy = false, _failed = false, _refreshed = false;
  int _request = 0;
  HomeHealthMetrics? _freshMetrics;
  @override
  void didUpdateWidget(covariant DailyActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.date, widget.date) ||
        oldWidget.metrics != widget.metrics) {
      _request++;
      _busy = false;
      _failed = false;
      _refreshed = false;
      _freshMetrics = null;
    }
  }

  Future<HomeHealthMetrics?> _manageHealth(DateTime date) async {
    final owner = await CacheScope.userId();
    if (!mounted || owner == 'anonymous') {
      throw StateError('Sign in to sync steps.');
    }
    await Navigator.of(context)
        .push(AppPageRoute<void>(page: const HealthConnectionView()));
    if (!mounted || await CacheScope.userId() != owner) {
      throw StateError('Account changed');
    }
    final data =
        await TodayRepository.shared.loadDate(date, forceRefresh: true);
    if (await CacheScope.userId() != owner) throw StateError('Account changed');
    if (data == null || TodayRepository.shared.refreshFailedFor(date)) {
      throw StateError('Could not refresh steps.');
    }
    return data.healthMetrics;
  }

  Future<void> _open() async {
    if (_busy) return;
    final request = ++_request;
    final date = widget.date;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final metrics =
          await (widget.onManageHealth?.call() ?? _manageHealth(date));
      if (!mounted || request != _request) return;
      setState(() {
        _freshMetrics = metrics;
        _refreshed = true;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Widget _metric(IconData icon, String label, String value) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: DSColors.muted, size: 16),
              const SizedBox(width: 7),
              Expanded(
                  child: FitnessText(label,
                      style: const TextStyle(
                          color: DSColors.muted, fontSize: 12, height: 1.4)))
            ]),
            const SizedBox(height: 8),
            Text(value,
                key: ValueKey('activity-$label-value'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    letterSpacing: -.4)),
          ]);
  Widget _missingSteps(bool hasOtherReadings) {
    final currentDay =
        DateUtils.isSameDay(widget.date, widget.now ?? DateTime.now());
    final supported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final canManage =
        currentDay && (supported || widget.onManageHealth != null);
    final message = _failed
        ? 'Could not refresh steps. Open health settings to try again.'
        : !currentDay
            ? 'No steps recorded for this day.'
            : !supported && widget.onManageHealth == null
                ? 'Connect your health app on your phone to see steps.'
                : hasOtherReadings
                    ? 'No steps shared yet. Review step access.'
                    : 'Connect your health app to import steps.';
    final action = TextButton(
        key: const ValueKey('activity-setup-steps'),
        onPressed: _busy ? null : _open,
        style: TextButton.styleFrom(
            foregroundColor: DSColors.silver,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: DSColors.silver, strokeWidth: 1.5))
            : FitnessText(
                hasOtherReadings || _failed
                    ? 'Health settings'
                    : 'Set up steps',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)));
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    if (widget.compact) {
      return Wrap(
          key: const ValueKey('activity-steps-setup'),
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.directions_walk_rounded,
                  color: DSColors.muted, size: 16),
              SizedBox(width: 7),
              FitnessText('Steps',
                  style: TextStyle(color: DSColors.muted, fontSize: 12)),
            ]),
            if (canManage)
              action
            else
              FitnessText(currentDay ? 'On your phone' : 'Not recorded',
                  style: const TextStyle(color: DSColors.muted, fontSize: 12)),
            if (_failed)
              FitnessText(message,
                  key: const ValueKey('activity-steps-message'),
                  style: const TextStyle(
                      color: DSColors.muted, fontSize: 12, height: 1.4)),
          ]);
    }
    return Column(
        mainAxisSize: MainAxisSize.min,
        key: const ValueKey('activity-steps-setup'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.directions_walk_rounded,
                color: DSColors.muted, size: 17),
            const SizedBox(width: 7),
            const Expanded(
                child: FitnessText('Steps',
                    style: TextStyle(
                        color: DSColors.silver, fontSize: 13, height: 1.4))),
            if (canManage && !large) action,
          ]),
          const SizedBox(height: 6),
          FitnessText(message,
              key: const ValueKey('activity-steps-message'),
              style: const TextStyle(
                  color: DSColors.muted, fontSize: 12, height: 1.5)),
          if (canManage && large) ...[const SizedBox(height: 8), action],
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final data = activityForDate(
        _refreshed ? _freshMetrics : widget.metrics, widget.date);
    final steps = data?.steps;
    final calories = data?.activeCalories;
    final hasSteps = steps != null && steps >= 0;
    final hasCalories = calories != null && calories.isFinite && calories >= 0;
    final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag());
    final tiles = [
      if (hasSteps)
        _metric(Icons.directions_walk_rounded, 'Steps', format.format(steps)),
      if (hasCalories)
        _metric(CupertinoIcons.flame, 'Active energy',
            '${format.format(calories.round())} kcal'),
    ];
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final Widget content;
    if (widget.compact && hasSteps) {
      content = Row(children: [
        const Icon(Icons.directions_walk_rounded,
            color: DSColors.muted, size: 16),
        const SizedBox(width: 7),
        const Expanded(
            child: FitnessText('Steps',
                style: TextStyle(color: DSColors.muted, fontSize: 12))),
        Expanded(
            child: Text(format.format(steps),
                key: const ValueKey('activity-Steps-value'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: DSColors.silver,
                    fontSize: 17,
                    fontWeight: FontWeight.w500))),
      ]);
    } else if (widget.compact) {
      content = _missingSteps(data != null);
    } else {
      content = !hasSteps
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  _missingSteps(data != null),
                  if (hasCalories) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: DSColors.border),
                    const SizedBox(height: 16),
                    tiles.single,
                  ],
                ])
          : largeText
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        tiles[i],
                      ],
                    ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 20),
                    Expanded(child: tiles[i]),
                  ],
                ]);
    }
    if (widget.embedded) {
      return KeyedSubtree(
          key: const ValueKey('daily-activity-card'), child: content);
    }
    return Container(
        key: const ValueKey('daily-activity-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: DSColors.bgCard,
            border: Border.all(color: DSColors.border, width: .7),
            borderRadius: BorderRadius.circular(18)),
        child: content);
  }
}
