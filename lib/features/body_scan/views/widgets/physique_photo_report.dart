import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../models/physique_dashboard_models.dart';
import 'body_controls.dart';
import 'physique_photo_stage.dart';
import 'anatomical_training_map.dart';

class PhysiquePhotoReport extends StatefulWidget {
  final BodyAssessment entry;
  final Map<String, Uint8List> localPhotos;
  final VoidCallback? onCompare, onRefresh, onReadings, onRetake;
  final Future<Uint8List?> Function()? pickBackground;
  final bool compact;
  const PhysiquePhotoReport(
      {super.key,
      required this.entry,
      this.localPhotos = const {},
      this.onCompare,
      this.onRefresh,
      this.onReadings,
      this.onRetake,
      this.pickBackground,
      this.compact = false});
  @override
  State<PhysiquePhotoReport> createState() => _PhysiquePhotoReportState();
}

class _PhysiquePhotoReportState extends State<PhysiquePhotoReport> {
  String _view = 'front';
  Uint8List? _backgroundBytes;
  bool _pickingBackground = false;
  static const _blue = Color(0xFF8DBBFF), _amber = Color(0xFFE5B17C);
  List<String> get _views => ['front', 'back', 'left', 'right']
      .where((v) =>
          widget.localPhotos.containsKey(v) ||
          widget.entry.photos.any((p) => p.view == v))
      .toList();
  @override
  void didUpdateWidget(PhysiquePhotoReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _view = 'front';
      _backgroundBytes = null;
    }
  }

  Future<void> _pickBackground() async {
    if (_pickingBackground) return;
    final entryId = widget.entry.id;
    setState(() => _pickingBackground = true);
    try {
      Uint8List? bytes;
      if (widget.pickBackground != null) {
        bytes = await widget.pickBackground!();
      } else {
        final file = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1280,
            maxHeight: 1600,
            imageQuality: 85,
            requestFullMetadata: false);
        bytes = await file?.readAsBytes();
      }
      if (bytes != null && bytes.length > 2000000) {
        throw StateError('Choose a photo below 2 MB.');
      }
      if (mounted && bytes != null && widget.entry.id == entryId) {
        setState(() => _backgroundBytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText(
                'Could not open this background photo. Try another image.')));
      }
    } finally {
      if (mounted) setState(() => _pickingBackground = false);
    }
  }

  Widget _neutralBackground() => DecoratedBox(
      key: const ValueKey('physique-report-background'),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            Color(0xFF243348),
            Color(0xFF101722),
            Color(0xFF05080D)
          ])),
      child: IgnorePointer(
          child: Opacity(
              opacity: .18,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 35, 24, 100),
                  child: AnatomicalTrainingMap(
                      back: false,
                      female: widget.entry.gender == 'FEMALE',
                      colors: {
                        for (final id in bodyRegionNames.keys)
                          id: const Color(0xFF9EBCE0)
                      },
                      onSelected: (_) {})))));
  String _viewLabel(String v) => switch (v) {
        'left' => 'Side',
        'right' => 'Right side',
        'back' => 'Back',
        _ => 'Front'
      };
  void _sheet(String title, String description, {String? highlight}) {
    final h = (widget.entry.physiqueReport?['highlights'] as List? ?? [])
        .whereType<Map>()
        .where((item) => item['id'] == highlight)
        .firstOrNull;
    showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        backgroundColor: FitnessTheme.surface,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FitnessText(title,
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  FitnessText(description,
                      style: const TextStyle(fontSize: 14, height: 1.6)),
                  if (h != null) ...[
                    const SizedBox(height: 16),
                    FitnessText(h['observation'] as String? ?? '',
                        style: const TextStyle(height: 1.6)),
                    for (final note in (h['limitations'] as List? ?? [])
                        .whereType<String>())
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: FitnessText(note,
                              style: const TextStyle(
                                  color: FitnessTheme.muted, height: 1.5)))
                  ],
                ])));
  }

  void _about() => _sheet(
      'About your scan',
      'The symmetry number is an experimental index of visible left/right contours: each region uses 100 × smaller width ÷ larger width. At least two supported limb regions are averaged equally. It is not a health grade, percentile, strength assessment or muscle-size measurement.\n\n'
          'Shoulder and chest values describe photo alignment and outlines. V-taper uses shoulder joint span divided by visible waist width. Definition is a subjective AI visual rating. Body fat and muscle mass come only from readings you provide.\n\n'
          'Camera position, clothing, stance and lighting affect results. Small score changes have not been validated as body changes. The scoring method is stored with each scan.');
  Widget _hero(PhysiqueDashboardData data) => Semantics(
      button: true,
      label: data.score == null
          ? 'Visual symmetry not assessable. View details'
          : 'Visual symmetry ${data.score!.round()} out of 100. Experimental photo index. View details',
      child: InkWell(
          key: const ValueKey('photo-summary-symmetry'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => _sheet(
              'Visual symmetry',
              [
                'Experimental photo index, not a health grade. At least two paired limb regions are required. The same formula is used for every member.',
                ...data.notes
              ].join('\n\n'),
              highlight: 'symmetry'),
          child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: FitnessText('VISUAL SYMMETRY',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.7,
                                  color: Color(0xFFD5DFED)))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: _blue.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(5)),
                          child: const FitnessText('EXPERIMENTAL',
                              style: TextStyle(
                                  fontSize: 8, letterSpacing: 1, color: _blue)))
                    ]),
                    Row(children: [
                      Expanded(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                        data.score?.round().toString() ??
                                            'Not rated',
                                        style: TextStyle(
                                            fontSize:
                                                data.score == null ? 30 : 64,
                                            height: 1.04,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -3,
                                            color: Colors.white)),
                                    const SizedBox(width: 6),
                                    if (data.score != null)
                                      const Text('/100',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFFB5BFCE))),
                                  ]))),
                      const SizedBox(width: 12),
                      const Icon(CupertinoIcons.info_circle,
                          size: 15, color: Color(0xFFABB9CC))
                    ]),
                    if (data.score == null)
                      const FitnessText('Needs two clear left/right limb pairs',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFFB5BFCE))),
                  ]))));
  Widget _track(double value, Color color) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
          height: 4,
          child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              backgroundColor: const Color(0xFF303844),
              color: color)));
  Widget _metric(PhysiqueDashboardMetric m) {
    final reading = m.id == 'body_fat' || m.id == 'muscle_mass';
    final tint = m.source == 'ai_visual_rating' ? _amber : _blue;
    return Semantics(
        button: true,
        label:
            '${m.label}, ${m.formatted} ${m.value == null ? '' : m.unit}, ${m.sourceLabel}',
        child: InkWell(
            key: ValueKey('photo-metric-${m.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: reading && widget.onReadings != null
                ? widget.onReadings
                : () => _sheet(m.label,
                    '${m.detail}${m.recordedDate == null ? '' : '\n\nReading date: ${bodyDate(m.recordedDate!)}'}',
                    highlight: m.id == 'chest'
                        ? 'chest'
                        : m.id == 'v_taper'
                            ? 'v_taper'
                            : null),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FitnessText(m.label.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              letterSpacing: .8,
                              color: Color(0xFFC8D0DD))),
                      const SizedBox(height: 3),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                                child: Text(
                                    m.value == null
                                        ? (reading ? 'Add' : 'Retry')
                                        : m.formatted,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        fontSize: 27,
                                        height: 1.15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: -.8))),
                            if (m.value != null)
                              Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(m.unit,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFB5BFCE))))
                          ]),
                      const SizedBox(height: 6),
                      if (m.id == 'v_taper' && m.value != null)
                        Column(children: [
                          for (final width in [m.value!, 1.0])
                            Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child:
                                    _track(width / math.max(m.value!, 1), tint))
                        ])
                      else
                        _track(
                            m.value == null
                                ? 0
                                : m.unit == '/100' || m.unit == '%'
                                    ? m.value! / 100
                                    : 0,
                            tint),
                      const SizedBox(height: 5),
                      FitnessText(m.sourceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 8, color: Color(0xFF9AA9BE))),
                    ]))));
  }

  Widget _dashboard(PhysiqueDashboardData data) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(data),
            for (var i = 0; i < data.metrics.length; i += 2)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _metric(data.metrics[i])),
                const SizedBox(width: 24),
                Expanded(child: _metric(data.metrics[i + 1]))
              ]),
            const SizedBox(height: 12),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.sparkles, color: Color(0xFF8DBBFF), size: 12),
              SizedBox(width: 6),
              Text('SETCRAFT',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD9E3F3)))
            ])
          ]);
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry, views = _views, data = entry.dashboard;
    final selected = views.contains(_view) ? _view : views.firstOrNull;
    final photo = entry.photos.where((p) => p.view == selected).firstOrNull;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PhysiquePhotoStage(
          bytes: selected == null
              ? _backgroundBytes
              : widget.localPhotos[selected],
          photo: photo,
          background: _neutralBackground(),
          aspectRatio: .60,
          fit: BoxFit.cover,
          strongGradient: true,
          borderColor: _blue,
          label: selected == null
              ? (_backgroundBytes == null
                  ? 'Report · photo not saved'
                  : 'Display photo · not analysed')
              : '${_viewLabel(selected)} · ${bodyDate(entry.recordedDate)}',
          footer: largeText ? null : _dashboard(data)),
      if (largeText)
        Padding(
            padding: const EdgeInsets.only(top: 16), child: _dashboard(data)),
      if (views.length > 1)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(spacing: 8, children: [
              for (final view in views)
                ChoiceChip(
                    label: FitnessText(_viewLabel(view)),
                    selected: selected == view,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _view = view),
                    selectedColor: _blue,
                    backgroundColor: FitnessTheme.surface,
                    side: const BorderSide(color: FitnessTheme.line),
                    labelStyle: TextStyle(
                        fontSize: 11,
                        color: selected == view
                            ? Colors.black
                            : FitnessTheme.silver))
            ])),
      const SizedBox(height: 16),
      if (data.metrics.any((m) =>
              ['v_taper', 'chest', 'shoulders'].contains(m.id) &&
              m.value == null) ||
          data.score == null)
        FitnessCard(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FitnessText('Complete your photo results',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FitnessText(
                  data.issues.isEmpty
                      ? 'Retake a clear front photo with level shoulders, hips visible and arms slightly apart.'
                      : data.issues.take(2).join('\n'),
                  style: const TextStyle(
                      fontSize: 12, height: 1.5, color: FitnessTheme.muted)),
              if (widget.onRetake != null || widget.onRefresh != null)
                TextButton.icon(
                    onPressed: widget.onRetake ?? widget.onRefresh,
                    icon: const Icon(CupertinoIcons.camera, size: 15),
                    label: FitnessText(widget.onRetake != null
                        ? 'Retake front photo'
                        : 'Retry photo analysis')),
            ])),
      if (selected == null) ...[
        const SizedBox(height: 8),
        TextButton.icon(
            key: const ValueKey('choose-report-background'),
            onPressed: _pickingBackground ? null : _pickBackground,
            icon: const Icon(CupertinoIcons.photo, size: 15),
            label: const FitnessText('Add background photo')),
        const FitnessText(
            'Display only. Not uploaded or added to your saved scans.',
            style: TextStyle(
                fontSize: 11, height: 1.5, color: FitnessTheme.muted)),
        if (_backgroundBytes != null)
          TextButton(
              onPressed: () => setState(() => _backgroundBytes = null),
              child: const FitnessText('Use neutral background')),
      ],
      Row(children: [
        Expanded(
            child: FitnessText(bodyDate(entry.recordedDate),
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted))),
        TextButton.icon(
            onPressed: _about,
            icon: const Icon(CupertinoIcons.info_circle, size: 14),
            label: const FitnessText('About these numbers',
                style: TextStyle(fontSize: 11)))
      ]),
      if (widget.onReadings != null)
        TextButton.icon(
            onPressed: widget.onReadings,
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 15),
            label: const FitnessText('Update composition readings')),
      if (entry.photos.isEmpty)
        const Padding(
            padding: EdgeInsets.only(top: 6),
            child: FitnessText('Your report is saved. Photos were not kept.',
                style: TextStyle(fontSize: 11, color: FitnessTheme.muted))),
      if (widget.onCompare != null)
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    key: const ValueKey('compare-saved-scans'),
                    onPressed: widget.onCompare,
                    icon: const Icon(CupertinoIcons.arrow_left_right, size: 16),
                    label: const FitnessText('Compare scans')))),
      if (widget.onRefresh != null)
        TextButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(CupertinoIcons.arrow_clockwise, size: 15),
            label: const FitnessText('Update photo review')),
    ]);
  }
}
