import '../../../../core/theme/fitness_accents.dart';
import '../../../../core/theme/ds_motion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../models/body_progress_summary.dart';
import 'anatomical_training_map.dart';
import 'body_controls.dart';

const bodyReportAreas = <String, List<String>>{
  'Chest': ['chest'],
  'Shoulders': ['shoulders'],
  'Back': ['upper_back', 'lats', 'lower_back'],
  'Arms': ['biceps', 'triceps', 'forearms'],
  'Core': ['core'],
  'Legs': ['glutes', 'quads', 'hamstrings', 'calves'],
};

// Older reports keep their full saved text, with a short preview on each card.
String bodyReportBrief(String text) {
  final trimmed = text.trim();
  final sentence =
      RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(trimmed)?.group(0)?.trim() ??
          trimmed;
  return sentence.length > 180
      ? '${sentence.substring(0, 177).trimRight()}…'
      : sentence;
}

class BodyFocusPanel extends StatefulWidget {
  final BodyAssessment? assessment;
  final List<String> chosenFocus;
  final bool female;
  final bool compact;
  final List<BodyReading> readings;
  final VoidCallback? onScan;
  final VoidCallback? onRefreshReport, onCompare, onOpenPhotos;
  const BodyFocusPanel(
      {super.key,
      this.assessment,
      this.chosenFocus = const [],
      this.female = false,
      this.compact = false,
      this.readings = const [],
      this.onScan,
      this.onRefreshReport,
      this.onCompare,
      this.onOpenPhotos});
  @override
  State<BodyFocusPanel> createState() => _BodyFocusPanelState();
}

class _BodyFocusPanelState extends State<BodyFocusPanel> {
  bool _back = false;
  String? _selected;
  List<Map<String, dynamic>> get _regions =>
      (widget.assessment?.physiqueReport?['regions'] as List? ?? [])
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
  bool get _hasPhotoReport =>
      (widget.assessment?.physiqueReport?['photosUsed'] as num? ?? 0) > 0;
  Map<String, dynamic>? _region(String id) =>
      _regions.where((r) => r['region'] == id).firstOrNull;
  Map<String, dynamic>? _guidance(String id) => widget.assessment?.bodyRegions
      .where((region) => region['region'] == id)
      .firstOrNull;
  String _guidanceLabel(String? status) => switch (status) {
        'focus' => 'Extra emphasis',
        'balanced' => 'Balanced routine',
        _ => 'Not enough context',
      };

  String _status(Map<String, dynamic>? region) =>
      switch (region?['appearanceStatus']) {
        'observed' => 'Visible outline',
        'unclear' => 'Unclear in photos',
        _ => 'No photo assessment',
      };

  void _sheet(String title, List<Widget> children) =>
      showModalBottomSheet<void>(
          sheetAnimationStyle: DSMotion.sheetStyle(context),
          context: context,
          backgroundColor: FitnessTheme.surface,
          showDragHandle: true,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (context) => ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .8),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FitnessText(title,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ...children,
                      ]))));

  void _details(String id) {
    setState(() => _selected = id);
    final region = _hasPhotoReport ? _region(id) : null;
    final guidance = _guidance(id);
    final observation = region?['visualObservation'] as String?;
    final readings = widget.readings
        .where((reading) => bodyMetricSpecs[reading.key]?.region == id)
        .toList();

    _sheet(bodyRegionNames[id] ?? id, [
      Row(children: [
        Icon(CupertinoIcons.circle_fill,
            size: 8,
            color: FitnessAccents.physique(guidance?['status'] as String?)),
        const SizedBox(width: 8),
        FitnessText(_guidanceLabel(guidance?['status'] as String?),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 10),
      FitnessText(
          guidance?['reason'] as String? ??
              'No region-specific assessment is available for this area. Include it in your balanced routine.',
          style: const TextStyle(fontSize: 13, height: 1.5)),
      const SizedBox(height: 8),
      const FitnessText('Training guidance, not a strength or symmetry score.',
          style:
              TextStyle(fontSize: 11, height: 1.4, color: FitnessTheme.muted)),
      const SizedBox(height: 18),
      if (region != null &&
          observation != null &&
          observation.trim().isNotEmpty) ...[
        Row(children: [
          const FitnessText('AI observation',
              style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          const SizedBox(width: 10),
          Text(bodyDate(widget.assessment!.recordedDate),
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ]),
        const SizedBox(height: 10),
        FitnessText(widget.compact ? bodyReportBrief(observation) : observation,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 8),
        FitnessText(_status(region),
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        for (final note in (region['limitations'] as List? ?? [])
            .whereType<String>()
            .toSet())
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FitnessText(note,
                style: const TextStyle(
                    fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
          ),
      ] else ...[
        const FitnessText('No photo assessment is available for this area.',
            style: TextStyle(
                fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
        if (widget.onScan != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onScan!();
            },
            icon: const Icon(CupertinoIcons.camera, size: 16),
            label: const FitnessText('Scan your body',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ],
      if (readings.isNotEmpty) ...[
        const SizedBox(height: 22),
        const Divider(color: FitnessTheme.line),
        const SizedBox(height: 12),
        const FitnessText('Saved measurements',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        for (final reading in readings)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 12, runSpacing: 4, children: [
                FitnessText(bodyMetricSpecs[reading.key]!.label,
                    style: const TextStyle(fontSize: 12)),
                Text(reading.metric.display(bodyMetricSpecs[reading.key]!.unit),
                    style: const TextStyle(fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              Text(
                  '${bodyDate(reading.date)} · ${fitnessText(context, reading.sourceLabel)}',
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
              if (reading.metric.isPhotoEstimate)
                const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: FitnessText('Estimated, not a tape measurement.',
                        style: TextStyle(
                            fontSize: 11, color: FitnessTheme.muted))),
            ]),
          ),
      ],
    ]);
  }

  void _scanDetails() {
    final assessment = widget.assessment!;
    _sheet('Scan details', [
      const FitnessText(
          'Photo estimates are approximate. Photos do not measure strength or body fat.',
          style:
              TextStyle(fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
      if ((assessment.processing?['aiMs'] ?? assessment.processing?['geminiMs']) is num)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FitnessText(
                '${fitnessText(context, 'Report')} · ${(((assessment.processing?['aiMs'] ?? assessment.processing?['geminiMs']) as num) / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 12))),
      for (final note in assessment.qualityNotes.toSet())
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FitnessText('• $note',
                style: const TextStyle(
                    fontSize: 12, height: 1.4, color: FitnessTheme.muted))),
    ]);
  }

  Widget _areaCard(String title, List<String> ids) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FitnessCard(
          padding: const EdgeInsets.all(14),
          child: Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey('body-report-$title'),
                  initiallyExpanded: title == 'Chest',
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 6),
                  title: FitnessText(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: FitnessText(
                      ids.map((id) => _status(_region(id))).toSet().join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted)),
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final id in ids) ...[
                            const SizedBox(height: 12),
                            InkWell(
                                onTap: () => _details(id),
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Icon(
                                              _region(id)?[
                                                          'appearanceStatus'] ==
                                                      'observed'
                                                  ? CupertinoIcons.eye
                                                  : CupertinoIcons.eye_slash,
                                              size: 14,
                                              color: _region(id)?[
                                                          'appearanceStatus'] ==
                                                      'observed'
                                                  ? FitnessAccents.muscle(id)
                                                  : FitnessTheme.muted)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            if (ids.length > 1) ...[
                                              FitnessText(
                                                  bodyRegionNames[id] ?? id,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          FitnessTheme.muted)),
                                              const SizedBox(height: 3),
                                            ],
                                            FitnessText(
                                                bodyReportBrief(_region(id)?[
                                                            'visualObservation']
                                                        as String? ??
                                                    'No photo assessment is available for this area.'),
                                                style: const TextStyle(
                                                    fontSize: 13, height: 1.4)),
                                          ])),
                                      const SizedBox(width: 8),
                                      const Icon(CupertinoIcons.chevron_right,
                                          size: 12, color: FitnessTheme.muted),
                                    ])),
                          ],
                        ]),
                  ],
                ),
              ))));

  @override
  Widget build(BuildContext context) {
    final assessment = widget.assessment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FitnessCard(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: FitnessText(
                      assessment == null
                          ? 'Your starting point'
                          : bodyDate(assessment.recordedDate),
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted))),
              SizedBox(
                  width: 128,
                  child: BodySegment(
                      labels: const ['Front', 'Back'],
                      selected: _back ? 1 : 0,
                      onChanged: (v) => setState(() => _back = v == 1))),
            ]),
            GestureDetector(
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0).abs() > 80) {
                    setState(() => _back = !_back);
                  }
                },
                child: LayoutBuilder(
                    builder: (context, constraints) => SizedBox(
                        height:
                            (constraints.maxWidth * 1.2).clamp(360.0, 420.0),
                        child: AnatomicalTrainingMap(
                            back: _back,
                            female:
                                assessment?.gender == 'FEMALE' || widget.female,
                            colors: {
                              for (final id in bodyRegionNames.keys)
                                id: FitnessAccents.physique(
                                    _guidance(id)?['status'] as String?)
                            },
                            highlighted: widget.chosenFocus.toSet(),
                            selected: _selected,
                            onSelected: _details)))),
            Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  const BodyLegend(FitnessAccents.gold, 'Extra emphasis'),
                  const BodyLegend(FitnessAccents.blue, 'Balanced routine'),
                  const BodyLegend(
                      FitnessAccents.untrained, 'Not enough context'),
                  if (widget.chosenFocus.isNotEmpty)
                    const BodyLegend(FitnessTheme.silver, 'Chosen focus'),
                ]),
            const SizedBox(height: 10),
            const FitnessText(
                'Training guidance, not a strength or symmetry score.',
                style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          ])),
      if (assessment != null && !widget.compact) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
              onPressed: widget.onCompare,
              icon: const Icon(CupertinoIcons.arrow_left_right, size: 16),
              label:
                  const FitnessText('Compare', style: TextStyle(fontSize: 12))),
          if (assessment.photos.isNotEmpty && widget.onOpenPhotos != null)
            OutlinedButton.icon(
                onPressed: widget.onOpenPhotos,
                icon: const Icon(CupertinoIcons.photo, size: 16),
                label: const FitnessText('Saved photos',
                    style: TextStyle(fontSize: 12))),
        ]),
        if (_hasPhotoReport) ...[
          const BodySectionTitle('Your photo report'),
          for (final area in bodyReportAreas.entries)
            _areaCard(area.key, area.value),
        ] else ...[
          const SizedBox(height: 12),
          const FitnessText(
              'No photo assessment yet. Start with a front photo for your physique review.',
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: FitnessTheme.muted)),
        ],
        if (assessment.photoRetention == 'not_saved' ||
            assessment.photoRetention == 'deleted')
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: FitnessText('Report saved · Photos not kept',
                  style: TextStyle(fontSize: 11, color: FitnessTheme.muted))),
        const SizedBox(height: 8),
        TextButton.icon(
            onPressed: _scanDetails,
            icon: const Icon(CupertinoIcons.info_circle, size: 15),
            label: const FitnessText('Scan details',
                style: TextStyle(fontSize: 12))),
        if (widget.onRefreshReport != null) ...[
          TextButton.icon(
              onPressed: widget.onRefreshReport,
              icon: const Icon(CupertinoIcons.arrow_clockwise, size: 15),
              label: const FitnessText('Update body report',
                  style: TextStyle(fontSize: 12))),
          FitnessText(
              assessment.visualCoachingConsent && assessment.photos.isNotEmpty
                  ? 'Uses saved photos with OpenAI.'
                  : 'Uses saved measurements with OpenAI.',
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ],
      ],
    ]);
  }
}
