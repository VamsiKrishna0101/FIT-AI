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
import '../components/body_progress_content.dart';
import '../components/exercise_progress_content.dart';
import '../components/exercise_overview_control.dart';
import '../components/muscle_progress_content.dart';
import '../components/progress_date_filter.dart';
import '../components/progress_activity.dart';
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
  Map<String, dynamic> get _query => {
        ...(Map<String, dynamic>.from(widget.query)
          ..remove('start')
          ..remove('end')),
        if (_custom != null)
          'start': _custom!.start.toIso8601String().substring(0, 10),
        if (_custom != null)
          'end': _custom!.end.toIso8601String().substring(0, 10),
      };
  bool _loading = true, _failed = false, _more = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _period = widget.period;
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
    final request = ++_request;
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
    });
    try {
      final result = await _repo.load(widget.path, _period,
          refresh: refresh,
          query: {..._query, if (more) 'cursor': _data!['nextCursor']});
      if (!mounted || request != _request) return;
      if (more) {
        final key = widget.kind == 'exercise' ? 'history' : 'items';
        result[key] = [
          ...progressRows(_data![key]),
          ...progressRows(result[key])
        ];
      }
      setState(() => _data = result);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
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
            onMore: data['nextCursor'] == null || _more
                ? null
                : () => _load(more: true));
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
      case 'nutrition':
        return WellnessProgressContent(
            data: data, nutrition: widget.kind == 'nutrition');
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
          _data = null;
        });
        _load(refresh: true);
      });
  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: AppBar(
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (!_expandedFilter) ...[
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(width: 118, child: _dateFilter())),
                  const SizedBox(width: 18),
                ]
              ],
              title: Text(
                  fitnessText(
                      context,
                      progressTitle(
                          (_data?['exercise'] as Map?)?['name'] as String? ??
                              (_data?['muscle'] as Map?)?['label'] as String? ??
                              widget.title)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600))),
          body: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              color: progressSilver,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                  children: [
                    if (_expandedFilter) ...[
                      _dateFilter(expanded: true),
                      const SizedBox(height: 12),
                    ],
                    if (_rangeLabel != null) ...[
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(_rangeLabel!,
                              style: const TextStyle(
                                  color: progressMuted, fontSize: 12))),
                      const SizedBox(height: 14),
                    ],
                    if (_loading && _data == null)
                      const Padding(
                          padding: EdgeInsets.all(50),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: progressSilver, strokeWidth: 2))),
                    if (_failed)
                      Row(children: [
                        Expanded(
                            child: Text(
                                fitnessText(context,
                                    'Could not refresh. Pull down to retry.'),
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
                      if (widget.kind == 'exercise' &&
                          widget.query['dataset'] != 'preview')
                        ExerciseOverviewControl(
                            key: ValueKey(widget.path),
                            exerciseId: (_data?['exercise'] as Map?)?['id']
                                    as String? ??
                                widget.path.split('/').last),
                    ],
                    if (_more)
                      const Padding(
                          padding: EdgeInsets.all(15),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: progressSilver, strokeWidth: 2))),
                  ]))));
}
