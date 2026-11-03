import '../../../../core/components/liquid_glass.dart';
import 'weekly_nutrition_card.dart';
import '../../../train/components/workout_warmup.dart';
import '../../../train/components/exercise_recommendation_card.dart';
import '../../../nutrition/components/planned_meals_section.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/components/liquid_chrome_button.dart';
import '../../../train/views/workout_session_view.dart';
import '../../../train/components/reschedule_workout_sheet.dart';
import 'dart:async';
import '../../../../core/navigation/onboarding_page_route.dart';
import '../../../train/models/training_session.dart';
import '../../../train/repositories/training_repository.dart';
import '../../../train/views/train_dashboard_view.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/components/content_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../body_scan/views/widgets/body_controls.dart';
import 'plan_week_list.dart';

class WeeklyPlanSchedule extends StatefulWidget {
  final Map<String, dynamic> payload;
  final bool active;
  final Future<TrainingDay> Function(String)? loadDay;
  final Future<TrainingDay> Function(String)? startDay;
  final bool fromOnboarding;
  final bool showOverview;
  final String? initialDate;

  const WeeklyPlanSchedule(
      {super.key,
      required this.payload,
      this.active = false,
      this.loadDay,
      this.startDay,
      this.fromOnboarding = false,
      this.showOverview = true,
      this.initialDate});

  @override
  State<WeeklyPlanSchedule> createState() => _WeeklyPlanScheduleState();
}

class _WeeklyPlanScheduleState extends State<WeeklyPlanSchedule> {
  int _day = 0;
  int _section = 0;
  bool _startingFirst = false;
  List<Map<String, dynamic>> get _days =>
      (widget.payload['workouts'] as List? ?? [])
          .whereType<Map>()
          .map((day) => Map<String, dynamic>.from(day))
          .toList();

  final _live = <String, TrainingDay>{};
  final _weekRows = <String, Map<String, dynamic>>{};
  final _errors = <String>{};
  StreamSubscription<TrainingDay>? _subscription;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final current =
        _days.indexWhere((day) => day['date'] == (widget.initialDate ?? today));
    final firstWorkout = _days.indexWhere((day) => day['restDay'] != true);
    _day = widget.initialDate != null && current >= 0
        ? current
        : widget.fromOnboarding && firstWorkout >= 0
            ? firstWorkout
            : current >= 0
                ? current
                : firstWorkout >= 0
                    ? firstWorkout
                    : 0;
    _subscription = TrainingRepository.shared.changes.stream.listen((day) {
      if (mounted &&
          widget.active &&
          _days.any((row) => row['date'] == day.date)) {
        setState(() {
          _live[day.date] = day;
          for (final row in day.week) {
            _weekRows['${row['date']}'] = row;
          }
          _errors.remove(day.date);
        });
      }
    });
    if (widget.active) unawaited(_loadSelected());
  }

  @override
  void didUpdateWidget(WeeklyPlanSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active ||
            !identical(
                widget.payload['workouts'], oldWidget.payload['workouts']))) {
      unawaited(_loadSelected());
    }
  }

  Future<void> _loadSelected() async {
    final days = _days;
    if (!widget.active || days.isEmpty) return;
    final date = days[_day.clamp(0, days.length - 1)]['date'] as String;
    await _loadDate(date);
  }

  Future<void> _loadDate(String date) async {
    final request = ++_request;
    final owner = await CacheScope.userId();
    try {
      final day = await (widget.loadDay?.call(date) ??
          TrainingRepository.shared.load(date, refresh: true));
      if (!mounted ||
          request != _request ||
          owner != await CacheScope.userId()) {
        return;
      }
      setState(() {
        _live[date] = day;
        for (final row in day.week) {
          _weekRows['${row['date']}'] = row;
        }
        _errors.remove(date);
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _errors.add(date));
    }
  }

  Future<void> _editDay(String date) async {
    final route = AppPageRoute<void>(
        page: TrainView(standalone: true, editOnly: true, initialDate: date));
    await Navigator.of(context).push(route);
    await route.completed;
    if (mounted) await _loadSelected();
  }

  Future<void> _startFirstWorkout(String date) async {
    final live = _live[date];
    if (_startingFirst ||
        !widget.active ||
        live == null ||
        live.restDay ||
        live.items.isEmpty ||
        live.finished ||
        (!live.started && date != CacheScope.todayKey())) {
      return;
    }
    setState(() => _startingFirst = true);
    final owner = await CacheScope.userId();
    try {
      final day = live.started
          ? live
          : await (widget.startDay?.call(date) ??
              TrainingRepository.shared.mutate(date, 'POST', '/start'));
      final currentOwner = await CacheScope.userId();
      if (!mounted || owner != currentOwner) return;
      await Navigator.of(context)
          .push(AppPageRoute<void>(page: WorkoutSessionView(initial: day)));
      final returningOwner = await CacheScope.userId();
      if (mounted && owner == returningOwner) await _loadSelected();
    } catch (error) {
      final currentOwner = await CacheScope.userId();
      if (mounted && owner == currentOwner) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: FitnessText(TrainingRepository.errorMessage(
                error, 'Could not start your workout. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _startingFirst = false);
    }
  }

  Future<void> _restToday(String date) async {
    final changed = await showModalBottomSheet<bool>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        isScrollControlled: true,
        backgroundColor: FitnessTheme.surface,
        builder: (_) => FractionallySizedBox(
            heightFactor: .9,
            child: FitnessTheme(child: RescheduleWorkoutSheet(date: date))));
    if (changed == true && mounted) await _loadSelected();
  }

  Map<String, dynamic> _currentWorkout(Map<String, dynamic> saved) {
    final live = _live[saved['date']];
    if (!widget.active) return saved;
    if (live == null) {
      final row = _weekRows[saved['date']];
      return row == null
          ? saved
          : {
              ...saved,
              ...row,
              'restDay': row['status'] == 'REST_DAY' || row['status'] == 'EMPTY'
            };
    }
    final original = (saved['exercises'] as List? ?? []).whereType<Map>();
    return {
      ...saved,
      'name': live.name,
      'restDay': live.restDay,
      'warmup': live.json['warmup'],
      'estimatedMinutes': live.estimatedMinutes,
      'status': live.finished
          ? 'COMPLETED'
          : live.started
              ? 'IN_PROGRESS'
              : live.restDay
                  ? 'REST_DAY'
                  : 'SCHEDULED',
      'exercises': [
        for (final item in live.items)
          {
            ...?original
                .where((row) => row['exerciseId'] == item.exercise.id)
                .firstOrNull,
            'exerciseId': item.exercise.id,
            'displayName': item.exercise.displayName,
            'sets': item.targetSets,
            'targetReps': item.targetReps,
            'weightKg': item.targetWeight > 0 ? item.targetWeight : null,
            'weightBasis': item.setTargets?['weightBasis'],
            'weightUnit': item.setTargets?['weightUnit'],
            'setPrescriptions': item.setTargets?['sets'] ?? [],
            'targetRpe': item.targetRpe,
            'restSeconds': item.restSeconds,
            'reason': original
                .where((row) => row['exerciseId'] == item.exercise.id)
                .firstOrNull?['reason'],
            'progression': original
                .where((row) => row['exerciseId'] == item.exercise.id)
                .firstOrNull?['progression'],
          }
      ],
    };
  }

  @override
  void dispose() {
    ++_request;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    if (days.isEmpty) {
      return const FitnessCard(
          child: FitnessText('No workouts in this saved week.'));
    }

    final selected = days[_day.clamp(0, days.length - 1)];
    final trainingDays =
        days.where((day) => _currentWorkout(day)['restDay'] != true).length;
    final restDays = days.length - trainingDays;

    if (widget.showOverview) return _overview(days);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.initialDate == null) ...[
        FitnessText(
            '$trainingDays training ${trainingDays == 1 ? 'day' : 'days'} · $restDays rest ${restDays == 1 ? 'day' : 'days'}',
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 14),
        _weekStrip(days),
        const SizedBox(height: 16),
      ],
      BodySegment(
          labels: const ['Training', 'Nutrition'],
          selected: _section,
          onChanged: (section) => setState(() => _section = section)),
      const SizedBox(height: 20),
      if (widget.initialDate == null) ...[
        FitnessText(
            DateFormat.MMMMEEEEd()
                .format(DateTime.parse(selected['date'] as String)),
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 8),
      ],
      ContentTransition(
        child: KeyedSubtree(
          key: ValueKey('${selected['date']}:$_section'),
          child: _section == 0
              ? _workout(_currentWorkout(selected))
              : _food(selected['date'] as String),
        ),
      ),
    ]);
  }

  Widget _overview(List<Map<String, dynamic>> savedDays) {
    final days = savedDays.map(_currentWorkout).toList();
    final training = days.where((day) => day['restDay'] != true).toList();
    final completed =
        training.where((day) => day['status'] == 'COMPLETED').length;
    final progressKnown = widget.active &&
        training.isNotEmpty &&
        training.every((day) => day['status'] is String);
    final selected = days[_day.clamp(0, days.length - 1)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LiquidGlass(
          radius: 26,
          surfaceColor: const Color(0xFF171717),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const FitnessText('Training week',
                        style:
                            TextStyle(fontSize: 11, color: FitnessTheme.muted)),
                    const SizedBox(height: 6),
                    FitnessText('{count} workouts',
                        values: {'count': training.length},
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.7)),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(CupertinoIcons.calendar,
                    size: 19, color: Colors.white),
                const SizedBox(height: 8),
                FitnessText('{count} rest days',
                    values: {'count': days.length - training.length},
                    style: const TextStyle(
                        fontSize: 10, color: FitnessTheme.muted)),
              ]),
            ]),
            if (progressKnown) ...[
              const SizedBox(height: 16),
              Row(children: [
                for (var index = 0; index < training.length; index++) ...[
                  if (index > 0) const SizedBox(width: 5),
                  Expanded(
                      child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                              color: index < completed
                                  ? Colors.white
                                  : const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(3)))),
                ],
              ]),
            ],
            const SizedBox(height: 20),
            _weekStrip(days),
          ])),
      const SizedBox(height: 22),
      _sectionTabs(),
      const SizedBox(height: 22),
      ContentTransition(
          child: KeyedSubtree(
        key: ValueKey('week-detail-${selected['date']}-$_section'),
        child:
            _section == 0 ? _workout(selected) : _food('${selected['date']}'),
      )),
    ]);
  }

  Widget _sectionTabs() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0xFF191919),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FitnessTheme.line, width: .7)),
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            Expanded(
                child: Semantics(
              selected: _section == i,
              button: true,
              child: Material(
                color: _section == i ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _section = i),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 13),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                i == 0
                                    ? Icons.fitness_center_outlined
                                    : Icons.restaurant_outlined,
                                size: 16,
                                color: _section == i
                                    ? Colors.black
                                    : FitnessTheme.muted),
                            const SizedBox(width: 8),
                            Flexible(
                                child: FitnessText(
                                    i == 0 ? 'Training' : 'Nutrition',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _section == i
                                            ? Colors.black
                                            : FitnessTheme.muted))),
                          ])),
                ),
              ),
            )),
        ]),
      );

  Widget _weekStrip(List<Map<String, dynamic>> days) => LayoutBuilder(
        builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(10) > 14;
          final width = !largeText && days.length <= 7
              ? box.maxWidth / days.length
              : 54.0;
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var index = 0; index < days.length; index++)
                  SizedBox(
                      width: width,
                      child: _dayButton(_currentWorkout(days[index]), index)),
              ]));
        },
      );

  Widget _dayButton(Map<String, dynamic> day, int index) {
    final selected = _day == index;
    final date = DateTime.parse('${day['date']}');
    final locale = Localizations.localeOf(context).toLanguageTag();
    final complete = day['status'] == 'COMPLETED';
    return Semantics(
      button: true,
      selected: selected,
      label: '${DateFormat.yMMMMEEEEd(locale).format(date)} · ${day['name']}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('plan-day-${day['date']}'),
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              setState(() => _day = index);
              unawaited(_loadSelected());
            },
            child: AnimatedContainer(
              duration: DSMotion.duration(context, DSMotion.selection),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(17)),
              child: Column(children: [
                Text(DateFormat.E(locale).format(date),
                    style: TextStyle(
                        fontSize: 9,
                        color: selected ? Colors.black54 : FitnessTheme.muted)),
                const SizedBox(height: 8),
                Text(DateFormat.d(locale).format(date),
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.black : Colors.white)),
                const SizedBox(height: 8),
                Icon(
                    complete
                        ? CupertinoIcons.checkmark
                        : day['restDay'] == true
                            ? CupertinoIcons.minus
                            : CupertinoIcons.circle_fill,
                    size: day['restDay'] == true || complete ? 9 : 4,
                    color: selected ? Colors.black54 : FitnessTheme.muted),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _workout(Map<String, dynamic> day) {
    final date = '${day['date']}';
    final live = _live[date];
    final rest = day['restDay'] == true;
    final exercises =
        (day['exercises'] as List? ?? []).whereType<Map>().toList();
    final sets = exercises.fold(
        0, (sum, exercise) => sum + (exercise['sets'] as num? ?? 0).toInt());
    final minutes = (day['estimatedMinutes'] as num? ?? 0).round();
    final canStart = widget.active &&
        live != null &&
        !rest &&
        live.items.isNotEmpty &&
        !live.finished &&
        !_errors.contains(date) &&
        (live.started || date == CacheScope.todayKey());
    final canEdit = widget.active &&
        live != null &&
        !live.finished &&
        date.compareTo(CacheScope.todayKey()) >= 0 &&
        !_errors.contains(date);
    final canRest = widget.active &&
        date == CacheScope.todayKey() &&
        live?.json['canReschedule'] == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LiquidGlass(
          radius: 26,
          surfaceColor: const Color(0xFF1C1C1C),
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                  child: Text(
                      DateFormat.MMMEd(
                              Localizations.localeOf(context).toLanguageTag())
                          .format(DateTime.parse(date)),
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted))),
              if (live?.finished == true)
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white, size: 20)
              else if (widget.active && live == null && !_errors.contains(date))
                const CupertinoActivityIndicator(
                    color: Colors.white, radius: 8),
              if (canEdit || canRest)
                PopupMenuButton<String>(
                  tooltip: fitnessText(context, 'Workout options'),
                  padding: EdgeInsets.zero,
                  icon: const Icon(CupertinoIcons.ellipsis,
                      size: 22, color: Colors.white),
                  onSelected: (value) =>
                      value == 'rest' ? _restToday(date) : _editDay(date),
                  itemBuilder: (context) => [
                    if (canEdit)
                      PopupMenuItem(
                          value: 'edit', child: FitnessText('Edit workout')),
                    if (canRest)
                      PopupMenuItem(
                          value: 'rest', child: FitnessText('Rest today')),
                  ],
                ),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                  child: FitnessText(
                      rest ? 'Rest & recharge' : planWorkoutTitle(day),
                      style: const TextStyle(
                          fontSize: 29,
                          height: 1.2,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w500))),
              const SizedBox(width: 14),
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(17)),
                  child: Icon(
                      rest
                          ? CupertinoIcons.moon
                          : Icons.fitness_center_outlined,
                      color: Colors.white,
                      size: 23)),
            ]),
            if (rest) ...[
              const SizedBox(height: 12),
              const FitnessText(
                  'Room to recover. Your next session is on the calendar.',
                  style: TextStyle(
                      fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
            ] else ...[
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                    child: _workoutStat('${exercises.length}', 'Exercises')),
                if (minutes > 0)
                  Expanded(child: _workoutStat('$minutes', 'Minutes')),
                Expanded(child: _workoutStat('$sets', 'Sets')),
              ]),
              if (canStart || canEdit) ...[
                const SizedBox(height: 24),
                LiquidChromeButton(
                    key: const ValueKey('onboarding-first-workout-action'),
                    solid: true,
                    pill: true,
                    showArrow: true,
                    isLoading: _startingFirst,
                    title: canStart
                        ? (live.started ? 'Resume workout' : 'Start workout')
                        : 'Edit workout',
                    onPressed: _startingFirst
                        ? null
                        : canStart
                            ? () => _startFirstWorkout(date)
                            : () => _editDay(date)),
              ],
            ],
          ])),
      if (_errors.contains(date))
        TextButton.icon(
            onPressed: _loadSelected,
            icon: const Icon(CupertinoIcons.refresh, size: 15),
            label: const FitnessText('Could not sync. Tap to retry.',
                style: TextStyle(fontSize: 12))),
      if (!rest && exercises.isNotEmpty) ...[
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(
              child: FitnessText('Your exercises',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.3))),
          FitnessText('Tap for details',
              style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
        ]),
        const SizedBox(height: 14),
        WorkoutWarmup(warmup: (day['warmup'] as Map?)?.cast<String, dynamic>()),
        for (var i = 0; i < exercises.length; i++)
          _exercise(exercises[i], i + 1, date),
      ],
    ]);
  }

  Widget _workoutStat(String value, String label) => Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                height: 1.1,
                letterSpacing: -.7,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 7),
        FitnessText(label,
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
      ]));

  Widget _exercise(Map exercise, int number, String date) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ExerciseRecommendationCard(
          key: ValueKey('plan-exercise-$date-$number'),
          number: number,
          exercise: {...Map<String, dynamic>.from(exercise), 'date': date}));

  Widget _food(String date) {
    final nutrition = widget.payload["nutrition"] as Map?;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      WeeklyNutritionCard(targets: nutrition?["targets"] as Map?),
      const SizedBox(height: 22),
      _meals(date),
    ]);
  }

  Widget _meals(String date) {
    if (widget.active && date.compareTo(CacheScope.todayKey()) >= 0) {
      return PlannedMealsSection(
          showIntakeHint:
              (widget.payload["nutrition"] as Map?)?["targets"] is Map,
          key: ValueKey('weekly-food-$date'),
          date: DateTime.parse(date));
    }
    final nutrition = widget.payload['nutrition'] as Map?;
    final foodDay = (nutrition?['days'] as List? ?? [])
        .whereType<Map>()
        .where((day) => day['date'] == date)
        .firstOrNull;

    if (nutrition?['status'] != 'RECOMMENDED' || foodDay == null) {
      return FitnessCard(
          child: FitnessText(
              nutrition?['reason'] as String? ??
                  'No food suggestions for this day.',
              style: const TextStyle(
                  fontSize: 13, color: FitnessTheme.muted, height: 1.5)));
    }

    final totals = foodDay['totals'] as Map;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FitnessText('Food for the day',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      FitnessText(
          '${(totals['calories'] as num).round()} kcal · ${(totals['protein'] as num).round()} g protein',
          style: const TextStyle(fontSize: 13, color: FitnessTheme.muted)),
      const SizedBox(height: 16),
      if (nutrition?['guidance'] case final Map guidance) ...[
        FitnessCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FitnessText('Nutrition guidance',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FitnessText('${guidance['activity']}',
              style: const TextStyle(
                  fontSize: 12, color: FitnessTheme.muted, height: 1.45)),
          const SizedBox(height: 8),
          FitnessText('${guidance['review']}',
              style: const TextStyle(
                  fontSize: 12, color: FitnessTheme.muted, height: 1.45)),
        ])),
        const SizedBox(height: 12),
      ],
      for (final meal in (foodDay['meals'] as List).whereType<Map>())
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FitnessCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText('${meal['mealType']}'.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                for (final food in (meal['foods'] as List).whereType<Map>())
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FitnessText(
                          '${foodDisplayName('${food['foodId']}', '${food['name']}')} · ${food['servings'] != null ? '${food['servings']} × ${food['servingLabel'] ?? 'portion'}' : '${food['grams']} g'}',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.silver))),
              ])),
        ),
    ]);
  }
}
