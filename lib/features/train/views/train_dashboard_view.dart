import '../../today/components/weekly_rhythm_calendar.dart';
import 'package:setcraft/core/theme/ds_motion.dart';
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
import '../../../core/components/session_overview_card.dart';
import '../components/training_exercise_row.dart';
import '../components/training_targets.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';
import 'exercise_detail_view.dart';
import 'exercise_library_screen.dart';
import 'workout_session_view.dart';
import 'saved_routines_view.dart';
import 'create_workout_view.dart';
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
  bool _loading = true, _busy = false, _opening = false;
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
        await Navigator.of(context).push(AppPageRoute<void>(
            builder: (_) => WorkoutSessionView(initial: day)));
      }
      return null;
    });
    await _load();
  }

  Future<void> _restToday() async {
    if (_busy || _opening) return;
    setState(() => _opening = true);
    try {
      final changed = await showModalBottomSheet<bool>(
          sheetAnimationStyle: DSMotion.sheetStyle(context),
          context: context,
          isScrollControlled: true,
          backgroundColor: FitnessTheme.surface,
          builder: (_) => FractionallySizedBox(
              heightFactor: .9,
              child: FitnessTheme(child: RescheduleWorkoutSheet(date: _date))));
      if (changed == true && mounted) await _load(refresh: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _saveRoutine() async {
    final day = _day;
    if (_busy || _opening || day == null || day.items.isEmpty) return;
    setState(() => _opening = true);
    try {
      final route = AppPageRoute<TrainingDay>(
          page: CreateWorkoutView(
              date: _date,
              initialName: day.name == 'Workout' ? copy('Workout') : day.name,
              initialItems: day.items));
      await Navigator.of(context).push(route);
      await route.completed;
      if (mounted) await _load(refresh: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _renameWorkout() async {
    final day = _day;
    if (_busy || _opening || day == null || day.finished) return;
    setState(() => _opening = true);
    String? name;
    try {
      name = await trainingName(context, 'Rename workout',
          day.name == 'Workout' ? copy('Workout') : day.name);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    final title = name?.trim();
    if (!mounted || title == null || title.isEmpty) return;
    await _action(
        () => _repo.mutate(_date, 'PATCH', '/day', data: {'name': title}));
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

  Future<void> _myWorkouts() async {
    if (_busy || _day == null) return;
    await Navigator.of(context)
        .push(AppPageRoute<void>(page: SavedRoutinesView(initial: _day!)));
    if (mounted) await _load(refresh: true);
  }

  Future<void> _editWorkout() async {
    if (_busy || _opening || _day == null) return;
    setState(() => _opening = true);
    try {
      final route = AppPageRoute<void>(
          page:
              TrainView(standalone: true, editOnly: true, initialDate: _date));
      await Navigator.of(context).push(route);
      await route.completed;
      if (mounted) await _load(refresh: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final locale = Localizations.localeOf(context).toString();
    return FitnessTheme(
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
                key: const ValueKey('train-scroll'),
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
                  if (!widget.editOnly) ...[
                    _exploreButton(),
                    const SizedBox(height: 14),
                    _week(locale),
                    const SizedBox(height: 18)
                  ],
                  if (day?.pendingSync == true) ...[
                    WorkoutSyncNotice(
                        blocked: day!.syncBlocked,
                        onRetry: () => _load(refresh: true)),
                    const SizedBox(height: 14),
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
                    if (!widget.editOnly)
                      _sessionCard(day)
                    else
                      _editorSummary(day),
                    const SizedBox(height: 22),
                    _section('Exercises',
                        actionLabel: widget.editOnly
                            ? day.finished
                                ? null
                                : 'Add exercise'
                            : day.finished
                                ? 'Details'
                                : 'Edit',
                        action: _busy || _opening
                            ? null
                            : widget.editOnly
                                ? _add
                                : _editWorkout),
                    const SizedBox(height: 10),
                    if (day.items.isEmpty)
                      TrainingSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Text(copy('No exercises yet'),
                                style: const TextStyle(
                                    fontSize: 14, color: trainingMuted)),
                            if (!day.finished) ...[
                              const SizedBox(height: 12),
                              TrainingButton(
                                  label: 'Add exercise',
                                  onPressed: _busy ? null : _add),
                            ],
                          ]))
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
                                    padding: EdgeInsetsDirectional.only(
                                        start: 78, end: 14),
                                    child: Divider(
                                        height: 1,
                                        thickness: .5,
                                        color: DSColors.border)),
                            ],
                          ])),
                    if (!widget.editOnly) ...[
                      const SizedBox(height: 22),
                      WeeklyPlanCard(
                          key: const ValueKey('train-weekly-plan'),
                          compact: true,
                          isActive: widget.isActive,
                          onReturn: _load),
                      const SizedBox(height: 10),
                      TrainingSurface(
                          key: const ValueKey('train-my-workouts'),
                          padding: EdgeInsets.zero,
                          onTap: _busy ? null : _myWorkouts,
                          child: _resource(
                              'My workouts',
                              day.routines.isEmpty
                                  ? copy('Create your first workout')
                                  : copy(
                                      day.routines.length == 1
                                          ? '{count} saved workout'
                                          : '{count} saved workouts',
                                      values: {'count': day.routines.length}))),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              )),
            )),
          ])),
    ));
  }

  Widget _editorSummary(TrainingDay day) {
    final reschedule =
        _date == CacheScope.todayKey() && day.json['canReschedule'] == true;
    final actions = <(String, String, VoidCallback)>[
      if (!day.finished) ('rename', 'Rename workout', _renameWorkout),
      if (day.items.isNotEmpty) ('save', 'Save to My workouts', _saveRoutine),
      if (!day.finished && reschedule)
        ('rest', 'Rest today', _restToday)
      else if (!day.finished && !day.started && !day.restDay)
        (
          'rest',
          'Set as rest day',
          () => _action(() =>
              _repo.mutate(_date, 'PATCH', '/day', data: {'restDay': true}))
        ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(day.name,
          style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -.65)),
      if (day.finished) ...[
        const SizedBox(height: 8),
        Text(copy('This workout is already finished.'),
            style: const TextStyle(
                fontSize: 12, height: 1.4, color: trainingMuted)),
      ],
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 18),
        TrainingSurface(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0)
                  const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: DSColors.border),
                ListTile(
                    key: ValueKey('train-manage-${actions[index].$1}'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(copy(actions[index].$2),
                        style: const TextStyle(
                            fontSize: 13, height: 1.4, color: trainingSilver)),
                    trailing: const Icon(CupertinoIcons.chevron_right,
                        size: 12, color: trainingMuted),
                    onTap: _busy || _opening ? null : actions[index].$3),
              ],
            ])),
      ],
    ]);
  }

  Widget _resource(String title, String? subtitle) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(copy(title),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, height: 1.4, color: trainingMuted)),
                ],
              ])),
          const SizedBox(width: 12),
          const Icon(CupertinoIcons.chevron_right,
              size: 12, color: trainingMuted),
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
                Text(
                    copy(widget.editOnly
                        ? _day?.finished == true
                            ? 'Workout'
                            : 'Edit workout'
                        : 'Train'),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.6)),
              ])),
        ]),
      );

  Widget _exploreButton() => TrainingSurface(
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.of(context).push(AppPageRoute<void>(
            builder: (_) => ExerciseLibraryView(
                onExerciseAdded: () => _load(refresh: true))));
        await _load();
      },
      child: _resource('Exercise library', null));

  Widget _section(String title, {String? actionLabel, VoidCallback? action}) =>
      LayoutBuilder(builder: (context, bounds) {
        final heading = Text(copy(title),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -.3));
        if (actionLabel == null) return heading;
        final button = TextButton(
            onPressed: action,
            style: TextButton.styleFrom(foregroundColor: trainingSilver),
            child:
                Text(copy(actionLabel), style: const TextStyle(fontSize: 12)));
        if (MediaQuery.textScalerOf(context).scale(17) > 22 ||
            bounds.maxWidth < 260) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                Align(alignment: AlignmentDirectional.centerEnd, child: button)
              ]);
        }
        return Row(children: [Expanded(child: heading), button]);
      });

  Widget _week(String locale) {
    final selected = DateTime.parse(_date);
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text(
                '${DateFormat.MMMd(locale).format(monday)} – ${DateFormat.MMMd(locale).format(monday.add(const Duration(days: 6)))}',
                style: const TextStyle(fontSize: 11, color: trainingMuted))),
        WeeklyRhythmCalendarButton(
            selectedDate: selected,
            today: DateTime.now(),
            allowFuture: true,
            onSelected:
                _busy ? null : (date) => _select(CacheScope.todayKey(date))),
      ]),
      const SizedBox(height: 4),
      TrainingSurface(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
              children: List.generate(7, (index) {
            final date = monday.add(Duration(days: index));
            final key = CacheScope.todayKey(date), active = key == _date;
            final status = _day?.week
                .where((row) => row['date'] == key)
                .firstOrNull?['status'];
            return Expanded(
                child: Semantics(
              selected: active,
              label:
                  '${DateFormat.yMMMMEEEEd(locale).format(date)}${status == 'COMPLETED' ? ', ${copy('Completed')}' : status == 'REST_DAY' ? ', ${copy('Rest day')}' : ''}',
              button: true,
              onTap: _busy ? null : () => _select(key),
              excludeSemantics: true,
              child: InkWell(
                onTap: _busy ? null : () => _select(key),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(children: [
                      Text(DateFormat('EEEEE', locale).format(date),
                          style: const TextStyle(
                              fontSize: 10, color: trainingMuted)),
                      const SizedBox(height: 7),
                      Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color:
                                  active ? trainingSilver : Colors.transparent),
                          child: Text('${date.day}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      active ? DSColors.bg : trainingSilver))),
                      const SizedBox(height: 5),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status == 'COMPLETED'
                                  ? trainingSilver
                                  : status == 'SCHEDULED' ||
                                          status == 'IN_PROGRESS'
                                      ? trainingMuted
                                      : Colors.transparent)),
                    ])),
              ),
            ));
          }))),
    ]);
  }

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
    final title = day.name != 'Workout'
        ? day.name
        : copy(day.finished
            ? 'Workout complete'
            : day.restDay
                ? 'Recover & recharge'
                : 'Your workout');
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
            ? () => Navigator.of(context).push(AppPageRoute<void>(
                builder: (_) => WorkoutSessionView(initial: day)))
            : day.restDay
                ? () => _action(() => _repo
                    .mutate(_date, 'PATCH', '/day', data: {'restDay': false}))
                : day.items.isEmpty
                    ? _add
                    : (!day.started && _date != CacheScope.todayKey())
                        ? null
                        : _start;
    return SessionOverviewCard(
      key: const ValueKey('train-session-card'),
      status: day.finished
          ? SessionOverviewStatus.completed
          : day.restDay
              ? SessionOverviewStatus.restDay
              : day.started
                  ? SessionOverviewStatus.inProgress
                  : SessionOverviewStatus.notStarted,
      title: title,
      metrics: [
        if (day.finished && day.durationSeconds > 0)
          copy('{minutes} min',
              values: {'minutes': (day.durationSeconds / 60).ceil()})
        else if (!day.restDay && day.estimatedMinutes > 0)
          copy('About {minutes} min',
              values: {'minutes': day.estimatedMinutes}),
        if (!day.restDay && day.items.isNotEmpty)
          copy(day.items.length == 1 ? '{count} exercise' : '{count} exercises',
              values: {'count': day.items.length}),
      ],
      caption: day.started && !day.restDay
          ? Text(copy('{count} logged sets', values: {'count': day.loggedSets}),
              style: const TextStyle(color: trainingMuted, fontSize: 11))
          : null,
      actionLabel: copy(label),
      onAction: action,
      busy: _busy,
      primary: !day.restDay,
    );
  }

  Future<void> _openExercise(TodayPlanItemModel item, TrainingDay day) async {
    if (!widget.editOnly && day.started && !day.finished) {
      await Navigator.of(context).push(AppPageRoute<void>(
          builder: (_) =>
              WorkoutSessionView(initial: day, initialItemId: item.id)));
      await _load();
    } else {
      await Navigator.of(context).push(AppPageRoute<void>(
          builder: (_) => ExerciseDetailView(exercise: item.exercise)));
    }
  }

  Widget _exercise(TodayPlanItemModel item, TrainingDay day) =>
      TrainingExerciseRow(
        key: ValueKey('train-exercise-${item.id}'),
        item: item,
        subtitle: '${item.targetSets} × ${item.targetReps} ${copy('reps')}'
            '${item.isCompleted ? ' · ${copy('Completed')}' : item.isSkipped ? ' · ${copy('Skipped')}' : ''}',
        onTap: _busy
            ? null
            : () => widget.editOnly && !day.finished
                ? _edit(item, 'Edit targets')
                : _openExercise(item, day),
        trailing: widget.editOnly && !day.finished
            ? PopupMenuButton<String>(
                tooltip: copy('Edit exercise'),
                enabled: !_busy,
                color: DSColors.bgCard,
                icon: const Icon(CupertinoIcons.ellipsis,
                    size: 17, color: trainingMuted),
                onSelected: (action) => _edit(item, action),
                itemBuilder: (_) => [
                  'Edit targets',
                  'Move up',
                  'Move down',
                  if (day.logs(item.id).isEmpty) ...['Replace', 'Remove'],
                ]
                    .map((value) =>
                        PopupMenuItem(value: value, child: Text(copy(value))))
                    .toList(),
              )
            : null,
      );
}
