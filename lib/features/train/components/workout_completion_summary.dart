import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/training_session.dart';
import 'training_widgets.dart';

class WorkoutCompletionSummary extends StatelessWidget {
  final TrainingDay day;
  final VoidCallback onEdit, onRetry;
  const WorkoutCompletionSummary(
      {super.key,
      required this.day,
      required this.onEdit,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    String copy(String text, {Map<String, Object> values = const {}}) =>
        fitnessText(context, text, values: values);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime.tryParse(day.date);
    final completed = day.items.where((item) => item.isCompleted).length;
    final volume = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = day.volume < 1 ? 4 : 1;
    final stats = [
      (
        copy('Duration'),
        '${(day.durationSeconds / 60).ceil()}',
        copy('min'),
        CupertinoIcons.clock
      ),
      (
        copy('Logged sets'),
        '${day.loggedSets}',
        '',
        CupertinoIcons.square_stack_3d_up
      ),
      (copy('Reps logged'), '${day.loggedReps}', '', CupertinoIcons.repeat),
      if (day.loadedSets > 0)
        (
          copy('Volume'),
          volume.format(day.volume),
          'kg',
          CupertinoIcons.chart_bar
        )
      else
        (
          copy('Exercises completed'),
          '$completed',
          '/ ${day.items.length}',
          CupertinoIcons.checkmark_circle
        ),
    ];
    return ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: DSColors.accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(CupertinoIcons.checkmark,
                    size: 21, color: DSColors.accent)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    date == null
                        ? day.date
                        : DateFormat.yMMMEd(locale).format(date),
                    style:
                        const TextStyle(color: DSColors.muted, fontSize: 12))),
          ]),
          const SizedBox(height: 22),
          Text(
              copy(day.pendingSync
                  ? 'Workout saved on this phone'
                  : 'Workout complete'),
              style: const TextStyle(
                  fontSize: 31,
                  height: 1.12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1)),
          const SizedBox(height: 10),
          Text(day.name == 'Workout' ? copy('Your workout') : day.name,
              style: const TextStyle(
                  fontSize: 17, color: DSColors.muted, height: 1.4)),
          const SizedBox(height: 24),
          if (day.pendingSync) ...[
            WorkoutSyncNotice(blocked: day.syncBlocked, onRetry: onRetry),
            const SizedBox(height: 16)
          ],
          LayoutBuilder(builder: (context, constraints) {
            final columns =
                MediaQuery.textScalerOf(context).scale(14) > 21 ? 1 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final stat in stats)
                SizedBox(
                    width: width,
                    child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: DSColors.bgElevated,
                            border: Border.all(color: DSColors.border),
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(stat.$4, size: 17, color: DSColors.muted),
                              const SizedBox(height: 16),
                              Text(
                                  '${stat.$2}${stat.$3.isEmpty ? '' : ' ${stat.$3}'}',
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -.6)),
                              const SizedBox(height: 6),
                              Text(stat.$1,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: DSColors.muted,
                                      height: 1.4)),
                            ])))
            ]);
          }),
          if (day.missingLoadSets > 0)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                    copy(
                        'Some sets have no recorded load. Edit your sets to complete the volume.'),
                    style: const TextStyle(
                        fontSize: 12, color: DSColors.coral, height: 1.5))),
          if (day.loggedSets > 0 &&
              day.loadedSets == 0 &&
              day.missingLoadSets == 0)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(copy('Bodyweight session'),
                    style:
                        const TextStyle(fontSize: 12, color: DSColors.muted))),
          if (day.loggedSets == 0)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                    copy('No sets were logged. Your body map is unchanged.'),
                    style: const TextStyle(
                        fontSize: 12, color: DSColors.muted, height: 1.5))),
          const SizedBox(height: 26),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(copy('Exercise breakdown'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(CupertinoIcons.pencil, size: 14),
                    label: Text(copy('Edit logged sets'),
                        style: const TextStyle(fontSize: 12)),
                    style:
                        TextButton.styleFrom(foregroundColor: DSColors.silver)),
              ]),
          const SizedBox(height: 8),
          for (final item in day.items)
            Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                    color: DSColors.bgElevated,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: DSColors.border)),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 15),
                          leading: Icon(
                              item.isSkipped
                                  ? CupertinoIcons.arrow_turn_down_right
                                  : CupertinoIcons.checkmark_circle_fill,
                              color: item.isSkipped
                                  ? DSColors.muted
                                  : DSColors.accent,
                              size: 21),
                          title: Text(item.exercise.displayName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4)),
                          subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  item.isSkipped
                                      ? copy('Skipped')
                                      : copy('{sets} sets · {reps} reps',
                                          values: {
                                              'sets': day.logs(item.id).length,
                                              'reps': day.logs(item.id).fold<
                                                      int>(
                                                  0,
                                                  (sum, set) =>
                                                      sum +
                                                      (set['reps'] as num? ?? 0)
                                                          .toInt())
                                            }),
                                  style: const TextStyle(
                                      fontSize: 12, color: DSColors.muted))),
                          children: [
                            for (final log in day.logs(item.id))
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 32,
                                        child: Text(
                                            '${log['setNumber']}'
                                                .padLeft(2, '0'),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: DSColors.muted))),
                                    Expanded(
                                        child: Text(
                                            copy('{count} reps', values: {
                                              'count': log['reps'] ?? 0
                                            }),
                                            style:
                                                const TextStyle(fontSize: 13))),
                                    Text(
                                        log['weight'] == null
                                            ? '—'
                                            : '${log['weight']} kg',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: DSColors.silver)),
                                  ]))
                          ],
                        )))),
        ]);
  }
}
