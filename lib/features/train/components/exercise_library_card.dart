import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/exercise_library_copy.dart';
import '../models/workout_exercise_models.dart';
import 'exercise_thumbnail.dart';

class ExerciseLibraryCard extends StatelessWidget {
  const ExerciseLibraryCard(
      {super.key,
      required this.exercise,
      required this.picker,
      required this.selected,
      required this.added,
      required this.enabled,
      required this.onOpen,
      required this.onToggle});
  final WorkoutExerciseModel exercise;
  final bool picker, selected, added, enabled;
  final VoidCallback onOpen, onToggle;

  @override
  Widget build(BuildContext context) {
    String copy(String text) => exerciseLibraryText(context, text);
    final image = ExerciseThumbnail(exercise: exercise, size: 78);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: AnimatedContainer(
        duration: DSMotion.duration(context, DSMotion.selection),
        curve: DSMotion.standard,
        decoration: BoxDecoration(
            color: selected ? const Color(0xFF232323) : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? DSColors.borderHi : const Color(0xFF282828),
                width: .7)),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: !enabled || (picker && added)
                ? null
                : picker
                    ? onToggle
                    : onOpen,
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  if (picker)
                    Tooltip(
                        message: copy('Preview exercise'),
                        child: Semantics(
                            button: true,
                            label: copy('Preview exercise'),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: enabled ? onOpen : null,
                                child: Stack(children: [
                                  image,
                                  Positioned(
                                      right: 4,
                                      bottom: 4,
                                      child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: .7),
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                              CupertinoIcons.play_fill,
                                              size: 9,
                                              color: DSColors.silver))),
                                ]))))
                  else
                    ExcludeSemantics(child: image),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(exercise.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                            '${exercise.bodyPartLabel ?? fitnessText(context, exercise.bodyPart)} · ${exercise.equipmentLabel ?? fitnessText(context, exercise.equipment)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: DSColors.muted)),
                      ])),
                  if (picker) ...[
                    const SizedBox(width: 4),
                    IconButton(
                        key: ValueKey('add-exercise-${exercise.id}'),
                        tooltip: copy(added
                            ? 'Added'
                            : selected
                                ? 'Deselect exercise'
                                : 'Select exercise'),
                        onPressed: !enabled || added ? null : onToggle,
                        icon: Icon(
                            added || selected
                                ? CupertinoIcons.checkmark_square_fill
                                : CupertinoIcons.square,
                            size: 22,
                            color: added || selected
                                ? DSColors.silver
                                : DSColors.muted)),
                  ],
                ])),
          ),
        ),
      ),
    );
  }
}
