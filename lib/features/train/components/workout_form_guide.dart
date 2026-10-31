import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import 'training_widgets.dart';

class WorkoutFormGuide extends StatefulWidget {
  const WorkoutFormGuide({super.key, required this.exercise});
  final WorkoutExerciseModel exercise;
  @override
  State<WorkoutFormGuide> createState() => _WorkoutFormGuideState();
}

class _WorkoutFormGuideState extends State<WorkoutFormGuide> {
  late WorkoutExerciseModel _exercise = widget.exercise;
  bool _expanded = false, _loading = false, _failed = false;
  String? _locale;
  int _request = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale == locale) return;
    _locale = locale;
    if (_exercise.localizedInstructionSteps(locale).isEmpty) unawaited(_load());
  }

  @override
  void didUpdateWidget(WorkoutFormGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id == widget.exercise.id) return;
    _exercise = widget.exercise;
    _expanded = false;
    ++_request;
    if (_exercise.localizedInstructionSteps(_locale).isEmpty) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final exercise =
          await WorkoutRepository.shared.getExerciseDetail(widget.exercise.id);
      if (!mounted || request != _request) return;
      setState(() {
        if (exercise != null) _exercise = exercise;
        _failed = exercise == null;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _exercise
        .localizedInstructionSteps(_locale)
        .where((step) => step.trim().isNotEmpty)
        .toList();
    return TrainingSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: Text(fitnessText(context, 'How to perform'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        if (steps.length > 2)
          TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                  fitnessText(context, _expanded ? 'Show less' : 'Show all'),
                  style: const TextStyle(fontSize: 12, color: DSColors.muted))),
      ]),
      if (_loading && steps.isEmpty)
        const Padding(
            padding: EdgeInsets.all(12), child: CupertinoActivityIndicator())
      else if (steps.isEmpty) ...[
        const SizedBox(height: 8),
        Text(fitnessText(context, 'Instructions unavailable'),
            style: const TextStyle(fontSize: 12, color: DSColors.muted)),
        if (_failed)
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                  onPressed: _load,
                  child: Text(fitnessText(context, 'Retry')))),
      ] else ...[
        for (var index = 0;
            index < (_expanded ? steps.length : steps.length.clamp(0, 2));
            index++)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 22,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            fontSize: 12, height: 1.5, color: DSColors.muted))),
                Expanded(
                    child: Text(steps[index],
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: DSColors.silver))),
              ])),
        if (_exercise.contentLanguage == 'en' &&
            Localizations.localeOf(context).languageCode != 'en')
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                  fitnessText(context,
                      'English instructions shown while this translation is unavailable.'),
                  style: const TextStyle(fontSize: 11, color: DSColors.muted))),
      ],
    ]));
  }
}
