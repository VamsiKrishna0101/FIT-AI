import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../progress/components/progress_chart.dart';
import '../../../progress/models/progress_models.dart';
import '../../models/body_assessment_models.dart';
import '../../models/body_measurement_baseline.dart';
import '../../models/body_progress_summary.dart';
import 'body_progress_style.dart';

/// One compact supporting section. Trends and history open only when requested.
class BodyMeasurementDashboard extends StatefulWidget {
  final BodyOverview overview;
  final VoidCallback onUpdate, onMeasurements, onHistory;
  const BodyMeasurementDashboard(
      {super.key,
      required this.overview,
      required this.onUpdate,
      required this.onMeasurements,
      required this.onHistory});

  @override
  State<BodyMeasurementDashboard> createState() =>
      _BodyMeasurementDashboardState();
}

class _BodyMeasurementDashboardState extends State<BodyMeasurementDashboard> {
  bool _expanded = true;
  BodyOverview get overview => widget.overview;
  VoidCallback get onUpdate => widget.onUpdate;
  VoidCallback get onMeasurements => widget.onMeasurements;
  VoidCallback get onHistory => widget.onHistory;

  Future<void> _trend(BuildContext context, String key) async {
    final readings = BodyProgressSummary(overview).measuredTrend(key);
    final entered = BodyProgressSummary(overview).latestEntered(key);
    final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: FitnessTheme.surface,
        showDragHandle: true,
        isScrollControlled: true,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        builder: (context) => FitnessTheme(
                child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                            child: FitnessText(bodyMetricSpecs[key]!.label,
                                style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: fitnessText(context, 'Close'),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(CupertinoIcons.xmark, size: 16)),
                      ]),
                      const SizedBox(height: 20),
                      if (readings.isEmpty && entered != null) ...[
                        Text(entered.metric.display(bodyMetricSpecs[key]!.unit),
                            style: const TextStyle(
                                fontSize: 27, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        FitnessText(entered.sourceLabel,
                            style: const TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                      ] else if (readings.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: FitnessText('No measurements yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14, color: FitnessTheme.muted)))
                      else
                        ProgressChart(
                            key: ValueKey('body-chart-$key'),
                            points: [
                              for (final r in readings)
                                ProgressPoint(
                                    DateTime.parse(r.date), r.metric.value)
                            ],
                            unit: bodyMetricSpecs[key]!.unit,
                            color: FitnessTheme.blue,
                            height: 145 *
                                (MediaQuery.textScalerOf(context).scale(12) /
                                        12)
                                    .clamp(1, 2.5)),
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: () => Navigator.pop(context, 'update'),
                          child: const FitnessText('Update measurements')),
                      Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, 'all'),
                                child: const FitnessText('All measurements',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'history'),
                                child: const FitnessText('Measurement history',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))),
                          ]),
                    ]),
              ),
            )));
    if (!context.mounted) return;
    if (action == 'update') onUpdate();
    if (action == 'all') onMeasurements();
    if (action == 'history') onHistory();
  }

  @override
  Widget build(BuildContext context) {
    final summary = BodyProgressSummary(overview);
    final complete = BodyMeasurementBaseline(overview).isComplete;
    return BodyProgressCard(
      key: const ValueKey('body-measurements-card'),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Semantics(
                  button: true,
                  expanded: _expanded,
                  child: InkWell(
                      key: const ValueKey('body-measurements-toggle'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            const Expanded(
                                child: FitnessText('Measurements',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -.3))),
                            Icon(
                                _expanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.chevron_down,
                                size: 12,
                                color: FitnessTheme.muted),
                          ]))))),
          const SizedBox(width: 8),
          TextButton(
              key: const ValueKey('body-update-measurements'),
              onPressed: onUpdate,
              child: FitnessText(complete ? 'Update' : 'Add',
                  style: const TextStyle(
                      fontSize: 12, color: FitnessTheme.silver))),
        ]),
        AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const SizedBox(height: 8),
                        LayoutBuilder(builder: (context, box) {
                          final weight = _reading(context, 'weightKg', summary),
                              waist = _reading(context, 'waistCm', summary);
                          if (box.maxWidth < 260 ||
                              MediaQuery.textScalerOf(context).scale(12) > 18) {
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  weight,
                                  const SizedBox(height: 12),
                                  waist
                                ]);
                          }
                          return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: weight),
                                const SizedBox(width: 20),
                                Expanded(child: waist)
                              ]);
                        }),
                        const SizedBox(height: 12),
                        if (overview.profile?['height'] case final num height)
                          _line(context, 'Height',
                              '${height.toStringAsFixed(0)} cm'),
                        for (final key in bodyMetricSpecs.keys.where(
                            (key) => !['weightKg', 'waistCm'].contains(key)))
                          Builder(builder: (context) {
                            final reading =
                                summary.measuredTrend(key).lastOrNull ??
                                    summary.latestEntered(key);
                            return _line(
                                context,
                                bodyMetricSpecs[key]!.label,
                                reading?.metric
                                        .display(bodyMetricSpecs[key]!.unit) ??
                                    '—',
                                onTap: () => _trend(context, key));
                          }),
                        if (!complete)
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: FitnessText(
                                  'Add your measurements before creating your plan.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: FitnessTheme.muted,
                                      height: 1.4))),
                        Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                                key: const ValueKey('body-measurement-history'),
                                onPressed: onHistory,
                                child: const FitnessText('Measurement history',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.silver)))),
                      ])
                : const SizedBox.shrink()),
      ]),
    );
  }

  Widget _line(BuildContext context, String label, String value,
          {VoidCallback? onTap}) =>
      Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onTap,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: const BoxDecoration(
                      border: Border(
                          top:
                              BorderSide(color: Color(0x16FFFFFF), width: .5))),
                  child: Row(children: [
                    Expanded(
                        child: FitnessText(label,
                            style: const TextStyle(
                                fontSize: 12, color: FitnessTheme.muted))),
                    const SizedBox(width: 16),
                    Flexible(
                        child: Text(value,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)))
                  ]))));

  Widget _reading(
      BuildContext context, String key, BodyProgressSummary summary) {
    final readings = summary.measuredTrend(key);
    final latest = readings.lastOrNull ?? summary.latestEntered(key);
    final spec = bodyMetricSpecs[key]!;
    final number =
        NumberFormat('0.#', Localizations.localeOf(context).toLanguageTag());
    return Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('body-measurement-$key'),
          onTap: () => _trend(context, key),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitnessText(spec.label,
                        style: const TextStyle(
                            fontSize: 12, color: FitnessTheme.muted)),
                    const SizedBox(height: 7),
                    Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: latest == null
                                  ? '—'
                                  : number.format(latest.metric.value)),
                          TextSpan(
                              text: ' ${spec.unit}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: FitnessTheme.muted,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0)),
                        ]),
                        style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.7)),
                  ])),
        ));
  }
}
