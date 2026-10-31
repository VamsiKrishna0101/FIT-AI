import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../models/home_models.dart';
import '../components/daily_activity_card.dart';
import '../components/readiness_score_ring.dart';
import '../components/readiness_signals.dart';
import '../../wellness/models/check_in_state.dart';

class ReadinessDetailView extends StatelessWidget {
  final HomeReadiness? readiness;
  final HomeHealthMetrics? health;
  final Map<String, dynamic>? sleepLog;
  final DateTime? date;
  final bool readOnly;
  final VoidCallback? onEdit;
  const ReadinessDetailView(
      {super.key,
      required this.readiness,
      this.health,
      this.sleepLog,
      this.date,
      this.readOnly = false,
      this.onEdit});
  @override
  Widget build(BuildContext context) {
    final score = readinessScore(readiness);
    final day =
        date ?? DateTime.tryParse(readiness?.date ?? '') ?? DateTime.now();
    final metrics = activityForDate(health, day);
    final entries = sleepLog ??
        (metrics?.sleepMinutes == null
            ? null
            : {'sleepMinutes': metrics!.sleepMinutes});
    final checkIn =
        readiness == null || readiness!.source == 'check_in_estimate';
    final hasProgress =
        sleepLog?['sleepMinutes'] is num || hasAnyCheckInAnswer(sleepLog);
    final heading = score != null
        ? readinessHeadline(score)
        : hasProgress
            ? savedCheckInLabel(sleepLog!)
            : readOnly
                ? 'No check-in recorded'
                : 'How are you feeling?';
    return FitnessTheme(
        child: Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(
          toolbarHeight: (MediaQuery.textScalerOf(context).scale(17) * 2.4)
              .clamp(56.0, 120.0),
          title: const FitnessText('Recovery',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent),
      body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                Text(
                    DateFormat('EEEE, d MMM',
                            Localizations.localeOf(context).toLanguageTag())
                        .format(day),
                    key: const ValueKey('readiness-detail-date'),
                    style: const TextStyle(
                        color: DSColors.muted, fontSize: 12, height: 1.4)),
                const SizedBox(height: 18),
                Container(
                    key: const ValueKey('readiness-detail-hero'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: DSColors.bgCard,
                        border: Border.all(color: DSColors.border),
                        borderRadius: BorderRadius.circular(24)),
                    child: Column(children: [
                      if (score != null) ...[
                        ReadinessScoreRing(
                            score: score, color: DSColors.silver, size: 100),
                        const SizedBox(height: 14)
                      ] else ...[
                        const Icon(CupertinoIcons.sun_max,
                            size: 28, color: DSColors.silver),
                        const SizedBox(height: 18)
                      ],
                      FitnessText(heading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -.5)),
                      if (score != null) ...[
                        const SizedBox(height: 10),
                        const FitnessText('Check-in saved',
                            style: TextStyle(
                                color: DSColors.muted,
                                fontSize: 11,
                                height: 1.4)),
                      ],
                    ])),
                const SizedBox(height: 28),
                const FitnessText('Your check-in',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                    key: const ValueKey('readiness-detail-inputs'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: DSColors.bgCard,
                        border: Border.all(color: DSColors.border),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ReadinessSignals(
                          readiness: readiness,
                          sleepLog: entries,
                          checkIn: checkIn,
                          embedded: true),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: DSColors.border),
                      const SizedBox(height: 10),
                      DailyActivityCard(
                          metrics: metrics,
                          date: day,
                          compact: true,
                          embedded: true),
                    ])),
              ])),
      bottomNavigationBar: onEdit != null && checkIn && !readOnly
          ? Container(
              decoration: const BoxDecoration(
                  color: DSColors.bg,
                  border: Border(top: BorderSide(color: DSColors.border))),
              child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: LiquidChromeButton(
                      key: const ValueKey('readiness-detail-update'),
                      title: score != null || hasCheckInAnswers(sleepLog)
                          ? 'Update check-in'
                          : hasProgress
                              ? 'Finish check-in'
                              : 'Complete check-in',
                      showArrow: false,
                      solid: true,
                      onPressed: onEdit)))
          : readOnly
              ? const SafeArea(
                  top: false,
                  minimum: EdgeInsets.all(16),
                  child: FitnessText('Past week · Read-only',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: DSColors.muted, fontSize: 12, height: 1.4)))
              : const SafeArea(top: false, child: SizedBox.shrink()),
    ));
  }
}
