import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import '../views/exercise_detail_view.dart';
import 'exercise_recommendation_card.dart';

/// Plan IDs resolve to the same catalogue records shown in the exercise library.
class PlannedExerciseRow extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final WorkoutExerciseModel? initial;
  final String? summary;
  final bool showPrescription;
  final Future<WorkoutExerciseModel?> Function(String)? loadExercise;
  const PlannedExerciseRow(
      {super.key,
      required this.exercise,
      this.initial,
      this.summary,
      this.showPrescription = true,
      this.loadExercise});

  @override
  State<PlannedExerciseRow> createState() => _PlannedExerciseRowState();
}

class _PlannedExerciseRowState extends State<PlannedExerciseRow> {
  late Future<WorkoutExerciseModel?> _detail;
  String _locale = '';
  bool _opening = false;
  String get _id =>
      '${widget.exercise['exerciseId'] ?? widget.initial?.id ?? ''}';
  WorkoutExerciseModel get _preview =>
      widget.initial ??
      WorkoutExerciseModel.fromJson({
        ...?widget.exercise['exercise'] as Map?,
        'id': _id,
        'name': widget.exercise['displayName'] ??
            widget.exercise['name'] ??
            'Exercise',
        if (widget.exercise['thumbnailUrl'] != null)
          'thumbnailUrl': widget.exercise['thumbnailUrl'],
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale != locale) {
      _locale = locale;
      _detail = _load();
    }
  }

  @override
  void didUpdateWidget(PlannedExerciseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise['exerciseId'] != widget.exercise['exerciseId'] ||
        oldWidget.exercise['name'] != widget.exercise['name']) {
      _detail = _load();
    }
  }

  Future<WorkoutExerciseModel?> _load() async {
    try {
      if (_id.isNotEmpty) {
        return await (widget.loadExercise?.call(_id) ??
            WorkoutRepository.shared.getExerciseDetail(_id));
      }
      // Older saved plans may contain only a name. Never open a loosely matched exercise.
      final name = '${widget.exercise['name'] ?? ''}'.trim().toLowerCase();
      if (name.isEmpty) return null;
      final page = await WorkoutRepository.shared
          .getExercisePage(search: name, pageSize: 10);
      final matches = page.exercises
          .where((e) =>
              e.name.trim().toLowerCase() == name ||
              e.canonicalName?.trim().toLowerCase() == name)
          .toList();
      return matches.length == 1 ? matches.single : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(WorkoutExerciseModel? resolved) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final exercise = resolved ?? (_id.isNotEmpty ? _preview : await _detail);
      if (!mounted) return;
      if (exercise == null || exercise.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(context,
                'Exercise details are unavailable. Pull to refresh.'))));
        return;
      }
      await Navigator.of(context).push(AppPageRoute<void>(
          page: ExerciseDetailView(
              exercise: exercise,
              recommendation:
                  widget.showPrescription ? widget.exercise : null)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkoutExerciseModel?>(
        key: ValueKey('$_id:$_locale:${widget.exercise['name']}'),
        future: _detail,
        builder: (context, snapshot) {
          final exercise = snapshot.data ?? _preview;
          return ExerciseRecommendationCard(
            exercise: widget.exercise,
            embedded: true,
            showIcons: false,
            previewExercise: exercise,
            subtitleOverride: widget.summary,
            onTap: _opening ? () {} : () => _open(snapshot.data),
          );
        },
      );
}
