import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_surface.dart';
import 'progress_training_heatmap.dart';
import 'progress_workout_history.dart';

class ProgressHistoryFeed extends StatefulWidget {
  final String period;
  final Map<String, dynamic> query;
  final List<ProgressJson> initialSessions;
  final ProgressRepository repository;
  final ValueChanged<ProgressJson> onSession;
  const ProgressHistoryFeed(
      {super.key,
      required this.period,
      required this.query,
      required this.initialSessions,
      required this.repository,
      required this.onSession});
  @override
  State<ProgressHistoryFeed> createState() => ProgressHistoryFeedState();
}

class ProgressHistoryFeedState extends State<ProgressHistoryFeed> {
  List<ProgressJson> _sessions = [];
  String? _cursor;
  bool _loading = true, _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _sessions = widget.initialSessions;
    unawaited(_load());
  }

  String _signature(List<ProgressJson> sessions) => sessions
      .map((row) => '${row['id']}:${row['sets']}:${row['status']}')
      .join('|');

  @override
  void didUpdateWidget(ProgressHistoryFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period ||
        widget.query.toString() != oldWidget.query.toString()) {
      _sessions = [];
      _cursor = null;
      unawaited(_load());
    } else if (_signature(widget.initialSessions) !=
        _signature(oldWidget.initialSessions)) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() => _load(refresh: true);

  Future<void> _load({bool more = false, bool refresh = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await widget.repository.load('/sessions', widget.period,
          refresh: refresh,
          query: {...widget.query, if (more) 'cursor': _cursor});
      if (!mounted || request != _request) return;
      final combined = [
        if (more) ..._sessions,
        ...progressRows(result['items']),
      ];
      final unique = <String, ProgressJson>{};
      for (var i = 0; i < combined.length; i++) {
        final row = combined[i];
        unique[row['id']?.toString() ?? '${row['date']}:$i'] = row;
      }
      setState(() {
        _sessions = unique.values.toList();
        _cursor = result['nextCursor'] as String?;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_failed)
          Row(children: [
            Expanded(
                child: Text(
                    fitnessText(
                        context, 'Could not refresh. Pull down to retry.'),
                    style:
                        const TextStyle(color: progressMuted, fontSize: 12))),
            TextButton(
                onPressed: _loading ? null : refresh,
                child: Text(fitnessText(context, 'Retry'))),
          ]),
        if (_loading && _sessions.isEmpty)
          const ProgressSkeleton(heights: [150, 110, 110, 110])
        else ...[
          if (_sessions.isNotEmpty) ProgressTrainingHeatmap(sessions: _sessions),
          ProgressWorkoutHistory(
              sessions: _sessions, onSession: widget.onSession),
        ],
        if (_cursor != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                  key: const ValueKey('progress-history-more'),
                  onPressed: _loading ? null : () => _load(more: true),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(fitnessText(context, 'Load more')))),
      ]);
}
