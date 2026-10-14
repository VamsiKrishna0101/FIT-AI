import '../../../core/theme/ds_motion.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/body_focus_panel.dart';
import 'body_estimate_view.dart';
import 'body_comparison_view.dart';
import 'widgets/saved_body_photos.dart';

class BodyFocusResultView extends StatefulWidget {
  final BodyAssessment entry;
  final List<BodyAssessment> baselines;
  const BodyFocusResultView(
      {super.key, required this.entry, this.baselines = const []});
  @override
  State<BodyFocusResultView> createState() => _BodyFocusResultViewState();
}

class _BodyFocusResultViewState extends State<BodyFocusResultView> {
  bool _deleting = false;
  bool _changed = false;
  late BodyAssessment _entry = widget.entry;
  String? _error;
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
    await Navigator.of(context).push<bool>(AppPageRoute(
        page: BodyEstimateView(
            female: _entry.gender == 'FEMALE',
            fromPhotos: _entry.photos.length == 4,
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
                  title: const FitnessText('Your body report',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600))),
              body: SafeArea(
                  top: false,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        const FitnessText('Your saved assessment.',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.7)),
                        const SizedBox(height: 18),
                        BodyFocusPanel(
                            assessment: _entry,
                            onOpenPhotos: _photos,
                            onCompare: widget.baselines.isEmpty || _deleting
                                ? null
                                : () => Navigator.of(context).push(
                                    AppPageRoute<void>(
                                        page: BodyComparisonView(
                                            current: _entry,
                                            baselines: widget.baselines))),
                            onRefreshReport: _deleting ? null : _refreshReport),
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
