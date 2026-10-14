import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/training_targets.dart';
import '../components/training_widgets.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';

class SavedRoutinesView extends StatefulWidget {
  final TrainingDay initial;
  const SavedRoutinesView({super.key, required this.initial});

  @override
  State<SavedRoutinesView> createState() => _SavedRoutinesViewState();
}

class _SavedRoutinesViewState extends State<SavedRoutinesView> {
  late TrainingDay _day = widget.initial;
  bool _busy = false;
  String copy(String text) => fitnessText(context, text);

  Future<void> _open(Map<String, dynamic> routine) async {
    await Navigator.of(context).push(AppPageRoute<void>(
        page: RoutineDetailView(day: _day, routine: routine)));
    try {
      final day =
          await TrainingRepository.shared.load(_day.date, refresh: true);
      if (mounted) setState(() => _day = day);
    } catch (_) {/* Keep the last confirmed list when offline. */}
  }

  Future<void> _delete(Map<String, dynamic> routine) async {
    final approved = await showDialog<bool>(
        animationStyle: DSMotion.dialogStyle(context),
context: context,
        builder: (context) => AlertDialog(
              title: Text(copy('Delete routine?')),
              content: Text(routine['name'] as String),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(copy('Cancel'))),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(copy('Delete'))),
              ],
            ));
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final day = await TrainingRepository.shared
          .mutate(_day.date, 'DELETE', '/routines/${routine['id']}');
      if (mounted) setState(() => _day = day);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(copy(TrainingRepository.errorMessage(
                error, 'Could not save. Please try again.')))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DSColors.bg,
        appBar: AppBar(
            title: Text(copy('Saved routines')), backgroundColor: DSColors.bg),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(18), children: [
          Text(
              copy(
                  'Preview a routine, adjust its targets, then use it for a workout.'),
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: trainingMuted)),
          const SizedBox(height: 18),
          if (_day.routines.isEmpty)
            TrainingSurface(
                child: Text(copy('Save a workout to use it again.'))),
          for (final routine in _day.routines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TrainingSurface(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.bookmark,
                        size: 20, color: trainingSilver),
                    title: Text(routine['name'] as String,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text(fitnessText(context, '{count} exercises',
                        values: {'count': routine['count']})),
                    onTap: _busy ? null : () => _open(routine),
                    trailing: IconButton(
                        tooltip: copy('Delete routine'),
                        onPressed: _busy ? null : () => _delete(routine),
                        icon: const Icon(CupertinoIcons.trash,
                            size: 18, color: trainingMuted)),
                  )),
            ),
        ])),
      );
}

class RoutineDetailView extends StatefulWidget {
  final TrainingDay day;
  final Map<String, dynamic> routine;
  const RoutineDetailView(
      {super.key, required this.day, required this.routine});

  @override
  State<RoutineDetailView> createState() => _RoutineDetailViewState();
}

class _RoutineDetailViewState extends State<RoutineDetailView> {
  final _repo = TrainingRepository.shared;
  final _name = TextEditingController();
  List<TodayPlanItemModel>? _items;
  String? _error;
  bool _busy = false, _changed = false;
  String copy(String text) => fitnessText(context, text);

  @override
  void initState() {
    super.initState();
    _name.text = widget.routine['name'] as String;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data =
          await _repo.routine(widget.day.date, widget.routine['id'] as String);
      if (!mounted) return;
      setState(() {
        _name.text = data['name'] as String;
        _items = (data['items'] as List)
            .map((item) => TodayPlanItemModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = TrainingRepository.errorMessage(
            error, 'Could not sync. Pull to retry.'));
      }
    }
  }

  Future<void> _edit(int index) async {
    final input = await editTrainingTargets(context, _items![index]);
    if (input == null || !mounted) return;
    final previous = _items![index];
    setState(() {
      // Editing the general targets intentionally replaces per-set suggestions.
      _items![index] = TodayPlanItemModel.fromJson(
          {...previous.toJson(), ...input, 'setTargets': null});
      _changed = true;
    });
  }

  Future<bool> _save() async {
    if (!_changed) return true;
    if (_name.text.trim().isEmpty || _name.text.trim().length > 80) {
      setState(() => _error = 'Enter a routine name.');
      return false;
    }
    await _repo.mutate(
        widget.day.date, 'PUT', '/routines/${widget.routine['id']}',
        data: {
          'name': _name.text.trim(),
          'items': _items!.map(TrainingDay.targets).toList(),
        });
    if (mounted) setState(() => _changed = false);
    return true;
  }

  Future<void> _action({bool use = false}) async {
    setState(() => _busy = true);
    try {
      if (!await _save() || !mounted) return;
      if (use) {
        final approved = widget.day.items.isEmpty ||
            await showDialog<bool>(
                    animationStyle: DSMotion.dialogStyle(context),
context: context,
                    builder: (context) => AlertDialog(
                          title: Text(copy('Replace this workout?')),
                          content: Text(copy(
                              'Your saved routine will replace the scheduled exercises.')),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(copy('Cancel'))),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(copy('Use routine'))),
                          ],
                        )) ==
                true;
        if (!approved) return;
        await _repo.mutate(
            widget.day.date, 'POST', '/routines/${widget.routine['id']}/apply');
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(copy('Changes saved'))));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = TrainingRepository.errorMessage(
            error, 'Could not save. Please try again.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DSColors.bg,
        appBar:
            AppBar(title: Text(copy('Routine')), backgroundColor: DSColors.bg),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(18), children: [
          if (_error != null) ...[
            Text(copy(_error!), style: const TextStyle(color: trainingMuted)),
            if (_items == null)
              TextButton(onPressed: _load, child: Text(copy('Retry'))),
            const SizedBox(height: 12),
          ],
          if (_items == null && _error == null)
            const Center(child: CupertinoActivityIndicator()),
          if (_items != null) ...[
            TextField(
                controller: _name,
                enabled: !_busy,
                maxLength: 80,
                decoration: InputDecoration(labelText: copy('Routine name')),
                onChanged: (_) => setState(() => _changed = true)),
            const SizedBox(height: 14),
            for (var index = 0; index < _items!.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TrainingSurface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                '${index + 1}. ${_items![index].exercise.name}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500))),
                        IconButton(
                            tooltip: copy('Edit targets'),
                            onPressed: _busy ? null : () => _edit(index),
                            icon: const Icon(CupertinoIcons.pencil,
                                size: 17, color: trainingMuted)),
                      ]),
                      for (var number = 1;
                          number <= _items![index].targetSets;
                          number++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                              fitnessText(context, 'Set {number}: {target}',
                                  values: {
                                    'number': number,
                                    'target': fitnessText(
                                        context,
                                        _items![index].localizedTargetLabel(
                                                context, number) ??
                                            ''),
                                  }),
                              style: const TextStyle(
                                  fontSize: 13, color: trainingSilver)),
                        ),
                      const SizedBox(height: 6),
                      Text(
                          fitnessText(context, 'Rest: {seconds} sec',
                              values: {'seconds': _items![index].restSeconds}),
                          style: const TextStyle(
                              fontSize: 12, color: trainingMuted)),
                    ])),
              ),
            if (widget.day.started)
              Text(copy('Use routines before starting your workout.'),
                  style: const TextStyle(fontSize: 12, color: trainingMuted)),
          ],
        ])),
        bottomNavigationBar: _items == null
            ? null
            : SafeArea(
                child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_changed) ...[
                        OutlinedButton(
                            onPressed: _busy ? null : () => _action(),
                            child: Text(copy('Save changes'))),
                        const SizedBox(height: 8),
                      ],
                      TrainingButton(
                          label: 'Use routine',
                          primary: true,
                          onPressed: _busy ||
                                  widget.day.started ||
                                  widget.day.pendingSync
                              ? null
                              : () => _action(use: true)),
                    ]),
              )),
      );
}
