import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../models/home_models.dart';
import '../../wellness/models/check_in_state.dart';
import 'daily_activity_card.dart';
import 'readiness_score_ring.dart';
import 'readiness_signals.dart';

class ReadinessSummary extends StatelessWidget {
  final HomeReadiness? readiness;
  final HomeHealthMetrics? health;
  final Map<String, dynamic>? sleepLog;
  final DateTime date;
  final DateTime? now;
  final bool readOnly;
  const ReadinessSummary(
      {super.key,
      this.readiness,
      this.health,
      this.sleepLog,
      required this.date,
      this.now,
      this.readOnly = false});
  @override
  Widget build(BuildContext context) {
    final score = readinessScore(readiness);
    final metrics = activityForDate(health, date);
    final entries = sleepLog ??
        (metrics?.sleepMinutes == null
            ? null
            : {'sleepMinutes': metrics!.sleepMinutes});
    final savedSleep = sleepLog?['sleepMinutes'] is num;
    final hasProgress = savedSleep || hasAnyCheckInAnswer(sleepLog);
    final heading = score != null
        ? readinessHeadline(score)
        : hasProgress
            ? hasCheckInAnswers(sleepLog)
                ? 'Progress saved'
                : savedCheckInLabel(sleepLog!)
            : readOnly
                ? 'No check-in recorded'
                : 'How are you feeling?';
    final information = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitnessText(heading,
              key: const ValueKey('today-readiness-heading'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.4)),
        ]);
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final ring = score == null
        ? null
        : ReadinessScoreRing(
            key: const ValueKey('today-readiness-ring'),
            score: score,
            color: DSColors.silver,
            size: 56,
            minimal: true);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ring == null)
            information
          else if (large)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: information),
              const SizedBox(width: 10),
              ring,
            ])
          else
            Row(children: [
              Expanded(child: information),
              const SizedBox(width: 12),
              ring
            ]),
          const SizedBox(height: 10),
          ReadinessSignals(
              readiness: readiness,
              sleepLog: entries,
              checkIn: true,
              compact: true,
              embedded: true),
          const SizedBox(height: 10),
          const Divider(height: 1, color: DSColors.border),
          const SizedBox(height: 4),
          DailyActivityCard(
              metrics: metrics,
              date: date,
              now: now,
              compact: true,
              embedded: true),
        ]);
  }
}
