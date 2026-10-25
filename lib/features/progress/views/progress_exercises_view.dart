import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/progress_surface.dart';
import '../components/exercise_progress_list_row.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_detail_view.dart';

class ProgressExercisesView extends StatefulWidget {
  final String period;
  final List<ProgressJson> muscles;
  final Map<String, dynamic> query;
  final ProgressRepository? repository;
  const ProgressExercisesView(
      {super.key,
      required this.period,
      required this.muscles,
      this.query = const {},
      this.repository});
  @override
  State<ProgressExercisesView> createState() => _ProgressExercisesViewState();
}

class _ProgressExercisesViewState extends State<ProgressExercisesView> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<ProgressJson> _items = [];
  late final _repo = widget.repository ?? ProgressRepository.shared;
  Map? _range;
  String? _muscle, _cursor;
  bool _loading = true, _failed = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _languageChanged() {
    _debounce?.cancel();
    unawaited(_load());
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      if (!more) {
        _items = [];
        _cursor = null;
      }
    });
    try {
      final data = await _repo.load('/exercises', widget.period, query: {
        ...widget.query,
        'search': _search.text.trim(),
        if (_muscle != null) 'muscle': _muscle,
        if (more) 'cursor': _cursor,
      });
      if (mounted && request == _request) {
        setState(() {
          _items = [
            ...(more ? _items : <ProgressJson>[]),
            ...progressRows(data['items'])
          ];
          _cursor = data['nextCursor'] as String?;
          _range = data['range'] as Map?;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedMuscle =
        widget.muscles.where((row) => row['id'] == _muscle).firstOrNull;
    final muscleLabel = selectedMuscle == null
        ? fitnessText(context, 'All muscles')
        : progressMuscleLabel(context, selectedMuscle);
    const periods = {
      '4w': '4 weeks',
      '3m': '3 months',
      '1y': '1 year',
      'all': 'All time',
      'custom': 'Custom range'
    };
    final rangeStart = _range?['start'] as String?;
    final rangeEnd = _range?['end'] as String?;
    final crossesYears = DateTime.tryParse(rangeStart ?? '')?.year !=
        DateTime.tryParse(rangeEnd ?? '')?.year;
    final rangeLabel = _range == null
        ? fitnessText(context, periods[widget.period] ?? 'Selected period')
        : '${progressDate(rangeStart, locale, year: crossesYears)} – ${progressDate(rangeEnd, locale, year: true)}';
    return FitnessTheme(
        child: Scaffold(
      backgroundColor: DSColors.bg,
      appBar: AppBar(
          backgroundColor: DSColors.bg,
          surfaceTintColor: Colors.transparent,
          title: Text(fitnessText(context, 'Exercise progress'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: Column(children: [
        if (widget.query['dataset'] == 'preview')
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(fitnessText(context, 'Preview data'),
                  style: const TextStyle(color: progressMuted, fontSize: 12))),
        Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: TextField(
              controller: _search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                  filled: true,
                  fillColor: progressCard,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  hintText: fitnessText(context, 'Search your exercises'),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 18)),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce =
                    Timer(const Duration(milliseconds: 300), () => _load());
              },
            )),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Expanded(
                  child: Text(rangeLabel,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 11, color: progressMuted, height: 1.4))),
              const SizedBox(width: 12),
              Flexible(
                  child: PopupMenuButton<String>(
                tooltip: fitnessText(context, 'Filter by muscle'),
                color: progressCard,
                initialValue: _muscle ?? 'all',
                onSelected: (value) {
                  _muscle = value == 'all' ? null : value;
                  _load();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'all',
                      child: Text(fitnessText(context, 'All muscles'))),
                  ...widget.muscles.map((row) => PopupMenuItem(
                      value: row['id'] as String,
                      child: Text(progressMuscleLabel(context, row)))),
                ],
                child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                          child: Text(muscleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: progressSilver))),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.chevron_down,
                          size: 11, color: progressMuted),
                    ])),
              )),
            ])),
        Expanded(
            child: RefreshIndicator(
                color: progressSilver,
                onRefresh: () => _load(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                  itemCount: _items.length + 1,
                  separatorBuilder: (_, index) => index < _items.length - 1
                      ? const Divider(height: 1, color: DSColors.border)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      if (_failed) {
                        return TextButton(
                            onPressed: () => _load(
                                more: _items.isNotEmpty && _cursor != null),
                            child: Text(fitnessText(context, 'Retry')));
                      }
                      if (_loading) {
                        return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: progressSilver, strokeWidth: 2)));
                      }
                      if (_items.isEmpty) {
                        return const ProgressEmpty('No logged exercises found');
                      }
                      if (_cursor != null) {
                        return TextButton(
                            onPressed: () => _load(more: true),
                            child: Text(fitnessText(context, 'Load more')));
                      }
                      return const SizedBox.shrink();
                    }
                    final row = _items[index];
                    return ExerciseProgressListRow(
                        exercise: row,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ProgressDetailView(
                                    title: row['name'] as String,
                                    path: '/exercises/${row['id']}',
                                    period: widget.period,
                                    kind: 'exercise',
                                    query: widget.query))));
                  },
                ))),
      ]),
    ));
  }
}
