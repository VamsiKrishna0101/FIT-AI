import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_record_view.dart';
import 'widgets/body_controls.dart';
import 'widgets/private_body_photo.dart';
import 'widgets/body_focus_panel.dart';

class BodyComparisonView extends StatefulWidget {
  final BodyAssessment current;
  final List<BodyAssessment> baselines;
  final BodyAssessmentRepository? repository;
  const BodyComparisonView(
      {super.key,
      required this.current,
      required this.baselines,
      this.repository});
  @override
  State<BodyComparisonView> createState() => _BodyComparisonViewState();
}

class _BodyComparisonViewState extends State<BodyComparisonView> {
  BodyComparison? _data;
  String? _error;
  late String _baseline;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _baseline = widget.baselines.first.id;
    _load();
  }

  Future<void> _load() async {
    final request = ++_request, owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final data = await (widget.repository ?? BodyAssessmentRepository.shared)
          .compare(widget.current.id, _baseline);
      final currentOwner = await CacheScope.userId();
      if (mounted && request == _request && currentOwner == owner) {
        setState(() => _data = data);
      }
    } catch (error) {
      final currentOwner = await CacheScope.userId();
      if (mounted && request == _request && currentOwner == owner) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
              backgroundColor: FitnessTheme.canvas,
              surfaceTintColor: Colors.transparent,
              title: const FitnessText('Compare entries',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          body: SafeArea(
              top: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: DropdownButtonFormField<String>(
                        initialValue: _baseline,
                        isExpanded: true,
                        decoration: InputDecoration(
                            labelText: fitnessText(context, 'Earlier entry')),
                        items: [
                          for (final entry in widget.baselines)
                            DropdownMenuItem(
                                value: entry.id,
                                child: FitnessText(
                                    '${bodyDate(entry.recordedDate)} · ${entry.method == 'photo_review' ? 'Photo review' : 'Measurements'}',
                                    style: const TextStyle(fontSize: 13)))
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _baseline = value);
                            _load();
                          }
                        })),
                Expanded(
                    child: _data != null
                        ? BodyComparisonPanel(data: _data!)
                        : Center(
                            child: _error == null
                                ? const CupertinoActivityIndicator()
                                : Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FitnessText(_error!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: FitnessTheme.muted)),
                                          TextButton(
                                              onPressed: _load,
                                              child: const FitnessText('Retry'))
                                        ])))),
              ]))));
}

class BodyComparisonPanel extends StatefulWidget {
  final BodyComparison data;
  const BodyComparisonPanel({super.key, required this.data});
  @override
  State<BodyComparisonPanel> createState() => _BodyComparisonPanelState();
}

class _BodyComparisonPanelState extends State<BodyComparisonPanel> {
  int _view = 0;
  String _observation(BodyAssessment record, String id) {
    final regions =
        (record.physiqueReport?['regions'] as List? ?? []).whereType<Map>();
    final region = regions.where((r) => r['region'] == id).firstOrNull;
    final text = region?['visualObservation'] as String?;
    return '${fitnessText(context, bodyRegionNames[id] ?? id)}: ${text == null ? fitnessText(context, 'No photo assessment') : bodyReportBrief(text)}';
  }

  Widget _photo(BodyAssessment record) {
    final view = ['front', 'back', 'left', 'right'][_view];
    final photo = record.photos.where((p) => p.view == view).firstOrNull;
    return Column(children: [
      FitnessText(bodyDate(record.recordedDate),
          style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
      Expanded(
          child: photo == null
              ? const FitnessCard(
                  child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(CupertinoIcons.photo,
                      color: FitnessTheme.muted, size: 22),
                  SizedBox(height: 8),
                  FitnessText('No photo',
                      style: TextStyle(fontSize: 12, color: FitnessTheme.muted))
                ])))
              : GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      AppPageRoute<void>(page: BodyPhotoViewer(photo: photo))),
                  child:
                      PrivateBodyPhoto(key: ValueKey(photo.id), photo: photo))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final keys = bodyMetricSpecs.keys.where((key) =>
        data.current.metrics.containsKey(key) ||
        data.previous.metrics.containsKey(key));
    final changes = keys
        .where((key) =>
            data.metrics[key]?['delta'] != null &&
            data.current.metrics[key]?.isPhotoEstimate == false &&
            data.previous.metrics[key]?.isPhotoEstimate == false)
        .take(3)
        .toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (changes.isNotEmpty) ...[
            FitnessCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const FitnessText('Your progress',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  for (final key in changes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Expanded(
                            child: FitnessText(bodyMetricSpecs[key]!.label,
                                style: const TextStyle(fontSize: 14))),
                        FitnessText(data.label(key),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  const SizedBox(height: 7),
                  Text(
                      '${bodyDate(data.previous.recordedDate)} – ${bodyDate(data.current.recordedDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                ])),
            const SizedBox(height: 18),
          ],
          if (data.current.photos.isNotEmpty ||
              data.previous.photos.isNotEmpty) ...[
            BodySegment(
                labels: const ['Front', 'Back', 'Left', 'Right'],
                selected: _view,
                onChanged: (v) => setState(() => _view = v)),
            const SizedBox(height: 14),
            SizedBox(
                height: 270,
                child: Row(children: [
                  Expanded(child: _photo(data.previous)),
                  const SizedBox(width: 10),
                  Expanded(child: _photo(data.current))
                ])),
            const SizedBox(height: 10),
            const FitnessText(
                'Compare the same pose, lighting and distance. Photos are shown as captured; tap to zoom.',
                style: TextStyle(
                    fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
          ] else
            const FitnessCard(
                child: FitnessText('No saved photos',
                    style: TextStyle(fontSize: 13, color: FitnessTheme.muted))),
          if (data.current.physiqueReport != null ||
              data.previous.physiqueReport != null) ...[
            const BodySectionTitle('Photo notes'),
            const FitnessText(
                'Saved observations from each scan. Different poses or lighting can change appearance.',
                style: TextStyle(
                    fontSize: 11, height: 1.4, color: FitnessTheme.muted)),
            const SizedBox(height: 12),
            for (final area in bodyReportAreas.entries)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitnessCard(
                      padding: const EdgeInsets.all(14),
                      child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: FitnessText(area.key,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)),
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final record in [
                                    data.previous,
                                    data.current
                                  ]) ...[
                                    const SizedBox(height: 10),
                                    FitnessText(
                                        record.id == data.current.id
                                            ? 'Now'
                                            : 'Earlier',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: FitnessTheme.muted)),
                                    for (final id in area.value)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: FitnessText(
                                              _observation(record, id),
                                              style: const TextStyle(
                                                  fontSize: 12, height: 1.4))),
                                  ],
                                ]),
                          ]))),
          ],
          const SizedBox(height: 18),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const FitnessText('Measurement changes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            children: [
              for (final key in keys)
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FitnessCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          FitnessText(bodyMetricSpecs[key]!.label,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final record in [
                                  data.previous,
                                  data.current
                                ])
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        FitnessText(
                                            bodyDate(record.recordedDate),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: FitnessTheme.muted)),
                                        const SizedBox(height: 5),
                                        FitnessText(
                                            record.metrics[key]?.display(
                                                    bodyMetricSpecs[key]!
                                                        .unit) ??
                                                '—',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -.5)),
                                        const SizedBox(height: 4),
                                        FitnessText(
                                            record.metrics[key] == null
                                                ? 'No reading'
                                                : bodySourceLabel(record
                                                    .metrics[key]!.source),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: FitnessTheme.muted)),
                                      ]))
                              ]),
                          const SizedBox(height: 13),
                          FitnessText(data.label(key),
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.silver)),
                        ]))),
            ],
          ),
          const Padding(
              padding: EdgeInsets.only(top: 6),
              child: FitnessText(
                  'Matching sources only. Overlapping photo ranges do not confirm a change. Measurements cannot separate fat from muscle.',
                  style: TextStyle(
                      fontSize: 12, color: FitnessTheme.muted, height: 1.5))),
        ]);
  }
}
