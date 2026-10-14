import '../../../core/theme/ds_colors.dart';
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
import '../components/progress_activity.dart';
import '../components/progress_date_filter.dart';
import '../components/progress_surface.dart';
import '../components/progress_trend_tiles.dart';
import '../components/wellness_progress_content.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_detail_view.dart';
import 'progress_exercises_view.dart';

class ProgressOverviewView extends StatefulWidget {
  final bool isActive;
  final ProgressOverview? initial;
  const ProgressOverviewView({super.key, this.isActive = true, this.initial});
  @override
  State<ProgressOverviewView> createState() => _ProgressOverviewViewState();
}

class _ProgressOverviewViewState extends State<ProgressOverviewView> {
  ProgressOverview? _data;
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
      await ProgressRepository.shared.invalidate();
      if (mounted && widget.isActive) unawaited(_load(refresh: true));
    });
    _updates = ProgressRepository.shared.updates.stream.listen((key) {
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
    final json = await ProgressRepository.shared
        .cached('', _period, query: _filterQuery);
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
      if (clear) _data = null;
    });
    try {
      final pins = await ProgressRepository.shared.pins();
      if (!refresh) await _acceptCache();
      final json = await ProgressRepository.shared
          .load('', period, refresh: refresh, query: _filterQuery);
      if (mounted && request == _request) {
        setState(() {
          _data = ProgressOverview(json);
          _pins = pins;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(String title, String path, String kind,
      {ProgressJson? initial}) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProgressDetailView(
            title: title,
            path: path,
            kind: kind,
            period: _period,
            query: _filterQuery,
            initial: initial)));
    if (mounted && widget.initial == null) unawaited(_load(refresh: true));
  }

  Future<void> _exercises() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProgressExercisesView(
            period: _period,
            muscles: _data?.muscles ?? [],
            query: _filterQuery)));
    final pins = await ProgressRepository.shared.pins();
    if (mounted) setState(() => _pins = pins);
  }

  List<Widget> _sections(ProgressOverview data) {
    final pinned = _pins.isEmpty
        ? data.exercises.take(3).toList()
        : data.exercises
            .where((row) => _pins.contains(row['id']))
            .take(3)
            .toList();
    final muscles = [...data.muscles]..sort(
        (a, b) => (b['directSets'] as num).compareTo(a['directSets'] as num));
    final weight = progressRows(data.body['metrics'])
        .where((row) => row['id'] == 'weightKg')
        .firstOrNull;
    final weightSeries = progressRows(weight?['series']).firstOrNull;
    final weightPoints =
        ProgressPoint.parse(progressRows(weightSeries?['points']), 'value');
    final recoveryPoints = ProgressPoint.parse(
        progressRows(data.wellness['recovery']), 'recovery');
    final locale = Localizations.localeOf(context).toLanguageTag();
    return [
      ProgressActivity(
          summary: data.summary,
          weeks: data.weeks,
          activity: data.activity,
          endDate: (data.json['range'] as Map?)?['end'] as String?,
          onHistory: () => _open('Workout history', '/sessions', 'sessions')),
      ProgressHeading('Exercise progress', onTap: _exercises),
      if (pinned.isEmpty)
        const ProgressSurface(
            child: ProgressEmpty('Log sets to see how your exercises improve.'))
      else
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < pinned.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(
                    width: 218,
                    child: ProgressExercisePreview(
                        exercise: pinned[i],
                        onTap: () => _open(pinned[i]['name'] as String,
                            '/exercises/${pinned[i]['id']}', 'exercise'))),
              ],
            ])),
      ProgressHeading('Muscle distribution',
          onTap: () => _open('Muscle distribution', '', 'muscles',
              initial: {'muscles': data.muscles})),
      ProgressSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (muscles.every((row) => row['directSets'] == 0))
          const ProgressEmpty('Log sets to build your muscle training history.')
        else
          ProgressMuscleBars(
              muscles: muscles.take(5).toList(),
              onTap: (row) => _open(
                  row['label'] as String, '/muscles/${row['id']}', 'muscle')),
        const SizedBox(height: 8),
        Text(
            fitnessText(
                context, 'Direct sets. Assisting exposure is separate.'),
            style: const TextStyle(color: progressMuted, fontSize: 10)),
      ])),
      const ProgressHeading('Body & recovery'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: ProgressMetricPreview(
                title: 'Weight',
                unit: 'kg',
                points: weightPoints,
                onTap: () => _open('Body changes', '/body', 'body',
                    initial: data.body))),
        const SizedBox(width: 12),
        Expanded(
            child: ProgressMetricPreview(
                title: 'Recovery',
                unit: '/100',
                points: recoveryPoints,
                color: progressViolet,
                average: true,
                caption: 'Recorded-day average',
                onTap: () => _open('Recovery', '/wellness', 'recovery',
                    initial: data.wellness))),
      ]),
      ProgressHeading('Nutrition',
          onTap: () => _open('Nutrition', '/wellness', 'nutrition',
              initial: data.wellness),
          action: 'Explore'),
      WellnessProgressContent(
          data: data.wellness, nutrition: true, compact: true),
      ProgressHeading('Workout history',
          onTap: () => _open('Workout history', '/sessions', 'sessions')),
      ProgressSurface(
          child: data.sessions.isEmpty
              ? const ProgressEmpty('No workouts in this period')
              : Column(
                  children: data.sessions
                      .map((row) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () =>
                              _open('Workout history', '/sessions', 'sessions'),
                          title: Text(fitnessText(context, row['name'] as String? ?? 'Workout'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text('${progressDate(row['date'] as String?, locale)} · ${row['sets']} ${fitnessText(context, 'sets')}',
                              style: const TextStyle(
                                  color: progressMuted, fontSize: 12)),
                          trailing: Icon(
                              row['status'] == 'COMPLETED'
                                  ? CupertinoIcons.checkmark_circle
                                  : CupertinoIcons.clock,
                              color: progressMuted,
                              size: 18)))
                      .toList())),
    ];
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          body: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(fitnessText(context, 'Progress'),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1))),
                          ]),
                          const SizedBox(height: 12),
                          ProgressDateFilter(
                              period: _period,
                              custom: _custom,
                              rangeLabel: _rangeLabel,
                              onChanged: (value, dates) {
                                _period = value;
                                _custom = dates;
                                _load(clear: true);
                              }),
                        ])),
                Expanded(
                    child: RefreshIndicator(
                        color: progressSilver,
                        onRefresh: () => _load(refresh: true),
                        child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.fromLTRB(
                                18,
                                4,
                                18,
                                LiquidSilverBottomBar.scrollBottomInset(
                                    context)),
                            children: [
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
                                      onPressed: () => _load(refresh: true),
                                      child:
                                          Text(fitnessText(context, 'Retry')))
                                ]),
                              if (_loading && _data == null)
                                const ProgressSurface(
                                    child: SizedBox(
                                        height: 160,
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: progressSilver,
                                                strokeWidth: 2)))),
                              if (_data != null) ..._sections(_data!),
                            ]))),
              ]))));
}
