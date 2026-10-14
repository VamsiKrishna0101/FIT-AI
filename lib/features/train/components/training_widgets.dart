import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/workout_exercise_models.dart';
import '../views/exercise_library_screen.dart';

const trainingSilver = DSColors.silver;
const trainingMuted = DSColors.muted;

class TrainingSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const TrainingSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.onTap});

  @override
  Widget build(BuildContext context) => MotionPress(
      enabled: onTap != null,
      child: Material(
        color: DSColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: DSColors.border, width: .7),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap, child: Padding(padding: padding, child: child)),
      ));
}

class TrainingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  const TrainingButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.primary = false,
      this.icon});
  @override
  Widget build(BuildContext context) => MotionPress(
      enabled: onPressed != null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? trainingSilver : const Color(0xFF303030),
          foregroundColor: primary ? DSColors.bg : trainingSilver,
          disabledBackgroundColor: const Color(0xFF282828),
          disabledForegroundColor: trainingMuted,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17),
                const SizedBox(width: 7)
              ],
              Flexible(
                  child: Text(fitnessText(context, label),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))),
            ]),
      ));
}

class TrainingPoster extends StatelessWidget {
  final WorkoutExerciseModel exercise;
  final double size;
  const TrainingPoster({super.key, required this.exercise, this.size = 48});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
          width: size,
          height: size,
          child: exercise.thumbnailUrl == null
              ? const ColoredBox(
                  color: Color(0xFF303030),
                  child: Icon(CupertinoIcons.sportscourt, color: trainingMuted))
              : CachedNetworkImage(
                  imageUrl: exercise.thumbnailUrl!,
                  fit: BoxFit.contain,
                  memCacheWidth: 174,
                  memCacheHeight: 174,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFF303030)),
                  errorWidget: (_, __, ___) => const Icon(
                      CupertinoIcons.sportscourt,
                      color: trainingMuted))));
}

Future<String?> trainingName(
    BuildContext context, String title, String initial) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
      animationStyle: DSMotion.dialogStyle(context),
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: DSColors.bgCard,
            title: Text(fitnessText(context, title)),
            content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration:
                    InputDecoration(labelText: fitnessText(context, 'Name'))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(fitnessText(context, 'Cancel'))),
              TextButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) Navigator.pop(context, value);
                  },
                  child: Text(fitnessText(context, 'Save'))),
            ],
          ));
  Future<void>.delayed(const Duration(milliseconds: 300), controller.dispose);
  return result;
}

Future<WorkoutExerciseModel?> pickTrainingExercise(BuildContext context) =>
    Navigator.of(context).push<WorkoutExerciseModel>(MaterialPageRoute(
        builder: (pickerContext) => ExerciseLibraryView(
            onExerciseAdded: () {},
            onSelect: (exercise) =>
                Navigator.of(pickerContext).pop(exercise))));

class WorkoutSyncNotice extends StatelessWidget {
  final bool blocked;
  final VoidCallback onRetry;
  const WorkoutSyncNotice(
      {super.key, this.blocked = false, required this.onRetry});

  @override
  Widget build(BuildContext context) => TrainingSurface(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              fitnessText(context,
                  blocked ? 'Sync needs attention' : 'Saved on this phone'),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
              fitnessText(
                  context,
                  blocked
                      ? 'The server could not accept this workout. Reconnect and retry.'
                      : 'Waiting to sync. Body and Progress update after syncing.'),
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: trainingMuted)),
          TextButton(
              onPressed: onRetry, child: Text(fitnessText(context, 'Retry'))),
        ]),
      );
}
