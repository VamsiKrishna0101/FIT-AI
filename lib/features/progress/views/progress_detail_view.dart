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
import '../components/progress_activity.dart';
import '../components/progress_chart.dart';
import '../components/progress_surface.dart';
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
  const ProgressDetailView(
      {super.key,
      required this.title,
      required this.path,
      required this.period,
      required this.kind,
      this.initial,
      this.query = const {}});
  @override
  State<ProgressDetailView> createState() => _ProgressDetailViewState();
}

class _ProgressDetailViewState extends State<ProgressDetailView> {
  ProgressJson? _data;
  bool _loading = true, _failed = false, _more = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _data = widget.initial;
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
      final result = await ProgressRepository.shared.load(
          widget.path, widget.period,
          refresh: refresh,
          query: {...widget.query, if (more) 'cursor': _data!['nextCursor']});
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

  void _exercise(ProgressJson row) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProgressDetailView(
              title: row['name'] as String,
              path: '/exercises/${row['id']}',
              period: widget.period,
              kind: 'exercise',
              query: widget.query)));

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => const FitnessTheme(child: BodyEntryView())));
    if (saved == true) {
      await ProgressRepository.shared.invalidate();
      if (mounted) await _load(refresh: true);
    }
  }

  Future<void> _record(String id) async {
    try {
      final record = await BodyAssessmentRepository.shared.entry(id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FitnessTheme(
              child: BodyRecordView(entry: record, onCompare: () {}))));
      await ProgressRepository.shared.invalidate();
      if (mounted) await _load(refresh: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(
                context, 'Could not load this record. Please retry.'))));
      }
    }
  }

  Widget _content() {
    final data = _data!;
    switch (widget.kind) {
      case 'exercise':
        return ExerciseProgressContent(
            data: data,
            onMore: data['nextCursor'] == null || _more
                ? null
                : () => _load(more: true));
      case 'muscles':
        return ProgressSurface(
            child: ProgressMuscleBars(
                muscles: progressRows(data['muscles']),
                onTap: (row) => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProgressDetailView(
                        title: row['label'] as String,
                        path: '/muscles/${row['id']}',
                        period: widget.period,
                        kind: 'muscle',
                        query: widget.query)))));
      case 'muscle':
        final muscle = data['muscle'] as Map;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(fitnessText(context, 'Direct sets'),
                    style: const TextStyle(color: progressMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text('${muscle['directSets']}',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                    '${fitnessText(context, 'Assisting sets')} · ${muscle['assistingSets']}',
                    style: const TextStyle(color: progressMuted, fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                    '${fitnessText(context, 'Training days')} · ${muscle['trainingDays']}',
                    style: const TextStyle(color: progressMuted, fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                    '${fitnessText(context, 'Last trained')} · ${progressDate(muscle['lastTrained'] as String?, Localizations.localeOf(context).toLanguageTag())}',
                    style: const TextStyle(color: progressMuted, fontSize: 12)),
                const SizedBox(height: 18),
                ProgressChart(
                    points: ProgressPoint.parse(
                        progressRows(data['weeks']), 'sets'),
                    bars: true,
                    height: 125),
              ])),
          const SizedBox(height: 12),
          Text(
              fitnessText(context,
                  'Logged exposure describes training, not measured muscle growth.'),
              style: const TextStyle(
                  color: progressMuted, fontSize: 11, height: 1.4)),
          const ProgressHeading('Exercises'),
          ProgressSurface(
              child: Column(
                  children: progressRows(data['exercises'])
                      .map((row) => ProgressExerciseRow(
                          exercise: row, onTap: () => _exercise(row)))
                      .toList())),
        ]);
      case 'body':
        return BodyProgressContent(data: data, onAdd: _add, onRecord: _record);
      case 'recovery':
      case 'nutrition':
        return WellnessProgressContent(
            data: data, nutrition: widget.kind == 'nutrition');
      case 'sessions':
        final sessions = progressRows(data['items']);
        return Column(children: [
          if (sessions.isEmpty)
            const ProgressEmpty('No workouts in this period'),
          ...sessions.map((session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProgressSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: _SessionTile(session: session)))),
          if (data['nextCursor'] != null)
            TextButton(
                onPressed: _more ? null : () => _load(more: true),
                child: Text(fitnessText(context, 'Load more'))),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: const Color(0xFF111111),
          appBar: AppBar(
              backgroundColor: const Color(0xFF111111),
              surfaceTintColor: Colors.transparent,
              title: Text(
                  fitnessText(
                      context,
                      (_data?['exercise'] as Map?)?['name'] as String? ??
                          (_data?['muscle'] as Map?)?['label'] as String? ??
                          widget.title),
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
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                              fitnessText(
                                  context,
                                  const {
                                    '4w': '4 weeks',
                                    '3m': '3 months',
                                    '1y': '1 year',
                                    'all': 'All time',
                                    'custom': 'Custom range'
                                  }[widget.period]!),
                              style: const TextStyle(
                                  color: progressMuted, fontSize: 12))),
                      _content(),
                    ],
                    if (_more)
                      const Padding(
                          padding: EdgeInsets.all(15),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: progressSilver, strokeWidth: 2))),
                  ]))));
}

class _SessionTile extends StatelessWidget {
  final ProgressJson session;
  const _SessionTile({required this.session});
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final seconds = progressNumber(session['durationSeconds']);
    return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
            fitnessText(context, session['name'] as String? ?? 'Workout'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
                '${progressDate(session['date'] as String?, locale)} · ${session['sets']} ${fitnessText(context, 'sets')}${seconds != null && seconds > 0 ? ' · ${(seconds / 60).round()} ${fitnessText(context, 'min')}' : ''} · ${fitnessText(context, session['status'] == 'COMPLETED' ? 'Completed' : 'In progress')}',
                style: const TextStyle(color: progressMuted, fontSize: 11))),
        children: progressRows(session['exercises'])
            .map((exercise) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Text(exercise['name'] as String,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600))),
                  for (final set in progressRows(exercise['entries']))
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          SizedBox(
                              width: 32,
                              child: Text('${set['setNumber']}',
                                  style: const TextStyle(
                                      color: progressMuted, fontSize: 11))),
                          Expanded(
                              child: Text(
                                  '${set['weight'] != null && (set['weight'] as num) > 0 ? '${progressValue(context, progressNumber(set['weight']), unit: 'kg')} × ' : ''}${set['reps']} ${fitnessText(context, 'reps')}',
                                  style: const TextStyle(fontSize: 12))),
                          if (set['rpe'] != null)
                            Text(
                                'RPE ${progressValue(context, progressNumber(set['rpe']))}',
                                style: const TextStyle(
                                    color: progressMuted, fontSize: 11)),
                        ])),
                ]))
            .toList());
  }
}
