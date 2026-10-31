import 'package:flutter/material.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../models/body_progress_summary.dart';
import 'widgets/body_controls.dart';
import 'widgets/body_progress_style.dart';

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
    final readings = <BodyReading>[
      for (final key in bodyMetricSpecs.keys)
        if (summary.measuredTrend(key).lastOrNull ?? summary.latestEntered(key)
            case final reading?)
          reading,
    ];
    return FitnessTheme(
        child: Scaffold(
      appBar: AppBar(
          title: const FitnessText('All measurements',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                  if (overview.profile?['height'] case final num height) ...[
                    BodyProgressCard(
                        child: Row(children: [
                      const Expanded(
                          child: FitnessText('Height',
                              style: TextStyle(fontSize: 14))),
                      Text('${height.toStringAsFixed(0)} cm',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w500)),
                    ])),
                    const SizedBox(height: 12),
                  ],
                  if (readings.isEmpty)
                    const BodyProgressCard(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: FitnessText('No measurements yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 15, color: FitnessTheme.muted)))),
                  for (final reading in readings)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: reading.assessment == null
                                  ? null
                                  : () => onRecord(reading.assessment!),
                              child: BodyProgressCard(
                                  child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      FitnessText(
                                          bodyMetricSpecs[reading.key]!.label,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      Text(bodyDate(reading.date),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: FitnessTheme.muted)),
                                    ])),
                                const SizedBox(width: 12),
                                Flexible(
                                    child: Text(
                                        reading.metric.display(
                                            bodyMetricSpecs[reading.key]!.unit),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500))),
                              ])),
                            ))),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: LiquidChromeButton(
                    title: 'Update measurements',
                    solid: true,
                    showArrow: false,
                    onPressed: onAdd)),
          ])),
    ));
  }
}
