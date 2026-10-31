import 'package:flutter/cupertino.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../models/home_models.dart';

int? readinessScore(HomeReadiness? reading) =>
    reading == null || !reading.score.isFinite
        ? null
        : (reading.score <= 10 ? reading.score * 10 : reading.score)
            .clamp(0, 100)
            .round();
int? readinessSleepMinutes(
    HomeReadiness? reading, Map<String, dynamic>? sleepLog) {
  final minutes = sleepLog?['sleepMinutes'];
  if (minutes is num && minutes.isFinite && minutes >= 0 && minutes <= 1440) {
    return minutes.round();
  }
  if (reading != null &&
      (reading.sleepMinutes > 0 || reading.source == 'check_in_estimate')) {
    return reading.sleepMinutes;
  }
  return null;
}

String readinessHeadline(int score) => score >= 67
    ? 'Ready today'
    : score >= 34
        ? 'Keep it balanced'
        : 'Take it easier';
String readinessMeaning(int score) => score >= 67
    ? 'Use your warm-up to check how you feel.'
    : score >= 34
        ? 'Keep your effort comfortable today.'
        : 'Give yourself more recovery today.';
String readinessBasis(HomeReadiness readiness) {
  if (readiness.source == 'check_in_estimate') return 'Check-in estimate';
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
  final bool compact, embedded;
  const ReadinessSignals(
      {super.key,
      this.readiness,
      this.sleepLog,
      this.checkIn = false,
      this.compact = false,
      this.embedded = false});
  String _rating(String field, List<String> labels) {
    final rating = sleepLog?[field];
    if (rating is! num || !rating.isFinite || rating < 1 || rating > 5) {
      return 'Not added';
    }
    return labels[rating <= 2
        ? 0
        : rating <= 4
            ? 1
            : 2];
  }

  @override
  Widget build(BuildContext context) {
    final minutes = readinessSleepMinutes(readiness, sleepLog);
    final signals = <({IconData icon, String label, String value})>[
      (
        icon: CupertinoIcons.moon,
        label: 'Sleep',
        value:
            minutes == null ? 'Not added' : '${minutes ~/ 60}h ${minutes % 60}m'
      ),
      if (checkIn) ...[
        (
          icon: CupertinoIcons.bolt,
          label: 'Energy',
          value: _rating('energy', ['Low', 'Okay', 'Energized'])
        ),
        (
          icon: CupertinoIcons.sun_max,
          label: 'Rested',
          value: _rating(
              'rested', ['Not rested', 'Somewhat rested', 'Well rested'])
        ),
        (
          icon: CupertinoIcons.person,
          label: 'Muscle soreness',
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
      ],
    ];
    return LayoutBuilder(builder: (context, bounds) {
      final singleColumn = bounds.maxWidth < 250 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      Widget tile(int index) {
        final signal = signals[index];
        return Container(
            key: ValueKey('readiness-signal-${signal.label}'),
            constraints: BoxConstraints(minHeight: compact ? 52 : 68),
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: BoxDecoration(
                color: DSColors.bgRaised,
                border: Border.all(color: DSColors.border, width: .6),
                borderRadius: BorderRadius.circular(13)),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(signal.icon,
                        color: DSColors.muted, size: compact ? 13 : 15),
                    const SizedBox(width: 6),
                    Expanded(
                        child: FitnessText(signal.label,
                            style: TextStyle(
                                color: DSColors.muted,
                                fontSize: compact ? 10.5 : 11,
                                height: 1.3)))
                  ]),
                  SizedBox(height: compact ? 4 : 6),
                  FitnessText(signal.value,
                      style: TextStyle(
                          color: DSColors.silver,
                          fontSize: compact ? 14 : 15,
                          height: 1.3,
                          fontWeight: FontWeight.w500)),
                ]));
      }

      final grid = Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < signals.length; i += singleColumn ? 1 : 2) ...[
          if (i > 0) const SizedBox(height: 8),
          if (singleColumn)
            SizedBox(width: double.infinity, child: tile(i))
          else
            IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(child: tile(i)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: i + 1 < signals.length
                          ? tile(i + 1)
                          : const SizedBox.shrink()),
                ])),
        ],
      ]);
      return embedded
          ? grid
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: DSColors.bgCard,
                  border: Border.all(color: DSColors.border, width: .7),
                  borderRadius: BorderRadius.circular(18)),
              child: grid);
    });
  }
}
