import 'dart:async';
import 'dart:convert';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/training_targets.dart';
import '../components/training_widgets.dart';
import '../components/routine_exercise_card.dart';
import '../components/saved_routine_tile.dart';
import 'create_workout_view.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/theme/fitness_theme.dart';
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
  bool _busy = false, _managing = false;
  String copy(String text) => fitnessText(context, text);

  Future<void> _open(Map<String, dynamic> routine) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Navigator.of(context).push(AppPageRoute<void>(
          page: RoutineDetailView(day: _day, routine: routine)));
      final day =
          await TrainingRepository.shared.load(_day.date, refresh: true);
      if (mounted) setState(() => _day = day);
    } catch (_) {
      // Keep the last confirmed list when offline.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> routine) async {
    if (_busy) return;
    final approved =
        await confirmRoutineDeletion(context, routine['name'] as String);
    if (!approved || !mounted || _busy) return;
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

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final day = await Navigator.of(context).push(
          AppPageRoute<TrainingDay>(page: CreateWorkoutView(date: _day.date)));
      if (mounted && day != null) setState(() => _day = day);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(copy('My workouts'),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          actions: [
            if (_day.routines.isNotEmpty)
              TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _managing = !_managing),
                  child: Text(copy(_managing ? 'Done' : 'Manage'),
                      style: const TextStyle(
                          fontSize: 12, color: DSColors.silver))),
          ],
        ),
        body: SafeArea(
            bottom: false,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  if (_day.routines.isEmpty)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 40),
                        child: Column(children: [
                          Text(copy('Your workouts, ready to repeat'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -.6)),
                          const SizedBox(height: 12),
                          Text(
                              copy(
                                  'Save your exercises and sets once. Use them whenever you train.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: DSColors.muted)),
                        ])),
                  for (final routine in _day.routines)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TrainingSurface(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 5),
                            child: SavedRoutineTile(
                                routine: routine,
                                onOpen: _busy || _managing
                                    ? null
                                    : () => _open(routine),
                                onDelete: _busy || !_managing
                                    ? null
                                    : () => _delete(routine)))),
                ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: FitnessSubmit(
                    label: 'Create workout',
                    onPressed: _busy ? null : _create))),
      ));
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
  List<TodayPlanItemModel>? _items, _savedItems;
  String _savedName = '', _savedTargets = '';
  String? _error;
  bool _busy = false,
      _editing = false,
      _allowPop = false,
      _exitPromptOpen = false,
      _confirming = false;
  String copy(String text, {Map<String, Object> values = const {}}) =>
      fitnessText(context, text, values: values);
  bool get _changed =>
      _items != null &&
      (_name.text.trim() != _savedName ||
          jsonEncode(_items!.map(TrainingDay.targets).toList()) !=
              _savedTargets);

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

  void _rememberSaved() {
    _savedName = _name.text.trim();
    _savedItems = List.of(_items!);
    _savedTargets = jsonEncode(_items!.map(TrainingDay.targets).toList());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data =
          await _repo.routine(widget.day.date, widget.routine['id'] as String);
      if (!mounted) return;
      setState(() {
        _name.text = data['name'] as String;
        _items = (data['items'] as List)
            .map((row) => TodayPlanItemModel.fromJson(
                Map<String, dynamic>.from(row as Map)))
            .toList();
        _rememberSaved();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = TrainingRepository.errorMessage(
            error, 'Could not sync. Pull to retry.'));
      }
    }
  }

  Future<void> _edit(int index) async {
    if (_busy || !_editing) return;
    final input = await editTrainingTargets(context, _items![index]);
    if (input == null || !mounted) return;
    setState(() {
      _items![index] =
          TodayPlanItemModel.fromJson({..._items![index].toJson(), ...input});
      _error = null;
    });
  }

  void _cancelEditing() {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _name.text = _savedName;
      _items = List.of(_savedItems!);
      _editing = false;
      _error = null;
    });
  }

  void _pop() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _requestLeave() async {
    if (_busy || _confirming || _exitPromptOpen) return;
    if (!_changed) {
      _pop();
      return;
    }
    _exitPromptOpen = true;
    try {
      final discard = await showDialog<bool>(
          context: context,
          animationStyle: DSMotion.dialogStyle(context),
          builder: (context) => AlertDialog(
                  title: Text(copy('Discard changes?')),
                  content:
                      Text(copy('Your routine edits have not been saved.')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(copy('Keep editing'))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(copy('Discard'))),
                  ]));
      if (discard == true && mounted) _pop();
    } finally {
      _exitPromptOpen = false;
    }
  }

  Future<bool> _save() async {
    if (_name.text.trim().isEmpty || _name.text.trim().length > 80) {
      setState(() => _error = 'Enter a workout name.');
      return false;
    }
    if (!_changed) return true;
    await _repo.mutate(
        widget.day.date, 'PUT', '/routines/${widget.routine['id']}',
        data: {
          'name': _name.text.trim(),
          'items': _items!.map(TrainingDay.targets).toList(),
        });
    if (mounted) setState(_rememberSaved);
    return true;
  }

  Future<void> _action({bool use = false}) async {
    if (_busy ||
        _confirming ||
        _items == null ||
        (use &&
            (widget.day.started ||
                widget.day.pendingSync ||
                _items!.isEmpty))) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _confirming = true;
    try {
      // Confirm before saving or applying, so cancellation has no side effects.
      if (use && widget.day.items.isNotEmpty) {
        final approved = await showDialog<bool>(
            context: context,
            animationStyle: DSMotion.dialogStyle(context),
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
                          child: Text(copy('Use workout'))),
                    ]));
        if (approved != true || !mounted) return;
      }
      _confirming = false;
      if (!mounted) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      if (!await _save() || !mounted) return;
      if (use) {
        await _repo.mutate(
            widget.day.date, 'POST', '/routines/${widget.routine['id']}/apply');
        if (mounted) _pop();
      } else {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(copy('Changes saved'))));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = TrainingRepository.errorMessage(
            error, 'Could not save. Please try again.'));
      }
    } finally {
      _confirming = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _heading() {
    final items = _items!;
    final minutes = prescribedWorkoutMinutes(items, 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_editing)
        TextField(
            key: const ValueKey('routine-name'),
            controller: _name,
            enabled: !_busy,
            maxLength: 80,
            decoration: InputDecoration(labelText: copy('Workout name')),
            onChanged: (_) => setState(() => _error = null))
      else
        Text(_name.text,
            style: const TextStyle(
                fontSize: 23,
                height: 1.15,
                fontWeight: FontWeight.w500,
                letterSpacing: -.65)),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 6, children: [
        Text(copy('{count} exercises', values: {'count': items.length}),
            style: const TextStyle(fontSize: 12, color: DSColors.muted)),
        Text(
            copy('{count} sets', values: {
              'count': items.fold<int>(0, (sum, item) => sum + item.targetSets)
            }),
            style: const TextStyle(fontSize: 12, color: DSColors.muted)),
        if (minutes > 0)
          Text(copy('About {minutes} min', values: {'minutes': minutes}),
              style: const TextStyle(fontSize: 12, color: DSColors.muted)),
      ]),
      if (items.any((item) =>
          !item.isBodyweight &&
          List.generate(
                  item.targetSets, (i) => routineTargetWeight(item, i + 1))
              .any((weight) => weight == null))) ...[
        const SizedBox(height: 12),
        Text(copy('Choose your working weight when you start.'),
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: DSColors.muted)),
      ],
    ]);
  }

  Widget _footer() => SafeArea(
      top: false,
      child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
              color: DSColors.bg,
              border: Border(top: BorderSide(color: DSColors.border))),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_editing &&
                    (widget.day.started || widget.day.pendingSync)) ...[
                  Text(
                      copy(widget.day.started
                          ? 'Use routines before starting your workout.'
                          : 'Reconnect to sync your workout before making changes.'),
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: DSColors.muted)),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                    key: const ValueKey('routine-primary-action'),
                    onPressed: _busy ||
                            (!_editing &&
                                (widget.day.started ||
                                    widget.day.pendingSync ||
                                    _items!.isEmpty))
                        ? null
                        : () => _action(use: !_editing),
                    style: FilledButton.styleFrom(
                        backgroundColor: DSColors.silver,
                        foregroundColor: DSColors.bg,
                        disabledBackgroundColor:
                            _busy ? DSColors.silver : DSColors.bgRaised,
                        disabledForegroundColor:
                            _busy ? DSColors.bg : DSColors.muted,
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: _busy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: DSColors.bg)),
                                const SizedBox(width: 10),
                                Flexible(
                                    child: Text(
                                        copy(_editing
                                            ? 'Saving'
                                            : 'Adding routine…'),
                                        textAlign: TextAlign.center)),
                              ])
                        : Text(copy(_editing ? 'Save changes' : 'Use workout'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600))),
                if (_editing)
                  TextButton(
                      onPressed: _busy ? null : _cancelEditing,
                      style:
                          TextButton.styleFrom(foregroundColor: DSColors.muted),
                      child: Text(copy('Cancel'))),
              ])));

  @override
  Widget build(BuildContext context) => PopScope<void>(
      canPop: _allowPop || (!_busy && !_changed),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: AppBar(
              leading: Navigator.of(context).canPop()
                  ? BackButton(onPressed: _requestLeave)
                  : null,
              title: Text(copy('Workout'),
                  style: const TextStyle(fontSize: 16, color: DSColors.silver)),
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (_items != null && !_editing)
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _editing = true),
                          style: TextButton.styleFrom(
                              foregroundColor: DSColors.silver),
                          child: Text(copy('Edit'))))
              ]),
          body: SafeArea(
              bottom: false,
              child: ListView(
                  key: const ValueKey('routine-detail-scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (_error != null) ...[
                      Text(copy(_error!),
                          style: const TextStyle(
                              color: DSColors.muted, height: 1.5)),
                      if (_items == null)
                        TextButton(
                            onPressed: _load, child: Text(copy('Retry'))),
                      const SizedBox(height: 16),
                    ],
                    if (_items == null && _error == null)
                      const Center(child: CupertinoActivityIndicator()),
                    if (_items != null) ...[
                      _heading(),
                      const SizedBox(height: 24),
                      if (_items!.isEmpty)
                        Text(copy('No exercises found'),
                            style: const TextStyle(color: DSColors.muted)),
                      for (var index = 0; index < _items!.length; index++)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RoutineExerciseCard(
                                item: _items![index],
                                number: index + 1,
                                onEdit: _editing && !_busy
                                    ? () => _edit(index)
                                    : null)),
                    ],
                  ])),
          bottomNavigationBar: _items == null ? null : _footer()));
}
