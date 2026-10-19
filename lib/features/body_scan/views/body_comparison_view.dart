import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:fitai_mobile/core/theme/ds_colors.dart';
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

  Widget _buildBaselineSelector() {
    if (widget.baselines.length <= 1) {
      final entry = widget.baselines.first;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: DSColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DSColors.border, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                entry.method == 'photo_review'
                    ? CupertinoIcons.camera
                    : CupertinoIcons.chart_bar,
                size: 15,
                color: FitnessTheme.silver,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FitnessText(
                  '${bodyDate(entry.recordedDate)} · ${entry.method == 'photo_review' ? 'Photo review' : 'Measurements'}',
                  style:
                      const TextStyle(fontSize: 13, color: FitnessTheme.silver),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DSColors.bgRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FitnessText(
                  'Baseline',
                  style: TextStyle(fontSize: 10, color: FitnessTheme.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FitnessText(
                'Compare against baseline',
                style: TextStyle(fontSize: 12, color: FitnessTheme.muted),
              ),
              const Spacer(),
              FitnessText(
                '${widget.baselines.length} recorded',
                style: const TextStyle(fontSize: 11, color: FitnessTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.baselines.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = widget.baselines[index];
                final isSelected = entry.id == _baseline;
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() => _baseline = entry.id);
                      _load();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? DSColors.bgRaised : DSColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? FitnessTheme.silver : DSColors.border,
                        width: isSelected ? 1.4 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.method == 'photo_review'
                              ? CupertinoIcons.camera
                              : CupertinoIcons.chart_bar,
                          size: 13,
                          color: isSelected
                              ? FitnessTheme.silver
                              : FitnessTheme.muted,
                        ),
                        const SizedBox(width: 8),
                        FitnessText(
                          bodyDate(entry.recordedDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                isSelected ? Colors.white : FitnessTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
                _buildBaselineSelector(),
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

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double split;
  const _HorizontalSplitClipper(this.split);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * split, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) =>
      oldClipper.split != split;
}

class BodyComparisonPanel extends StatefulWidget {
  final BodyComparison data;
  const BodyComparisonPanel({super.key, required this.data});
  @override
  State<BodyComparisonPanel> createState() => _BodyComparisonPanelState();
}

class _BodyComparisonPanelState extends State<BodyComparisonPanel> {
  int _view = 0;
  int _photoMode = 0; // 0: Split Slider, 1: Side by Side, 2: Ghost Overlay
  double _split = 0.5;
  double _overlayOpacity = 0.5;

  String _observation(BodyAssessment record, String id) {
    final regions =
        (record.physiqueReport?['regions'] as List? ?? []).whereType<Map>();
    final region = regions.where((r) => r['region'] == id).firstOrNull;
    final text = region?['visualObservation'] as String?;
    return '${fitnessText(context, bodyRegionNames[id] ?? id)}: ${text == null ? fitnessText(context, 'No photo assessment') : bodyReportBrief(text)}';
  }

  Widget _singlePhotoBox(BodyPhoto? photo, String dateLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: DSColors.bgRaised,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FitnessText(
            dateLabel,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: photo == null
              ? const FitnessCard(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.photo,
                            color: FitnessTheme.muted, size: 22),
                        SizedBox(height: 8),
                        FitnessText('No photo',
                            style: TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    AppPageRoute<void>(page: BodyPhotoViewer(photo: photo)),
                  ),
                  child: PrivateBodyPhoto(
                    key: ValueKey(photo.id),
                    photo: photo,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSplitSlider(
      BodyPhoto prevPhoto, BodyPhoto currPhoto, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.border, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final dividerX = (width * _split).clamp(10.0, width - 10.0);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                final localX = details.localPosition.dx;
                setState(() {
                  _split = (localX / width).clamp(0.05, 0.95);
                });
              },
              onTapDown: (details) {
                final localX = details.localPosition.dx;
                setState(() {
                  _split = (localX / width).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Earlier photo (Left/Background)
                  PrivateBodyPhoto(
                    key: ValueKey('prev-${prevPhoto.id}'),
                    photo: prevPhoto,
                    fit: BoxFit.contain,
                  ),

                  // Current photo (Right/Clipped Foreground)
                  ClipRect(
                    clipper: _HorizontalSplitClipper(_split),
                    child: PrivateBodyPhoto(
                      key: ValueKey('curr-${currPhoto.id}'),
                      photo: currPhoto,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Divider Line & Handle
                  Positioned(
                    left: dividerX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_left_right,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Labels: Before & After
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5),
                      ),
                      child: FitnessText(
                        'BEFORE · ${bodyDate(widget.data.previous.recordedDate)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: FitnessTheme.silver.withValues(alpha: 0.4),
                            width: 0.5),
                      ),
                      child: FitnessText(
                        'AFTER · ${bodyDate(widget.data.current.recordedDate)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FitnessTheme.silver),
                      ),
                    ),
                  ),

                  // Bottom Drag Hint
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FitnessText(
                          'Slide to compare alignment & definition',
                          style: TextStyle(
                              fontSize: 10, color: FitnessTheme.muted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGhostOverlay(
      BodyPhoto prevPhoto, BodyPhoto currPhoto, double height) {
    return Column(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DSColors.border, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: (1.0 - _overlayOpacity).clamp(0.05, 1.0),
                  child: PrivateBodyPhoto(
                    key: ValueKey('ghost-prev-${prevPhoto.id}'),
                    photo: prevPhoto,
                    fit: BoxFit.contain,
                  ),
                ),
                Opacity(
                  opacity: _overlayOpacity.clamp(0.05, 1.0),
                  child: PrivateBodyPhoto(
                    key: ValueKey('ghost-curr-${currPhoto.id}'),
                    photo: currPhoto,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            FitnessText(
              'Earlier (${((1 - _overlayOpacity) * 100).round()}%)',
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted),
            ),
            const Spacer(),
            FitnessText(
              'Now (${(_overlayOpacity * 100).round()}%)',
              style: const TextStyle(fontSize: 11, color: FitnessTheme.silver),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            trackHeight: 3,
            activeTrackColor: FitnessTheme.silver,
            inactiveTrackColor: DSColors.bgRaised,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: _overlayOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => setState(() => _overlayOpacity = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySide(BodyPhoto? prevPhoto, BodyPhoto? currPhoto) {
    return SizedBox(
      height: 310,
      child: Row(
        children: [
          Expanded(
            child: _singlePhotoBox(
              prevPhoto,
              bodyDate(widget.data.previous.recordedDate),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _singlePhotoBox(
              currPhoto,
              bodyDate(widget.data.current.recordedDate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoModeButton(String label, IconData icon, int mode) {
    final isSelected = _photoMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _photoMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DSColors.bgRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? FitnessTheme.silver : DSColors.border,
            width: isSelected ? 1.0 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : FitnessTheme.muted,
            ),
            const SizedBox(width: 5),
            FitnessText(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : FitnessTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
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
        .take(4)
        .toList();

    final viewStr = ['front', 'back', 'left', 'right'][_view];
    final prevPhoto =
        data.previous.photos.where((p) => p.view == viewStr).firstOrNull;
    final currPhoto =
        data.current.photos.where((p) => p.view == viewStr).firstOrNull;
    final hasBothPhotos = prevPhoto != null && currPhoto != null;
    final hasAnyPhotos =
        data.current.photos.isNotEmpty || data.previous.photos.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // ── 1. Hero Progress Summary Card ──
        if (changes.isNotEmpty) ...[
          FitnessCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FitnessText(
                  'Your progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bodyDate(data.previous.recordedDate)} – ${bodyDate(data.current.recordedDate)}',
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted),
                ),
                const SizedBox(height: 12),
                for (final key in changes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitnessText(
                                bodyMetricSpecs[key]!.label,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data.previous.metrics[key]?.display(bodyMetricSpecs[key]!.unit) ?? '—'} → ${data.current.metrics[key]?.display(bodyMetricSpecs[key]!.unit) ?? '—'}',
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        FitnessText(
                          data.label(key),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: FitnessTheme.silver,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ── 2. Regional Muscle Shift Summary (Surfacing data.regions) ──
        if (data.regions.values.any((v) => v != 'unavailable')) ...[
          FitnessCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.sparkles,
                        size: 15, color: FitnessTheme.silver),
                    SizedBox(width: 8),
                    FitnessText(
                      'Visual muscle status',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in data.regions.entries)
                      if (entry.value != 'unavailable')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: DSColors.bgRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: entry.value == 'increased'
                                  ? DSColors.accentLime.withValues(alpha: 0.35)
                                  : entry.value == 'decreased'
                                      ? DSColors.coral.withValues(alpha: 0.35)
                                      : DSColors.border,
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.value == 'increased'
                                    ? CupertinoIcons.arrow_up_right
                                    : entry.value == 'decreased'
                                        ? CupertinoIcons.arrow_down_right
                                        : CupertinoIcons.minus,
                                size: 11,
                                color: entry.value == 'increased'
                                    ? DSColors.accentLime
                                    : entry.value == 'decreased'
                                        ? DSColors.coral
                                        : FitnessTheme.muted,
                              ),
                              const SizedBox(width: 5),
                              FitnessText(
                                '${bodyRegionNames[entry.key] ?? entry.key}: ${entry.value}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ── 3. High-Res Photo Comparison Studio ──
        if (hasAnyPhotos) ...[
          BodySegment(
            labels: const ['Front', 'Back', 'Left', 'Right'],
            selected: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          const SizedBox(height: 12),
          if (hasBothPhotos) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPhotoModeButton(
                      'Split slider', CupertinoIcons.arrow_left_right, 0),
                  const SizedBox(width: 8),
                  _buildPhotoModeButton(
                      'Side by side', CupertinoIcons.square_split_2x1, 1),
                  const SizedBox(width: 8),
                  _buildPhotoModeButton('Overlay', CupertinoIcons.layers, 2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_photoMode == 0)
              _buildSplitSlider(prevPhoto, currPhoto, 360)
            else if (_photoMode == 2)
              _buildGhostOverlay(prevPhoto, currPhoto, 320)
            else
              _buildSideBySide(prevPhoto, currPhoto),
          ] else ...[
            _buildSideBySide(prevPhoto, currPhoto),
          ],
          const SizedBox(height: 10),
          const FitnessText(
            'Compare the same pose, lighting and distance. Photos are shown as captured; tap to zoom.',
            style:
                TextStyle(fontSize: 11, color: FitnessTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
        ] else ...[
          const FitnessCard(
            child: FitnessText(
              'No saved photos',
              style: TextStyle(fontSize: 13, color: FitnessTheme.muted),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ── 4. Photo Notes & Regional Gemini Critic ──
        if (data.current.physiqueReport != null ||
            data.previous.physiqueReport != null) ...[
          const BodySectionTitle('Photo notes'),
          const FitnessText(
            'Saved observations from each scan. Different poses or lighting can change appearance.',
            style:
                TextStyle(fontSize: 11, height: 1.4, color: FitnessTheme.muted),
          ),
          const SizedBox(height: 12),
          for (final area in bodyReportAreas.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FitnessCard(
                padding: const EdgeInsets.all(14),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    title: FitnessText(
                      area.key,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final record in [
                            data.previous,
                            data.current
                          ]) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: record.id == data.current.id
                                    ? DSColors.bgRaised
                                    : const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: record.id == data.current.id
                                      ? FitnessTheme.silver
                                          .withValues(alpha: 0.3)
                                      : DSColors.border,
                                  width: 0.6,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: record.id == data.current.id
                                              ? FitnessTheme.silver
                                              : DSColors.bgCard,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          record.id == data.current.id
                                              ? 'Now'
                                              : 'Earlier',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: record.id == data.current.id
                                                ? Colors.black
                                                : FitnessTheme.muted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        bodyDate(record.recordedDate),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: FitnessTheme.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  for (final id in area.value)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: FitnessText(
                                        _observation(record, id),
                                        style: const TextStyle(
                                            fontSize: 12, height: 1.45),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],

        // ── 5. Detailed Measurement Changes ──
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const FitnessText(
              'Measurement changes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            children: [
              for (final key in keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitnessCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FitnessText(
                                bodyMetricSpecs[key]!.label,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            FitnessText(
                              data.label(key),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FitnessTheme.silver,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final record in [data.previous, data.current])
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FitnessText(
                                      bodyDate(record.recordedDate),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: FitnessTheme.muted),
                                    ),
                                    const SizedBox(height: 4),
                                    FitnessText(
                                      record.metrics[key]?.display(
                                              bodyMetricSpecs[key]!.unit) ??
                                          '—',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    FitnessText(
                                      record.metrics[key] == null
                                          ? 'No reading'
                                          : bodySourceLabel(
                                              record.metrics[key]!.source),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: FitnessTheme.muted),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: FitnessText(
            'Matching sources only. Overlapping photo ranges do not confirm a change. Measurements cannot separate fat from muscle.',
            style:
                TextStyle(fontSize: 11, color: FitnessTheme.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
