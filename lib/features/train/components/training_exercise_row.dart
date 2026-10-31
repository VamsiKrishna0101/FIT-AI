import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/ds_colors.dart';
import 'exercise_thumbnail.dart';
import '../models/workout_exercise_models.dart';

/// A preview has one destination. Editing controls belong to the editor.
class TrainingExerciseRow extends StatelessWidget {
  const TrainingExerciseRow(
      {super.key,
      required this.item,
      required this.subtitle,
      required this.onTap,
      this.trailing});
  final TodayPlanItemModel item;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            ExerciseThumbnail(exercise: item.exercise, size: 52),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.exercise.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, height: 1.4, color: DSColors.muted)),
                ])),
            const SizedBox(width: 8),
            trailing ??
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: DSColors.muted),
          ]),
        ),
      );
}
