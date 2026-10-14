import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/media/fit_video_surface.dart';
import '../components/training_widgets.dart';
import '../components/workout_item_actions.dart';
import '../components/workout_set_entry.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';
import 'exercise_detail_view.dart';

class WorkoutSessionView extends StatefulWidget {
  final TrainingDay initial;
  final String? initialItemId;
  const WorkoutSessionView(
      {super.key, required this.initial, this.initialItemId});
  @override
  State<WorkoutSessionView> createState() => _WorkoutSessionViewState();
}

class _WorkoutSessionViewState extends State<WorkoutSessionView> {
  late TrainingDay _day;
  int _index = 0;
  bool _busy = false;
  bool _editingFinished = false;
  final _setEntries = <String, GlobalKey<WorkoutSetEntryState>>{};
  final _repo = TrainingRepository.shared;
  final _clock = ValueNotifier(DateTime.now());
  Timer? _timer;
  StreamSubscription<TrainingDay>? _syncSubscription;
  DateTime? _restEnd;
  Future<Map<String, dynamic>>? _previous;
  String copy(String key, {Map<String, Object> values = const {}}) =>
      fitnessText(context, key, values: values);

  @override
  void initState() {
    super.initState();
    _day = widget.initial;
    final pending = _day.items.indexWhere((item) => item.isPending);
    final selected =
        _day.items.indexWhere((item) => item.id == widget.initialItemId);
    _index = selected >= 0
        ? selected
        : pending < 0
            ? 0
            : pending;
    _loadPrevious();
    _restoreRest();
    _syncSubscription = _repo.changes.stream.listen((day) {
      if (!mounted || day.date != _day.date) return;
      setState(() {
        _day = day;
        _index = _index.clamp(0, (_day.items.length - 1).clamp(0, 100));
      });
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clock.value = DateTime.now();
      if (_day.pendingSync && _.tick % 30 == 0 && !_busy) _sync();
    });
  }

  Future<void> _sync({bool retry = false}) async {
    try {
      await _repo.syncPending(retry: retry);
    } catch (error) {
      if (mounted && retry) {
        _error(TrainingRepository.errorMessage(
            error, 'Could not sync. Pull to retry.'));
      }
    }
  }

  Future<void> _restoreRest() async {
    final end = await _repo.restEnds(_day.date);
    if (mounted) setState(() => _restEnd = end);
  }

  void _loadPrevious() {
    if (_day.items.isNotEmpty) {
      _previous = _repo.previous(_day.date, _day.items[_index].exercise.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncSubscription?.cancel();
    _clock.dispose();
    super.dispose();
  }

  Future<void> _mutate(String method, String suffix,
      {Map<String, dynamic>? data}) async {
    final day = await _repo.mutate(_day.date, method, suffix, data: data);
    if (mounted) setState(() => _day = day);
  }

  Future<void> _status(TodayPlanItemModel item, String status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (status == 'COMPLETED') {
        final entries = _setEntries.entries
            .where((entry) => entry.key.startsWith('${item.id}:'))
            .map((entry) => entry.value.currentState)
            .whereType<WorkoutSetEntryState>()
            .toList();
        await Future.wait(entries.map((entry) => entry.waitForSave()));
        final sets = entries
            .map((entry) => entry.pendingSet())
            .whereType<Map<String, dynamic>>()
            .toList();
        if (_day.logs(item.id).isEmpty && sets.isEmpty) {
          _error('Log at least one set before marking this exercise done.');
          return;
        }
        await _mutate('POST', '/items/${item.id}/complete',
            data: {'sets': sets});
        for (final entry in entries) {
          entry.confirmSaved();
        }
      } else {
        await _mutate('PATCH', '/items/${item.id}/status',
            data: {'status': status});
      }
      if (mounted && status != 'NOT_STARTED') {
        final next = _day.items.indexWhere((row) => row.isPending);
        if (next >= 0) {
          setState(() {
            _index = next;
            _loadPrevious();
          });
        }
      }
    } catch (error) {
      _error(TrainingRepository.errorMessage(
          error, 'Could not save. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveEnteredSets(String itemId) async {
    for (final entry in _setEntries.entries
        .where((entry) => entry.key.startsWith('$itemId:'))) {
      await entry.value.currentState?.savePending();
    }
  }

  Future<void> _saveFinishedEdits() async {
    setState(() => _busy = true);
    try {
      if (_day.items.isNotEmpty) await _saveEnteredSets(_day.items[_index].id);
      if (mounted) setState(() => _editingFinished = false);
    } catch (error) {
      _error(TrainingRepository.errorMessage(
          error, 'Not saved yet. Tap save to retry.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _error(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(copy(message))));
    }
  }

  Future<void> _rest(int seconds) async {
    await _repo.setRest(_day.date, seconds);
    if (mounted) {
      setState(() => _restEnd = DateTime.now().add(Duration(seconds: seconds)));
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      if (_day.items.isNotEmpty) await _saveEnteredSets(_day.items[_index].id);
      await _mutate('POST', '/finish');
      await _rest(0);
      await HapticFeedback.mediumImpact();
    } catch (error) {
      _error(TrainingRepository.errorMessage(
          error, 'Could not finish. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _day.items.isEmpty
        ? null
        : _day.items[_index.clamp(0, _day.items.length - 1)];
    return Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: trainingSilver, secondary: trainingSilver)),
        child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: AppBar(
              backgroundColor: DSColors.bg,
              title: Text(
                  _day.name == 'Workout' ? copy('Your workout') : _day.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              actions: [
                if (!_day.finished)
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ValueListenableBuilder<DateTime>(
                          valueListenable: _clock,
                          builder: (_, now, __) {
                            final start = DateTime.tryParse(
                                _day.session?['startedAt'] as String? ?? '');
                            final minutes = start == null
                                ? 0
                                : now.difference(start).inMinutes;
                            return Center(
                                child: Text(
                                    copy('{minutes} min',
                                        values: {'minutes': minutes}),
                                    style: const TextStyle(
                                        color: trainingMuted, fontSize: 12)));
                          }))
              ]),
          body: _day.finished && !_editingFinished
              ? _summary()
              : item == null
                  ? Center(child: Text(copy('No exercises found')))
                  : Column(children: [
                      if (_day.pendingSync)
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            child: WorkoutSyncNotice(
                                blocked: _day.syncBlocked,
                                onRetry: () => _sync(retry: true))),
                      SizedBox(
                          height: 54,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              itemCount: _day.items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, index) => ChoiceChip(
                                  label: Text('${index + 1}'),
                                  selected: index == _index,
                                  showCheckmark: false,
                                  selectedColor: trainingSilver,
                                  backgroundColor: const Color(0xFF242424),
                                  labelStyle: TextStyle(
                                      color: index == _index
                                          ? Colors.black
                                          : trainingMuted),
                                  avatar: _day.items[index].isCompleted
                                      ? Icon(CupertinoIcons.checkmark,
                                          size: 12,
                                          color: index == _index
                                              ? Colors.black
                                              : trainingSilver)
                                      : null,
                                  onSelected: _busy
                                      ? null
                                      : (_) => setState(() {
                                            _index = index;
                                            _loadPrevious();
                                          })))),
                      Expanded(
                          child: ListView(
                              key: const ValueKey('workout-session-scroll'),
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                              children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: RepaintBoundary(
                                        child: FitVideoSurface(
                                            key: ValueKey(item.id),
                                            url: item.exercise.url,
                                            autoplay: true,
                                            fit: BoxFit.contain,
                                            neutralBackground: true,
                                            backgroundColor: Colors.white)))),
                            const SizedBox(height: 17),
                            Text(item.exercise.displayName,
                                style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.5)),
                            const SizedBox(height: 5),
                            Text(
                                '${item.exercise.targetLabel ?? item.exercise.target} · ${item.exercise.equipmentLabel ?? item.exercise.equipment}',
                                style: const TextStyle(
                                    fontSize: 13, color: trainingMuted)),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                            builder: (_) => ExerciseDetailView(
                                                exercise: item.exercise))),
                                    icon: const Icon(CupertinoIcons.info_circle,
                                        size: 16),
                                    label: Text(copy('Form guide'),
                                        style: const TextStyle(fontSize: 12)))),
                            _restCard(),
                            const SizedBox(height: 13),
                            TrainingSurface(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(copy('Your sets'),
                                                style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Text(
                                            copy('{sets} × {reps}', values: {
                                              'sets': item.targetSets,
                                              'reps': item.targetReps
                                            }),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: trainingMuted))
                                      ]),
                                      const SizedBox(height: 7),
                                      Text(
                                          copy(
                                              'Confirm or edit each set before saving.'),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: trainingMuted)),
                                      if (item.setTargets?['weightBasis'] ==
                                          'estimated_start')
                                        Text(
                                            copy(
                                                'Starting estimate · reduce the load if needed'),
                                            style: const TextStyle(
                                                color: trainingMuted,
                                                fontSize: 11)),
                                      const SizedBox(height: 10),
                                      for (int number = 1;
                                          number <= _setCount(item);
                                          number++)
                                        WorkoutSetEntry(
                                            key: _setEntries.putIfAbsent(
                                                '${item.id}:$number',
                                                () => GlobalKey<
                                                    WorkoutSetEntryState>()),
                                            date: _day.date,
                                            itemId: item.id,
                                            number: number,
                                            targetLabel:
                                                item.localizedTargetLabel(
                                                    context, number),
                                            suggestedReps:
                                                _suggestedReps(item, number),
                                            suggestedWeight:
                                                _suggestedWeight(item, number),
                                            previous: _previous,
                                            log: _day
                                                .logs(item.id)
                                                .where((row) =>
                                                    row['setNumber'] == number)
                                                .firstOrNull,
                                            disabled: _busy,
                                            onSave:
                                                (reps, weight, effort) async {
                                              await _mutate('PUT',
                                                  '/items/${item.id}/sets',
                                                  data: {
                                                    'setNumber': number,
                                                    'reps': reps,
                                                    'weight': weight,
                                                    'rpe': effort,
                                                  });
                                              await _rest(item.restSeconds);
                                              await HapticFeedback
                                                  .selectionClick();
                                            },
                                            onDelete: () => _mutate('DELETE',
                                                '/items/${item.id}/sets/$number')),
                                      TextButton.icon(
                                          onPressed: _busy
                                              ? null
                                              : () => _extraSet(item),
                                          icon: const Icon(CupertinoIcons.plus,
                                              size: 14),
                                          label: Text(copy('Add set'),
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      const SizedBox(height: 5),
                                      Text(
                                          copy(
                                              'Only saved sets count toward your body map.'),
                                          style: const TextStyle(
                                              color: trainingMuted,
                                              fontSize: 11,
                                              height: 1.4)),
                                      const SizedBox(height: 12),
                                      if (!_day.finished)
                                        WorkoutItemActions(
                                            item: item,
                                            busy: _busy,
                                            onDone: () =>
                                                _status(item, 'COMPLETED'),
                                            onSkip: () =>
                                                _status(item, 'SKIPPED'),
                                            onUndo: () =>
                                                _status(item, 'NOT_STARTED')),
                                    ])),
                          ])),
                    ]),
          bottomNavigationBar: _day.finished
              ? (_editingFinished
                  ? SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton(
                              onPressed: _busy ? null : _saveFinishedEdits,
                              child: Text(copy('Save changes')))))
                  : null)
              : SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: TrainingButton(
                          label: _day.allResolved
                              ? 'Finish workout'
                              : 'Continue workout',
                          primary: true,
                          onPressed: _busy
                              ? null
                              : _day.allResolved
                                  ? _finish
                                  : () {
                                      final index = _day.items
                                          .indexWhere((row) => row.isPending);
                                      if (index >= 0) {
                                        setState(() {
                                          _index = index;
                                          _loadPrevious();
                                        });
                                      }
                                    }))),
        ));
  }

  final _extra = <String, int>{};
  int _setCount(TodayPlanItemModel item) {
    final logs =
        _day.logs(item.id).map((row) => (row['setNumber'] as num).toInt());
    return [item.targetSets, _extra[item.id] ?? 0, ...logs]
        .reduce((a, b) => a > b ? a : b);
  }

  void _extraSet(TodayPlanItemModel item) {
    final count = _setCount(item);
    if (count < 100) setState(() => _extra[item.id] = count + 1);
  }

  int? _suggestedReps(TodayPlanItemModel item, int number) {
    if (number > item.targetSets) return null;
    final target = item.targetForSet(number);
    if (target == null) return int.tryParse(item.targetReps);
    if (target['repsMin'] != target['repsMax']) return null;
    return (target['repsMax'] as num?)?.toInt();
  }

  double? _suggestedWeight(TodayPlanItemModel item, int number) {
    if (number > item.targetSets) return null;
    final target = item.targetForSet(number);
    if (target != null) return (target['weightKg'] as num?)?.toDouble();
    return item.targetWeight > 0 ? item.targetWeight : null;
  }

  Widget _restCard() => ValueListenableBuilder<DateTime>(
      valueListenable: _clock,
      builder: (_, now, __) {
        final remaining =
            (_restEnd?.difference(now).inSeconds ?? 0).clamp(0, 1800);
        return TrainingSurface(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(children: [
              const Icon(CupertinoIcons.timer, size: 20, color: trainingMuted),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      remaining > 0
                          ? copy('Rest')
                          : copy('Ready for your next set'),
                      style: const TextStyle(fontSize: 13))),
              if (remaining > 0)
                Text(
                    '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()])),
              IconButton(
                  tooltip: copy('Add 30 seconds'),
                  onPressed: () => _rest((remaining + 30).clamp(0, 1800)),
                  icon: const Icon(CupertinoIcons.plus, size: 16)),
              if (remaining > 0)
                IconButton(
                    tooltip: copy('Skip rest'),
                    onPressed: () => _rest(0),
                    icon: const Icon(CupertinoIcons.forward_end, size: 16)),
            ]));
      });
  Widget _summary() => ListView(padding: const EdgeInsets.all(18), children: [
        const SizedBox(height: 30),
        const Icon(CupertinoIcons.checkmark_circle_fill,
            size: 54, color: trainingSilver),
        const SizedBox(height: 18),
        Text(
            copy(_day.pendingSync
                ? 'Workout saved on this phone'
                : 'Workout complete'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -.7)),
        const SizedBox(height: 8),
        Text(_day.date,
            textAlign: TextAlign.center,
            style: const TextStyle(color: trainingMuted, fontSize: 13)),
        const SizedBox(height: 28),
        if (_day.pendingSync) ...[
          WorkoutSyncNotice(
              blocked: _day.syncBlocked, onRetry: () => _sync(retry: true)),
          const SizedBox(height: 16),
        ],
        TrainingSurface(
            child: Column(children: [
          _stat(
              'Duration',
              copy('{minutes} min',
                  values: {'minutes': (_day.durationSeconds / 60).ceil()})),
          const Divider(color: Color(0xFF333333)),
          _stat('Logged sets', '${_day.loggedSets}'),
          const Divider(color: Color(0xFF333333)),
          _stat('Volume', '${_day.volume.toStringAsFixed(0)} kg'),
          const Divider(color: Color(0xFF333333)),
          _stat('Skipped', '${_day.skipped}'),
        ])),
        const SizedBox(height: 16),
        TextButton.icon(
            onPressed: () => setState(() => _editingFinished = true),
            icon: const Icon(CupertinoIcons.pencil),
            label: Text(copy('Edit logged sets'))),
        if (_day.loggedSets == 0)
          Text(copy('No sets were logged. Your body map is unchanged.'),
              style: const TextStyle(color: trainingMuted, fontSize: 13)),
        const SizedBox(height: 20),
        TrainingButton(
            label: 'Done',
            primary: true,
            onPressed: () => Navigator.pop(context)),
      ]);
  Widget _stat(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(
            child: Text(copy(label),
                style: const TextStyle(color: trainingMuted, fontSize: 14))),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ]));
}
