import '../../../core/theme/fitness_accents.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../body_scan/views/widgets/anatomical_training_map.dart';
import '../models/workout_exercise_models.dart';

/// Canonical catalogue tags, never translated display names.
Set<String> exerciseMuscleIds(Iterable<String> tags) {
  const aliases = {
    'chest': ['chest', 'pectorals', 'pectoral', 'pecs'],
    'shoulders': ['shoulders', 'shoulder', 'delts', 'deltoids', 'deltoid'],
    'biceps': ['biceps', 'bicep', 'brachialis'],
    'triceps': ['triceps', 'tricep'],
    'forearms': ['forearms', 'forearm', 'wrist flexors', 'wrist extensors'],
    'lats': ['lats', 'latissimus dorsi', 'latissimus'],
    'upper_back': ['upper back', 'traps', 'trapezius', 'rhomboids'],
    'lower_back': [
      'lower back',
      'erector spinae',
      'erectors',
      'spinal erectors'
    ],
    'core': ['abs', 'abdominals', 'abdominal', 'core', 'obliques'],
    'glutes': ['glutes', 'gluteus maximus', 'gluteus medius', 'gluteal'],
    'quads': ['quads', 'quadriceps', 'quadricep'],
    'hamstrings': ['hamstrings', 'hamstring'],
    'calves': ['calves', 'calf', 'gastrocnemius', 'soleus'],
  };
  final muscles = <String>{};
  for (final tag in tags) {
    final text =
        ' ${tag.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim()} ';
    for (final entry in aliases.entries) {
      if (entry.value.any((alias) => text.contains(' $alias '))) {
        muscles.add(entry.key);
      }
    }
  }
  return muscles;
}

class ExerciseMuscleMap extends StatefulWidget {
  final WorkoutExerciseModel exercise;
  final bool female;
  const ExerciseMuscleMap(
      {super.key, required this.exercise, this.female = false});

  @override
  State<ExerciseMuscleMap> createState() => _ExerciseMuscleMapState();
}

class _ExerciseMuscleMapState extends State<ExerciseMuscleMap> {
  bool? _back;

  @override
  void didUpdateWidget(ExerciseMuscleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) _back = null;
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    var primary = exerciseMuscleIds([exercise.target]);
    if (primary.isEmpty) {
      primary =
          exerciseMuscleIds([exercise.muscleGroup ?? '', exercise.bodyPart]);
    }
    final secondary = exerciseMuscleIds(exercise.secondaryMuscles)
      ..removeAll(primary);
    final targets = {...primary, ...secondary};
    final frontPaths = musclePaths(back: false, female: widget.female);
    final backPaths = musclePaths(back: true, female: widget.female);
    final hasFront = targets.any(frontPaths.containsKey);
    final hasBack = targets.any(backPaths.containsKey);
    final preferBack = primary.any({
      'triceps',
      'upper_back',
      'lats',
      'lower_back',
      'glutes',
      'hamstrings'
    }.contains);
    final back = _back ?? (hasBack && (preferBack || !hasFront));
    final paths = back ? backPaths : frontPaths;
    final visiblePrimary = primary.where(paths.containsKey).toSet();
    final visibleTargets = targets.where(paths.containsKey).toSet();
    final focus = visiblePrimary.isNotEmpty ? visiblePrimary : visibleTargets;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(fitnessText(context, 'Target muscles'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600))),
        if (hasFront && hasBack)
          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontSize: 11),
              side: BorderSide.none,
              selectedBackgroundColor: DSColors.bgRaised,
              selectedForegroundColor: DSColors.silver,
            ),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: false, label: Text(fitnessText(context, 'Front'))),
              ButtonSegment(
                  value: true, label: Text(fitnessText(context, 'Back'))),
            ],
            selected: {back},
            onSelectionChanged: (selection) =>
                setState(() => _back = selection.first),
          ),
      ]),
      const SizedBox(height: 12),
      if (focus.isNotEmpty)
        Semantics(
          image: true,
          label:
              '${fitnessText(context, back ? 'Back muscle map' : 'Front muscle map')}: ${exercise.targetLabel ?? exercise.target}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: DSColors.bg,
              child: SizedBox(
                key: const ValueKey('exercise-cropped-map'),
                width: double.infinity,
                height: 218,
                child: RepaintBoundary(
                    child: CustomPaint(
                  painter:
                      ExerciseMusclePainter(paths, primary, secondary, focus),
                )),
              ),
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(fitnessText(context, 'Muscle map unavailable'),
              style: const TextStyle(color: DSColors.muted, fontSize: 12)),
        ),
      const SizedBox(height: 14),
      _MuscleLabel(
          exercise.targetLabel ?? fitnessText(context, exercise.target),
          primary.isEmpty
              ? FitnessAccents.coral
              : FitnessAccents.muscle(primary.first)),
      if (exercise.secondaryMuscles.isNotEmpty) ...[
        const SizedBox(height: 9),
        _MuscleLabel(
          (exercise.secondaryMuscleLabels ??
                  exercise.secondaryMuscles
                      .map((value) => fitnessText(context, value))
                      .toList())
              .join(' · '),
          FitnessAccents.blue,
          label: fitnessText(context, 'Secondary muscles'),
        ),
      ],
    ]);
  }
}

class _MuscleLabel extends StatelessWidget {
  final String text;
  final Color color;
  final String? label;
  const _MuscleLabel(this.text, this.color, {this.label});

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )),
        const SizedBox(width: 9),
        Expanded(
            child: Text(label == null ? text : '$label · $text',
                style: TextStyle(
                    color: label == null ? DSColors.silver : DSColors.muted,
                    fontSize: 12,
                    height: 1.45))),
      ]);
}

/// Uses the Body tab's existing anatomical paths and crops around the target.
class ExerciseMusclePainter extends CustomPainter {
  final Map<String, List<Path>> paths;
  final Set<String> primary, secondary, focus;
  ExerciseMusclePainter(this.paths, this.primary, this.secondary, this.focus);

  Rect get viewport {
    final bounds = focus
        .expand((id) => paths[id] ?? <Path>[])
        .map((path) => path.getBounds());
    final box = bounds.reduce((a, b) => a.expandToInclude(b));
    return Rect.fromCenter(
        center: box.center,
        width: math.max(110, box.width + 32),
        height: math.max(100, box.height + 30));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final box = viewport;
    final scale = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-box.center.dx, -box.center.dy);
    final fill = Paint();
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .45;
    for (final entry in paths.entries) {
      final color = primary.contains(entry.key)
          ? FitnessAccents.muscle(entry.key)
          : secondary.contains(entry.key)
              ? FitnessAccents.blue.withValues(alpha: .65)
              : const Color(0xFF25282C);
      for (final path in entry.value) {
        canvas.drawPath(path, fill..color = color);
        canvas.drawPath(path,
            outline..color = const Color(0xFF747A80).withValues(alpha: .35));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ExerciseMusclePainter old) => true;
}
