import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/training_exercise_row.dart';
import '../components/training_targets.dart';
import '../components/training_widgets.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';

/// A template is edited locally and saved once; the scheduled day is untouched.
class CreateWorkoutView extends StatefulWidget {
  const CreateWorkoutView(
      {super.key,
      required this.date,
      this.initialName = '',
      this.initialItems = const []});
  final String date, initialName;
  final List<TodayPlanItemModel> initialItems;

  @override
  State<CreateWorkoutView> createState() => _CreateWorkoutViewState();
}

class _CreateWorkoutViewState extends State<CreateWorkoutView> {
  late final _name = TextEditingController(text: widget.initialName);
  late final List<TodayPlanItemModel> _items = List.of(widget.initialItems);
  late final _initialTargets =
      jsonEncode(widget.initialItems.map(TrainingDay.targets).toList());
  bool _busy = false, _picking = false, _allowPop = false, _confirming = false;
  int _nextId = 0;
  String? _error;
  bool get _changed =>
      _name.text != widget.initialName ||
      jsonEncode(_items.map(TrainingDay.targets).toList()) != _initialTargets;
  String copy(String text) => fitnessText(context, text);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pop([TrainingDay? result]) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  Future<void> _leave() async {
    if (_busy || _picking || _confirming) {
      return;
    }
    if (!_changed) {
      _pop();
      return;
    }
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      animationStyle: DSMotion.dialogStyle(context),
      builder: (context) => AlertDialog(
        title: const FitnessText('Discard changes?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const FitnessText('Keep editing')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const FitnessText('Discard')),
        ],
      ),
    );
    _confirming = false;
    if (mounted && discard == true) _pop();
  }

  Future<void> _add() async {
    if (_busy || _picking) {
      return;
    }
    setState(() => _picking = true);
    try {
      final exercises = await pickTrainingExercises(context);
      if (!mounted || exercises == null || exercises.isEmpty) {
        return;
      }
      final drafts = exercises
          .map((exercise) => TodayPlanItemModel(
              id: 'draft-${_nextId++}',
              dayOfWeek: '',
              orderIndex: _items.length,
              targetSets: 3,
              targetReps: '10',
              targetWeight: 0,
              restSeconds: 90,
              status: 'NOT_STARTED',
              exercise: exercise))
          .toList();
      if (drafts.length == 1) {
        final item = drafts.single;
        final targets = await editTrainingTargets(context, item);
        if (!mounted || targets == null) {
          return;
        }
        drafts[0] = TodayPlanItemModel.fromJson({...item.toJson(), ...targets});
      }
      if (mounted) {
        setState(() {
          _items.addAll(drafts);
          _error = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _edit(int index) async {
    if (_busy || _picking) {
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FitnessTheme.canvas,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      showDragHandle: true,
      builder: (context) => FitnessTheme(
          child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final action in [
                  'Edit targets',
                  if (index > 0) 'Move up',
                  if (index < _items.length - 1) 'Move down',
                  'Remove exercise'
                ])
                  ListTile(
                      title: FitnessText(action),
                      onTap: () => Navigator.pop(context, action)),
                const SizedBox(height: 12),
              ]))),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'Edit targets') {
      final targets = await editTrainingTargets(context, _items[index]);
      if (mounted && targets != null) {
        setState(() {
          _items[index] = TodayPlanItemModel.fromJson(
              {..._items[index].toJson(), ...targets});
          _error = null;
        });
      }
    } else {
      setState(() {
        final item = _items.removeAt(index);
        if (action == 'Move up') _items.insert(index - 1, item);
        if (action == 'Move down') _items.insert(index + 1, item);
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (_busy || _picking) {
      return;
    }
    if (_name.text.trim().isEmpty || _items.isEmpty) {
      setState(() => _error = _name.text.trim().isEmpty
          ? 'Enter a workout name.'
          : 'Add at least one exercise.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final day = await TrainingRepository.shared
          .mutate(widget.date, 'POST', '/routines', data: {
        'name': _name.text.trim(),
        'items': _items.map(TrainingDay.targets).toList(),
      });
      if (mounted) _pop(day);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = TrainingRepository.errorMessage(
              error, 'Could not save. Please try again.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: PopScope<TrainingDay>(
        canPop: _allowPop || (!_busy && !_picking && !_changed),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: Navigator.of(context).canPop()
                ? BackButton(onPressed: _leave)
                : null,
            title: FitnessText(
                widget.initialItems.isEmpty ? 'Create workout' : 'Save workout',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
          body: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                TextField(
                  key: const ValueKey('workout-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                      labelText: copy('Workout name'),
                      hintText: copy('e.g. Push day'),
                      counterText: ''),
                ),
                const SizedBox(height: 24),
                const FitnessText('Exercises',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                if (_items.isNotEmpty) ...[
                  TrainingSurface(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0)
                            const Padding(
                                padding: EdgeInsetsDirectional.only(
                                    start: 78, end: 14),
                                child: Divider(
                                    height: 1, color: FitnessTheme.line)),
                          TrainingExerciseRow(
                              item: _items[i],
                              subtitle:
                                  '${_items[i].targetSets} × ${_items[i].targetReps} ${copy('reps')}',
                              onTap: _busy || _picking ? null : () => _edit(i)),
                        ],
                      ])),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                    onPressed: _busy || _picking ? null : _add,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: FitnessTheme.silver,
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: FitnessTheme.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const FitnessText('Add exercise')),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FitnessText(_error!,
                          style: const TextStyle(
                              color: FitnessTheme.coral,
                              fontSize: 12,
                              height: 1.4))),
              ]),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: FitnessSubmit(
                      key: const ValueKey('save-workout-action'),
                      label: 'Save workout',
                      busy: _busy,
                      onPressed: _picking ? null : _save))),
        ),
      ));
}
