import 'package:flutter/semantics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../../core/components/app_date_filter.dart';
import '../../models/body_map_models.dart';
import 'anatomical_training_map.dart';
import 'body_controls.dart';
import 'body_calendar.dart';
import 'body_muscle_details_sheet.dart';
import 'body_training_scale.dart';

class BodyMapPalette {
  static const planned = Color(0xFF8BA9CC);
  static const progress = Color(0xFFC6A77D);
  static const completed = Color(0xFF80B69E);
  static const neutral = Color(0xFF595E64);
}

class BodyMuscleMapCard extends StatefulWidget {
  final BodyMapData? data;
  final bool female, loading, canCreatePlan;
  final DateTime week;
  final String? error;
  final VoidCallback onRetry, onPreparePlan, onTrain;
  final ValueChanged<DateTime> onWeekChanged;
  final ValueChanged<String> onExercise;
  final ValueChanged<BodyExerciseSelection>? onExerciseSelection;
  final BodyDateSelection? selection;
  final ValueChanged<BodyDateSelection>? onSelectionChanged;
  final ValueChanged<bool>? onModeChanged;
  const BodyMuscleMapCard(
      {super.key,
      this.data,
      required this.female,
      required this.week,
      required this.onWeekChanged,
      required this.onExercise,
      this.onExerciseSelection,
      this.selection,
      this.onSelectionChanged,
      this.onModeChanged,
      required this.onPreparePlan,
      this.canCreatePlan = false,
      this.loading = false,
      this.error,
      required this.onRetry,
      required this.onTrain});

  @override
  State<BodyMuscleMapCard> createState() => _BodyMuscleMapCardState();
}

class _BodyMuscleMapCardState extends State<BodyMuscleMapCard> {
  bool _trained = true, _back = false;
  BodyDateSelection get _selection =>
      widget.selection ?? BodyDateSelection.thisWeek(DateTime.now());
  Color _color(BodyMapRegion r) {
    if (_trained) {
      return bodyTrainingColor(
          r.involvedSets, bodyTrainingBands(), BodyMapPalette.neutral);
    }
    if (r.plannedSets == 0) return BodyMapPalette.neutral;
    return r.status == 'completed'
        ? BodyMapPalette.completed
        : r.status == 'in_progress'
            ? BodyMapPalette.progress
            : BodyMapPalette.planned;
  }

  String get _period {
    if (_trained) return bodySelectionLabel(context, _selection);
    final week = bodyMapWeek(widget.week);
    return bodyDateRangeLabel(
        context, week, DateTime(week.year, week.month, week.day + 6));
  }

  Future<void> _calendar() async {
    if (!_trained) {
      final selection = await showBodyDateFilter(context,
          planned: true,
          selection: BodyDateSelection(
              mode: BodyDateMode.range,
              start: bodyMapWeek(widget.week),
              end: widget.week));
      if (selection != null && mounted) {
        widget.onWeekChanged(bodyMapWeek(selection.start!));
      }
      return;
    }
    final selection = await showBodyDateFilter(context, selection: _selection);
    if (selection != null && mounted) {
      widget.onSelectionChanged?.call(selection);
    }
  }

  Future<void> _details(String id) async {
    final region = widget.data?.regions.where((r) => r.id == id).firstOrNull;
    final selection = await showModalBottomSheet<BodyExerciseSelection>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        backgroundColor: const Color(0xFF181A1D),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: Color(0x18FFFFFF), width: .7)),
        clipBehavior: Clip.antiAlias,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        constraints: BoxConstraints(
            maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .88),
        builder: (_) => BodyMuscleDetailsSheet(
            id: id,
            region: region,
            trained: _trained,
            accent: region == null ? FitnessTheme.silver : _color(region),
            period: _period,
            workouts: widget.data?.workouts ?? []));
    if (selection != null && mounted) {
      final onSelection = widget.onExerciseSelection;
      if (onSelection != null) {
        onSelection(selection);
      } else {
        widget.onExercise(selection.exerciseId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final bands = bodyTrainingBands();
    final colors = {
      for (final r in data?.regions ?? <BodyMapRegion>[]) r.id: _color(r)
    };
    return Column(
        key: const ValueKey('body-muscle-map-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
                child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CupertinoSlidingSegmentedControl<bool>(
                        groupValue: _trained,
                        backgroundColor: const Color(0xFF17191C),
                        thumbColor: const Color(0xFF34383D),
                        padding: const EdgeInsets.all(3),
                        onValueChanged: (trained) {
                          if (trained == null || trained == _trained) return;
                          setState(() => _trained = trained);
                          widget.onModeChanged?.call(trained);
                        },
                        children: {
                          for (final trained in [true, false])
                            trained: Padding(
                                key: ValueKey(trained
                                    ? 'body-map-trained'
                                    : 'body-map-plan'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: FitnessText(
                                    trained ? 'Trained' : 'Planned',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: trained == _trained
                                            ? Colors.white
                                            : FitnessTheme.muted)))
                        }))),
            const SizedBox(width: 12),
            if (widget.loading) const CupertinoActivityIndicator(radius: 7),
            AppDateFilterButton(
                key: const ValueKey('body-calendar-button'),
                onPressed: _calendar),
          ]),
          const SizedBox(height: 14),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(_period,
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                FitnessText(
                    _trained ? '{count} sets logged' : '{count} sets planned',
                    values: {
                      'count': data == null
                          ? '—'
                          : _trained
                              ? data.loggedSets
                              : data.plannedSets
                    },
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.silver)),
              ]),
          Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 16,
                  runSpacing: 8,
                  children: _trained
                      ? [
                          for (final band in bands)
                            _legend(
                                band.color,
                                band.last == null
                                    ? fitnessText(context, '{count}+ sets',
                                        values: {'count': band.first})
                                    : fitnessText(
                                        context, '{first}–{last} sets',
                                        values: {
                                            'first': band.first,
                                            'last': band.last!
                                          })),
                        ]
                      : [
                          _legend(BodyMapPalette.planned, 'Planned'),
                          _legend(BodyMapPalette.progress, 'In progress'),
                          _legend(BodyMapPalette.completed, 'Completed'),
                        ])),
          if (widget.error != null)
            TextButton(
                onPressed: widget.onRetry,
                child: const FitnessText('Retry training data')),
          const SizedBox(height: 16),
          Semantics(
              container: true,
              customSemanticsActions: {
                for (final id
                    in musclePaths(back: _back, female: widget.female).keys)
                  CustomSemanticsAction(
                          label: fitnessText(context, bodyRegionNames[id]!)):
                      () => _details(id),
              },
              child: Center(
                  child: LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                          width:
                              (constraints.maxWidth * .66).clamp(160.0, 226.0),
                          child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              child: AnatomicalTrainingMap(
                                  key: ValueKey(_back
                                      ? 'body-back-map'
                                      : 'body-front-map'),
                                  back: _back,
                                  female: widget.female,
                                  colors: colors,
                                  satin: true,
                                  onSelected: _details)))))),
          const SizedBox(height: 12),
          Center(
              child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _back,
                  backgroundColor: const Color(0xFF141618),
                  thumbColor: const Color(0xFF34383D),
                  onValueChanged: (back) {
                    if (back != null) setState(() => _back = back);
                  },
                  children: {
                for (final back in [false, true])
                  back: Padding(
                      key:
                          ValueKey(back ? 'body-show-back' : 'body-show-front'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: FitnessText(back ? 'Back view' : 'Front view',
                          style: TextStyle(
                              fontSize: 11,
                              color: _back == back
                                  ? Colors.white
                                  : FitnessTheme.muted)))
              })),
          const SizedBox(height: 16),
          if (!_trained && data != null && !data.hasPlan) ...[
            const SizedBox(height: 12),
            const FitnessText('No plan for this week',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            if (!widget.week.isBefore(bodyMapWeek(DateTime.now())))
              TextButton(
                  onPressed: widget.onPreparePlan,
                  child: FitnessText(widget.canCreatePlan
                      ? 'Create plan'
                      : 'Add measurements')),
          ],
        ]);
  }

  Widget _legend(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        FitnessText(label,
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
      ]);
}
