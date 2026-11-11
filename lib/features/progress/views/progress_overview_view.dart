import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/components/app_date_filter.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/models/body_map_models.dart';
import '../../body_scan/views/widgets/body_calendar.dart';
import '../../planner/repositories/weekly_plan_repository.dart';
import '../../planner/views/weekly_plan_history_view.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../train/models/training_session.dart';
import '../../train/repositories/training_repository.dart';
import '../../train/views/train_view.dart';
import '../components/progress_surface.dart';
import '../components/progress_photos.dart';
import '../components/progress_visual_cards.dart';
import '../models/progress_chart_data.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_detail_view.dart';
import 'progress_exercises_view.dart';

class ProgressOverviewView extends StatefulWidget {
  final bool isActive;
  final ProgressOverview? initial;
  final ProgressRepository? repository;
  final WeeklyPlanRepository? planRepository;
  final DateTime Function()? clock;
  final DateTimeRange? initialRange;
  final bool standalone;
  const ProgressOverviewView(
      {super.key,
      this.isActive = true,
      this.initial,
      this.repository,
      this.planRepository,
      this.clock,
      this.initialRange,
      this.standalone = false});
  @override
  State<ProgressOverviewView> createState() => _ProgressOverviewViewState();
}

class _ProgressOverviewViewState extends State<ProgressOverviewView> {
  ProgressOverview? _data;
  ProgressRepository get _repo =>
      widget.repository ?? ProgressRepository.shared;
  late BodyDateSelection _selection;
  bool _followsWeek = true;
  String get _period => _selection.mode == BodyDateMode.all ? 'all' : 'custom';
  Map<String, dynamic> get _query => progressSelectionQuery(_selection);
  DateTime get _now =>
      DateUtils.dateOnly(widget.clock?.call() ?? DateTime.now());
  List<String> _pins = [];
  bool _loading = true, _failed = false;
  String? _loadedQuery;
  int _request = 0;
  int _photoRefresh = 0;
  StreamSubscription<TrainingDay>? _training;
  StreamSubscription<String>? _updates;

  @override
  void initState() {
    super.initState();
    final range = widget.initialRange;
    _followsWeek = range == null;
    _selection = range == null
        ? BodyDateSelection.thisWeek(_now)
        : BodyDateSelection(
            mode: BodyDateMode.range, start: range.start, end: range.end);
    _data = widget.initial;
    if (_data != null) {
      final range = _data!.json['range'] as Map?;
      final start = DateTime.tryParse(range?['start'] as String? ?? '');
      final end = DateTime.tryParse(range?['end'] as String? ?? '');
      final dates = (range?['selectedDates'] as List?)
          ?.whereType<String>()
          .map(DateTime.parse)
          .toList();
      if (start != null && end != null) {
        _followsWeek =
            dates == null && start == bodyMapWeek(_now) && end == _now;
        _selection = BodyDateSelection(
            mode: dates != null
                ? BodyDateMode.days
                : range?['comparable'] == false
                    ? BodyDateMode.all
                    : BodyDateMode.range,
            start: start,
            end: end,
            dates: dates ?? []);
      }
      _loadedQuery = _query.toString();
      _loading = false;
    } else {
      _training = TrainingRepository.shared.changes.stream.listen((_) async {
        await _repo.invalidate();
        if (mounted && widget.isActive) unawaited(_load(refresh: true));
      });
      _updates = _repo.updates.stream.listen((key) {
        if (!mounted || !widget.isActive) return;
        if (key == 'invalidated') {
          unawaited(_load(refresh: true));
        } else if (!_loading && key.contains('__${_period}_')) {
          unawaited(_acceptCache(_request, _period, _query));
        }
      });
      if (widget.isActive) unawaited(_load());
    }
    LanguageManager.shared.addListener(_languageChanged);
  }

  void _languageChanged() {
    if (widget.isActive) unawaited(_load(refresh: true, clear: true));
  }

  @override
  void didUpdateWidget(ProgressOverviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && widget.initial == null) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _training?.cancel();
    _updates?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  Future<void> _acceptCache(
      int request, String period, Map<String, dynamic> query) async {
    final json = await _repo.cached('', period, query: query);
    if (mounted && request == _request && json != null) {
      setState(() => _data = ProgressOverview(json));
    }
  }

  Future<void> _load({bool refresh = false, bool clear = false}) async {
    final request = ++_request;
    if (_followsWeek) _selection = BodyDateSelection.thisWeek(_now);
    final period = _period;
    final query = _query;
    setState(() {
      _loading = true;
      if (refresh) _photoRefresh++;
      _failed = false;
      if (clear || _loadedQuery != query.toString()) _data = null;
      _loadedQuery = query.toString();
    });
    try {
      final pins = await _repo.pins();
      if (!refresh && _data == null) {
        await _acceptCache(request, period, query);
      }
      final json = await _repo.load('', period, refresh: refresh, query: query);
      if (mounted && request == _request) {
        setState(() {
          _data = ProgressOverview(json);
          _pins = pins;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _calendar() async {
    final selection =
        await showBodyDateFilter(context, selection: _selection, today: _now);
    if (!mounted || selection == null) return;
    setState(() {
      _selection = selection;
      _followsWeek = selection.mode == BodyDateMode.range &&
          selection.start == bodyMapWeek(_now) &&
          selection.end == _now;
    });
    await _load(clear: true);
  }

  Future<void> _open(String title, String path, String kind,
      {ProgressJson? initial}) async {
    await Navigator.of(context).push(AppPageRoute(
        builder: (_) => ProgressDetailView(
            repository: _repo,
            title: title,
            path: path,
            kind: kind,
            period: _period,
            query: _query,
            initial: initial)));
    if (mounted && widget.initial == null) unawaited(_load());
  }

  void _exercise(ProgressJson row) => _open(
      row['name'] as String? ?? 'Exercise',
      '/exercises/${row['id']}',
      'exercise');
  Future<void> _exercises() async {
    await Navigator.of(context).push(AppPageRoute(
        builder: (_) => ProgressExercisesView(
            repository: _repo,
            period: _period,
            muscles: _data?.muscles ?? [],
            query: _query)));
    final pins = await _repo.pins();
    if (mounted) setState(() => _pins = pins);
  }

  void _plan(String id) => Navigator.of(context).push(AppPageRoute(
      builder: (_) => WeeklyPlanView(
          repository: widget.planRepository, initialPlanId: id)));
  Future<void> _plans() async {
    final plan = await Navigator.of(context).push<Map<String, dynamic>>(
        AppPageRoute(
            builder: (_) => WeeklyPlanHistoryView(
                    query: {
                      'period': _period,
                      ..._query,
                      'utcOffsetMinutes':
                          DateTime.now().timeZoneOffset.inMinutes
                    },
                    rangeLabel: _label,
                    repository:
                        widget.planRepository ?? WeeklyPlanRepository())));
    if (mounted && plan?['id'] is String) _plan(plan!['id'] as String);
  }

  bool get _stacked =>
      MediaQuery.sizeOf(context).width < 360 ||
      MediaQuery.textScalerOf(context).scale(14) > 18;
  String get _label {
    if (_followsWeek) {
      final week = bodyMapWeek(_now);
      return '${fitnessText(context, 'This week')} · ${bodyDateRangeLabel(context, week, DateTime(week.year, week.month, week.day + 6))}';
    }
    return bodySelectionLabel(context, _selection);
  }

  List<DateTime> _days(ProgressOverview data) {
    if (_followsWeek) {
      final week = bodyMapWeek(_now);
      return List.generate(
          7, (i) => DateTime(week.year, week.month, week.day + i));
    }
    return progressCalendarDays(data);
  }

  Widget _history(ProgressOverview data) {
    final plans = progressRows(data.json['planHistory']);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressHeading('Plan history',
          topPadding: 12, action: 'View all', onTap: _plans, stacked: _stacked),
      ProgressSurface(
          padding: plans.isEmpty ? const EdgeInsets.all(16) : EdgeInsets.zero,
          child: plans.isEmpty
              ? const ProgressEmpty('No plans in this period')
              : Column(children: [
                  for (var i = 0; i < plans.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: DSColors.border),
                    ListTile(
                        key: ValueKey('progress-plan-${plans[i]['id']}'),
                        onTap: () => _plan(plans[i]['id'] as String),
                        title: Text(
                            fitnessText(context, 'Week of {date}', values: {
                              'date': progressDate(
                                  plans[i]['weekStart'] as String?, locale)
                            }),
                            style: const TextStyle(
                                color: progressSilver, fontSize: 14)),
                        subtitle: Text(
                            fitnessText(
                                context,
                                plans[i]['status'] == 'ACTIVE'
                                    ? 'Active'
                                    : plans[i]['status'] == 'ARCHIVED'
                                        ? 'Archived'
                                        : 'Saved'),
                            style: const TextStyle(
                                color: progressMuted, fontSize: 11)),
                        trailing: const Icon(CupertinoIcons.chevron_right,
                            size: 12, color: progressMuted)),
                  ]
                ])),
      Align(
          alignment: Alignment.centerRight,
          child: TextButton(
              key: const ValueKey('progress-view-all-history'),
              onPressed: () =>
                  _open('Workout history', '/sessions', 'sessions'),
              child: Text(fitnessText(context, 'Workout history'),
                  style: const TextStyle(color: progressMuted, fontSize: 12)))),
    ]);
  }

  List<Widget> _content(ProgressOverview data) {
    final days = _days(data);
    final sections = <Widget>[
      ProgressHeading('Activity',
          topPadding: 12,
          action: 'Training details',
          stacked: _stacked,
          onTap: () => _open('Training', '', 'training', initial: data.json)),
      ProgressAttendanceCard(
          data: data,
          days: days,
          onOpen: () => _open('Training', '', 'training', initial: data.json)),
      if ((progressNumber(data.summary['sets']) ?? 0) == 0)
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FilledButton.icon(
                key: const ValueKey('progress-open-training'),
                onPressed: () => Navigator.of(context).push(AppPageRoute(
                    builder: (_) => const TrainView(standalone: true))),
                style: FilledButton.styleFrom(
                    backgroundColor: DSColors.silver,
                    foregroundColor: DSColors.bg,
                    minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.fitness_center, size: 18),
                label: Text(fitnessText(context, 'Open training')))),
      ProgressHeading('Muscle training',
          topPadding: 12,
          action: 'View all',
          stacked: _stacked,
          onTap: () =>
              _open('Muscle distribution', '', 'muscles', initial: data.json)),
      ProgressMuscleChartCard(
          muscles: data.muscles,
          onMuscle: (row) => _open(progressMuscleLabel(context, row),
              '/muscles/${row['id']}', 'muscle')),
      ProgressHeading('Recent exercises',
          topPadding: 12,
          action: 'View all',
          onTap: _exercises,
          stacked: _stacked),
      ProgressExerciseChartShelf(
          exercises: data.exercises, pins: _pins, onOpen: _exercise),
      ProgressHeading('Body changes',
          topPadding: 12,
          action: 'View all',
          stacked: _stacked,
          onTap: () =>
              _open('Body changes', '/body', 'body', initial: data.body)),
      ProgressBodyChartCard(
          body: data.body,
          onOpen: () =>
              _open('Body changes', '/body', 'body', initial: data.body)),
      ProgressHeading('Nutrition',
          topPadding: 12,
          action: 'View all',
          stacked: _stacked,
          onTap: () => _open('Nutrition', '/wellness', 'nutrition',
              initial: data.wellness)),
      ProgressNutritionDonutCard(wellness: data.wellness),
      const ProgressHeading('Daily trends', topPadding: 12),
      ProgressDailyTrendsCard(data: data, days: days),
      _history(data),
    ];
    // Lazy sections should be ready while scrolling, rather than replaying
    // opacity animations whenever a card is mounted again by the sliver list.
    return sections;
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          appBar: widget.standalone
              ? AppBar(
                  backgroundColor: DSColors.bg,
                  foregroundColor: DSColors.textPrimary,
                  surfaceTintColor: Colors.transparent,
                  title: Text(fitnessText(context, 'Weekly summary')))
              : null,
          backgroundColor: DSColors.bg,
          body: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(fitnessText(context, 'Progress'),
                                key: const ValueKey('progress-title'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -.4)),
                            const SizedBox(height: 5),
                            Text(_label,
                                key: const ValueKey('progress-range-label'),
                                style: const TextStyle(
                                    color: progressMuted,
                                    fontSize: 11,
                                    height: 1.4)),
                          ])),
                      const SizedBox(width: 12),
                      AppDateFilterButton(
                          key: const ValueKey('progress-calendar-button'),
                          onPressed: _calendar),
                    ])),
                SizedBox(
                    height: 2,
                    child: _loading && _data != null
                        ? const LinearProgressIndicator(
                            minHeight: 2,
                            color: progressSilver,
                            backgroundColor: Colors.transparent)
                        : null),
                Expanded(
                    child: RefreshIndicator(
                        color: progressSilver,
                        onRefresh: () => _load(refresh: true),
                        child: CustomScrollView(
                            key: const PageStorageKey('progress-scroll'),
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            slivers: [
                              SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                      18,
                                      0,
                                      18,
                                      LiquidSilverBottomBar.scrollBottomInset(
                                          context)),
                                  sliver: SliverList.list(children: [
                                    if (!widget.standalone)
                                      ProgressPhotoShelf(
                                          isActive: widget.isActive,
                                          refreshVersion: _photoRefresh),
                                    if (_failed)
                                      Row(children: [
                                        Expanded(
                                            child: Text(
                                                fitnessText(context,
                                                    'Could not refresh. Pull down to retry.'),
                                                style: const TextStyle(
                                                    color: progressMuted,
                                                    fontSize: 12))),
                                        TextButton(
                                            onPressed: () =>
                                                _load(refresh: true),
                                            child: Text(
                                                fitnessText(context, 'Retry'))),
                                      ]),
                                    if (_data == null && _loading)
                                      const ProgressSkeleton(
                                          heights: [190, 220, 265, 240])
                                    else if (_data != null)
                                      ..._content(_data!),
                                  ]))
                            ]))),
              ]))));
}
