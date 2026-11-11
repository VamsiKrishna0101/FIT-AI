import '../components/workout_warmup.dart';
import '../../progress/components/progress_photos.dart';
import '../../progress/repositories/progress_photo_repository.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../notifications/services/rest_notification_service.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/media/fit_video_surface.dart';
import '../components/training_widgets.dart';
import '../components/workout_completion_summary.dart';
import '../components/workout_set_entry.dart';
import '../components/workout_rest_timer.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/services/weekly_plan_prompt_service.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../rating/services/rate_app_service.dart';
import '../models/training_session.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/training_repository.dart';
import '../components/workout_form_guide.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/watch/watch_models.dart';
import '../../../core/watch/watch_sync_service.dart';
import '../../../core/watch/components/virtual_watch_sheet.dart';

class WorkoutSessionView extends StatefulWidget {
  final TrainingDay initial;
  final String? initialItemId;
  final DateTime Function()? clock;
  const WorkoutSessionView(
      {super.key, required this.initial, this.initialItemId, this.clock});
  @override
  State<WorkoutSessionView> createState() => _WorkoutSessionViewState();
}

class _WorkoutSessionViewState extends State<WorkoutSessionView>
    with WidgetsBindingObserver {
  late TrainingDay _day;
  int _index = 0;
  bool _busy = false, _optionsOpen = false;
  final _scroll = ScrollController();
  final _selectedSets = <String, int>{};
  final _activeSelections = <String, ValueNotifier<int?>>{};
  final _setsVersion = ValueNotifier(0);
  final _collapsedDemos = <String>{};
  final _stepKeys = <int, GlobalKey>{};
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  bool _editingFinished = false;
  bool _warmupCompleted = false;

  bool get _hasWarmup {
    final raw = (_day.json['warmup'] as Map?)?.cast<String, dynamic>();
    final steps = (raw?['steps'] as List? ?? []);
    return steps.isNotEmpty;
  }

  bool get _isWarmupDone =>
      !_hasWarmup ||
      _warmupCompleted ||
      _day.loggedSets > 0 ||
      _day.items.any((item) => item.isCompleted);

  final _setEntries = <String, GlobalKey<WorkoutSetEntryState>>{};
  final _repo = TrainingRepository.shared;
  late final _clock = ValueNotifier(_now);
  Timer? _timer;
  StreamSubscription<TrainingDay>? _syncSubscription;
  StreamSubscription<WatchIncomingAction>? _watchSubscription;
  final _restState = ValueNotifier<WorkoutRest?>(null);
  // True while a rest countdown is running or paused with time left.
  final _resting = ValueNotifier(false);
  bool _restOpen = false, _restNotified = false;
  int _restVersion = 0;
  Future<Map<String, dynamic>>? _previous;
  String copy(String key, {Map<String, Object> values = const {}}) =>
      fitnessText(context, key, values: values);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _day = widget.initial;
    _warmupCompleted = _day.loggedSets > 0 || _day.items.any((item) => item.isCompleted);
    final pending = _day.items.indexWhere((item) => item.isPending);
    final selected =
        _day.items.indexWhere((item) => item.id == widget.initialItemId);
    _index = selected >= 0
        ? selected
        : pending < 0
            ? 0
            : pending;
    _loadPrevious();
    _restState.addListener(_syncResting);
    _restoreRest();
    _syncSubscription = _repo.changes.stream.listen((day) {
      if (!mounted || day.date != _day.date) return;
      setState(() {
        _day = day;
        if (_day.finished) _syncRestAlert();
        _index = _index.clamp(0, (_day.items.length - 1).clamp(0, 100));
      });
      _refreshSelections();
      _syncToWatch();
    });
    _watchSubscription =
        WatchSyncService.shared.actions.listen(_handleWatchAction);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToWatch();
      WatchSyncService.shared.startWatchApp();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
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

  void _tick() {
    _syncRestVisibility();
    final now = _now;
    _clock.value = now;
    _syncResting();
    final rest = _restState.value;
    if (rest != null &&
        !rest.isPaused &&
        rest.remaining(now) == 0 &&
        !_restNotified) {
      _restNotified = true;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (_restOpen || ModalRoute.of(context)?.isCurrent == true)) {
        unawaited(HapticFeedback.lightImpact());
      }
    }
  }

  void _syncResting() {
    final rest = _restState.value;
    _resting.value = rest != null && rest.remaining(_now) > 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRestVisibility();
  }

  void _syncRestVisibility() {
    unawaited(RestNotificationService.shared
        .setInAppTimerVisible(
          this,
          _restOpen || ModalRoute.of(context)?.isCurrent == true,
        )
        .catchError((Object _) {}));
  }

  Future<void> _restoreRest() async {
    if (_day.finished ||
        !DateUtils.isSameDay(DateTime.tryParse(_day.date), _now)) {
      return;
    }
    final version = _restVersion;
    try {
      final data = await _repo.restData(_day.date);
      if (!mounted || version != _restVersion) return;
      _restState.value = WorkoutRest.fromJson(data, _now);
      _syncRestAlert();
    } catch (_) {
      // Rest is optional; a cache read must never block logging a workout.
    }
  }

  void _loadPrevious() {
    if (_day.items.isNotEmpty) {
      _previous = _repo.previous(_day.date, _day.items[_index].exercise.id);
    }
  }

  @override
  void dispose() {
    unawaited(RestNotificationService.shared
        .setInAppTimerVisible(this, false)
        .catchError((Object _) {}));
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scroll.dispose();
    _syncSubscription?.cancel();
    _watchSubscription?.cancel();
    WatchSyncService.shared.clearSession();
    _restState.dispose();
    _resting.dispose();
    _clock.dispose();
    _setsVersion.dispose();
    for (final selection in _activeSelections.values) {
      selection.dispose();
    }
    super.dispose();
  }

  Future<void> _mutate(String method, String suffix,
      {Map<String, dynamic>? data}) async {
    final day = await _repo.mutate(_day.date, method, suffix, data: data);
    if (mounted) {
      if (!identical(_day, day)) setState(() => _day = day);
      _refreshSelections();
    }
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
        _updateRest(null);
        final next = _day.items.indexWhere((row) => row.isPending);
        if (next >= 0) {
          setState(() {
            _index = next;
            _loadPrevious();
          });
          _showCurrentStep();
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

  void _updateRest(WorkoutRest? rest) {
    if (!mounted) return;
    _restVersion++;
    _restNotified = false;
    _restState.value = rest;
    _syncRestAlert();
    _clock.value = _now;
    unawaited(_repo.saveRest(_day.date, rest?.toJson()).catchError((Object _) {
      // A timer cache failure must not turn a saved set into a failed save.
    }));
    _syncToWatch();
  }

  void _syncRestAlert() {
    final rest = _day.finished ? null : _restState.value;
    unawaited(RestNotificationService.shared
        .update(
          date: _day.date,
          end: rest?.end,
          paused: rest?.isPaused ?? false,
        )
        .catchError((Object _) {}));
  }

  void _syncToWatch() {
    if (!mounted) return;
    final rest = _restState.value;
    final restPayload = rest == null
        ? null
        : WatchRestPayload(
            isActive: true,
            exerciseName: rest.exercise,
            setNumber: rest.setNumber ?? 1,
            remainingSeconds: rest.remaining(_now),
            duration: rest.duration,
            isPaused: rest.isPaused,
            endTimeEpochMs: rest.end.millisecondsSinceEpoch,
          );

    final snapshot = WatchWorkoutSnapshot(
      sessionId: _day.session?['id']?.toString() ?? _day.date,
      date: _day.date,
      title: _day.name,
      activeItemIndex: _index,
      items: _day.items.asMap().entries.map((entry) {
        final item = entry.value;
        final rawLogs = _day.logs(item.id);
        return WatchExerciseItem(
          id: item.id,
          exerciseName: item.exercise.displayName,
          orderIndex: item.orderIndex,
          targetSets: item.targetSets,
          targetReps: item.targetReps,
          targetWeight: item.targetWeight,
          restSeconds: item.restSeconds,
          status: item.status,
          loggedSets: rawLogs
              .map((log) => WatchSetLog(
                    setNumber: (log['setNumber'] as num?)?.toInt() ?? 1,
                    weight: (log['weight'] as num?)?.toDouble() ?? 0.0,
                    reps: (log['reps'] as num?)?.toInt() ?? 0,
                    completed: log['completed'] != false,
                    rpe: (log['rpe'] as num?)?.toDouble(),
                  ))
              .toList(),
        );
      }).toList(),
      rest: restPayload,
    );

    WatchSyncService.shared.syncWorkoutState(snapshot);
    WatchSyncService.shared.syncRestState(restPayload);
  }

  void _handleWatchAction(WatchIncomingAction action) {
    if (!mounted) return;
    switch (action) {
      case WatchLogSetAction(
          :final itemId,
          :final setNumber,
          :final weight,
          :final reps
        ):
        final itemIndex = _day.items.indexWhere((i) => i.id == itemId);
        if (itemIndex >= 0) {
          _saveWatchSet(_day.items[itemIndex], setNumber, weight, reps);
        }
        break;
      case WatchSelectExerciseAction(:final itemId):
        final targetIndex = _day.items.indexWhere((i) => i.id == itemId);
        if (targetIndex >= 0 && targetIndex != _index) {
          setState(() {
            _index = targetIndex;
            _loadPrevious();
          });
          _showCurrentStep();
          _syncToWatch();
        }
        break;
      case WatchSkipExerciseAction(:final itemId):
        final targetIndex = _day.items.indexWhere((i) => i.id == itemId);
        if (targetIndex >= 0) {
          _status(_day.items[targetIndex], 'SKIPPED');
        }
        break;
      case WatchRestControlAction(:final operation):
        if (operation == 'EXTEND') {
          _addRest();
        } else if (operation == 'SKIP') {
          _updateRest(null);
        } else if (operation == 'TOGGLE_PAUSE') {
          final rest = _restState.value;
          if (rest != null) _updateRest(rest.togglePause(_now));
        }
        break;
      case WatchBiometricUpdateAction():
        break;
      case WatchFinishWorkoutAction():
        _finish();
        break;
    }
  }

  Future<void> _saveWatchSet(
      TodayPlanItemModel item, int number, double weight, int reps) async {
    final count = _setCount(item);
    final wasLogged =
        _day.logs(item.id).any((log) => log['setNumber'] == number);
    setState(() => _busy = true);
    try {
      await _mutate('PUT', '/items/${item.id}/sets', data: {
        'setNumber': number,
        'reps': reps,
        'weight': item.isBodyweight ? 0.0 : weight,
        'rpe': null,
      });
      if (mounted) {
        _clearSelection(item);
        if (!wasLogged) {
          if (_day.logs(item.id).length < count) {
            _startRest(item, number);
          } else if (_restState.value?.exercise == item.exercise.displayName) {
            _updateRest(null);
          }
        }
        _syncToWatch();
      }
    } catch (error) {
      _error(TrainingRepository.errorMessage(
          error, 'Could not save set from Watch.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startRest(TodayPlanItemModel item, int setNumber) {
    if (!mounted ||
        _day.finished ||
        !DateUtils.isSameDay(DateTime.tryParse(_day.date), _now)) {
      return;
    }
    final duration = item.restSeconds.clamp(0, 1800);
    if (duration == 0) return;
    _updateRest(WorkoutRest(
        end: _now.add(Duration(seconds: duration)),
        duration: duration,
        exercise: item.exercise.displayName,
        setNumber: setNumber));
  }

  void _addRest() {
    final rest = _restState.value;
    if (rest != null) _updateRest(rest.extend(_now));
  }

  Future<void> _showRest() async {
    if (_restOpen || _restState.value == null || !mounted) return;
    _restOpen = true;
    var closing = false;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: DSColors.bg,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: DSColors.border)),
        builder: (sheetContext) => FitnessTheme(
            child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(sheetContext).height * .88),
                  child: SingleChildScrollView(child: _restPanel(onClose: () {
                    if (closing || !sheetContext.mounted) return;
                    closing = true;
                    Navigator.of(sheetContext).pop();
                  })),
                ))),
      );
    } finally {
      if (mounted) _restOpen = false;
    }
  }

  Widget _restPanel({bool compact = false, VoidCallback? onClose}) {
    var displayed = _restState.value;
    return ValueListenableBuilder<WorkoutRest?>(
      valueListenable: _restState,
      builder: (_, value, __) {
        if (value != null) displayed = value;
        // Keep the last frame while the sheet slides out after Skip.
        final rest = value ?? (compact ? null : displayed);
        if (rest == null) return const SizedBox.shrink();
        return ValueListenableBuilder<DateTime>(
          valueListenable: _clock,
          builder: (_, now, __) => WorkoutRestTimer(
            rest: rest,
            now: now,
            compact: compact,
            onAdd: _addRest,
            onTogglePause: () {
              final rest = _restState.value;
              if (rest != null) {
                _updateRest(rest.togglePause(_now));
              }
            },
            onMinimize: onClose ?? _showRest,
            onSkip: () {
              _updateRest(null);
              onClose?.call();
            },
          ),
        );
      },
    );
  }

  Widget _restBar() => ValueListenableBuilder<WorkoutRest?>(
        valueListenable: _restState,
        builder: (_, rest, __) => rest == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TrainingSurface(
                    key: const ValueKey('minimized-rest-timer'),
                    onTap: _showRest,
                    padding: const EdgeInsets.fromLTRB(12, 8, 2, 8),
                    child: _restPanel(compact: true))),
      );

  Future<void> _finish() async {
    final wasFinished = _day.finished;
    setState(() => _busy = true);
    try {
      if (_day.items.isNotEmpty) await _saveEnteredSets(_day.items[_index].id);
      await _mutate('POST', '/finish');
      _updateRest(null);
      unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
      if (!wasFinished &&
          _day.finished &&
          _day.date == CacheScope.todayKey(_now) &&
          _day.items.isNotEmpty &&
          _day.items.every((item) => item.isCompleted)) {
        // Run after the saved summary renders; photo errors never fail a workout.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_offerAfterWorkoutPrompts());
        });
      }
    } catch (error) {
      _error(TrainingRepository.errorMessage(
          error, 'Could not finish. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerProgressPhoto() async {
    try {
      final show = await ProgressPhotoRepository.shared.claimPrompt(_day.date);
      if (mounted && show && ModalRoute.of(context)?.isCurrent == true) {
        await showProgressPhotoCapture(context,
            workoutDate: _day.date, afterWorkout: true);
      }
    } catch (_) {/* The saved workout remains available. */}
  }

  Future<void> _offerAfterWorkoutPrompts() async {
    await _offerProgressPhoto();
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final generate = await WeeklyPlanPromptService.shared
        .maybePromptAfterWorkout(context, completedDate: _day.date);
    if (!generate || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      if (mounted) await RateAppService.shared.maybePrompt(context);
      return;
    }
    final completedDate = DateTime.tryParse(_day.date) ?? _now;
    final daysUntilNextMonday = 8 - completedDate.weekday;
    final nextWeek = DateUtils.dateOnly(
        completedDate.add(Duration(days: daysUntilNextMonday)));
    await Navigator.of(context).push(AppPageRoute<void>(
        page: WeeklyPlanView(
            startGenerationOnOpen: true, initialStartDate: nextWeek)));
  }

  int? _activeNumber(TodayPlanItemModel item) {
    final numbers = _setNumbers(item);
    final selected = _selectedSets[item.id];
    if (selected != null && numbers.contains(selected)) return selected;
    if (!item.isPending || _editingFinished) return null;
    final saved = _day.logs(item.id).map((row) => row['setNumber']).toSet();
    for (final number in numbers) {
      if (!saved.contains(number)) return number;
    }
    return null;
  }

  void _showCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final step = _stepKeys[_index]?.currentContext;
      if (step != null) {
        unawaited(Scrollable.ensureVisible(step,
            alignment: .5,
            duration: DSMotion.duration(context, DSMotion.regular)));
      }
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _selectSet(TodayPlanItemModel item, int number) {
    if (_busy || _activeNumber(item) == number) return;
    _selectedSets[item.id] = number;
    _selectionFor(item).value = number;
  }

  ValueNotifier<int?> _selectionFor(TodayPlanItemModel item) =>
      _activeSelections.putIfAbsent(
          item.id, () => ValueNotifier(_activeNumber(item)));

  void _clearSelection(TodayPlanItemModel item) {
    _selectedSets.remove(item.id);
    _selectionFor(item).value = _activeNumber(item);
  }

  void _refreshSelections() {
    for (final entry in _activeSelections.entries) {
      final item = _day.items.where((item) => item.id == entry.key).firstOrNull;
      entry.value.value = item == null ? null : _activeNumber(item);
    }
  }

  Future<void> _logSet(TodayPlanItemModel item, int number) async {
    if (_busy) return;
    setState(() => _busy = true);
    FocusScope.of(context).unfocus();
    try {
      var entry = _setEntries['${item.id}:$number']?.currentState;
      if (entry == null && _scroll.hasClients) {
        await _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: DSMotion.duration(context, DSMotion.regular),
            curve: DSMotion.standard);
        await WidgetsBinding.instance.endOfFrame;
        entry = _setEntries['${item.id}:$number']?.currentState;
      }
      if (entry == null) return;
      await entry.savePending(confirmSuggestion: true);
      if (!mounted) return;
      _clearSelection(item);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final next = _activeNumber(item);
        final row = next == null
            ? null
            : _setEntries['${item.id}:$next']?.currentContext;
        if (row != null) {
          unawaited(Scrollable.ensureVisible(row,
              alignment: .6,
              duration: DSMotion.duration(context, DSMotion.regular)));
        }
      });
    } catch (error) {
      _error(error is FormatException
          ? error.message
          : TrainingRepository.errorMessage(
              error, 'Not saved yet. Tap save to retry.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeAndAdvance(TodayPlanItemModel item) async {
    await _status(item, 'COMPLETED');
    if (mounted && _day.allResolved) await _finish();
  }

  Future<void> _exerciseOptions(TodayPlanItemModel item) async {
    if (_busy || _optionsOpen) return;
    _optionsOpen = true;
    FocusScope.of(context).unfocus();
    final actions = [
      if (item.isPending) 'Skip exercise' else 'Reopen exercise',
      if (item.isPending && _day.logs(item.id).isNotEmpty) 'Finish exercise',
    ];
    final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: DSColors.bg,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: DSColors.border)),
        builder: (sheetContext) => FitnessTheme(
            child: SafeArea(
                top: false,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: Text(copy('Exercise options'),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500))),
                      for (final action in actions)
                        ListTile(
                            title: Text(copy(action),
                                style: const TextStyle(fontSize: 14)),
                            onTap: () => Navigator.pop(sheetContext, action)),
                      const SizedBox(height: 12),
                    ]))));
    _optionsOpen = false;
    if (!mounted || action == null) return;
    if (action == 'Finish exercise') {
      await _status(item, 'COMPLETED');
    } else {
      await _status(
          item, action == 'Skip exercise' ? 'SKIPPED' : 'NOT_STARTED');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _day.finished && !_editingFinished;
    final item = _day.items.isEmpty
        ? null
        : _day.items[_index.clamp(0, _day.items.length - 1)];
    return FitnessTheme(
        child: Scaffold(
      backgroundColor: DSColors.bg,
      appBar: AppBar(
        backgroundColor: DSColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: summary ? true : null,
        leading: summary && Navigator.of(context).canPop()
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.chevron_left,
                    size: 20, color: DSColors.silver))
            : null,
        title: Text(
            summary
                ? copy('Workout summary')
                : _day.name == 'Workout'
                    ? copy('Your workout')
                    : _day.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: summary ? 17 : 14,
                fontWeight: FontWeight.w500,
                color: DSColors.silver)),
        actions: [
          // Live Biometric Heart Rate pill from Apple Watch (if telemetry available)
          if (!_day.finished)
            ValueListenableBuilder<WatchBiometrics?>(
              valueListenable: WatchSyncService.shared.biometricsNotifier,
              builder: (_, bio, __) {
                if (bio == null || bio.heartRate <= 0) {
                  return const SizedBox.shrink();
                }
                final zoneColor = switch (bio.hrZone) {
                  1 => DSColors.silver,
                  2 => DSColors.blue,
                  3 => DSColors.accentLime,
                  4 => DSColors.gold,
                  _ => DSColors.heat,
                };
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: DSColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: zoneColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.heart_fill,
                          size: 12, color: zoneColor),
                      const SizedBox(width: 4),
                      Text(
                        '${bio.heartRate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: zoneColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Debug builds only: a fake Apple Watch for testing without hardware.
          if (kDebugMode && !_day.finished)
            IconButton(
                key: const ValueKey('virtual-watch-debug'),
                tooltip: 'Virtual Apple Watch (debug)',
                icon: const Icon(Icons.watch_outlined,
                    size: 18, color: DSColors.silver),
                onPressed: () => VirtualWatchSheet.show(context)),

          if (!_day.finished)
            Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                    child: ValueListenableBuilder<DateTime>(
                        valueListenable: _clock,
                        builder: (_, now, __) {
                          final start = DateTime.tryParse(
                              _day.session?['startedAt'] as String? ?? '');
                          final seconds = start == null
                              ? 0
                              : now.difference(start).inSeconds.clamp(0, 86400);
                          return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                  color: DSColors.bgElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: DSColors.border)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.clock,
                                        size: 13, color: DSColors.muted),
                                    const SizedBox(width: 6),
                                    Text(
                                        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: DSColors.silver)),
                                  ]));
                        })))
        ],
      ),
      body: _day.finished && !_editingFinished
          ? _summary()
          : item == null
              ? Center(child: Text(copy('No exercises found')))
              : Column(children: [
                  _progress(),
                  if (_day.pendingSync)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: WorkoutSyncNotice(
                            blocked: _day.syncBlocked,
                            onRetry: () => _sync(retry: true))),
                  Expanded(
                      child: MotionEntrance(
                          key: ValueKey(item.id),
                          child: ListView(
                              key: const ValueKey('workout-session-scroll'),
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                              children: [
                                _movement(item),
                                const SizedBox(height: 12),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: WorkoutFormGuide(
                                        key: ValueKey('form-${item.id}'),
                                        exercise: item.exercise)),
                                const SizedBox(height: 12),
                                if (_index == 0)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18),
                                      child: WorkoutWarmup(
                                          warmup: (_day.json['warmup'] as Map?)
                                              ?.cast<String, dynamic>(),
                                          isCompleted: _isWarmupDone,
                                          onComplete: () {
                                            unawaited(HapticFeedback.mediumImpact()
                                                .catchError((Object _) {}));
                                            setState(() => _warmupCompleted = true);
                                          })),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: _sets(item)),
                              ]))),
                ]),
      bottomNavigationBar:
          item == null && !_day.finished ? null : _footer(item),
    ));
  }

  Widget _progress() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            copy('Exercise {current} of {total}',
                values: {'current': _index + 1, 'total': _day.items.length}),
            style: const TextStyle(fontSize: 11, color: DSColors.muted)),
        const SizedBox(height: 6),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var index = 0; index < _day.items.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                _exerciseStep(index),
              ],
            ])),
      ]));

  Widget _exerciseStep(int index) {
    final item = _day.items[index];
    final selected = index == _index;
    final size = MediaQuery.textScalerOf(context).scale(14) + 30;
    final touchSize = (size + 4).clamp(48.0, double.infinity);
    final locked = !_isWarmupDone && index > 0;
    return Semantics(
        key: _stepKeys.putIfAbsent(index, () => GlobalKey()),
        button: true,
        selected: selected,
        enabled: !_busy && !locked,
        label: '${index + 1}: ${item.exercise.displayName}',
        value: item.isCompleted
            ? copy('Done')
            : item.isPending
                ? null
                : copy('Skipped'),
        child: InkWell(
            onTap: _busy
                ? null
                : locked
                    ? () {
                        unawaited(HapticFeedback.lightImpact()
                            .catchError((Object _) {}));
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(copy('Complete warm-up first')),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : () {
                        setState(() {
                          _index = index;
                          _loadPrevious();
                        });
                        _showCurrentStep();
                      },
            borderRadius: BorderRadius.circular(10),
            highlightColor: Colors.white.withValues(alpha: .08),
            splashColor: Colors.white.withValues(alpha: .12),
            child: SizedBox.square(
                dimension: touchSize,
                child: Center(
                    child: Container(
                        width: size,
                        height: size,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: item.isCompleted
                                ? Colors.white
                                : DSColors.bgElevated,
                            border: Border.all(
                                color: selected || item.isCompleted
                                    ? Colors.white
                                    : DSColors.borderHi,
                                width: selected ? 2 : 1)),
                        child: ExcludeSemantics(
                            child: locked
                                ? const Icon(CupertinoIcons.lock_fill,
                                    size: 13, color: DSColors.muted)
                                : Text('${index + 1}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: item.isCompleted
                                            ? Colors.black
                                            : DSColors.silver))))))));
  }

  Widget _movement(TodayPlanItemModel item) {
    final expanded = !_collapsedDemos.contains(item.id);
    final hasMedia = item.exercise.url?.isNotEmpty == true ||
        item.exercise.thumbnailUrl?.isNotEmpty == true;
    final name = Text(item.exercise.displayName,
        style: const TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w500,
            letterSpacing: -.5));
    final toggle = TextButton(
        onPressed: () => setState(() {
              if (expanded) {
                _collapsedDemos.add(item.id);
              } else {
                _collapsedDemos.remove(item.id);
              }
            }),
        child: Text(copy(expanded ? 'Hide demo' : 'Show demo'),
            style: const TextStyle(fontSize: 11, color: DSColors.muted)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(
                builder: (context, box) =>
                    MediaQuery.textScalerOf(context).scale(14) > 20
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                name,
                                Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: toggle)
                              ])
                        : Row(children: [
                            Expanded(child: name),
                            const SizedBox(width: 8),
                            toggle
                          ])),
            Text(
                '${item.exercise.targetLabel ?? item.exercise.target} · ${item.exercise.equipmentLabel ?? item.exercise.equipment}',
                style: const TextStyle(
                    color: DSColors.muted, fontSize: 11, height: 1.4)),
          ])),
      if (expanded)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TrainingSurface(
                key: ValueKey('demo-${item.id}'),
                padding: EdgeInsets.zero,
                child: !hasMedia
                    ? SizedBox(
                        height: 88,
                        child: Center(
                            child: Text(copy('Demo unavailable'),
                                style: const TextStyle(
                                    color: DSColors.muted, fontSize: 12))))
                    : AspectRatio(
                        aspectRatio: item.exercise.demoAspectRatio,
                        child: RepaintBoundary(
                            child: FitVideoSurface(
                                url: item.exercise.url,
                                autoplay: true,
                                fit: BoxFit.contain,
                                neutralBackground: true,
                                backgroundColor:
                                    hasMedia ? Colors.white : DSColors.bgCard,
                                placeholder: item.exercise.thumbnailUrl?.isNotEmpty == true
                                    ? CachedNetworkImage(
                                        imageUrl: item.exercise.thumbnailUrl!,
                                        fit: BoxFit.contain,
                                        errorWidget: (_, __, ___) => Center(
                                            child: Text(copy('Demo unavailable'),
                                                style: const TextStyle(
                                                    color: DSColors.muted,
                                                    fontSize: 12))))
                                    : Center(
                                        child: Text(copy('Demo unavailable'),
                                            style: const TextStyle(color: DSColors.muted, fontSize: 12)))))))),
    ]);
  }

  Widget _sets(TodayPlanItemModel item) => ValueListenableBuilder<int>(
      valueListenable: _setsVersion, builder: (_, __, ___) => _buildSets(item));

  Widget _buildSets(TodayPlanItemModel item) {
    final count = _setCount(item);
    final selection = _selectionFor(item);
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    Widget heading(String text) => Text(copy(text),
        textAlign: TextAlign.center,
        style:
            const TextStyle(fontSize: 10, height: 1.4, color: DSColors.muted));
    return TrainingSurface(
        padding: const EdgeInsets.all(12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!_isWarmupDone) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: DSColors.bgRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DSColors.border),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.lock_fill,
                      size: 16, color: DSColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy('Complete warm-up first'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DSColors.silver,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copy('Finish the warm-up routine above to unlock your working sets.'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: DSColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
              child: Row(children: [
                Expanded(
                    child: Text(copy('Your sets'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500))),
                Text(
                    copy('{sets} × {reps}', values: {
                      'sets': item.targetSets,
                      'reps': item.targetReps
                    }),
                    style:
                        const TextStyle(fontSize: 11, color: DSColors.muted)),
              ])),
          ValueListenableBuilder<int?>(
              valueListenable: selection,
              builder: (_, active, __) => active == null ||
                      item.localizedTargetLabel(context, active) == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                      child: Text(
                          '${copy('Target')} · ${item.localizedTargetLabel(context, active)}',
                          style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: DSColors.muted)))),
          if (!large)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  SizedBox(width: 28, child: heading('Set')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: heading('Previous')),
                  const SizedBox(width: 8),
                  if (!item.isBodyweight) ...[
                    Expanded(flex: 2, child: heading('Weight (kg)')),
                    const SizedBox(width: 8),
                  ],
                  Expanded(flex: 2, child: heading('Reps')),
                  const SizedBox(width: 52),
                ])),
          for (final number in _setNumbers(item))
            WorkoutSetEntry(
                key: _setEntries.putIfAbsent('${item.id}:$number',
                    () => GlobalKey<WorkoutSetEntryState>()),
                date: _day.date,
                itemId: item.id,
                number: number,
                compact: true,
                selection: selection,
                removable: number > item.targetSets,
                showSaveAction: false,
                showDetailsAction: false,
                onActivate: () => _selectSet(item, number),
                bodyweight: item.isBodyweight,
                targetLabel: item.localizedTargetLabel(context, number),
                suggestedReps: _suggestedReps(item, number),
                suggestedWeight: _suggestedWeight(item, number),
                previous: _previous,
                log: _day
                    .logs(item.id)
                    .where((row) => row['setNumber'] == number)
                    .firstOrNull,
                disabled: _busy || !_isWarmupDone,
                onSave: (reps, weight, effort) async {
                  final wasLogged = _day
                      .logs(item.id)
                      .any((log) => log['setNumber'] == number);
                  setState(() => _busy = true);
                  try {
                    await _mutate('PUT', '/items/${item.id}/sets', data: {
                      'setNumber': number,
                      'reps': reps,
                      'weight': weight,
                      'rpe': effort
                    });
                    if (mounted) {
                      _clearSelection(item);
                      if (!wasLogged) {
                        if (_day.logs(item.id).length < count) {
                          _startRest(item, number);
                        } else if (_restState.value?.exercise ==
                            item.exercise.displayName) {
                          _updateRest(null);
                        }
                      }
                    }
                    unawaited(HapticFeedback.selectionClick()
                        .catchError((Object _) {}));
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
                onDelete: () => _deleteSet(item, number)),
          const SizedBox(height: 6),
          const Divider(height: 1, color: DSColors.border),
          ValueListenableBuilder<int?>(
              valueListenable: selection,
              builder: (_, active, __) =>
                  Wrap(alignment: WrapAlignment.spaceBetween, children: [
                    TextButton(
                        onPressed: _busy ? null : () => _extraSet(item),
                        child: Text(copy('Add set'),
                            style: const TextStyle(
                                fontSize: 12, color: DSColors.silver))),
                    if (active != null)
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => _setEntries['${item.id}:$active']
                                  ?.currentState
                                  ?.showDetails(),
                          child: Text(copy('Set details'),
                              style: const TextStyle(
                                  fontSize: 12, color: DSColors.muted))),
                    if (!_day.finished)
                      TextButton(
                          onPressed:
                              _busy ? null : () => _exerciseOptions(item),
                          child: Text(copy('Exercise options'),
                              style: const TextStyle(
                                  fontSize: 11, color: DSColors.muted))),
                  ])),
        ]));
  }

  void _nextExercise() {
    final index = _day.items.indexWhere((item) => item.isPending);
    if (index >= 0) {
      setState(() {
        _index = index;
        _loadPrevious();
      });
      _showCurrentStep();
    }
  }

  Widget _footer(TodayPlanItemModel? item) => Builder(builder: (footerContext) {
        final keyboardInset = MediaQuery.viewInsetsOf(footerContext).bottom;
        if (item == null) return _buildFooter(item, keyboardInset);
        return ListenableBuilder(
            listenable: Listenable.merge([_selectionFor(item), _resting]),
            builder: (_, __) => _buildFooter(item, keyboardInset));
      });

  Widget _buildFooter(TodayPlanItemModel? item, double keyboardInset) {
    final summary = _day.finished && !_editingFinished;
    final active = item == null ? null : _activeNumber(item);
    final editing = active != null &&
        _day.logs(item!.id).any((log) => log['setNumber'] == active);
    final last =
        _day.items.where((row) => row.isPending && row.id != item?.id).isEmpty;
    final label = !_isWarmupDone
        ? copy('Complete warm-up')
        : summary
            ? copy('Done')
            : _editingFinished || editing
                ? copy('Save changes')
                : active != null
                    ? copy('Log set {number}', values: {'number': active})
                    : _day.allResolved || last
                        ? copy('Finish workout')
                        : copy('Next exercise');
    final VoidCallback? action = _busy
        ? null
        : !_isWarmupDone
            ? () {
                unawaited(HapticFeedback.mediumImpact()
                    .catchError((Object _) {}));
                setState(() => _warmupCompleted = true);
              }
            : summary
                ? () => Navigator.pop(context)
                : _editingFinished
                    ? _saveFinishedEdits
                    : active != null && item != null
                        // A new set waits for the rest to end or be skipped;
                        // corrections to logged sets stay available.
                        ? _resting.value && !editing
                            ? null
                            : () => _logSet(item, active)
                        : _day.allResolved
                            ? _finish
                            : item?.isPending == true
                                ? () => _completeAndAdvance(item!)
                                : _nextExercise;
    return Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
            top: false,
            child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                decoration: const BoxDecoration(
                    color: DSColors.bg,
                    border: Border(
                        top: BorderSide(color: DSColors.border, width: .7))),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!summary && !_editingFinished && keyboardInset == 0)
                        _restBar(),
                      FilledButton(
                          key: const ValueKey('workout-primary-action'),
                          onPressed: action,
                          style: FilledButton.styleFrom(
                              backgroundColor: DSColors.silver,
                              foregroundColor: DSColors.bg,
                              disabledBackgroundColor: DSColors.bgRaised,
                              disabledForegroundColor: DSColors.muted,
                              minimumSize: const Size(double.infinity, 50),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: _busy
                              ? const CupertinoActivityIndicator(
                                  color: DSColors.bg)
                              : Text(label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600))),
                    ]))));
  }

  final _extra = <String, Set<int>>{};
  List<int> _setNumbers(TodayPlanItemModel item) => {
        for (var number = 1; number <= item.targetSets; number++) number,
        ...?_extra[item.id],
        for (final row in _day.logs(item.id)) (row['setNumber'] as num).toInt(),
      }.toList()
        ..sort();

  int _setCount(TodayPlanItemModel item) => _setNumbers(item).length;

  void _extraSet(TodayPlanItemModel item) {
    final numbers = _setNumbers(item).toSet();
    final number = Iterable<int>.generate(100, (index) => index + 1)
        .where(
            (number) => number > item.targetSets && !numbers.contains(number))
        .firstOrNull;
    if (number == null) return;
    (_extra[item.id] ??= {}).add(number);
    _setsVersion.value++;
    _refreshSelections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _setEntries['${item.id}:$number']?.currentContext;
      if (mounted && row != null) {
        unawaited(Scrollable.ensureVisible(row,
            alignment: .6,
            duration: DSMotion.duration(context, DSMotion.fast)));
      }
    });
  }

  Future<void> _deleteSet(TodayPlanItemModel item, int number) async {
    final logged = _day.logs(item.id).any((row) => row['setNumber'] == number);
    if (logged) {
      setState(() => _busy = true);
      try {
        await _mutate('DELETE', '/items/${item.id}/sets/$number');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (!mounted) return;
    _extra[item.id]?.remove(number);
    _setEntries.remove('${item.id}:$number');
    if (_selectedSets[item.id] == number) _selectedSets.remove(item.id);
    _setsVersion.value++;
    _refreshSelections();
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

  Future<WorkoutComparison?>? _comparison;

  Widget _summary() => MotionEntrance(
      child: WorkoutCompletionSummary(
          day: _day,
          comparison: _comparison ??= WorkoutComparison.of(
              _day, (exerciseId) => _repo.previous(_day.date, exerciseId)),
          onAddPhoto: () =>
              showProgressPhotoCapture(context, workoutDate: _day.date),
          onEdit: () => setState(() => _editingFinished = true),
          onRetry: () => _sync(retry: true)));
}

