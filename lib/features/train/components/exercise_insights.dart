import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/ds_colors.dart';
import '../../progress/components/exercise_progress_content.dart';
import '../../progress/components/progress_surface.dart';
import '../../progress/models/progress_models.dart';
import '../../progress/repositories/progress_repository.dart';

typedef ExerciseProgressLoader = Future<ProgressJson> Function(
    {String? cursor, bool refresh});

class ExerciseInsights extends StatefulWidget {
  const ExerciseInsights({super.key, required this.exerciseId, this.loader});
  final String exerciseId;
  final ExerciseProgressLoader? loader;
  @override
  State<ExerciseInsights> createState() => _ExerciseInsightsState();
}

class _ExerciseInsightsState extends State<ExerciseInsights> {
  ProgressJson? _data;
  bool _loading = true, _more = false, _failed = false, _moreFailed = false;
  int _request = 0;
  StreamSubscription<String>? _updates;
  String get _path => '/exercises/${Uri.encodeComponent(widget.exerciseId)}';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    LanguageManager.shared.addListener(_languageChanged);
    _updates = ProgressRepository.shared.updates.stream.listen((key) {
      if (key == 'invalidated') {
        unawaited(_load(refresh: true));
      } else if (!_loading &&
          !_more &&
          key.contains(_path) &&
          widget.loader == null) {
        unawaited(_readCache());
      }
    });
  }

  @override
  void didUpdateWidget(ExerciseInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId ||
        oldWidget.loader != widget.loader) {
      _data = null;
      unawaited(_load());
    }
  }

  void _languageChanged() {
    _data = null;
    unawaited(_load());
  }

  Future<void> _readCache() async {
    final request = _request;
    final data = await ProgressRepository.shared
        .cached(_path, 'all', query: const {'limit': 8});
    if (mounted && request == _request && data != null) {
      setState(() => _data = data);
    }
  }

  Future<void> _load({bool refresh = false, bool more = false}) async {
    if (more && (_loading || _more || _data?['nextCursor'] == null)) return;
    final request = ++_request;
    final cursor = more ? _data!['nextCursor'] as String? : null;
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
      _moreFailed = false;
    });
    try {
      final data = widget.loader != null
          ? await widget.loader!(cursor: cursor, refresh: refresh)
          : await ProgressRepository.shared.load(_path, 'all',
              refresh: refresh,
              query: {'limit': 8, if (cursor != null) 'cursor': cursor});
      if (!mounted || request != _request) return;
      setState(() {
        if (more) {
          final history = {
            for (final day in [
              ...progressRows(_data?['history']),
              ...progressRows(data['history'])
            ])
              day['date']: day,
          };
          _data = {...?_data, ...data, 'history': history.values.toList()};
        } else {
          _data = data;
        }
      });
    } on DioException catch (error) {
      if (!mounted || request != _request) return;
      final body = error.response?.data;
      final message = body is Map ? (body['message'] ?? body['error']) : null;
      if (!more &&
          error.response?.statusCode == 404 &&
          message == 'Exercise history not found') {
        setState(() => _data = {'series': [], 'history': [], 'records': {}});
      } else {
        setState(() => more ? _moreFailed = true : _failed = true);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => more ? _moreFailed = true : _failed = true);
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

  @override
  void dispose() {
    _updates?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final hasHistory = progressRows(data?['series']).isNotEmpty ||
        progressRows(data?['history']).isNotEmpty;
    return RefreshIndicator(
      color: DSColors.silver,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        key: PageStorageKey('exercise-${widget.exerciseId}-progress'),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        children: [
          if (_loading && data == null)
            const Padding(
                padding: EdgeInsets.all(48),
                child: CupertinoActivityIndicator())
          else if (_failed && data == null)
            ProgressSurface(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const ProgressEmpty('Could not load exercise history.'),
                  TextButton(
                      onPressed: () => _load(refresh: true),
                      child: Text(fitnessText(context, 'Retry'))),
                ]))
          else if (data != null) ...[
            if (_loading)
              const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(
                      minHeight: 1, color: DSColors.silver)),
            if (!hasHistory)
              ProgressSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(fitnessText(context, 'Your progress starts here'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500)),
                    const ProgressEmpty(
                        'Log your first set to see your progress.'),
                  ]))
            else
              ExerciseProgressContent(
                  data: data,
                  loadingMore: _more,
                  moreFailed: _moreFailed,
                  onMore: !_more && data['nextCursor'] != null
                      ? () => _load(more: true, refresh: _moreFailed)
                      : null),
            if (_failed)
              TextButton(
                  onPressed: () => _load(refresh: true),
                  child: Text(fitnessText(
                      context, 'Could not refresh. Tap to retry.'))),
          ],
        ],
      ),
    );
  }
}
