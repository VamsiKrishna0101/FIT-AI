import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../models/body_progress_summary.dart';
import 'widgets/body_controls.dart';
import 'widgets/body_progress_style.dart';
import 'widgets/body_progress_cards.dart';

class BodyMeasurementsView extends StatelessWidget {
  final BodyOverview overview;
  final VoidCallback onAdd;
  final ValueChanged<BodyAssessment> onRecord;

  const BodyMeasurementsView(
      {super.key,
      required this.overview,
      required this.onAdd,
      required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final summary = BodyProgressSummary(overview);
    final composition = [summary.weight, summary.latest('bodyFatPct')]
        .whereType<BodyReading>()
        .toList();
    final groups = {
      'Upper body': ['chestCm', 'neckCm', 'leftArmCm', 'rightArmCm'],
      'Waist & hips': ['waistCm', 'hipsCm'],
      'Lower body': [
        'leftThighCm',
        'rightThighCm',
        'leftCalfCm',
        'rightCalfCm'
      ],
    };

    return FitnessTheme(
        child: Scaffold(
      appBar: AppBar(
          title:
              const FitnessText('Measurements', style: TextStyle(fontSize: 17)),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                  const FitnessText('Your latest readings',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.5)),
                  const SizedBox(height: 7),
                  const FitnessText(
                      'Measured values and photo ranges, with their sources.',
                      style: TextStyle(
                          color: FitnessTheme.muted,
                          fontSize: 12,
                          height: 1.4)),
                  if (composition.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      final tiles = composition.map(_compositionTile).toList();
                      if (constraints.maxWidth < 330 ||
                          MediaQuery.textScalerOf(context).scale(12) > 16) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final tile in tiles)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: tile)
                            ]);
                      }
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < tiles.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: 10),
                              Expanded(child: tiles[index]),
                            ],
                          ]);
                    }),
                  ],
                  const SizedBox(height: 20),
                  BodyBalanceCard(summary: summary, onAdd: onAdd),
                  for (final group in groups.entries)
                    if (group.value
                        .any((key) => summary.latest(key) != null)) ...[
                      BodySectionTitle(group.key),
                      BodyProgressCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Column(children: [
                            for (final key in group.value)
                              if (summary.latest(key) case final reading?)
                                _readingRow(reading),
                          ])),
                    ],
                  if (summary.readings.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Column(children: [
                          Icon(CupertinoIcons.resize,
                              size: 32, color: FitnessTheme.muted),
                          SizedBox(height: 16),
                          FitnessText('Start with your baseline',
                              style: TextStyle(fontSize: 18)),
                          SizedBox(height: 7),
                          FitnessText(
                              'Add a weight or tape measurement to begin.',
                              style: TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted)),
                        ])),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: LiquidChromeButton(
                    title: 'Add measurements', onPressed: onAdd)),
          ])),
    ));
  }

  Widget _compositionTile(BodyReading reading) => BodyProgressCard(
        highlighted: true,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(bodyMetricSpecs[reading.key]!.label,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          const SizedBox(height: 13),
          Text(reading.metric.display(bodyMetricSpecs[reading.key]!.unit),
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.6)),
          const SizedBox(height: 10),
          FitnessText(reading.sourceLabel,
              style: const TextStyle(fontSize: 10, color: FitnessTheme.silver)),
          const SizedBox(height: 4),
          Text(bodyDate(reading.date),
              style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
        ]),
      );

  Widget _readingRow(BodyReading reading) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: reading.assessment == null
              ? null
              : () => onRecord(reading.assessment!),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: LayoutBuilder(builder: (context, constraints) {
              final label = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitnessText(bodyMetricSpecs[reading.key]!.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    FitnessText(
                        '${reading.sourceLabel} · ${bodyDate(reading.date)}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: FitnessTheme.muted,
                            height: 1.4)),
                  ]);
              final value = Text(
                  reading.metric.display(bodyMetricSpecs[reading.key]!.unit),
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.4));
              if (MediaQuery.textScalerOf(context).scale(12) > 16) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [label, const SizedBox(height: 9), value]);
              }
              return Row(children: [
                Expanded(child: label),
                const SizedBox(width: 12),
                value,
                if (reading.assessment != null) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 11, color: FitnessTheme.muted),
                ],
              ]);
            }),
          ),
        ),
      );
}
