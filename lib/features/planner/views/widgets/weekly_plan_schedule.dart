import '../../../train/components/workout_warmup.dart';
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
import '../../../../core/theme/ds_colors.dart';
import '../../../../core/components/content_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../body_scan/views/widgets/body_controls.dart';

class WeeklyPlanSchedule extends StatefulWidget {
  final Map<String, dynamic> payload;
  final bool active;
  final Future<TrainingDay> Function(String)? loadDay;
  final Future<TrainingDay> Function(String)? startDay;
  final bool fromOnboarding;

  const WeeklyPlanSchedule(
      {super.key,
      required this.payload,
      this.active = false,
      this.loadDay,
      this.startDay,
      this.fromOnboarding = false});

  @override
  State<WeeklyPlanSchedule> createState() => _WeeklyPlanScheduleState();
}

class _WeeklyPlanScheduleState extends State<WeeklyPlanSchedule>
    with SingleTickerProviderStateMixin {
  int _day = 0;
  int _section = 0;
  bool _startingFirst = false;
  late final _reveal =
      AnimationController(vsync: this, duration: DSMotion.regular);
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) {
      _reveal.value = 1;
      _revealed = true;
    } else if (!_revealed) {
      _revealed = true;
      _reveal.forward();
    }
  }

  List<Map<String, dynamic>> get _days =>
      (widget.payload['workouts'] as List? ?? [])
          .whereType<Map>()
          .map((day) => Map<String, dynamic>.from(day))
          .toList();

  final _live = <String, TrainingDay>{};
  final _errors = <String>{};
  StreamSubscription<TrainingDay>? _subscription;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final current = _days.indexWhere((day) => day['date'] == today);
    final firstWorkout = _days.indexWhere((day) => day['restDay'] != true);
    _day = widget.fromOnboarding && firstWorkout >= 0
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
          _errors.remove(day.date);
        });
      }
    });
    if (widget.active) unawaited(_loadSelected());
  }

  @override
  void didUpdateWidget(WeeklyPlanSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) unawaited(_loadSelected());
  }

  Future<void> _loadSelected() async {
    final days = _days;
    if (!widget.active || days.isEmpty) return;
    final date = days[_day.clamp(0, days.length - 1)]['date'] as String;
    final request = ++_request;
    try {
      final day = await (widget.loadDay?.call(date) ??
          TrainingRepository.shared.load(date, refresh: true));
      if (!mounted || request != _request) return;
      setState(() {
        _live[date] = day;
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

  Future<void> _viewFirstWorkout(String date) async {
    await Navigator.of(context).push(AppPageRoute<void>(
        page: TrainView(standalone: true, initialDate: date)));
    if (mounted) await _loadSelected();
  }

  Future<void> _restToday(String date) async {
    final changed = await showModalBottomSheet<bool>(
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
    if (!widget.active || live == null) return saved;
    final original = (saved['exercises'] as List? ?? []).whereType<Map>();
    return {
      ...saved,
      'name': live.name,
      'restDay': live.restDay,
      'warmup': live.json['warmup'],
      'estimatedMinutes': live.estimatedMinutes,
      'exercises': [
        for (final item in live.items)
          {
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
          }
      ],
    };
  }

  @override
  void dispose() {
    ++_request;
    _subscription?.cancel();
    _reveal.dispose();
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

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText(
          '$trainingDays training ${trainingDays == 1 ? 'day' : 'days'} · $restDays rest ${restDays == 1 ? 'day' : 'days'}',
          style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      const SizedBox(height: 14),
      _weekStrip(days),
      const SizedBox(height: 16),
      BodySegment(
          labels: const ['Workout', 'Food'],
          selected: _section,
          onChanged: (section) => setState(() => _section = section)),
      const SizedBox(height: 20),
      FitnessText(
          DateFormat.MMMMEEEEd()
              .format(DateTime.parse(selected['date'] as String)),
          style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      const SizedBox(height: 8),
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

  Widget _weekStrip(List<Map<String, dynamic>> days) => LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
          final width = !largeText && days.length >= 5
              ? (constraints.maxWidth - 12) / days.length
              : 58.0;

          return Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DSColors.border, width: .7),
              color: DSColors.bgCard,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var index = 0; index < days.length; index++)
                  SizedBox(
                      width: width,
                      child: _dayButton(_currentWorkout(days[index]), index)),
              ]),
            ),
          );
        },
      );

  Widget _dayButton(Map<String, dynamic> day, int index) {
    final selected = index == _day;
    final date = DateTime.parse(day['date'] as String);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Semantics(
      selected: selected,
      button: true,
      label: '${DateFormat.yMMMMEEEEd(locale).format(date)} · ${day['name']}',
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('plan-day-${day['date']}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => _day = index);
              unawaited(_loadSelected());
            },
            child: AnimatedContainer(
              duration: DSMotion.duration(context, DSMotion.selection),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: .30)
                        : Colors.transparent),
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF505050), Color(0xFF303030)],
                      )
                    : null,
              ),
              child: Column(children: [
                Text(DateFormat.E(locale).format(date),
                    style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? FitnessTheme.silver
                            : FitnessTheme.muted)),
                const SizedBox(height: 5),
                Text(DateFormat.d(locale).format(date),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : FitnessTheme.silver)),
                const SizedBox(height: 6),
                Container(
                    width: day['restDay'] == true ? 9 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: selected
                            ? FitnessTheme.silver
                            : FitnessTheme.muted.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(3))),
              ]),
            ),
          )),
    );
  }

  Widget _workout(Map<String, dynamic> day) {
    final exercises =
        (day['exercises'] as List? ?? []).whereType<Map>().toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitnessText('${day['name']}',
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.5)),
      const SizedBox(height: 8),
      if (widget.active) ...[
        if (widget.fromOnboarding &&
            day['restDay'] != true &&
            _days.where((d) => d['restDay'] != true).firstOrNull?['date'] ==
                day['date'] &&
            _live[day['date']] != null &&
            !_errors.contains(day['date']) &&
            _live[day['date']]!.items.isNotEmpty &&
            _live[day['date']]?.finished != true) ...[
          LiquidChromeButton(
              key: const ValueKey('onboarding-first-workout-action'),
              solid: true,
              pill: true,
              showArrow: false,
              isLoading: _startingFirst,
              title: _live[day['date']]!.started
                  ? 'Resume workout'
                  : day['date'] == CacheScope.todayKey()
                      ? 'Start my first workout'
                      : 'View my first workout',
              onPressed: _startingFirst
                  ? null
                  : day['date'] == CacheScope.todayKey() ||
                          _live[day['date']]!.started
                      ? () => _startFirstWorkout(day['date'] as String)
                      : () => _viewFirstWorkout(day['date'] as String)),
          const SizedBox(height: 14),
        ],
        if (day['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now()) &&
            _live[day['date']]?.json['canReschedule'] == true)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () => _restToday(day['date'] as String),
                  child: const FitnessText('Rest today',
                      style: TextStyle(color: FitnessTheme.silver)))),
        if (_errors.contains(day['date']))
          TextButton.icon(
              onPressed: _loadSelected,
              icon: const Icon(CupertinoIcons.refresh, size: 15),
              label: const FitnessText('Could not sync. Tap to retry.',
                  style: TextStyle(fontSize: 12))),
        if (!_live.containsKey(day['date']) && !_errors.contains(day['date']))
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CupertinoActivityIndicator(radius: 8)),
        if (_live.containsKey(day['date']) &&
            !_errors.contains(day['date']) &&
            _live[day['date']]?.finished != true)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('edit-plan-day-${day['date']}'),
                onPressed: () => _editDay(day['date'] as String),
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 16),
                label: const FitnessText('Edit workout',
                    style: TextStyle(fontSize: 13)),
                style:
                    TextButton.styleFrom(foregroundColor: FitnessTheme.silver),
              )),
        const SizedBox(height: 8),
      ],
      if (day['restDay'] == true)
        const FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(CupertinoIcons.moon, color: FitnessTheme.silver, size: 26),
            SizedBox(height: 14),
            FitnessText('Recovery day', style: TextStyle(fontSize: 18)),
            SizedBox(height: 6),
            FitnessText('No workout scheduled. Give yourself time to recover.',
                style: TextStyle(
                    fontSize: 13, color: FitnessTheme.muted, height: 1.4)),
          ]),
        )
      else ...[
        FitnessText(
            '${exercises.length} ${exercises.length == 1 ? 'exercise' : 'exercises'} · ${day['estimatedMinutes']} min',
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 16),
        WorkoutWarmup(warmup: (day['warmup'] as Map?)?.cast<String, dynamic>()),
        for (var index = 0; index < exercises.length; index++)
          SlideTransition(
            key: ValueKey('plan-card-reveal-$index'),
            position:
                Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero)
                    .chain(CurveTween(
                        curve: Interval((index.clamp(0, 3)) * .08, 1,
                            curve: DSMotion.snappy)))
                    .animate(_reveal),
            child:
                _exercise(exercises[index], index + 1, day['date'] as String),
          ),
      ],
    ]);
  }

  Widget _exercise(Map exercise, int number, String date) {
    final targets =
        (exercise['setPrescriptions'] as List? ?? []).whereType<Map>().toList();
    final sameTargets = targets.isNotEmpty &&
        targets.every((set) =>
            set['repsMin'] == targets.first['repsMin'] &&
            set['repsMax'] == targets.first['repsMax'] &&
            set['weightKg'] == targets.first['weightKg']);
    final unit = exercise['weightUnit'] == 'per_hand'
        ? ' per hand'
        : exercise['weightUnit'] == 'total_load'
            ? ' total'
            : '';
    final weight =
        sameTargets ? targets.first['weightKg'] : exercise['weightKg'];
    final load = exercise['weightBasis'] == 'bodyweight'
        ? 'Bodyweight'
        : weight == null
            ? 'Choose starting load'
            : exercise['weightBasis'] == 'estimated_start'
                ? '~$weight kg$unit · suggested start'
                : '$weight kg$unit · as logged';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(number.toString().padLeft(2, '0'),
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: FitnessText(
                    '${exercise['displayName'] ?? exercise['name']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 14),
          if (targets.isEmpty || sameTargets)
            FitnessText(
                '${sameTargets ? targets.length : exercise['sets']} × ${sameTargets ? (targets.first['repsMin'] == targets.first['repsMax'] ? targets.first['repsMax'] : '${targets.first['repsMin']}–${targets.first['repsMax']}') : exercise['targetReps'] ?? (exercise['repsMin'] == exercise['repsMax'] ? exercise['repsMax'] : '${exercise['repsMin']}–${exercise['repsMax']}')} · $load',
                style:
                    const TextStyle(fontSize: 14, color: FitnessTheme.silver)),
          for (final set in sameTargets ? <Map>[] : targets)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  FitnessText('Set ${set['setNumber']}',
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: FitnessText(
                          '${set['repsMin'] == set['repsMax'] ? set['repsMax'] : '${set['repsMin']}–${set['repsMax']}'} reps · ${set['weightKg'] == null ? 'Choose starting load' : exercise['weightBasis'] == 'bodyweight' ? 'Bodyweight' : '${set['weightKg']} kg$unit'}',
                          style: const TextStyle(
                              fontSize: 14, color: FitnessTheme.silver))),
                ])),
          if (targets.isNotEmpty &&
              exercise['weightBasis'] == 'estimated_start')
            const FitnessText('Starting estimate · reduce the load if needed',
                style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          const SizedBox(height: 6),
          FitnessText(
              '${exercise['targetRpe'] == null ? '' : 'Effort ${exercise['targetRpe']}/10 · '}${exercise['restSeconds']} s rest',
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          if (exercise['reason'] is String &&
              (exercise['reason'] as String).isNotEmpty)
            Material(
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: ValueKey('plan-exercise-$date-$number'),
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: const FitnessText('Why this exercise',
                        style:
                            TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                    children: [
                      FitnessText(exercise['reason'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: FitnessTheme.muted,
                              height: 1.5)),
                    ],
                  ),
                )),
        ]),
      ),
    );
  }

  Widget _food(String date) {
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
          const FitnessText('Your training and nutrition',
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
                          '${foodDisplayName('${food['foodId']}', '${food['name']}')} · ${food['grams']} g',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.silver))),
              ])),
        ),
    ]);
  }
}
