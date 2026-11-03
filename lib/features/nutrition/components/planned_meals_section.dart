import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart'
    show foodDisplayName, fitnessText;
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/food_planning_repository.dart';
import '../views/meal_portion_view.dart' show mealSlotLabel;
import '../views/food_routine_view.dart';
import 'meal_food_picker.dart';

class PlannedMealsSection extends StatefulWidget {
  final DateTime date;
  final Future<void> Function()? onChanged;
  final Future<Map<String, dynamic>> Function()? loader;
  final Future<void> Function(String, String, Map<String, dynamic>?)? action;
  final int refreshVersion;
  final bool showIntakeHint;
  const PlannedMealsSection(
      {super.key,
      required this.date,
      this.onChanged,
      this.loader,
      this.action,
      this.refreshVersion = 0,
      this.showIntakeHint = false});
  @override
  State<PlannedMealsSection> createState() => _PlannedMealsSectionState();
}

class _PlannedMealsSectionState extends State<PlannedMealsSection> {
  Map<String, dynamic>? _day;
  String? _error, _busy;
  bool _loading = true;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PlannedMealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion ||
        !DateUtils.isSameDay(widget.date, oldWidget.date)) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final day = await (widget.loader?.call() ??
          (AppDataMode.shared.preview
              ? Future.value(<String, dynamic>{
                  'settings': {'mode': 'TRACK'},
                  'meals': []
                })
              : FoodPlanningRepository.shared.day(widget.date)));
      if (mounted && request == _request) {
        setState(() {
          _day = day;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _act(Map meal, String action) async {
    if (_busy != null) return;
    Map<String, dynamic>? replacement;
    if (action == 'REPLACE') {
      final chosen = await pickMealFood(context);
      if (!mounted || chosen == null) return;
      replacement = {'nutritionId': chosen.$1.id, 'servings': chosen.$2};
    }
    setState(() {
      _busy = meal['key'] as String;
      _error = null;
    });
    try {
      if (widget.action != null) {
        await widget.action!(_busy!, action, replacement);
      } else {
        await FoodPlanningRepository.shared
            .act(widget.date, _busy!, action, replacement: replacement);
      }
      await _load();
      await widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _openRoutine() async {
    await Navigator.push(context, AppPageRoute(page: const FoodRoutineView()));
    if (mounted) {
      await _load();
      await widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = CacheScope.todayKey();
    final date = CacheScope.todayKey(widget.date);
    final confirm = date == today && !AppDataMode.shared.preview;
    final edit = date.compareTo(today) >= 0 && !AppDataMode.shared.preview;
    final meals = (_day?['meals'] as List? ?? []).whereType<Map>().toList();
    final number = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag())
      ..maximumFractionDigits = 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            const FitnessText('Planned for you',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            if (meals.isNotEmpty)
              TextButton(
                  onPressed: _busy == null ? _openRoutine : null,
                  style: TextButton.styleFrom(
                      foregroundColor: FitnessTheme.silver),
                  child: const FitnessText('Meals & routine',
                      style: TextStyle(fontSize: 11)))
          ]),
      const SizedBox(height: 12),
      if (_loading) const LinearProgressIndicator(color: Colors.white),
      if (!_loading && _error == null && meals.isEmpty)
        FitnessCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              FitnessText(
                  (_day?['settings'] as Map?)?['mode'] == 'TRACK'
                      ? 'Manual food tracking'
                      : 'Choose your meals',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              FitnessText(
                  (_day?['settings'] as Map?)?['mode'] == 'TRACK'
                      ? (widget.showIntakeHint
                          ? 'Use the daily targets above as you log your meals.'
                          : 'Log meals as you go.')
                      : 'Choose AI suggestions for a meal plan, or add the meals you repeat.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: FitnessTheme.muted, fontSize: 12, height: 1.5)),
              const SizedBox(height: 14),
              OutlinedButton(
                  onPressed: _busy == null ? _openRoutine : null,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: FitnessTheme.silver,
                      minimumSize: const Size(0, 44),
                      side: const BorderSide(color: FitnessTheme.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const FitnessText('Set up meals',
                      style: TextStyle(fontSize: 12))),
            ])),
      if (_error != null)
        FitnessCard(
            child: Column(children: [
          FitnessText(_error!,
              style: const TextStyle(color: FitnessTheme.coral)),
          TextButton(
              onPressed: _busy == null ? _load : null,
              child: const FitnessText('Retry'))
        ])),
      for (final meal in meals)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FitnessCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Row(children: [
                    Expanded(
                        child: FitnessText(
                            mealSlotLabel(meal['mealType'] as String),
                            style: const TextStyle(
                                color: FitnessTheme.muted, fontSize: 12))),
                    FitnessText(
                        meal['source'] == 'ROUTINE'
                            ? 'Your routine'
                            : 'Suggested',
                        style: const TextStyle(
                            color: FitnessTheme.muted, fontSize: 11))
                  ]),
                  const SizedBox(height: 10),
                  Text(meal['name'] as String,
                      style: const TextStyle(
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w500)),
                  for (final entry
                      in (meal['entries'] as List).whereType<Map>())
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            '${foodDisplayName(entry['nutritionId'] as String? ?? '', entry['name'] as String)} · ${number.format((entry['servingSize'] as num) * (entry['servings'] as num))} ${fitnessText(context, entry['servingUnit'] as String)}',
                            style: const TextStyle(
                                color: FitnessTheme.muted, fontSize: 12))),
                  const SizedBox(height: 12),
                  Text(
                      '${number.format((meal['entries'] as List).fold(0.0, (n, e) => n + ((e as Map)['calories'] as num).toDouble()).round())} kcal · ${number.format((meal['entries'] as List).fold(0.0, (n, e) => n + ((e as Map)['protein'] as num).toDouble()))} g ${fitnessText(context, 'Protein')}',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  if (meal['status'] == 'PENDING')
                    Wrap(spacing: 8, children: [
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: FitnessTheme.silver,
                              foregroundColor: FitnessTheme.canvas),
                          onPressed: confirm && _busy == null
                              ? () => _act(meal, 'LOGGED')
                              : null,
                          child: FitnessText(
                              _busy == meal['key'] ? 'Saving…' : 'Log meal')),
                      TextButton(
                          onPressed: edit && _busy == null
                              ? () => _act(meal, 'SKIPPED')
                              : null,
                          child: const FitnessText('Skip')),
                      PopupMenuButton<String>(
                          enabled: edit && _busy == null,
                          onSelected: (v) => _act(meal, v),
                          itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'REPLACE',
                                    child: FitnessText('Change this day')),
                                if (meal['changedToday'] == true)
                                  const PopupMenuItem(
                                      value: 'RESET',
                                      child:
                                          FitnessText('Restore planned meal'))
                              ]),
                    ])
                  else
                    Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                              meal['status'] == 'LOGGED'
                                  ? Icons.check_circle_outline
                                  : Icons.remove_circle_outline,
                              size: 18),
                          FitnessText(meal['status'] == 'LOGGED'
                              ? 'Logged'
                              : 'Skipped'),
                          if (meal['status'] == 'SKIPPED' && edit)
                            TextButton(
                                onPressed: _busy == null
                                    ? () => _act(meal, 'RESET')
                                    : null,
                                child: const FitnessText('Restore'))
                        ]),
                ]))),
      const SizedBox(height: 18),
    ]);
  }
}
