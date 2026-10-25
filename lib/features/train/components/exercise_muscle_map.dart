import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import 'graphite_anatomy.dart';
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
  final bool anatomyReady;
  const ExerciseMuscleMap(
      {super.key,
      required this.exercise,
      this.female = false,
      this.anatomyReady = true});

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
    final frontPaths = graphiteMusclePaths(back: false, female: widget.female);
    final backPaths = graphiteMusclePaths(back: true, female: widget.female);
    final hasFront = targets.any(frontPaths.containsKey);
    final hasBack = targets.any(backPaths.containsKey);
    final preferBack = primary.any({
      'triceps',
      'upper_back',
      'lats',
      'lower_back',
      'glutes',
      'hamstrings',
      'calves'
    }.contains);
    final back = _back ?? (hasBack && (preferBack || !hasFront));
    final paths = back ? backPaths : frontPaths;
    final visiblePrimary = primary.where(paths.containsKey).toSet();
    final visibleTargets = targets.where(paths.containsKey).toSet();
    final focus = visiblePrimary.isNotEmpty ? visiblePrimary : visibleTargets;

    String muscleLabel(String id) => fitnessText(
        context,
        switch (id) {
          'chest' => 'Chest',
          'shoulders' => 'Shoulders',
          'biceps' => 'Biceps',
          'triceps' => 'Triceps',
          'forearms' => 'Forearms',
          'lats' => 'Lats',
          'upper_back' => 'Upper back',
          'lower_back' => 'Lower back',
          'core' => 'Core',
          'glutes' => 'Glutes',
          'quads' => 'Quads',
          'hamstrings' => 'Hamstrings',
          'calves' => 'Calves',
          _ => id,
        });
    final primaryText = primary.isNotEmpty
        ? primary.map(muscleLabel).join(' · ')
        : exercise.targetLabel ?? fitnessText(context, exercise.target);
    final secondaryText = secondary.isNotEmpty
        ? secondary.map(muscleLabel).join(' · ')
        : (exercise.secondaryMuscleLabels ??
                exercise.secondaryMuscles
                    .map((value) => fitnessText(context, value))
                    .toList())
            .join(' · ');
    final knownTargets = hasFront || hasBack;
    final diagram = knownTargets
        ? Semantics(
            image: true,
            label:
                '${fitnessText(context, back ? 'Back muscle map' : 'Front muscle map')}: ${exercise.targetLabel ?? exercise.target}',
            child: Container(
              key: const ValueKey('exercise-anatomy-map'),
              width: double.infinity,
              height: 320,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(20)),
              child: widget.anatomyReady
                  ? GraphiteMuscleFigure(
                      female: widget.female,
                      back: back,
                      primary: primary,
                      secondary: secondary)
                  : const Center(child: CupertinoActivityIndicator()),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(fitnessText(context, 'Muscle map unavailable'),
                style: const TextStyle(color: DSColors.muted, fontSize: 12)),
          );
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MuscleLabel(primaryText, anatomyPrimary,
            label: fitnessText(context, 'Primary muscle')),
        if (secondaryText.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: DSColors.border),
          ),
          _MuscleLabel(secondaryText, anatomySecondary,
              label: fitnessText(context, 'Secondary muscles')),
        ],
      ],
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(fitnessText(context, 'Target muscles'),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -.3)),
      if (knownTargets) ...[
        const SizedBox(height: 14),
        CupertinoSlidingSegmentedControl<bool>(
          groupValue: back,
          backgroundColor: DSColors.bg,
          thumbColor: DSColors.bgRaised,
          padding: const EdgeInsets.all(3),
          children: {
            for (final view in [false, true])
              view: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Text(fitnessText(context, view ? 'Back' : 'Front'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            back == view ? DSColors.silver : DSColors.muted)),
              ),
          },
          onValueChanged: (value) {
            if (value != null) setState(() => _back = value);
          },
        ),
      ],
      const SizedBox(height: 16),
      diagram,
      const SizedBox(height: 20),
      labels,
      if (knownTargets && focus.isEmpty) ...[
        const SizedBox(height: 12),
        Text(fitnessText(context, 'Targets are visible on the other side.'),
            style: const TextStyle(color: DSColors.muted, fontSize: 12)),
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
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Expanded(
              child: Text(label ?? '',
                  style: const TextStyle(
                      color: DSColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.4))),
        ]),
        const SizedBox(height: 7),
        Text(text,
            style: const TextStyle(
                color: DSColors.silver,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45)),
      ]);
}
