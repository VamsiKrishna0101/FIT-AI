import 'package:setcraft/core/theme/ds_motion.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/motion.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/theme/ds_colors.dart';
import '../../../../core/theme/fitness_accents.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/training_map_models.dart';
import 'anatomical_training_map.dart';

/// A group counts direct muscle sets, not unique sets across a workout.
class MuscleCoverageGroup {
  final String id, label;
  final List<MuscleRegion> regions;
  const MuscleCoverageGroup(this.id, this.label, this.regions);
  int get completed =>
      regions.fold(0, (total, region) => total + region.completedSets);
  int get target =>
      regions.fold(0, (total, region) => total + region.targetSets);
  double? get progress =>
      target > 0 ? (completed / target).clamp(0.0, 1.0) : null;
  static List<MuscleCoverageGroup> fromRegions(List<MuscleRegion> regions) {
    const groups = <String, (String, List<String>)>{
      'chest': ('Chest', ['chest']),
      'back': ('Back', ['upper_back', 'lats', 'lower_back']),
      'shoulders': ('Shoulders', ['shoulders']),
      'arms': ('Arms', ['biceps', 'triceps', 'forearms']),
      'legs': ('Legs', ['glutes', 'quads', 'hamstrings', 'calves']),
      'core': ('Core', ['core']),
    };
    return [
      for (final entry in groups.entries)
        MuscleCoverageGroup(
            entry.key,
            entry.value.$1,
            regions
                .where((region) => entry.value.$2.contains(region.id))
                .toList())
    ];
  }
}

class WeeklyMuscleCoverage extends StatelessWidget {
  final List<MuscleRegion> regions;
  final bool daily, female;
  final ValueChanged<String> onSelect;
  final VoidCallback? onTrain;
  const WeeklyMuscleCoverage(
      {super.key,
      required this.regions,
      required this.onSelect,
      this.daily = false,
      this.female = false,
      this.onTrain});

  String _sets(BuildContext context, int value) => NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag())
      .format(value);
  String _description(BuildContext context, MuscleCoverageGroup group) =>
      group.target > 0
          ? fitnessText(context, '{completed} of {target} planned sets',
              values: {
                  'completed': _sets(context, group.completed),
                  'target': _sets(context, group.target)
                })
          : group.completed == 0
              ? fitnessText(context, 'Not trained yet')
              : fitnessText(context, '{count} sets',
                  values: {'count': _sets(context, group.completed)});

  Future<void> _open(BuildContext context, MuscleCoverageGroup group) async {
    if (group.regions.isEmpty) return;
    if (group.regions.length == 1) {
      onSelect(group.regions.single.id);
      return;
    }
    final selected = await showModalBottomSheet<String>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: DSColors.bgElevated,
        builder: (sheetContext) => FitnessTheme(
            child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fitnessText(context, group.label),
                              style: const TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(_description(context, group),
                              style: const TextStyle(
                                  fontSize: 14, color: FitnessTheme.muted)),
                          const SizedBox(height: 20),
                          for (final region in group.regions)
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(region.id),
                                title: Text(fitnessText(context, region.label),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                        _description(
                                            context,
                                            MuscleCoverageGroup(region.id,
                                                region.label, [region])),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: FitnessTheme.muted))),
                                trailing: const Icon(Icons.chevron_right,
                                    size: 19, color: FitnessTheme.muted)),
                          const SizedBox(height: 8),
                          Text(
                              fitnessText(context,
                                  'Direct muscle sets · assisting sets are separate.'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: FitnessTheme.muted)),
                        ])))));
    if (context.mounted && selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    final groups = MuscleCoverageGroup.fromRegions(regions);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(fitnessText(context, daily ? 'Daily coverage' : 'Weekly coverage'),
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -.4)),
      const SizedBox(height: 7),
      Text(
          fitnessText(
              context, 'Direct muscle sets · assisting sets are separate.'),
          style: const TextStyle(
              fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, box) {
        final textSize = MediaQuery.textScalerOf(context).scale(14);
        final columns = box.maxWidth < 280 || textSize > 22
            ? 1
            : box.maxWidth >= 340 && textSize <= 18
                ? 3
                : 2;
        return Column(children: [
          for (var start = 0; start < groups.length; start += columns) ...[
            if (start > 0) const SizedBox(height: 10),
            IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  for (var i = start;
                      i < math.min(start + columns, groups.length);
                      i++) ...[
                    if (i > start) const SizedBox(width: 10),
                    Expanded(child: _card(context, groups[i])),
                  ],
                ])),
          ],
        ]);
      }),
      if (regions.every((region) => region.completedSets == 0) &&
          onTrain != null) ...[
        const SizedBox(height: 12),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: onTrain,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(fitnessText(context, 'Open Train')))),
      ],
    ]);
  }

  Widget _card(BuildContext context, MuscleCoverageGroup group) {
    const accent = FitnessAccents.mint;
    final caption = _description(context, group);
    return Semantics(
        button: group.regions.isNotEmpty,
        label: '${fitnessText(context, group.label)}. $caption',
        child: ExcludeSemantics(
            child: MotionPress(
                child: Material(
                    color: DSColors.bgCard,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                            color: DSColors.border, width: .7)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: group.regions.isEmpty
                            ? null
                            : () => _open(context, group),
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fitnessText(context, group.label),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.3)),
                                  const SizedBox(height: 10),
                                  Center(
                                      child: SizedBox(
                                          width: 58,
                                          height: 58,
                                          child: group.progress == null
                                              ? Center(
                                                  child: SizedBox(
                                                      width: 29,
                                                      height: 58,
                                                      child: IgnorePointer(
                                                          child: AnatomicalMuscleIllustration(
                                                              female: female,
                                                              back: group.id ==
                                                                  'back',
                                                              colors: {
                                                            for (final region
                                                                in group
                                                                    .regions)
                                                              region.id: region
                                                                          .completedSets >
                                                                      0
                                                                  ? accent
                                                                  : FitnessAccents
                                                                      .rank(0)
                                                          }))))
                                              : MotionValue(
                                                  value: group.progress!,
                                                  builder: (context, progress) => CustomPaint(
                                                      painter: _CoverageRing(
                                                          progress, accent),
                                                      child: Center(
                                                          child: Text(
                                                              _sets(
                                                                  context,
                                                                  group
                                                                      .completed),
                                                              style: const TextStyle(
                                                                  fontSize: 22,
                                                                  fontWeight: FontWeight
                                                                      .w600,
                                                                  letterSpacing:
                                                                      -.8))))))),
                                  const SizedBox(height: 10),
                                  Text(caption,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500)),
                                  if (group.target == 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                        fitnessText(
                                            context, 'No planned target'),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: FitnessTheme.muted)),
                                  ],
                                ])))))));
  }
}

class _CoverageRing extends CustomPainter {
  final double progress;
  final Color color;
  const _CoverageRing(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final track = Paint()
      ..color = DSColors.bgRaised
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [color.withValues(alpha: .65), color]).createShader(bounds);
    canvas.drawArc(bounds, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1),
        false, stroke);
  }

  @override
  bool shouldRepaint(_CoverageRing old) =>
      old.progress != progress || old.color != color;
}
