import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/navigation/onboarding_page_route.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../train/views/train_dashboard_view.dart';
import '../../models/planned_physique_models.dart';
import 'anatomical_training_map.dart';
import 'body_controls.dart';
import 'physique_week_filter.dart';
import '../../../../core/cache/cache_scope.dart';

class PlannedPhysiqueMap extends StatefulWidget {
  final PlannedPhysiqueData? data;
  final bool female, loading;
  final String? error;
  final VoidCallback? onRetry;
  final DateTime? selectedWeek;
  final ValueChanged<DateTime>? onWeekChanged;
  const PlannedPhysiqueMap(
      {super.key,
      this.data,
      this.female = false,
      this.loading = false,
      this.error,
      this.selectedWeek,
      this.onWeekChanged,
      this.onRetry});
  @override
  State<PlannedPhysiqueMap> createState() => _PlannedPhysiqueMapState();
}

class _PlannedPhysiqueMapState extends State<PlannedPhysiqueMap> {
  bool _back = false;
  String? _selected, _exercise;
  static const _primary = Color(0xFF8FB9F0),
      _supporting = Color(0xFF4D627F),
      _neutral = Color(0xFF30343B);
  List<PlannedPhysiqueDay> get _days => widget.data?.workouts ?? [];
  List<PlannedPhysiqueExercise> get _exercises =>
      _days.expand((d) => d.exercises).toList();

  @override
  void didUpdateWidget(PlannedPhysiqueMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _selected = null;
      _exercise = null;
    }
  }

  void _muscle(String id) {
    setState(() => _selected = id);
    final days = _days;
    final direct = _exercises
        .where((e) => e.primary.contains(id))
        .fold<int>(0, (sum, e) => sum + e.sets);
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: FitnessTheme.surface,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8),
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FitnessText(bodyRegionNames[id] ?? id,
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.6)),
                      const SizedBox(height: 6),
                      FitnessText('$direct direct sets planned for this week',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.muted)),
                      const SizedBox(height: 18),
                      if (!days.any((d) => d.exercises.any((e) =>
                          e.primary.contains(id) || e.secondary.contains(id))))
                        const FitnessText(
                            'No exercises for this area in the selected plan view.',
                            style: TextStyle(fontSize: 14, height: 1.5)),
                      for (final day in days)
                        for (final e in day.exercises)
                          if (e.primary.contains(id) ||
                              e.secondary.contains(id)) ...[
                            FitnessText('${bodyDate(day.date)} · ${day.name}',
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted)),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: FitnessText(e.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500)),
                                subtitle: FitnessText(
                                    '${e.sets} sets · ${e.targetReps} reps · ${e.primary.contains(id) ? 'Primary' : 'Supporting'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: FitnessTheme.silver)),
                                trailing: const Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() => _exercise = e.itemId);
                                }),
                            if (e.reason?.isNotEmpty == true)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: FitnessText(e.reason!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: FitnessTheme.muted))),
                            if (e.progression?.isNotEmpty == true)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: FitnessText(e.progression!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: FitnessTheme.silver))),
                            const Divider(color: FitnessTheme.line),
                          ],
                    ]))));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final exercises = _exercises;
    final selectedExercise =
        exercises.where((e) => e.itemId == _exercise).firstOrNull;
    final colors = <String, Color>{};
    for (final id in bodyRegionNames.keys) {
      final direct = exercises
          .where((e) => e.primary.contains(id))
          .fold<int>(0, (sum, e) => sum + e.sets);
      final supporting = exercises.any((e) => e.secondary.contains(id));
      colors[id] = selectedExercise != null
          ? selectedExercise.primary.contains(id)
              ? _primary
              : selectedExercise.secondary.contains(id)
                  ? _supporting
                  : _neutral
          : direct > 0
              ? _primary
              : supporting
                  ? _supporting
                  : _neutral;
    }
    final next = data?.workouts
        .where((d) =>
            !d.restDay &&
            !['COMPLETED', 'SKIPPED'].contains(d.status) &&
            d.exercises.isNotEmpty &&
            d.date.compareTo(CacheScope.todayKey(DateTime.now())) >= 0)
        .firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FitnessText('Your training blueprint',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.7)),
      const SizedBox(height: 6),
      FitnessText(
          data?.hasPlan == true
              ? 'Muscles in your selected week’s workout plan.'
              : 'No saved workout plan for this week.',
          style: const TextStyle(
              fontSize: 12, height: 1.5, color: FitnessTheme.muted)),
      const SizedBox(height: 16),
      if (widget.selectedWeek != null && widget.onWeekChanged != null) ...[
        PhysiqueWeekFilter(
            selected: widget.selectedWeek!, onChanged: widget.onWeekChanged!),
        const SizedBox(height: 16),
      ],
      FitnessCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              SizedBox(
                  width: 108,
                  child: BodySegment(
                      labels: const ['Front', 'Back'],
                      selected: _back ? 1 : 0,
                      onChanged: (index) =>
                          setState(() => _back = index == 1))),
            ]),
            SizedBox(
                height: 340,
                child: AnatomicalTrainingMap(
                    female: data?.gender == 'FEMALE' || widget.female,
                    back: _back,
                    colors: colors,
                    selected: _selected,
                    onSelected: _muscle)),
            const Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  BodyLegend(_primary, 'Primary'),
                  BodyLegend(_supporting, 'Supporting'),
                ]),
            const SizedBox(height: 10),
            const FitnessText('Tap a muscle to see its planned exercises.',
                style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          ])),
      if (widget.loading)
        const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Center(child: CupertinoActivityIndicator())),
      if (widget.error != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitnessText(widget.error!,
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              TextButton(
                  onPressed: widget.onRetry,
                  child: const FitnessText('Retry plan map')),
            ])),
      if (data?.hasPlan == true && exercises.isEmpty)
        const Padding(
            padding: EdgeInsets.only(top: 14),
            child: FitnessText('No scheduled exercises in this week.',
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: FitnessTheme.muted))),
      if (selectedExercise != null)
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: FitnessCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        FitnessText(selectedExercise.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        FitnessText(
                            '${selectedExercise.sets} sets · ${selectedExercise.targetReps} reps',
                            style: const TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                      ])),
                  IconButton(
                      tooltip: 'Show all planned exercises',
                      onPressed: () => setState(() => _exercise = null),
                      icon: const Icon(CupertinoIcons.xmark, size: 15)),
                ]))),
      if (exercises.isNotEmpty) ...[
        const SizedBox(height: 18),
        const FitnessText('Explore your exercises',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
            height: 42,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final e = exercises[index];
                  return ChoiceChip(
                      label: FitnessText(e.name,
                          style: const TextStyle(fontSize: 11)),
                      selected: selectedExercise?.itemId == e.itemId,
                      showCheckmark: false,
                      selectedColor: _supporting,
                      onSelected: (_) => setState(() {
                            _exercise = selectedExercise?.itemId == e.itemId
                                ? null
                                : e.itemId;
                            if (_exercise != null &&
                                e.primary.any((id) => [
                                      'upper_back',
                                      'lats',
                                      'lower_back',
                                      'glutes',
                                      'hamstrings'
                                    ].contains(id))) {
                              _back = true;
                            } else if (_exercise != null) {
                              _back = false;
                            }
                          }));
                })),
      ],
      if (next != null) ...[
        const SizedBox(height: 18),
        FitnessCard(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitnessText('NEXT WORKOUT · ${bodyDate(next.date)}',
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: .8,
                      color: FitnessTheme.muted)),
              const SizedBox(height: 8),
              FitnessText(next.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              FitnessText('${next.exercises.length} exercises',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(AppPageRoute<void>(
                        page: TrainView(
                            standalone: true, initialDate: next.date)));
                    if (mounted) widget.onRetry?.call();
                  },
                  icon: const Icon(CupertinoIcons.arrow_right, size: 16),
                  label: const FitnessText('Open workout')),
            ])),
      ],
    ]);
  }
}
