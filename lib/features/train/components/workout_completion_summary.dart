import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import 'exercise_thumbnail.dart';
import 'training_widgets.dart';

/// A completed session uses the same surfaces and scale as the Train dashboard.
class WorkoutCompletionSummary extends StatelessWidget {
  final TrainingDay day;
  final VoidCallback onEdit, onRetry;
  final VoidCallback? onAddPhoto;
  const WorkoutCompletionSummary(
      {super.key,
      required this.day,
      required this.onEdit,
      this.onAddPhoto,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    String copy(String text, {Map<String, Object> values = const {}}) =>
        fitnessText(context, text, values: values);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime.tryParse(day.date);
    final items = day.items;
    final completed = items.where((item) => item.isCompleted).length;
    final volume = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = day.volume < 1 ? 4 : 1;
    final stats = [
      (
        copy('Duration'),
        '${(day.durationSeconds / 60).ceil()} ${copy('min')}',
        CupertinoIcons.clock
      ),
      (
        copy('Logged sets'),
        '${day.loggedSets}',
        CupertinoIcons.square_stack_3d_up
      ),
      (copy('Reps logged'), '${day.loggedReps}', CupertinoIcons.repeat),
      day.loadedSets > 0
          ? (
              copy('Volume'),
              '${volume.format(day.volume)} kg',
              CupertinoIcons.chart_bar
            )
          : (
              copy('Exercises completed'),
              '$completed / ${items.length}',
              CupertinoIcons.checkmark_circle
            ),
    ];
    final note = day.missingLoadSets > 0
        ? 'Some sets have no recorded load. Edit your sets to complete the volume.'
        : day.loggedSets == 0
            ? 'No sets were logged. Your body map is unchanged.'
            : day.loadedSets == 0
                ? 'Bodyweight session'
                : null;
    return ListView(
      key: const ValueKey('workout-summary-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        TrainingSurface(
          key: const ValueKey('workout-summary-overview'),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        day.pendingSync ? DSColors.bgRaised : DSColors.silver,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        day.pendingSync
                            ? CupertinoIcons.arrow_up_circle
                            : CupertinoIcons.check_mark,
                        size: 12,
                        color: day.pendingSync ? DSColors.silver : DSColors.bg),
                    const SizedBox(width: 5),
                    Flexible(
                        child: Text(
                      copy(day.pendingSync
                          ? 'Workout saved on this phone'
                          : 'Workout complete'),
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color:
                              day.pendingSync ? DSColors.silver : DSColors.bg),
                    )),
                  ]),
                ),
                Text(
                    date == null
                        ? day.date
                        : DateFormat.yMMMEd(locale).format(date),
                    style: const TextStyle(
                        fontSize: 11, color: DSColors.muted, height: 1.4)),
              ],
            ),
            const SizedBox(height: 18),
            Semantics(
                header: true,
                child: Text(
                  day.name == 'Workout' ? copy('Your workout') : day.name,
                  style: const TextStyle(
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.65),
                )),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, bounds) {
              final columns = MediaQuery.textScalerOf(context).scale(14) > 21 ||
                      bounds.maxWidth < 250
                  ? 1
                  : 2;
              final width = (bounds.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < stats.length; i++)
                  SizedBox(
                      width: width,
                      child: _SummaryMetric(
                        key: ValueKey('workout-summary-stat-$i'),
                        label: stats[i].$1,
                        value: stats[i].$2,
                        icon: stats[i].$3,
                      )),
              ]);
            }),
            if (note != null) ...[
              const SizedBox(height: 16),
              Text(copy(note),
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: day.missingLoadSets > 0
                          ? DSColors.silver
                          : DSColors.muted)),
            ],
          ]),
        ),
        if (day.pendingSync) ...[
          const SizedBox(height: 14),
          WorkoutSyncNotice(blocked: day.syncBlocked, onRetry: onRetry),
        ],
        if (onAddPhoto != null) ...[
          const SizedBox(height: 14),
          TrainingSurface(
              child: Row(children: [
            const Icon(CupertinoIcons.camera, color: DSColors.silver, size: 24),
            const SizedBox(width: 12),
            Expanded(
                child: Text(copy('Capture your progress'),
                    style:
                        const TextStyle(color: DSColors.silver, fontSize: 14))),
            TextButton(
                onPressed: onAddPhoto,
                child: Text(copy('Add photo'),
                    style: const TextStyle(color: DSColors.silver))),
          ])),
        ],
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Semantics(
                header: true,
                child: Text(copy('Exercises'),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.3))),
            TextButton(
              key: const ValueKey('workout-summary-edit'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                  foregroundColor: DSColors.silver,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text(copy('Edit logged sets'),
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          TrainingSurface(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: DSColors.border),
                _ExerciseSummary(
                  key: ValueKey('workout-summary-exercise-${items[i].id}'),
                  item: items[i],
                  logs: day.logs(items[i].id),
                ),
              ],
            ]),
          ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryMetric(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: DSColors.bgRaised, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.5))),
            const SizedBox(width: 8),
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(icon, size: 14, color: DSColors.muted)),
          ]),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: DSColors.muted, height: 1.4)),
        ]),
      );
}

class _ExerciseSummary extends StatefulWidget {
  final TodayPlanItemModel item;
  final List<Map<String, dynamic>> logs;
  const _ExerciseSummary({super.key, required this.item, required this.logs});

  @override
  State<_ExerciseSummary> createState() => _ExerciseSummaryState();
}

class _ExerciseSummaryState extends State<_ExerciseSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final logs = [
      ...widget.logs
    ]..sort((a, b) => (a['setNumber'] as num).compareTo(b['setNumber'] as num));
    final reps = logs.fold<int>(
        0, (sum, log) => sum + (log['reps'] as num? ?? 0).toInt());
    final subtitle = item.isSkipped
        ? fitnessText(context, 'Skipped')
        : fitnessText(context, '{sets} sets · {reps} reps',
            values: {'sets': logs.length, 'reps': reps});
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: DSColors.muted,
        collapsedIconColor: DSColors.muted,
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        expansionAnimationStyle: DSMotion.sheetStyle(context),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        leading: ExerciseThumbnail(exercise: item.exercise, size: 48),
        title: Text(item.exercise.displayName,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: DSColors.silver)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                  item.isSkipped
                      ? CupertinoIcons.arrow_turn_down_right
                      : item.isCompleted
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                  size: 12,
                  color: item.isCompleted ? DSColors.silver : DSColors.muted),
            ),
            const SizedBox(width: 5),
            Expanded(
                child: Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: DSColors.muted, height: 1.4))),
          ]),
        ),
        trailing: AnimatedRotation(
          turns: _expanded ? .5 : 0,
          duration: DSMotion.duration(context, DSMotion.fast),
          curve: DSMotion.effects,
          child: const Icon(CupertinoIcons.chevron_down,
              size: 12, color: DSColors.muted),
        ),
        children: [
          if (logs.isEmpty)
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(fitnessText(context, 'No sets logged'),
                    style: const TextStyle(
                        fontSize: 12, color: DSColors.muted, height: 1.4)))
          else
            _SetTable(item: item, logs: logs),
        ],
      ),
    );
  }
}

class _SetTable extends StatelessWidget {
  final TodayPlanItemModel item;
  final List<Map<String, dynamic>> logs;
  const _SetTable({required this.item, required this.logs});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag())
      ..maximumFractionDigits = 2;
    String load(Map<String, dynamic> log) {
      final weight = log['weight'] as num?;
      if (item.isBodyweight && (weight == null || weight <= 0)) {
        return fitnessText(context, 'Bodyweight');
      }
      return weight == null ? '—' : '${format.format(weight)} kg';
    }

    Widget row(List<String> values, {bool header = false}) => Padding(
          padding: EdgeInsets.symmetric(vertical: header ? 0 : 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                  flex: i == 0 ? 1 : 2,
                  child: Text(values[i],
                      textAlign: i == 2 ? TextAlign.end : TextAlign.start,
                      style: TextStyle(
                          fontSize: header ? 10 : 12,
                          height: 1.4,
                          fontWeight:
                              header ? FontWeight.w500 : FontWeight.w400,
                          color: header ? DSColors.muted : DSColors.silver))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      decoration: BoxDecoration(
          color: DSColors.bgRaised, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        row([
          fitnessText(context, 'Set'),
          fitnessText(context, 'Reps'),
          fitnessText(context, 'Load')
        ], header: true),
        const SizedBox(height: 6),
        for (var i = 0; i < logs.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: DSColors.border),
          row([
            format.format(logs[i]['setNumber']),
            format.format(logs[i]['reps'] ?? 0),
            load(logs[i])
          ]),
        ],
      ]),
    );
  }
}
