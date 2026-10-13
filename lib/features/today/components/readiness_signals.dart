import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../models/home_models.dart';

String readinessHeadline(int score) => score >= 67
    ? 'Ready for your day'
    : score >= 34
        ? 'Keep it balanced'
        : 'Take it easier';

String readinessMeaning(int score) => score >= 67
    ? 'Your recorded inputs look positive today.'
    : score >= 34
        ? 'A steady day may suit how you feel.'
        : 'Your recorded inputs suggest a lighter day.';

String readinessBasis(HomeReadiness readiness) {
  if (readiness.source == 'check_in_estimate') return 'Based on your check-in';
  if (readiness.source == 'mixed_estimate') {
    return 'Entered sleep + synced heart';
  }
  if (readiness.source == 'manual') return 'Based on your entries';
  return readiness.source == 'health_connect'
      ? 'Health Connect'
      : 'Apple Health';
}

class ReadinessSignals extends StatelessWidget {
  final HomeReadiness? readiness;
  final Map<String, dynamic>? sleepLog;
  final bool checkIn;
  const ReadinessSignals(
      {super.key, this.readiness, this.sleepLog, this.checkIn = false});

  String _rating(String field, List<String> labels) {
    final rating = sleepLog?[field] as num?;
    if (rating == null) return 'Add answer';
    return labels[rating <= 2
        ? 0
        : rating <= 4
            ? 1
            : 2];
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (readiness?.sleepMinutes ?? 0) > 0
        ? readiness!.sleepMinutes
        : (sleepLog?['sleepMinutes'] as num?)?.toInt() ?? 0;
    final hasSleep = minutes > 0 || sleepLog?['sleepMinutes'] != null;
    final signals = <({IconData icon, String label, String value})>[
      (
        icon: CupertinoIcons.moon,
        label: 'Sleep',
        value: hasSleep ? '${minutes ~/ 60}h ${minutes % 60}m' : 'Not recorded'
      ),
      if (checkIn) ...[
        (
          icon: CupertinoIcons.bolt,
          label: 'Energy',
          value: _rating('energy', ['Low', 'Okay', 'Energized'])
        ),
        (
          icon: CupertinoIcons.sun_max,
          label: 'Rest',
          value: _rating(
              'rested', ['Not rested', 'Somewhat rested', 'Well rested'])
        ),
        (
          icon: CupertinoIcons.person,
          label: 'Soreness',
          value: _rating('soreness', ['Little', 'Some', 'Very sore'])
        ),
      ] else ...[
        if ((readiness?.hrvMs ?? 0) > 0)
          (
            icon: CupertinoIcons.waveform_path,
            label: 'HRV',
            value: '${readiness!.hrvMs} ms'
          ),
        if ((readiness?.restingHrBpm ?? 0) > 0)
          (
            icon: CupertinoIcons.heart,
            label: 'Resting HR',
            value: '${readiness!.restingHrBpm} bpm'
          ),
        if ((readiness?.sleepEfficiency ?? 0) > 0)
          (
            icon: CupertinoIcons.moon_zzz,
            label: 'Sleep efficiency',
            value: '${readiness!.sleepEfficiency}%'
          ),
      ],
    ];

    return LayoutBuilder(
        builder: (context, bounds) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final signal in signals)
                  Container(
                    width: MediaQuery.textScalerOf(context).scale(14) > 22
                        ? bounds.maxWidth
                        : (bounds.maxWidth - 10) / 2,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .035),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(signal.icon,
                                size: 14, color: FitnessTheme.muted),
                            const SizedBox(width: 6),
                            Expanded(
                                child: FitnessText(signal.label,
                                    style: const TextStyle(
                                        color: FitnessTheme.muted,
                                        fontSize: 11))),
                          ]),
                          const SizedBox(height: 7),
                          FitnessText(signal.value,
                              style: const TextStyle(
                                  color: FitnessTheme.silver,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
              ],
            ));
  }
}
