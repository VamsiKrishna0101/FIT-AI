import '../../../train/components/workout_warmup.dart';
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
import '../../../../core/theme/ds_colors.dart';
import '../../../../core/components/content_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../body_scan/views/widgets/body_controls.dart';
import 'plan_week_list.dart';
import '../../../../core/components/fitness_form.dart';

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

class _WeeklyPlanScheduleState extends State<WeeklyPlanSchedule>
    with SingleTickerProviderStateMixin {
  int _day = 0;
  int _section = 0;
  bool _startingFirst = false;
  bool _openingDay = false;
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
    if (widget.showOverview && mounted) {
      final next = _nextTraining(_days.map(_currentWorkout).toList());
      if (next != null && next['date'] != date) {
        await _loadDate('${next['date']}');
      }
    }
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

  Future<void> _openDay(String date) async {
    if (_openingDay) return;
    _openingDay = true;
    try {
      await Navigator.of(context).push(AppPageRoute<void>(
          page: FitnessTheme(
              child: Scaffold(
        appBar: AppBar(
            title: Text(
                DateFormat.yMMMEd(
                        Localizations.localeOf(context).toLanguageTag())
                    .format(DateTime.parse(date)),
                style: const TextStyle(fontSize: 15))),
        body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: WeeklyPlanSchedule(
                payload: widget.payload,
                active: widget.active,
                initialDate: date,
                fromOnboarding: widget.fromOnboarding,
                showOverview: false,
                loadDay: widget.loadDay,
                startDay: widget.startDay)),
      ))));
      if (mounted) await _loadSelected();
    } finally {
      _openingDay = false;
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
          labels: const ['Workout', 'Food'],
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
    final training = days.where((d) => d['restDay'] != true).toList();
    final statuses = <String, String>{
      for (final d in days)
        if (d['status'] is String) '${d['date']}': d['status'] as String
    };
    final completed =
        training.where((d) => statuses[d['date']] == 'COMPLETED').length;
    final knownProgress = widget.active &&
        training.isNotEmpty &&
        training.every((d) => statuses.containsKey(d['date']));
    final next = _nextTraining(days);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (next != null) ...[
        _nextWorkout(next),
        const SizedBox(height: 24),
      ],
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const FitnessText('Your week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (knownProgress)
              FitnessText('{done} of {total} complete',
                  values: {'done': completed, 'total': training.length},
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted))
            else
              FitnessText('{count} training days',
                  values: {'count': training.length},
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          ]),
      if (knownProgress) ...[
        const SizedBox(height: 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: completed / training.length,
                minHeight: 4,
                color: FitnessTheme.silver,
                backgroundColor: FitnessTheme.line)),
        const SizedBox(height: 6),
        Text('${(completed / training.length * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      ],
      const SizedBox(height: 12),
      PlanWeekList(days: days, statuses: statuses, onSelected: _openDay),
      if (widget.active && _errors.isNotEmpty)
        TextButton.icon(
            onPressed: _loadSelected,
            icon: const Icon(Icons.refresh, size: 16),
            label: const FitnessText('Could not sync. Tap to retry.')),
    ]);
  }

  Map<String, dynamic>? _nextTraining(List<Map<String, dynamic>> days) {
    final remaining = days
        .where((d) =>
            d['restDay'] != true &&
            d['status'] != 'COMPLETED' &&
            d['status'] != 'SKIPPED')
        .toList();
    return remaining.where((d) => d['status'] == 'IN_PROGRESS').firstOrNull ??
        remaining
            .where((d) => '${d['date']}'.compareTo(CacheScope.todayKey()) >= 0)
            .firstOrNull;
  }

  Widget _nextWorkout(Map<String, dynamic> day) {
    final date = '${day['date']}';
    final live = _live[date];
    final start = widget.active &&
        live != null &&
        !live.restDay &&
        live.items.isNotEmpty &&
        !live.finished &&
        (live.started || date == CacheScope.todayKey());
    final count =
        day['exerciseCount'] ?? (day['exercises'] as List? ?? []).length;
    return FitnessCard(
        key: const ValueKey('next-plan-workout'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FitnessText(
              live?.started == true ? 'Continue your workout' : 'Next workout',
              style: const TextStyle(color: FitnessTheme.muted, fontSize: 12)),
          const SizedBox(height: 12),
          FitnessText('${day['name']}',
              style: const TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
              DateFormat.yMMMMEEEEd(
                      Localizations.localeOf(context).toLanguageTag())
                  .format(DateTime.parse(date)),
              style: const TextStyle(fontSize: 12, color: FitnessTheme.silver)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            FitnessText(count == 1 ? '{count} exercise' : '{count} exercises',
                values: {'count': count},
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            if ((day['estimatedMinutes'] as num? ?? 0) > 0)
              FitnessText('{minutes} min',
                  values: {'minutes': (day['estimatedMinutes'] as num).round()},
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          ]),
          const SizedBox(height: 18),
          FitnessSubmit(
              label: start
                  ? (live.started ? 'Resume workout' : 'Start workout')
                  : 'View workout',
              busy: _startingFirst,
              onPressed: _startingFirst
                  ? null
                  : start
                      ? () => _startFirstWorkout(date)
                      : () => _openDay(date)),
          if (start)
            TextButton(
                onPressed: _startingFirst ? null : () => _openDay(date),
                child: const FitnessText('View workout')),
        ]));
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
        if (day['restDay'] != true &&
            _live[day['date']] != null &&
            !_errors.contains(day['date']) &&
            _live[day['date']]!.items.isNotEmpty &&
            _live[day['date']]?.finished != true &&
            (_live[day['date']]!.started ||
                day['date'] == CacheScope.todayKey())) ...[
          LiquidChromeButton(
              key: const ValueKey('onboarding-first-workout-action'),
              solid: true,
              pill: true,
              showArrow: false,
              isLoading: _startingFirst,
              title: _live[day['date']]!.started
                  ? 'Resume workout'
                  : 'Start workout',
              onPressed: _startingFirst
                  ? null
                  : () => _startFirstWorkout(day['date'] as String)),
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
    final unit = exercise['weightUnit'] == 'per_hand'
        ? ' per hand'
        : exercise['weightUnit'] == 'total_load'
            ? ' total'
            : '';
    final reps = exercise['targetReps'] ??
        (exercise['repsMin'] == exercise['repsMax']
            ? exercise['repsMax']
            : '${exercise['repsMin']}–${exercise['repsMax']}');
    String load(num? weight) => exercise['weightBasis'] == 'bodyweight'
        ? 'Bodyweight'
        : weight == null
            ? 'Choose starting load'
            : '$weight kg$unit';
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FitnessCard(
            padding: EdgeInsets.zero,
            child: Material(
                type: MaterialType.transparency,
                child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey('plan-exercise-$date-$number'),
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      leading: Text(number.toString().padLeft(2, '0'),
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      title: FitnessText(
                          '${exercise['displayName'] ?? exercise['name']}',
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w500)),
                      subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: FitnessText('{sets} sets · {reps} reps',
                              values: {
                                'sets': targets.isEmpty
                                    ? exercise['sets'] ?? 0
                                    : targets.length,
                                'reps': reps ?? ''
                              },
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(
                                  height: 1, color: FitnessTheme.line),
                              const SizedBox(height: 12),
                              if (targets.isEmpty)
                                FitnessText(load(exercise['weightKg'] as num?),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: FitnessTheme.silver)),
                              for (final set in targets)
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FitnessText('Set ${set['setNumber']}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: FitnessTheme.muted)),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: FitnessText(
                                                  '${set['repsMin'] == set['repsMax'] ? set['repsMax'] : '${set['repsMin']}–${set['repsMax']}'} reps · ${load(set['weightKg'] as num?)}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: FitnessTheme
                                                          .silver))),
                                        ])),
                              if (exercise['weightBasis'] == 'estimated_start')
                                const FitnessText(
                                    'Starting estimate · reduce the load if needed',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: FitnessTheme.muted)),
                              const SizedBox(height: 10),
                              FitnessText(
                                  '${exercise['targetRpe'] == null ? '' : 'Effort ${exercise['targetRpe']}/10 · '}${exercise['restSeconds']} s rest',
                                  style: const TextStyle(
                                      fontSize: 12, color: FitnessTheme.muted)),
                              if (exercise['reason'] is String &&
                                  (exercise['reason'] as String)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const FitnessText('Why this exercise',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                FitnessText(exercise['reason'] as String,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted,
                                        height: 1.5)),
                              ],
                            ])
                      ],
                    )))));
  }

  Widget _food(String date) {
    if (widget.active && date.compareTo(CacheScope.todayKey()) >= 0) {
      return PlannedMealsSection(
          key: ValueKey('weekly-food-$date'), date: DateTime.parse(date));
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
                          '${foodDisplayName('${food['foodId']}', '${food['name']}')} · ${food['servings'] != null ? '${food['servings']} × ${food['servingLabel'] ?? 'portion'}' : '${food['grams']} g'}',
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.silver))),
              ])),
        ),
    ]);
  }
}
