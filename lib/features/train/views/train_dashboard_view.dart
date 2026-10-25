import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../components/training_widgets.dart';
import '../components/training_targets.dart';
import '../components/workout_item_actions.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';
import 'exercise_detail_view.dart';
import 'exercise_library_screen.dart';
import 'workout_session_view.dart';
import 'saved_routines_view.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../planner/views/weekly_plan_card.dart';
import '../components/reschedule_workout_sheet.dart';
import '../../../core/theme/fitness_theme.dart';

class TrainView extends StatefulWidget {
  final bool standalone;
  final bool editOnly;
  final bool isActive;
  final String? initialDate;
  const TrainView(
      {super.key,
      this.standalone = false,
      this.editOnly = false,
      this.isActive = true,
      this.initialDate});
  @override
  State<TrainView> createState() => _TrainViewState();
}

class _TrainViewState extends State<TrainView> with WidgetsBindingObserver {
  String _date = CacheScope.todayKey();
  TrainingDay? _day;
  bool _loading = true, _busy = false;
  String? _error;
  int _generation = 0;
  Timer? _syncTimer;
  StreamSubscription<TrainingDay>? _subscription;
  final _repo = TrainingRepository.shared;
  String copy(String key, {Map<String, Object> values = const {}}) =>
      fitnessText(context, key, values: values);

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? CacheScope.todayKey();
    WidgetsBinding.instance.addObserver(this);
    LanguageManager.shared.addListener(_localeChanged);
    _subscription = _repo.changes.stream.listen((day) {
      if (mounted && day.date == _date) setState(() => _day = day);
    });
    _load();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.isActive && !_busy && _day?.pendingSync == true) {
        unawaited(_repo.syncPending().catchError((Object _) {}));
      }
    });
  }

  void _localeChanged() {
    setState(() {
      _day = null;
      _loading = true;
    });
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final generation = ++_generation;
    final date = _date;
    final cached = await _repo.cached(date);
    if (mounted && generation == _generation && cached != null) {
      setState(() {
        _day = cached;
        _loading = false;
      });
    }
    try {
      final day = await _repo.load(date, refresh: refresh);
      if (mounted && generation == _generation) {
        setState(() {
          _day = day;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = 'Could not sync. Pull to retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LanguageManager.shared.removeListener(_localeChanged);
    _subscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TrainView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _load();
  }

  Future<void> _action(Future<Object?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
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

  Future<void> _add({TodayPlanItemModel? replace}) async {
    final exercise = await pickTrainingExercise(context,
        workoutDate:
            DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString())
                .format(DateTime.parse(_date)));
    if (exercise == null || !mounted) return;
    final input = await editTrainingTargets(
        context,
        TodayPlanItemModel(
          id: '',
          dayOfWeek: '',
          orderIndex: 0,
          targetSets: replace?.targetSets ?? 3,
          targetReps: replace?.targetReps ?? '10',
          targetWeight: 0,
          restSeconds: replace?.restSeconds ?? 90,
          status: 'NOT_STARTED',
          exercise: exercise,
        ));
    if (input == null || !mounted) return;
    await _action(() => _repo.mutate(_date, replace == null ? 'POST' : 'PUT',
            replace == null ? '/items' : '/items/${replace.id}',
            data: {
              ...input,
              'workoutId': exercise.id,
            }));
  }

  Future<void> _start() async {
    if (_day?.started != true && _date != CacheScope.todayKey()) return;
    await _action(() async {
      final day = _day?.started == true
          ? _day!
          : await _repo.mutate(_date, 'POST', '/start');
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WorkoutSessionView(initial: day)));
      }
      return null;
    });
    await _load();
  }

  Future<void> _restToday() async {
    final changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: FitnessTheme.surface,
        builder: (_) => FractionallySizedBox(
            heightFactor: .9,
            child: FitnessTheme(child: RescheduleWorkoutSheet(date: _date))));
    if (changed == true && mounted) await _load(refresh: true);
  }

  Future<void> _saveRoutine() async {
    final day = _day;
    if (day == null || day.items.isEmpty) return;
    final name = await trainingName(context, 'Save routine',
        day.name == 'Workout' ? copy('Workout') : day.name);
    if (name != null) {
      await _action(() => _repo.mutate(_date, 'POST', '/routines', data: {
            'name': name,
            'items': day.items.map(TrainingDay.targets).toList(),
          }));
    }
  }

  Future<void> _edit(TodayPlanItemModel item, String action) async {
    final day = _day!;
    if (action == 'Edit targets') {
      final targets = await editTrainingTargets(context, item);
      if (targets != null) {
        await _action(() => _repo.mutate(
            _date, 'PATCH', '/items/${item.id}/targets',
            data: targets));
      }
      return;
    }
    if (action == 'Replace') {
      await _add(replace: item);
      return;
    }
    if (action == 'Remove') {
      await _action(() => _repo.mutate(_date, 'DELETE', '/items/${item.id}'));
      return;
    }
    final ids = day.items.map((row) => row.id).toList();
    final index = ids.indexOf(item.id);
    final next = action == 'Move up' ? index - 1 : index + 1;
    if (next < 0 || next >= ids.length) return;
    ids[index] = ids[next];
    ids[next] = item.id;
    await _action(
        () => _repo.mutate(_date, 'PUT', '/order', data: {'itemIds': ids}));
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme.copyWith(
          primary: trainingSilver,
          secondary: trainingSilver,
        );
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: Scaffold(
        backgroundColor: DSColors.bg,
        body: SafeArea(
            bottom: false,
            child: Column(children: [
              _header(locale),
              Expanded(
                  child: RefreshIndicator(
                color: trainingSilver,
                onRefresh: () => _load(refresh: true),
                child: MotionEntrance(
                    child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      widget.standalone
                          ? 28
                          : LiquidSilverBottomBar.scrollBottomInset(context)),
                  children: [
                    if (day?.pendingSync == true) ...[
                      WorkoutSyncNotice(
                          blocked: day!.syncBlocked,
                          onRetry: () => _load(refresh: true)),
                      const SizedBox(height: 14),
                    ],
                    if (!widget.editOnly) ...[
                      _exploreButton(),
                      const SizedBox(height: 16),
                      _week(locale),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(copy(_error!),
                              style: const TextStyle(
                                  color: trainingMuted, fontSize: 12))),
                    if (_loading && day == null)
                      const SizedBox(
                          height: 150,
                          child: Center(child: CupertinoActivityIndicator()))
                    else if (day != null) ...[
                      if (!widget.editOnly) _sessionCard(day),
                      if (widget.editOnly) _editorSummary(day),
                      const SizedBox(height: 18),
                      _section('Exercises',
                          icon: day.finished || widget.editOnly
                              ? null
                              : CupertinoIcons.plus,
                          tooltip: 'Add exercise',
                          action: _busy ? null : _add),
                      const SizedBox(height: 8),
                      if (day.items.isEmpty)
                        TrainingSurface(
                            child: Text(
                                copy(
                                    'Build your workout or choose a saved routine.'),
                                style: const TextStyle(
                                    color: trainingMuted,
                                    fontSize: 13,
                                    height: 1.4)))
                      else
                        TrainingSurface(
                            padding: EdgeInsets.zero,
                            child: Column(children: [
                              for (var index = 0;
                                  index < day.items.length;
                                  index++) ...[
                                _exercise(day.items[index], day),
                                if (index < day.items.length - 1)
                                  const Padding(
                                      padding:
                                          EdgeInsets.only(left: 76, right: 14),
                                      child: Divider(
                                          height: 1,
                                          thickness: .5,
                                          color: Color(0x18FFFFFF))),
                              ],
                            ])),
                      if (!widget.editOnly) ...[
                        const SizedBox(height: 18),
                        _section('Saved routines',
                            icon: day.items.isEmpty
                                ? null
                                : CupertinoIcons.bookmark,
                            tooltip: 'Save routine',
                            action: _busy ? null : _saveRoutine),
                        const SizedBox(height: 8),
                        TrainingSurface(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            child: day.routines.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(children: [
                                      const Icon(CupertinoIcons.bookmark,
                                          size: 19, color: trainingMuted),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(
                                              copy(
                                                  'Save a workout to use it again.'),
                                              style: const TextStyle(
                                                  color: trainingMuted,
                                                  fontSize: 13,
                                                  height: 1.4))),
                                    ]))
                                : Column(children: [
                                    for (final routine in day.routines.take(3))
                                      _routine(routine, day),
                                    if (day.routines.length > 3)
                                      TextButton(
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                                AppPageRoute<void>(
                                                    page: SavedRoutinesView(
                                                        initial: day)));
                                            await _load(refresh: true);
                                          },
                                          child: Text(copy('View all'))),
                                  ])),
                        const SizedBox(height: 20),
                        WeeklyPlanCard(
                            isActive: widget.isActive, onReturn: _load),
                      ],
                    ],
                  ],
                )),
              )),
            ])),
      ),
    );
  }

  Widget _editorSummary(TrainingDay day) => TrainingSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(day.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.5)),
          const SizedBox(height: 8),
          Text(
              copy(day.finished
                  ? 'This workout is already finished.'
                  : 'Changes are saved to this day in your training schedule.'),
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: trainingMuted)),
          if (!day.finished) ...[
            const SizedBox(height: 16),
            TrainingButton(
                label: 'Add exercise',
                icon: CupertinoIcons.plus,
                primary: true,
                onPressed: _busy ? null : _add),
          ],
        ]),
      );

  Widget _header(String locale) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Row(children: [
          if (widget.standalone)
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.back, size: 22)),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(copy(widget.editOnly ? 'Edit workout' : 'Train'),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.6)),
                const SizedBox(height: 5),
                Text(
                    DateFormat('EEEE, MMM d', locale)
                        .format(DateTime.parse(_date)),
                    style: const TextStyle(fontSize: 12, color: trainingMuted)),
              ])),
        ]),
      );

  Widget _exploreButton() => TrainingSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ExerciseLibraryView(
                onExerciseAdded: _load,
                workoutDate: DateFormat.yMMMEd().format(DateTime.parse(_date)),
                addToWorkout: (exercise) async {
                  try {
                    if (_day?.finished == true) return false;
                    await _repo.mutate(_date, 'POST', '/items', data: {
                      'workoutId': exercise.id,
                      'targetSets': 3,
                      'targetReps': '10',
                      'targetWeight': 0,
                      'restSeconds': 90,
                    });
                    return true;
                  } catch (_) {
                    return false;
                  }
                })));
        await _load();
      },
      child: Row(children: [
        const Icon(CupertinoIcons.search, size: 20, color: trainingSilver),
        const SizedBox(width: 12),
        Expanded(
            child: Text(copy('Explore exercises'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        const SizedBox(width: 12),
        const Icon(CupertinoIcons.chevron_right,
            size: 16, color: trainingMuted),
      ]));
  Widget _section(String title,
          {IconData? icon, String? tooltip, VoidCallback? action}) =>
      Row(children: [
        Expanded(
            child: Text(copy(title),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2))),
        if (icon != null)
          SizedBox(
              height: 38,
              width: 44,
              child: IconButton(
                  tooltip: copy(tooltip ?? title),
                  onPressed: action,
                  icon: Icon(icon, size: 18, color: trainingSilver))),
      ]);

  Widget _week(String locale) {
    final selected = DateTime.parse(_date);
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text(DateFormat('MMM d', locale).format(monday),
                style: const TextStyle(fontSize: 12, color: trainingMuted))),
        _weekControl(
            CupertinoIcons.chevron_left,
            'Previous week',
            () => _select(CacheScope.todayKey(
                selected.subtract(const Duration(days: 7))))),
        _weekControl(CupertinoIcons.calendar, 'Today',
            () => _select(CacheScope.todayKey())),
        _weekControl(
            CupertinoIcons.chevron_right,
            'Next week',
            () => _select(
                CacheScope.todayKey(selected.add(const Duration(days: 7))))),
      ]),
      const SizedBox(height: 5),
      TrainingSurface(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
          child: Row(
              children: List.generate(7, (index) {
            final date = monday.add(Duration(days: index));
            final key = CacheScope.todayKey(date);
            final active = key == _date;
            final status = _day?.week
                .where((row) => row['date'] == key)
                .firstOrNull?['status'];
            return Expanded(
                child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _busy ? null : () => _select(key),
              child: Column(children: [
                Text(DateFormat('EEEEE', locale).format(date),
                    style: const TextStyle(fontSize: 10, color: trainingMuted)),
                const SizedBox(height: 7),
                Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? trainingSilver : Colors.transparent),
                    child: Text('${date.day}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: active ? DSColors.bg : trainingSilver))),
                const SizedBox(height: 5),
                SizedBox(
                    height: 7,
                    child: status == 'COMPLETED'
                        ? const Icon(CupertinoIcons.checkmark,
                            size: 8, color: trainingSilver)
                        : status == 'REST_DAY'
                            ? const Icon(CupertinoIcons.moon,
                                size: 8, color: trainingMuted)
                            : Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: status == 'SCHEDULED' ||
                                            status == 'IN_PROGRESS'
                                        ? trainingMuted
                                        : Colors.transparent))),
              ]),
            ));
          }))),
    ]);
  }

  Widget _weekControl(IconData icon, String label, VoidCallback action) =>
      SizedBox(
        width: 38,
        height: 36,
        child: IconButton(
            tooltip: copy(label),
            onPressed: _busy ? null : action,
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 16, color: trainingMuted)),
      );

  void _select(String date) {
    setState(() {
      _date = date;
      _day = null;
      _loading = true;
      _error = null;
    });
    _load();
  }

  Widget _sessionCard(TrainingDay day) {
    final completed = day.items.where((item) => item.isCompleted).length;
    final progress = day.finished
        ? 1.0
        : day.items.isEmpty
            ? 0.0
            : completed / day.items.length;
    final title = day.name != 'Workout'
        ? day.name
        : copy(day.finished
            ? (day.pendingSync ? 'Saved on this phone' : 'Workout complete')
            : day.restDay
                ? 'Recover & recharge'
                : 'Your workout');
    final detail = day.finished
        ? copy('{sets} sets · {minutes} min · {skipped} skipped', values: {
            'sets': day.loggedSets,
            'minutes': (day.durationSeconds / 60).ceil(),
            'skipped': day.skipped
          })
        : day.restDay
            ? copy('Rest day')
            : day.started
                ? '${copy('Completed')}: $completed/${day.items.length} · ${copy('{count} logged sets', values: {
                        'count': day.loggedSets
                      })}'
                : '${copy('{count} exercises', values: {
                        'count': day.items.length
                      })}'
                    '${day.items.isEmpty ? '' : ' · ≈ ${copy('{minutes} min', values: {
                            'minutes': day.estimatedMinutes
                          })}'}';
    final label = day.finished
        ? 'View summary'
        : day.restDay
            ? 'Build a workout'
            : day.items.isEmpty
                ? 'Add exercise'
                : day.started
                    ? 'Resume workout'
                    : 'Start workout';
    final VoidCallback? action = _busy
        ? null
        : day.finished
            ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => WorkoutSessionView(initial: day)))
            : day.restDay
                ? () => _action(() => _repo
                    .mutate(_date, 'PATCH', '/day', data: {'restDay': false}))
                : day.items.isEmpty
                    ? _add
                    : (!day.started && _date != CacheScope.todayKey())
                        ? null
                        : _start;
    return TrainingSurface(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            SizedBox(
                width: 48,
                height: 48,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                      child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          color: trainingSilver,
                          backgroundColor: const Color(0xFF393939),
                          strokeCap: StrokeCap.round)),
                  Icon(
                      day.finished
                          ? CupertinoIcons.checkmark
                          : day.restDay
                              ? CupertinoIcons.moon
                              : CupertinoIcons.bolt,
                      size: 21,
                      color: trainingSilver),
                ])),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.3)),
                  const SizedBox(height: 5),
                  Text(detail,
                      style: const TextStyle(
                          fontSize: 12, color: trainingMuted, height: 1.4)),
                ])),
            if (!day.finished)
              PopupMenuButton<String>(
                  tooltip: copy('Your session'),
                  enabled: !_busy,
                  icon: const Icon(CupertinoIcons.ellipsis,
                      size: 18, color: trainingMuted),
                  color: const Color(0xFF252525),
                  itemBuilder: (_) => [
                        'Rename workout',
                        if (_date == CacheScope.todayKey() &&
                            day.json['canReschedule'] == true)
                          'Rest today',
                        if (!day.started &&
                            !day.restDay &&
                            !(_date == CacheScope.todayKey() &&
                                day.json['canReschedule'] == true))
                          'Set as rest day'
                      ]
                          .map((value) => PopupMenuItem(
                              value: value, child: Text(copy(value))))
                          .toList(),
                  onSelected: (value) async {
                    if (value == 'Rest today') {
                      await _restToday();
                    } else if (value == 'Set as rest day') {
                      await _action(() => _repo.mutate(_date, 'PATCH', '/day',
                          data: {'restDay': true}));
                    } else {
                      final name = await trainingName(context, 'Rename workout',
                          day.name == 'Workout' ? copy('Workout') : day.name);
                      if (name != null) {
                        await _action(() => _repo.mutate(_date, 'PATCH', '/day',
                            data: {'name': name}));
                      }
                    }
                  }),
          ]),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: TrainingButton(
                  label: label,
                  primary: !day.finished,
                  icon: day.finished
                      ? CupertinoIcons.checkmark_circle
                      : day.items.isEmpty
                          ? CupertinoIcons.plus
                          : day.restDay
                              ? CupertinoIcons.bolt
                              : CupertinoIcons.play_fill,
                  onPressed: action)),
          if (_date == CacheScope.todayKey() &&
              day.json['canReschedule'] == true)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _busy ? null : _restToday,
                    child: Text(copy('Rest today'),
                        style: const TextStyle(color: trainingMuted)))),
        ]));
  }

  Future<void> _openExercise(TodayPlanItemModel item, TrainingDay day) async {
    if (!widget.editOnly && day.started && !day.finished) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              WorkoutSessionView(initial: day, initialItemId: item.id)));
      await _load();
    } else {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ExerciseDetailView(exercise: item.exercise)));
    }
  }

  Future<void> _completeExercise(
      TodayPlanItemModel item, TrainingDay day) async {
    await _action(() async {
      if (day.logs(item.id).isEmpty) {
        await _openExercise(item, day);
        return null;
      }
      return _repo.mutate(_date, 'PATCH', '/items/${item.id}/status',
          data: {'status': 'COMPLETED'});
    });
  }

  Widget _exercise(TodayPlanItemModel item, TrainingDay day) => InkWell(
        onTap: () => _openExercise(item, day),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
            child: Column(children: [
              Row(children: [
                TrainingPoster(exercise: item.exercise),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(item.exercise.displayName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3)),
                      const SizedBox(height: 4),
                      Text(
                          copy('{sets} sets · {reps} reps', values: {
                            'sets': item.targetSets,
                            'reps': item.targetReps
                          }),
                          style: const TextStyle(
                              fontSize: 11, color: trainingMuted)),
                    ])),
                if (!day.finished)
                  PopupMenuButton<String>(
                      tooltip: copy('Edit exercise'),
                      enabled: !_busy,
                      color: const Color(0xFF252525),
                      icon: const Icon(CupertinoIcons.ellipsis,
                          size: 17, color: trainingMuted),
                      onSelected: (action) => _edit(item, action),
                      itemBuilder: (_) => [
                            'Edit targets',
                            'Move up',
                            'Move down',
                            if (day.logs(item.id).isEmpty) ...[
                              'Replace',
                              'Remove'
                            ]
                          ]
                              .map((value) => PopupMenuItem(
                                  value: value, child: Text(copy(value))))
                              .toList()),
              ]),
              if (!widget.editOnly && day.started && !day.finished)
                Padding(
                    padding: const EdgeInsets.only(left: 60, top: 8),
                    child: WorkoutItemActions(
                        item: item,
                        busy: _busy,
                        doneLabel:
                            day.logs(item.id).isEmpty ? 'Log sets' : 'Done',
                        onDone: () => _completeExercise(item, day),
                        onSkip: () => _action(() => _repo.mutate(
                            _date, 'PATCH', '/items/${item.id}/status',
                            data: {'status': 'SKIPPED'})),
                        onUndo: () => _action(() => _repo.mutate(
                            _date, 'PATCH', '/items/${item.id}/status',
                            data: {'status': 'NOT_STARTED'})))),
            ])),
      );

  Widget _routine(Map<String, dynamic> routine, TrainingDay day) => InkWell(
        onTap: _busy
            ? null
            : () async {
                await Navigator.of(context).push(AppPageRoute<void>(
                    page: RoutineDetailView(day: day, routine: routine)));
                await _load(refresh: true);
              },
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(CupertinoIcons.bookmark,
                  size: 18, color: trainingMuted),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(routine['name'] as String,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(
                        copy('{count} exercises',
                            values: {'count': routine['count'] as int}),
                        style: const TextStyle(
                            fontSize: 11, color: trainingMuted)),
                  ])),
              IconButton(
                  tooltip: copy('Delete routine'),
                  onPressed: _busy
                      ? null
                      : () => _action(() => _repo.mutate(
                          _date, 'DELETE', '/routines/${routine['id']}')),
                  icon: const Icon(CupertinoIcons.trash,
                      size: 16, color: trainingMuted)),
            ])),
      );
}
