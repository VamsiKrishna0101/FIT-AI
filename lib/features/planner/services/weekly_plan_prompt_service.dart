import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/storage/local_cache.dart';
import '../../train/models/training_session.dart';
import '../../train/repositories/training_repository.dart';
import '../repositories/weekly_plan_repository.dart';
import '../views/weekly_plan_prompt_sheet.dart';

class WeeklyPlanPromptService {
  WeeklyPlanPromptService._();

  static final shared = WeeklyPlanPromptService._();

  final WeeklyPlanRepository _plans = WeeklyPlanRepository();
  bool _showingPrompt = false;

  Future<bool> maybePromptOnAppOpen(BuildContext context) async {
    if (!_canPresent(context)) return false;
    final state = await _loadState();
    if (state == null || state.pendingRun != null || !_canPresent(context)) {
      return false;
    }

    final plan = state.plan;
    if (plan != null && plan['status'] == 'ACTIVE') {
      final completionKey = _completionKey(plan['id'] as String);
      if (!await _wasPromptShown(completionKey) &&
          _allPlannedWorkoutsAreScheduled(plan) &&
          await _allPlannedWorkoutsComplete(plan)) {
        if (!_canPresent(context)) return false;
        await _claimCompletionPrompt(plan['id'] as String);
        await _claimDailyPrompt();
        return _show(context, state, weekComplete: true);
      }
    }

    if (plan != null && _coversToday(plan)) return false;
    if (state.canGenerate != true || state.pendingRun != null) return false;

    final todaySuffix = _dailyPromptKey();
    if (await _wasPromptShown(todaySuffix)) return false;
    if (!_canPresent(context)) return false;
    final todayKey = await _userKey(todaySuffix);
    await LocalCache.shared.saveString(todayKey, 'shown');
    return _show(context, state, weekComplete: false);
  }

  Future<bool> maybePromptAfterWorkout(
    BuildContext context, {
    required String completedDate,
  }) async {
    if (!_canPresent(context)) return false;
    final state = await _loadState();
    if (state == null || state.pendingRun != null || !_canPresent(context)) {
      return false;
    }
    final plan = state.plan;
    if (plan == null || plan['status'] != 'ACTIVE') return false;

    final id = plan['id'];
    if (id is! String || await _wasPromptShown(_completionKey(id))) {
      return false;
    }
    if (!_scheduledWorkoutDates(plan).contains(completedDate)) return false;
    if (!await _allPlannedWorkoutsComplete(plan)) return false;

    if (!_canPresent(context)) return false;
    await _claimCompletionPrompt(id);
    await _claimDailyPrompt();
    return _show(context, state, weekComplete: true);
  }

  bool _canPresent(BuildContext context) =>
      context.mounted &&
      !_showingPrompt &&
      ModalRoute.of(context)?.isCurrent == true;

  Future<_PlanPromptState?> _loadState() async {
    try {
      await UserDataCache.shared.invalidate('plans');
      final availability = await _plans.availability();
      final id = availability['lastPlanId'];
      final plan = id is String ? await _plans.savedPlan(id) : null;
      return _PlanPromptState(
        availability: availability,
        plan: plan,
      );
    } catch (_) {
      // A prompt must never block app entry when the planner is offline.
      return null;
    }
  }

  bool _coversToday(Map<String, dynamic> plan) {
    final start = DateTime.tryParse(plan['weekStart'] as String? ?? '');
    if (start == null) return false;
    final end = DateUtils.dateOnly(start.add(const Duration(days: 6)));
    return !end.isBefore(DateUtils.dateOnly(DateTime.now()));
  }

  bool _allPlannedWorkoutsAreScheduled(Map<String, dynamic> plan) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dates = _scheduledWorkoutDates(plan);
    return dates.isNotEmpty &&
        dates.every((date) {
          final parsed = DateTime.tryParse(date);
          return parsed != null && !DateUtils.dateOnly(parsed).isAfter(today);
        });
  }

  Future<bool> _allPlannedWorkoutsComplete(Map<String, dynamic> plan) async {
    final dates = _scheduledWorkoutDates(plan);
    if (dates.isEmpty) return false;

    try {
      final days = await Future.wait(
        dates
            .map((date) => TrainingRepository.shared.load(date, refresh: true)),
      );
      return days.every((TrainingDay day) =>
          day.finished &&
          day.items.isNotEmpty &&
          day.items.every((item) => item.isCompleted));
    } catch (_) {
      // Never infer completion when an offline or stale schedule cannot be read.
      return false;
    }
  }

  Set<String> _scheduledWorkoutDates(Map<String, dynamic> plan) {
    final payload = plan['payload'];
    if (payload is! Map || payload['workouts'] is! List) return {};
    return (payload['workouts'] as List)
        .whereType<Map>()
        .where((workout) => workout['restDay'] != true)
        .map((workout) => workout['date'])
        .whereType<String>()
        .toSet();
  }

  Future<String> _userKey(String suffix) => CacheScope.userKey(suffix);

  String _completionKey(String planId) => 'weekly_plan_complete_prompt_$planId';

  Future<bool> _wasPromptShown(String suffix) async {
    final key = await _userKey(suffix);
    return await LocalCache.shared.getString(key) == 'shown';
  }

  Future<void> _claimCompletionPrompt(String planId) async {
    final key = await _userKey(_completionKey(planId));
    await LocalCache.shared.saveString(key, 'shown');
  }

  String _dailyPromptKey() => 'plan_prompt_daily_${CacheScope.todayKey()}';

  Future<void> _claimDailyPrompt() async {
    final key = await _userKey(_dailyPromptKey());
    await LocalCache.shared.saveString(key, 'shown');
  }

  Future<bool> _show(
    BuildContext context,
    _PlanPromptState state, {
    required bool weekComplete,
  }) async {
    if (!_canPresent(context)) return false;
    _showingPrompt = true;
    try {
      return await WeeklyPlanPromptSheet.show(
            context,
            weekComplete: weekComplete,
            canGenerate: state.canGenerate == true && state.pendingRun == null,
            nextGenerationAt: DateTime.tryParse(
              state.availability['nextGenerationAt'] as String? ?? '',
            ),
          ) ==
          true;
    } finally {
      _showingPrompt = false;
    }
  }
}

class _PlanPromptState {
  final Map<String, dynamic> availability;
  final Map<String, dynamic>? plan;

  const _PlanPromptState({required this.availability, required this.plan});

  bool? get canGenerate => availability['canGenerate'] as bool?;
  Map? get pendingRun => availability['pendingRun'] as Map?;
}
