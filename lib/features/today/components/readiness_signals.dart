import 'package:flutter/cupertino.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';
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
  final bool compact;
  const ReadinessSignals(
      {super.key,
      this.readiness,
      this.sleepLog,
      this.checkIn = false,
      this.compact = false});

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
    final hasVitals =
        (readiness?.hrvMs ?? 0) > 0 || (readiness?.restingHrBpm ?? 0) > 0;
    final signals = <({IconData icon, String label, String value})>[
      if (!compact || checkIn || !hasVitals)
        (
          icon: CupertinoIcons.moon,
          label: 'Sleep',
          value:
              hasSleep ? '${minutes ~/ 60}h ${minutes % 60}m' : 'Not recorded'
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
        if (!compact && (readiness?.sleepEfficiency ?? 0) > 0)
          (
            icon: CupertinoIcons.moon_zzz,
            label: 'Sleep efficiency',
            value: '${readiness!.sleepEfficiency}%'
          ),
      ],
    ];

    return LayoutBuilder(builder: (context, bounds) {
      final columns = MediaQuery.textScalerOf(context).scale(14) > 22 ? 1 : 2;
      return Column(children: [
        for (var index = 0; index < signals.length; index += columns)
          Padding(
            padding: EdgeInsets.only(
                bottom: index + columns < signals.length ? 10 : 0),
            child: columns == 1
                ? _tile(signals[index].icon, signals[index].label,
                    signals[index].value)
                : IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _tile(signals[index].icon,
                                  signals[index].label, signals[index].value)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: index + 1 < signals.length
                                  ? _tile(
                                      signals[index + 1].icon,
                                      signals[index + 1].label,
                                      signals[index + 1].value)
                                  : const SizedBox.shrink()),
                        ]),
                  ),
          ),
      ]);
    });
  }

  Widget _tile(IconData icon, String label, String value) => compact
      ? SizedBox(
          key: ValueKey('readiness-signal-$label'),
          width: double.infinity,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(label,
                style:
                    const TextStyle(color: FitnessTheme.muted, fontSize: 11)),
            const SizedBox(height: 6),
            FitnessText(value,
                style: const TextStyle(
                    color: FitnessTheme.silver,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.2)),
          ]),
        )
      : Container(
          key: ValueKey('readiness-signal-$label'),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: DSColors.bgRaised,
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 14, color: FitnessTheme.muted),
              const SizedBox(width: 6),
              Expanded(
                  child: FitnessText(label,
                      style: const TextStyle(
                          color: FitnessTheme.muted, fontSize: 11))),
            ]),
            const SizedBox(height: 7),
            FitnessText(value,
                style: const TextStyle(
                    color: FitnessTheme.silver,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        );
}
