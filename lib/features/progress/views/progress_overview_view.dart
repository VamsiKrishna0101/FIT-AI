import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import '../../../core/components/animated_tab_stack.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../train/models/training_session.dart';
import '../../train/repositories/training_repository.dart';
import '../components/progress_dashboard.dart';
import '../components/progress_history_feed.dart';
import '../components/progress_workout_history.dart';
import '../components/progress_date_filter.dart';
import '../components/progress_surface.dart';
import '../components/progress_training_hero.dart';

import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_detail_view.dart';
import 'progress_exercises_view.dart';

class ProgressOverviewView extends StatefulWidget {
  final bool isActive;
  final ProgressOverview? initial;
  final ProgressRepository? repository;
  const ProgressOverviewView(
      {super.key, this.isActive = true, this.initial, this.repository});
  @override
  State<ProgressOverviewView> createState() => _ProgressOverviewViewState();
}

class _ProgressOverviewViewState extends State<ProgressOverviewView> {
  ProgressOverview? _data;
  ProgressRepository get _repo =>
      widget.repository ?? ProgressRepository.shared;
  ProgressSection _section = ProgressSection.summary;
  final _visited = <ProgressSection>{ProgressSection.summary};
  final _historyKey = GlobalKey<ProgressHistoryFeedState>();
  bool _changingRange = false;
  String _period = '4w';
  DateTimeRange? _custom;
  Map<String, dynamic> get _filterQuery => {
        'dataset': 'real',
        if (_custom != null) 'start': CacheScope.todayKey(_custom!.start),
        if (_custom != null) 'end': CacheScope.todayKey(_custom!.end),
      };
  List<String> _pins = [];
  String? get _rangeLabel {
    final range = _data?.json['range'] as Map?;
    if (range == null) return null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${progressDate(range['start'] as String?, locale)} – ${progressDate(range['end'] as String?, locale)}';
  }

  bool _loading = true, _failed = false;
  int _request = 0;
  StreamSubscription<TrainingDay>? _training;
  StreamSubscription<String>? _updates;
  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    if (widget.initial != null) {
      if ((widget.initial!.json['range'] as Map?)?['comparable'] == false) {
        _period = 'all';
      }
      _loading = false;
      return;
    }
    _training = TrainingRepository.shared.changes.stream.listen((_) async {
      await _repo.invalidate();
      if (mounted && widget.isActive) unawaited(_load(refresh: true));
    });
    _updates = _repo.updates.stream.listen((key) {
      if (key == 'invalidated' && mounted && widget.isActive) {
        unawaited(_load(refresh: true));
        return;
      }
      if (key.contains('__${_period}_') && mounted && widget.isActive) {
        unawaited(_acceptCache());
      }
    });
    LanguageManager.shared.addListener(_languageChanged);
    if (widget.isActive) unawaited(_load());
  }

  void _languageChanged() {
    if (widget.isActive) unawaited(_load(refresh: true, clear: true));
  }

  @override
  void didUpdateWidget(ProgressOverviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && widget.initial == null) {
      unawaited(_load(refresh: true));
    }
  }

  @override
  void dispose() {
    _training?.cancel();
    _updates?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  Future<void> _acceptCache() async {
    final request = _request;
    final json = await _repo.cached('', _period, query: _filterQuery);
    if (mounted && request == _request && json != null) {
      setState(() => _data = ProgressOverview(json));
    }
  }

  Future<void> _load({bool refresh = false, bool clear = false}) async {
    final request = ++_request;
    final period = _period;
    setState(() {
      _loading = true;
      _failed = false;
      _changingRange = clear;
    });
    try {
      final pins = await _repo.pins();
      if (!refresh) await _acceptCache();
      final json =
          await _repo.load('', period, refresh: refresh, query: _filterQuery);
      if (mounted && request == _request) {
        setState(() {
          _data = ProgressOverview(json);
          _pins = pins;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _failed = true;
          if (_changingRange) _data = null;
        });
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _changingRange = false;
        });
      }
    }
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
            query: _filterQuery,
            initial: initial)));
    if (mounted && widget.initial == null) unawaited(_load(refresh: true));
  }

  Future<void> _exercises() async {
    await Navigator.of(context).push(AppPageRoute(
        builder: (_) => ProgressExercisesView(
            repository: _repo,
            period: _period,
            muscles: _data?.muscles ?? [],
            query: _filterQuery)));
    final pins = await _repo.pins();
    if (mounted) setState(() => _pins = pins);
  }

  Future<void> _activity(ProgressOverview data) =>
      _open('Training', '', 'training', initial: data.json);

  void _changeSection(ProgressSection section) {
    if (_section == section) return;
    setState(() {
      _section = section;
      _visited.add(section);
    });
  }

  void _trend(String kind, ProgressOverview data) {
    switch (kind) {
      case 'training':
        _activity(data);
      case 'exercises':
        _exercises();
      case 'muscles':
        _open('Muscle distribution', '', 'muscles',
            initial: {'muscles': data.muscles});
      case 'body':
        _open('Body changes', '/body', 'body', initial: data.body);
      case 'nutrition':
        _open('Nutrition', '/wellness', 'nutrition', initial: data.wellness);
      case 'recovery':
        _open('Recovery', '/wellness', 'recovery', initial: data.wellness);
    }
  }

  void _session(ProgressJson session) =>
      Navigator.of(context).push(AppPageRoute(
          builder: (_) => ProgressWorkoutRecap(
              session: session,
              onExercise: (exercise) => _open(
                  exercise['name'] as String? ?? 'Exercise',
                  '/exercises/${exercise['id']}',
                  'exercise'))));

  List<Widget> _summary(ProgressOverview data) {
    final empty = (progressNumber(data.summary['workouts']) ?? 0) == 0 &&
        (progressNumber(data.summary['sets']) ?? 0) == 0 &&
        data.exercises.isEmpty;
    final blocks = [
      if (empty)
        ProgressSurface(
            key: const ValueKey('progress-empty-summary'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(children: [
              const Icon(CupertinoIcons.chart_bar,
                  size: 32, color: progressMuted),
              const SizedBox(height: 16),
              Text(fitnessText(context, 'Your progress starts here'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                  fitnessText(
                      context, 'Log sets to see how your exercises improve.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, height: 1.6, color: progressMuted)),
            ]))
      else
        ProgressTrainingHero(
            summary: data.summary,
            weeks: data.weeks,
            rangeLabel: _rangeLabel,
            onOpen: () => _activity(data)),
      if (data.exercises.isNotEmpty) ...[
        ProgressHeading('Exercise progress',
            action: 'All exercises',
            onTap: _exercises,
            stacked: _expandedHeader(context)),
        ProgressExerciseTrends(
            exercises: data.exercises,
            pins: _pins,
            onOpen: (exercise) => _open(exercise['name'] as String,
                '/exercises/${exercise['id']}', 'exercise')),
      ],
      ProgressBeyondTraining(
          data: data,
          onBody: () => _trend('body', data),
          onNutrition: () => _trend('nutrition', data),
          onRecovery: () => _trend('recovery', data)),
      Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                  key: const ValueKey('progress-all-trends'),
                  onPressed: () => _changeSection(ProgressSection.trends),
                  icon: const Icon(CupertinoIcons.chart_bar, size: 17),
                  label: Text(fitnessText(context, 'All trends'))))),
    ];
    // Blocks fade in one after another on first appearance only.
    return [
      for (var i = 0; i < blocks.length; i++)
        MotionEntrance(order: i, child: blocks[i]),
    ];
  }

  Future<void> _refresh(ProgressSection section) async {
    if (section == ProgressSection.history &&
        _historyKey.currentState != null) {
      await _historyKey.currentState!.refresh();
    } else {
      await _load(refresh: true);
    }
  }

  Widget _scroll(ProgressSection section) => RefreshIndicator(
      color: progressSilver,
      onRefresh: () => _refresh(section),
      child: CustomScrollView(
          key: PageStorageKey('progress-scroll-${section.name}'),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 4, 18,
                    LiquidSilverBottomBar.scrollBottomInset(context)),
                sliver: SliverList.list(children: [
                  if (_failed && section != ProgressSection.history)
                    Row(children: [
                      Expanded(
                          child: Text(
                              fitnessText(context,
                                  'Could not refresh. Pull down to retry.'),
                              style: const TextStyle(
                                  color: progressMuted, fontSize: 12))),
                      TextButton(
                          onPressed: () => _load(refresh: true),
                          child: Text(fitnessText(context, 'Retry'))),
                    ]),
                  if (section == ProgressSection.history)
                    ProgressHistoryFeed(
                        key: _historyKey,
                        period: _period,
                        query: _filterQuery,
                        initialSessions: _data?.sessions ?? [],
                        repository: _repo,
                        onSession: _session)
                  else if (_data != null)
                    ...section == ProgressSection.summary
                        ? _summary(_data!)
                        : [
                            ProgressTrendsList(
                                data: _data!,
                                onOpen: (kind) => _trend(kind, _data!))
                          ]
                  else if (_loading)
                    const ProgressSkeleton(),
                ]))
          ]));
  bool _expandedHeader(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ||
      MediaQuery.textScalerOf(context).scale(14) > 18;

  Widget _dateFilter(BuildContext context, {bool expanded = false}) =>
      ProgressDateFilter(
          period: _period,
          custom: _custom,
          compact: true,
          controlWidth: expanded ? MediaQuery.sizeOf(context).width - 36 : null,
          onChanged: (value, dates) {
            _period = value;
            _custom = dates;
            _load(clear: true);
          });

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          body: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Text(fitnessText(context, 'Progress'),
                                key: const ValueKey('progress-title'),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.9))),
                        if (!_expandedHeader(context)) ...[
                          const SizedBox(width: 12),
                          SizedBox(width: 128, child: _dateFilter(context)),
                        ],
                      ]),
                      if (_expandedHeader(context)) ...[
                        const SizedBox(height: 10),
                        _dateFilter(context, expanded: true),
                      ],
                      const SizedBox(height: 16),
                      ProgressSectionControl(
                          selected: _section, onChanged: _changeSection),
                    ])),
                SizedBox(
                    height: 2,
                    child: _loading && _data != null
                        ? const LinearProgressIndicator(
                            minHeight: 2,
                            color: progressBlue,
                            backgroundColor: Colors.transparent)
                        : null),
                Expanded(
                    child: IgnorePointer(
                        ignoring: _changingRange,
                        child: AnimatedOpacity(
                            opacity: _changingRange ? .45 : 1,
                            duration: DSMotion.duration(context, DSMotion.fast),
                            child: AnimatedTabStack(
                                index: _section.index,
                                children: [
                                  for (final section in ProgressSection.values)
                                    TickerMode(
                                        enabled: section == _section,
                                        child: _visited.contains(section)
                                            ? _scroll(section)
                                            : const SizedBox.shrink()),
                                ])))),
              ]))));
}
