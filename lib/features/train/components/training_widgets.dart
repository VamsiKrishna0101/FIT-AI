import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/workout_exercise_models.dart';
import '../views/exercise_library_screen.dart';

const trainingSilver = Color(0xFFE2E2E2);
const trainingMuted = Color(0xFF999999);

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
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap, child: Padding(padding: padding, child: child)),
      );
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
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? trainingSilver : const Color(0xFF303030),
          foregroundColor: primary ? const Color(0xFF111111) : trainingSilver,
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
      );
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
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF202020),
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
