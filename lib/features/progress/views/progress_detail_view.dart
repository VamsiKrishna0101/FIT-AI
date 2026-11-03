import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../../body_scan/views/body_entry_view.dart';
import '../../body_scan/views/body_record_view.dart';
import '../../body_scan/models/body_map_models.dart';
import '../../body_scan/views/widgets/body_calendar.dart';
import '../components/body_progress_content.dart';
import '../components/exercise_progress_content.dart';
import '../components/progress_exercise_header.dart';
import '../components/muscle_progress_content.dart';
import '../components/progress_date_filter.dart';
import '../components/progress_activity.dart';
import '../components/progress_chart.dart';
import '../components/progress_surface.dart';
import '../components/progress_workout_history.dart';
import '../components/wellness_progress_content.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';

class ProgressDetailView extends StatefulWidget {
  final String title;
  final String path;
  final String period;
  final String kind;
  final ProgressJson? initial;
  final Map<String, dynamic> query;
  final ProgressRepository? repository;
  const ProgressDetailView(
      {super.key,
      required this.title,
      required this.path,
      required this.period,
      required this.kind,
      this.repository,
      this.initial,
      this.query = const {}});
  @override
  State<ProgressDetailView> createState() => _ProgressDetailViewState();
}

class _ProgressDetailViewState extends State<ProgressDetailView> {
  ProgressRepository get _repo =>
      widget.repository ?? ProgressRepository.shared;
  ProgressJson? _data;
  late String _period;
  DateTimeRange? _custom;
  String? _selectedDates;
  BodyDateSelection? _exerciseSelection;
  Map<String, dynamic> get _query => _exerciseSelection != null
      ? progressExerciseQuery(_exerciseSelection!, widget.query)
      : {
          ...(Map<String, dynamic>.from(widget.query)
            ..remove('start')
            ..remove('end')
            ..remove('dates')),
          if (_selectedDates != null) 'dates': _selectedDates,
          if (_custom != null)
            'start': _custom!.start.toIso8601String().substring(0, 10),
          if (_custom != null)
            'end': _custom!.end.toIso8601String().substring(0, 10),
          if (_custom != null)
            'date': _custom!.end.toIso8601String().substring(0, 10),
        };
  bool _loading = true, _failed = false, _more = false;
  bool _moreFailed = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _period = widget.period;
    _selectedDates = widget.query['dates'] as String?;
    final start = DateTime.tryParse(widget.query['start']?.toString() ?? '');
    final end = DateTime.tryParse(widget.query['end']?.toString() ?? '');
    if (start != null && end != null) {
      _custom = DateTimeRange(start: start, end: end);
    }
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _languageChanged() {
    setState(() => _data = null);
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  Future<void> _load({bool refresh = false, bool more = false}) async {
    if (more && (_loading || _more || _data?['nextCursor'] == null)) return;
    final request = ++_request;
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
      _moreFailed = false;
    });
    try {
      final result = await _repo.load(widget.path, _period,
          refresh: refresh,
          query: {..._query, if (more) 'cursor': _data!['nextCursor']});
      if (!mounted || request != _request) return;
      if (more) {
        final key = widget.kind == 'exercise' ? 'history' : 'items';
        final seen = <Object>{};
        result[key] = [
          ...progressRows(_data![key]),
          ...progressRows(result[key])
        ].where((row) {
          final id = row['id'] ?? row['date'];
          return id == null || seen.add(id);
        }).toList();
      }
      setState(() => _data = result);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => more && widget.kind == 'exercise'
            ? _moreFailed = true
            : _failed = true);
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _more = false;
        });
      }
    }
  }

  void _exercise(ProgressJson row) => Navigator.of(context).push(AppPageRoute(
      builder: (_) => ProgressDetailView(
          repository: _repo,
          title: row['name'] as String,
          path: '/exercises/${row['id']}',
          period: _period,
          kind: 'exercise',
          query: _query)));

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(AppPageRoute(
        builder: (_) => const FitnessTheme(child: BodyEntryView())));
    if (saved == true) {
      await _repo.invalidate();
      if (mounted) await _load(refresh: true);
    }
  }

  Future<void> _record(String id) async {
    try {
      final record = await BodyAssessmentRepository.shared.entry(id);
      if (!mounted) return;
      await Navigator.of(context).push(AppPageRoute(
          builder: (_) => FitnessTheme(
              child: BodyRecordView(entry: record, onCompare: () {}))));
      await _repo.invalidate();
      if (mounted) await _load(refresh: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(
                context, 'Could not load this record. Please retry.'))));
      }
    }
  }

  String? get _rangeLabel {
    final range = _data?['range'] as Map?;
    if (range == null) return null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${progressDate(range['start'] as String?, locale)} – ${progressDate(range['end'] as String?, locale)}';
  }

  Widget _content() {
    final data = _data!;
    switch (widget.kind) {
      case 'training':
        return Column(children: [
          ProgressTrainingSummary(
              summary: Map<String, dynamic>.from(data['summary'] as Map? ?? {}),
              rangeLabel: _rangeLabel),
          const SizedBox(height: 14),
          ProgressActivity(
              weeks: progressRows(data['weeks']),
              activity: progressRows(data['activity']),
              endDate: (data['range'] as Map?)?['end'] as String?),
        ]);
      case 'exercise':
        return ExerciseProgressContent(
            data: data,
            loadingMore: _more,
            moreFailed: _moreFailed,
            onMore: data['nextCursor'] == null
                ? null
                : () => _load(more: true, refresh: _moreFailed));
      case 'muscles':
        return MuscleDistributionContent(
            muscles: progressRows(data['muscles']),
            onMuscle: (row) => Navigator.of(context).push(AppPageRoute(
                builder: (_) => ProgressDetailView(
                    repository: _repo,
                    title: row['label'] as String,
                    path: '/muscles/${row['id']}',
                    period: _period,
                    kind: 'muscle',
                    query: _query))));
      case 'muscle':
        return MuscleProgressContent(data: data, onExercise: _exercise);
      case 'body':
        return BodyProgressContent(data: data, onAdd: _add, onRecord: _record);
      case 'recovery':
      case 'sleep':
        return ProgressSurface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fitnessText(context, 'Sleep'),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ProgressChart(
              points: ProgressPoint.parse(progressRows(data['sleep']), 'sleep'),
              unit: 'h',
              bars: true,
              daily: true,
              average: true,
              color: progressMuscle,
              showReadings: true),
        ]));
      case 'nutrition':
        return WellnessProgressContent(data: data, nutrition: true);
      case 'sessions':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressWorkoutHistory(
              sessions: progressRows(data['items']),
              onSession: (session) => Navigator.of(context).push(AppPageRoute(
                  builder: (_) => ProgressWorkoutRecap(
                      session: session, onExercise: _exercise)))),
          if (data['nextCursor'] != null)
            Center(
                child: TextButton(
                    onPressed: _more ? null : () => _load(more: true),
                    child: Text(fitnessText(context, 'Load more')))),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  bool get _expandedFilter =>
      MediaQuery.sizeOf(context).width < 360 ||
      MediaQuery.textScalerOf(context).scale(14) > 18;

  Widget _dateFilter({bool expanded = false}) => ProgressDateFilter(
      period: _period,
      custom: _custom,
      compact: true,
      controlWidth: expanded ? MediaQuery.sizeOf(context).width - 36 : 118,
      onChanged: (period, dates) {
        setState(() {
          _period = period;
          _custom = dates;
          _selectedDates = null;
          _data = null;
        });
        _load(refresh: true);
      });
  bool get _isExercise => widget.kind == 'exercise';

  String get _title =>
      progressTitle((_data?['exercise'] as Map?)?['name'] as String? ??
          (_data?['muscle'] as Map?)?['label'] as String? ??
          widget.title);

  BodyDateSelection get _currentExerciseSelection =>
      _exerciseSelection ??
      progressExerciseSelection(_period, {
        ...?_data?['range'] as Map?,
        ..._query,
      });

  Future<void> _exerciseCalendar() async {
    final selection =
        await showProgressExerciseCalendar(context, _currentExerciseSelection);
    if (selection == null || !mounted) return;
    setState(() {
      _exerciseSelection = selection;
      _period = selection.mode == BodyDateMode.all ? 'all' : 'custom';
      _data = null;
    });
    await _load(refresh: true);
  }

  Widget _scrollContent() => RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      color: progressSilver,
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, _isExercise ? 2 : 10, 18, 40),
          children: [
            if (!_isExercise && _expandedFilter) ...[
              _dateFilter(expanded: true),
              const SizedBox(height: 12),
            ],
            if (!_isExercise && _rangeLabel != null) ...[
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(_rangeLabel!,
                      style:
                          const TextStyle(color: progressMuted, fontSize: 12))),
              const SizedBox(height: 14),
            ],
            if (_loading && _data == null)
              const ProgressSkeleton(heights: [260, 120]),
            if (_failed)
              Row(children: [
                Expanded(
                    child: Text(
                        fitnessText(
                            context, 'Could not refresh. Pull down to retry.'),
                        style: const TextStyle(
                            color: progressMuted, fontSize: 12))),
                TextButton(
                    onPressed: () => _load(refresh: true),
                    child: Text(fitnessText(context, 'Retry')))
              ]),
            if (_data != null) ...[
              if (widget.query['dataset'] == 'preview')
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(fitnessText(context, 'Preview data'),
                        style: const TextStyle(
                            color: progressMuted, fontSize: 12))),
              _content(),
            ],
            if (_more && !_isExercise)
              const Padding(
                  padding: EdgeInsets.all(15),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: progressSilver, strokeWidth: 2))),
          ]));

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: _isExercise
              ? null
              : AppBar(
                  backgroundColor: DSColors.bg,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: DSColors.silver),
                  actions: [
                    if (!_expandedFilter) ...[
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _dateFilter()),
                      const SizedBox(width: 16),
                    ]
                  ],
                  title: Text(fitnessText(context, _title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600))),
          body: _isExercise
              ? SafeArea(
                  bottom: false,
                  child: Column(children: [
                    ProgressExerciseHeader(
                        title: _title,
                        rangeLabel: bodySelectionLabel(
                            context, _currentExerciseSelection),
                        onCalendar: _exerciseCalendar),
                    Expanded(child: _scrollContent()),
                  ]))
              : _scrollContent()));
}
