import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import 'widgets/body_controls.dart';
import 'widgets/body_progress_style.dart';

class BodyHistoryView extends StatelessWidget {
  final BodyOverview overview;
  final ValueChanged<BodyAssessment> onRecord;

  const BodyHistoryView(
      {super.key, required this.overview, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<BodyAssessment>>{};
    for (final entry in overview.records) {
      groups
          .putIfAbsent(entry.recordedDate.substring(0, 7), () => [])
          .add(entry);
    }

    return FitnessTheme(
        child: Scaffold(
      appBar: AppBar(
          title:
              const FitnessText('Body history', style: TextStyle(fontSize: 17)),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            const FitnessText('Your timeline',
                style: TextStyle(
                    fontSize: 24,
                    letterSpacing: -.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            FitnessText(
                '${overview.records.length} recent saved ${overview.records.length == 1 ? 'entry' : 'entries'}',
                style:
                    const TextStyle(color: FitnessTheme.muted, fontSize: 12)),
            if (overview.records.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Column(children: [
                    Icon(CupertinoIcons.clock,
                        size: 32, color: FitnessTheme.muted),
                    SizedBox(height: 15),
                    FitnessText('No saved entries yet.',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 7),
                    FitnessText('Your scans and measurements will appear here.',
                        style:
                            TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                  ])),
            for (final group in groups.entries) ...[
              BodySectionTitle(DateFormat.yMMMM(
                      Localizations.localeOf(context).toLanguageTag())
                  .format(DateTime.parse('${group.key}-01'))),
              for (final entry in group.value) ...[
                _entryCard(entry),
                const SizedBox(height: 12),
              ],
            ],
            if (overview.syncedMeasurements.isNotEmpty) ...[
              const BodySectionTitle('Synced readings'),
              for (final reading in overview.syncedMeasurements) ...[
                BodyProgressCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FitnessText(bodyDate(reading.date),
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 5),
                          FitnessText(reading.sourceLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: FitnessTheme.muted)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 14, runSpacing: 8, children: [
                            if (reading.weight != null)
                              Text('${reading.weight!.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w500)),
                            if (reading.bodyFatPct != null)
                              FitnessText(
                                  'Body fat ${reading.bodyFatPct!.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: FitnessTheme.silver)),
                          ]),
                        ])),
                const SizedBox(height: 12),
              ],
            ],
          ]),
    ));
  }

  Widget _entryCard(BodyAssessment entry) {
    final photo = entry.method == 'photo_review';
    const preferredKeys = ['weightKg', 'waistCm', 'chestCm'];
    final otherKeys =
        entry.metrics.keys.where((key) => !preferredKeys.contains(key));
    final readings = [...preferredKeys, ...otherKeys]
        .where((key) =>
            entry.metrics.containsKey(key) && bodyMetricSpecs.containsKey(key))
        .take(3)
        .map((key) => MapEntry(key, entry.metrics[key]!));
    return BodyProgressCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRecord(entry),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(13)),
                          child: Icon(
                              photo
                                  ? CupertinoIcons.camera
                                  : CupertinoIcons.resize,
                              size: 18,
                              color: FitnessTheme.silver)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            FitnessText(
                                photo
                                    ? 'Photo assessment'
                                    : 'Entered measurements',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(bodyDate(entry.recordedDate),
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted)),
                          ])),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 12, color: FitnessTheme.muted),
                    ]),
                    if (readings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final reading in readings)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                                border: Border.all(color: FitnessTheme.line),
                                borderRadius: BorderRadius.circular(10)),
                            child: FitnessText(
                                '${bodyMetricSpecs[reading.key]!.label} ${reading.value.display(bodyMetricSpecs[reading.key]!.unit)}',
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.silver)),
                          ),
                      ]),
                    ],
                    if (photo) ...[
                      const SizedBox(height: 12),
                      FitnessText(
                          entry.photos.isEmpty
                              ? 'Report saved · Photos not kept'
                              : '${entry.photos.length} private photos saved',
                          style: const TextStyle(
                              fontSize: 10, color: FitnessTheme.muted)),
                    ],
                  ]),
            ),
          ),
        ));
  }
}
