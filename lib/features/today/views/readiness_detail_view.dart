import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../models/home_models.dart';
import '../components/readiness_score_ring.dart';
import '../components/readiness_signals.dart';

class ReadinessDetailView extends StatelessWidget {
  final HomeReadiness readiness;
  final Map<String, dynamic>? sleepLog;
  final VoidCallback? onEdit;
  const ReadinessDetailView(
      {super.key, required this.readiness, this.sleepLog, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final score =
        (readiness.score <= 10 ? readiness.score * 10 : readiness.score)
            .clamp(0, 100)
            .round();
    final checkIn = readiness.source == 'check_in_estimate';
    final date = DateTime.tryParse(readiness.date ?? '');
    final color = score >= 67
        ? FitnessTheme.silver
        : score >= 34
            ? const Color(0xFFE9C76B)
            : FitnessTheme.coral;

    return FitnessTheme(
        child: Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(
          title: const FitnessText('Training readiness',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent),
      body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Center(
                  child: FitnessText(readinessBasis(readiness),
                      style: const TextStyle(
                          color: FitnessTheme.muted, fontSize: 12))),
              if (date != null) ...[
                const SizedBox(height: 7),
                Center(
                    child: Text(
                        DateFormat('EEE, d MMM',
                                Localizations.localeOf(context).toLanguageTag())
                            .format(date),
                        style: const TextStyle(
                            color: FitnessTheme.muted, fontSize: 11))),
              ],
              const SizedBox(height: 26),
              Center(
                  child: ReadinessScoreRing(
                      score: score, color: color, size: 210)),
              const SizedBox(height: 24),
              FitnessText(readinessHeadline(score),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: FitnessTheme.silver,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.6)),
              const SizedBox(height: 8),
              FitnessText(readinessMeaning(score),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: FitnessTheme.muted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 32),
              const FitnessText('What went into your score',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              ReadinessSignals(
                  readiness: readiness, sleepLog: sleepLog, checkIn: checkIn),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: FitnessTheme.surface,
                    borderRadius: BorderRadius.circular(18)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(CupertinoIcons.info_circle,
                            size: 16, color: FitnessTheme.silver),
                        const SizedBox(width: 8),
                        Expanded(
                            child: FitnessText(
                                checkIn
                                    ? 'How this is calculated'
                                    : 'About this reading',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                      ]),
                      const SizedBox(height: 10),
                      FitnessText(
                          checkIn
                              ? 'Sleep contributes 40%. Rest, energy and soreness contribute 20% each. Very short reported sleep limits the estimate. This uses your saved sleep and check-in answers. It is a fitness estimate, not a wearable recovery measurement.'
                              : readiness.source == 'mixed_estimate'
                                  ? 'Uses your entered sleep and available heart readings from your health app. This is a fitness estimate.'
                                  : 'Uses the recorded inputs shown above. This is a fitness estimate, not a medical assessment.',
                          style: const TextStyle(
                              color: FitnessTheme.muted,
                              fontSize: 12,
                              height: 1.6)),
                      if (!checkIn && readiness.aiTarget.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        FitnessText(readiness.aiTarget,
                            style: const TextStyle(
                                color: FitnessTheme.silver,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ]),
              ),
              if (checkIn && onEdit != null) ...[
                const SizedBox(height: 24),
                LiquidChromeButton(title: 'Update check-in', onPressed: onEdit),
              ],
            ],
          )),
    ));
  }
}
