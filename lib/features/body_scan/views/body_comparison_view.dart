import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:setcraft/core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/body_controls.dart';
import 'widgets/photo_comparison_studio.dart';

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
  List<BodyAssessment> get _baselines => widget.baselines
      .where((entry) => widget.current.hasPhotoAssessment
          ? widget.current.canComparePhotosWith(entry)
          : entry.isEarlierThan(widget.current))
      .toList();

  @override
  void initState() {
    super.initState();
    _baseline = _baselines.firstOrNull?.id ?? '';
    if (_baseline.isNotEmpty) {
      _load();
    } else {
      _error = 'Photo comparison needs two saved scans with a matching view.';
    }
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
    if (_baselines.isEmpty) return const SizedBox.shrink();
    if (_baselines.length <= 1) {
      final entry = _baselines.first;
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
                '${_baselines.length} recorded',
                style: const TextStyle(fontSize: 11, color: FitnessTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _baselines.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _baselines[index];
                final isSelected = entry.id == _baseline;
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() => _baseline = entry.id);
                      _load();
                    }
                  },
                  child: AnimatedContainer(
                    duration: DSMotion.duration(context, DSMotion.selection),
                    curve: DSMotion.effects,
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
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

class BodyComparisonPanel extends StatelessWidget {
  final BodyComparison data;
  const BodyComparisonPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final photoPair = data.current.canComparePhotosWith(data.previous);
    final keys = bodyMetricSpecs.keys
        .where((key) =>
            data.current.metrics.containsKey(key) ||
            data.previous.metrics.containsKey(key))
        .toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (photoPair)
            PhotoComparisonStudio(
                key: ValueKey('${data.previous.id}:${data.current.id}'),
                before: data.previous,
                after: data.current)
          else
            const FitnessCard(
                child: FitnessText('No saved photos',
                    style: TextStyle(fontSize: 13, color: FitnessTheme.muted))),
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 24),
            const FitnessText('Measurement changes',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5)),
            const SizedBox(height: 12),
            for (final key in keys)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FitnessCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: FitnessText(
                                      bodyMetricSpecs[key]!.label,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600))),
                              FitnessText(data.label(key),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.silver)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              for (final record in [
                                data.previous,
                                data.current
                              ])
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      FitnessText(bodyDate(record.recordedDate),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: FitnessTheme.muted)),
                                      const SizedBox(height: 4),
                                      FitnessText(
                                          record.metrics[key]?.display(
                                                  bodyMetricSpecs[key]!.unit) ??
                                              '—',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      FitnessText(
                                          record.metrics[key] == null
                                              ? 'No reading'
                                              : bodySourceLabel(
                                                  record.metrics[key]!.source),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: FitnessTheme.muted)),
                                    ])),
                            ]),
                          ]))),
            const FitnessText(
                'Matching sources only. Photos do not establish how much fat or muscle has changed.',
                style: TextStyle(
                    fontSize: 11, height: 1.5, color: FitnessTheme.muted)),
          ],
        ]);
  }
}
