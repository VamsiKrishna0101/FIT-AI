import '../../../core/theme/ds_motion.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../models/body_progress_summary.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/body_focus_panel.dart';
import 'body_estimate_view.dart';
import 'body_photo_review_view.dart';
import 'body_comparison_view.dart';
import 'widgets/saved_body_photos.dart';
import 'widgets/physique_photo_report.dart';
import 'widgets/composition_readings_sheet.dart';

class BodyFocusResultView extends StatefulWidget {
  final BodyAssessment entry;
  final List<BodyAssessment> baselines;
  final bool compact;
  const BodyFocusResultView(
      {super.key,
      required this.entry,
      this.baselines = const [],
      this.compact = false});
  @override
  State<BodyFocusResultView> createState() => _BodyFocusResultViewState();
}

class _BodyFocusResultViewState extends State<BodyFocusResultView> {
  bool _deleting = false;
  bool _changed = false;
  late BodyAssessment _entry = widget.entry;
  String? _error;
  Future<void> _readings() async {
    final owner = await CacheScope.userId();
    if (!mounted || _deleting) return;
    final readings = await showCompositionReadings(context,
        initial: _entry.dashboard.readings, scanDate: _entry.recordedDate);
    if (readings == null || !mounted || await CacheScope.userId() != owner) {
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final updated = await BodyAssessmentRepository.shared
          .updateReadings(_entry, readings);
      if (mounted && await CacheScope.userId() == owner && mounted) {
        setState(() {
          _entry = updated;
          _changed = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _deletePhotos() async {
    final owner = await CacheScope.userId();
    if (!mounted) return;
    final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
                title: const FitnessText('Delete saved photos?'),
                content: const FitnessText(
                    'Your report and measurements will stay.'),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context, false),
                      child: const FitnessText('Keep')),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context, true),
                      child: const FitnessText('Delete photos'))
                ]));
    final currentOwner = await CacheScope.userId();
    if (confirmed != true || !mounted || currentOwner != owner) {
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final entry =
          await BodyAssessmentRepository.shared.deletePhotos(_entry.id);
      final currentOwner = await CacheScope.userId();
      if (mounted && currentOwner == owner) {
        setState(() {
          _entry = entry;
          _changed = true;
        });
      }
    } catch (error) {
      final currentOwner = await CacheScope.userId();
      if (mounted && currentOwner == owner) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _photos() => showModalBottomSheet<void>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      context: context,
      backgroundColor: FitnessTheme.canvas,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                SavedBodyPhotos(
                    entry: _entry,
                    onDelete: _deleting
                        ? null
                        : () {
                            Navigator.pop(context);
                            _deletePhotos();
                          }),
              ])));
  void _close() => Navigator.pop(context, _changed);
  Future<void> _refreshReport() async {
    final agreed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
            title: const FitnessText('Update body report'),
            content: const FitnessText(
                'I agree to Setcraft and OpenAI analyzing my photos, measurements, profile and training data for my report.'),
            actions: [
              CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const FitnessText('Cancel')),
              CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, true),
                  child: const FitnessText('Continue')),
            ]));
    if (agreed != true || !mounted) return;
    await Navigator.of(context).push<bool>(AppPageRoute(
        page: BodyEstimateView(
            female: _entry.gender == 'FEMALE',
            fromPhotos: _entry.photos.isNotEmpty,
            savedPhotos: _entry.photos,
            estimate: (stage, cancelled) => BodyAssessmentRepository.shared
                .refreshFocus(_entry, cancelled: cancelled, onStage: stage),
            onCompleted: (entry) {
              if (mounted) {
                setState(() {
                  _entry = entry;
                  _changed = true;
                });
              }
            })));
  }

  Future<void> _retakePhoto() async {
    final changed = await Navigator.of(context).push<bool>(AppPageRoute(
        page: BodyPhotoReviewView(female: _entry.gender == 'FEMALE')));
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final owner = await CacheScope.userId();
    if (!mounted) return;
    final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
                title: const FitnessText('Delete this assessment?'),
                content: const FitnessText(
                    'Its photos and saved assessment will also be removed.'),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context, false),
                      child: const FitnessText('Keep')),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context, true),
                      child: const FitnessText('Delete'))
                ]));
    final currentOwner = await CacheScope.userId();
    if (confirmed != true || !mounted || currentOwner != owner) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await BodyAssessmentRepository.shared.delete(_entry.id);
      final latestOwner = await CacheScope.userId();
      if (mounted && latestOwner == owner) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _close();
          },
          child: Scaffold(
              backgroundColor: FitnessTheme.canvas,
              appBar: AppBar(
                  backgroundColor: FitnessTheme.canvas,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                      onPressed: _close,
                      tooltip: 'Back',
                      icon: const Icon(CupertinoIcons.chevron_left, size: 22)),
                  title: FitnessText(
                      _entry.hasPhotoAssessment
                          ? 'Your physique review'
                          : 'Your body report',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600))),
              body: SafeArea(
                  top: false,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (!_entry.hasPhotoAssessment)
                          const FitnessText('Your saved assessment.',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.7)),
                        const SizedBox(height: 18),
                        if (_entry.hasPhotoAssessment)
                          PhysiquePhotoReport(
                              entry: _entry,
                              onRetake: _deleting ? null : _retakePhoto,
                              onReadings:
                                  _deleting || _entry.method != 'photo_review'
                                      ? null
                                      : _readings,
                              onRefresh: _deleting ||
                                      !_entry.visualCoachingConsent ||
                                      _entry.photos.isEmpty
                                  ? null
                                  : _refreshReport,
                              onCompare: _deleting ||
                                      !widget.baselines
                                          .any(_entry.canComparePhotosWith)
                                  ? null
                                  : () => Navigator.of(context).push(
                                      AppPageRoute<void>(
                                          page: BodyComparisonView(
                                              current: _entry,
                                              baselines: widget.baselines
                                                  .where(
                                                      _entry.canComparePhotosWith)
                                                  .toList()))))
                        else
                          BodyFocusPanel(
                              assessment: _entry,
                              compact: widget.compact,
                              readings: [
                                for (final metric in _entry.metrics.entries)
                                  if (bodyMetricSpecs.containsKey(metric.key))
                                    BodyReading(
                                        key: metric.key,
                                        date: _entry.recordedDate,
                                        metric: metric.value,
                                        series: metric.value.source,
                                        sourceLabel: bodySourceLabel(
                                            metric.value.source))
                              ],
                              onOpenPhotos: _photos,
                              onCompare: widget.baselines.isEmpty || _deleting
                                  ? null
                                  : () => Navigator.of(context).push(
                                      AppPageRoute<void>(
                                          page: BodyComparisonView(
                                              current: _entry,
                                              baselines: widget.baselines))),
                              onRefreshReport:
                                  _deleting ? null : _refreshReport),
                        if (_entry.hasPhotoAssessment &&
                            _entry.photos.isNotEmpty)
                          TextButton.icon(
                              onPressed: _photos,
                              icon: const Icon(CupertinoIcons.photo, size: 16),
                              label: const FitnessText('Manage saved photos')),
                        if (widget.compact && !_entry.hasPhotoAssessment) ...[
                          if (_entry.photos.isNotEmpty)
                            TextButton.icon(
                                onPressed: _photos,
                                icon:
                                    const Icon(CupertinoIcons.photo, size: 16),
                                label: const FitnessText('Saved photos',
                                    style: TextStyle(fontSize: 12))),
                          TextButton.icon(
                              onPressed: _deleting ? null : _refreshReport,
                              icon: const Icon(CupertinoIcons.arrow_clockwise,
                                  size: 16),
                              label: const FitnessText('Update body report',
                                  style: TextStyle(fontSize: 12))),
                        ],
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: FitnessText(_error!,
                                  style: const TextStyle(
                                      color: FitnessTheme.coral))),
                        const SizedBox(height: 22),
                        TextButton(
                            onPressed: _deleting ? null : _delete,
                            child: _deleting
                                ? const CupertinoActivityIndicator()
                                : const FitnessText('Delete assessment',
                                    style: TextStyle(
                                        color: FitnessTheme.muted,
                                        fontSize: 12))),
                      ])))));
}
