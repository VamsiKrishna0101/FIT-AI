import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/anatomical_training_map.dart';
import 'widgets/body_focus_panel.dart';
import 'widgets/body_controls.dart';
import '../../../core/cache/cache_scope.dart';
import 'body_comparison_view.dart';
import 'body_focus_result_view.dart';

typedef BodyEstimateRunner = Future<BodyAssessment> Function(
    ValueChanged<String> onStage, bool Function() cancelled);

class BodyEstimateView extends StatefulWidget {
  final BodyEstimateRunner estimate;
  final bool female;
  final bool fromPhotos;
  final ValueChanged<BodyAssessment>? onCompleted;
  const BodyEstimateView(
      {super.key,
      required this.estimate,
      this.female = false,
      this.fromPhotos = true,
      this.onCompleted});
  @override
  State<BodyEstimateView> createState() => _BodyEstimateViewState();
}

class _BodyEstimateViewState extends State<BodyEstimateView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  BodyAssessment? _entry;
  String _stage = 'uploading';
  String? _error;
  bool _cancelled = false;
  Future<void> _compare() async {
    final owner = await CacheScope.userId();
    final entry = _entry;
    if (entry == null || !mounted) return;
    try {
      final overview = await BodyAssessmentRepository.shared.load();
      final currentOwner = await CacheScope.userId();
      if (!mounted || currentOwner != owner) return;
      final earlier =
          overview.records.where((r) => r.isEarlierThan(entry)).toList();
      if (earlier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText(
                'Add another assessment to compare your progress.')));
        return;
      }
      await Navigator.of(context).push(AppPageRoute<void>(
          page: BodyComparisonView(current: entry, baselines: earlier)));
    } catch (error) {
      final currentOwner = await CacheScope.userId();
      if (mounted && currentOwner == owner) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: FitnessText(BodyAssessmentRepository.message(error))));
      }
    }
  }

  Future<void> _photos() async {
    final route = AppPageRoute<bool>(page: BodyFocusResultView(entry: _entry!));
    final changed = await Navigator.of(context).push(route);
    await route.completed;
    if (changed == true && mounted) _close();
  }

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    unawaited(_start());
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _stage = 'uploading';
    });
    _pulse.repeat(reverse: true);
    try {
      final entry = await widget.estimate((stage) {
        if (mounted && !_cancelled) {
          setState(() => _stage = stage);
        }
      }, () => _cancelled || !mounted);
      if (mounted && !_cancelled) {
        setState(() => _entry = entry);
        widget.onCompleted?.call(entry);
      }
    } catch (error) {
      if (mounted && !_cancelled) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) _pulse.stop();
    }
  }

  void _close() {
    _cancelled = true;
    Navigator.of(context).pop(_entry != null);
  }

  @override
  void dispose() {
    _cancelled = true;
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _entry != null;
    final stageText = switch (_stage) {
      'outlines' => 'Reading your body outlines',
      'focus' => 'Preparing your body report',
      'saving' => 'Saving your baseline',
      _ => widget.fromPhotos
          ? 'Preparing your four views'
          : 'Preparing your context',
    };
    return FitnessTheme(
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
                      tooltip: done ? 'Back' : 'Cancel estimate',
                      icon: const Icon(CupertinoIcons.chevron_left, size: 22)),
                  title: FitnessText(
                      done ? 'Your body report' : 'Your assessment',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600))),
              body: SafeArea(
                  top: false,
                  child: Column(children: [
                    Expanded(
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            children: [
                          FitnessText(
                              done
                                  ? 'Your baseline is saved.'
                                  : _error == null
                                      ? 'Made for your body.'
                                      : 'Let’s try that again.',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.8)),
                          const SizedBox(height: 8),
                          FitnessText(
                              done
                                  ? 'You can return to this assessment from Body.'
                                  : widget.fromPhotos
                                      ? 'Your photos, height, weight and training context come together here.'
                                      : 'Your measurements, profile and training context come together here.',
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: FitnessTheme.muted)),
                          const SizedBox(height: 22),
                          if (done)
                            BodyFocusPanel(
                                assessment: _entry,
                                female: widget.female,
                                onCompare: _compare,
                                onOpenPhotos: _photos)
                          else ...[
                            FitnessCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(children: [
                                  SizedBox(
                                      height: 310,
                                      child: AnimatedBuilder(
                                          animation: _pulse,
                                          builder: (_, child) => Opacity(
                                              opacity: _error != null
                                                  ? .4
                                                  : .45 + _pulse.value * .5,
                                              child: child),
                                          child: AnatomicalTrainingMap(
                                              back: false,
                                              female: widget.female,
                                              colors: {
                                                for (final id
                                                    in bodyRegionNames.keys)
                                                  id: const Color(0xFF949BA4)
                                              },
                                              onSelected: (_) {}))),
                                  const SizedBox(height: 18),
                                  if (_error == null) ...[
                                    const SizedBox(
                                        width: 160,
                                        child: LinearProgressIndicator(
                                            minHeight: 2,
                                            color: FitnessTheme.silver,
                                            backgroundColor:
                                                FitnessTheme.line)),
                                    const SizedBox(height: 20),
                                    FitnessText(stageText,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    const FitnessText(
                                        'This can take a few minutes. Keep this screen open.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: FitnessTheme.muted)),
                                  ] else
                                    FitnessText(_error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: FitnessTheme.coral)),
                                ])),
                            const SizedBox(height: 16),
                            const FitnessText(
                                'Only usable measurements inform your assessment. Uncertain readings are left out.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: FitnessTheme.muted)),
                          ],
                        ])),
                    if (done || _error != null)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child: LiquidChromeButton(
                              title: done ? 'Done' : 'Try again',
                              onPressed: done ? _close : _start)),
                  ])),
            )));
  }
}
