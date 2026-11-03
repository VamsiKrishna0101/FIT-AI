import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/models/body_map_models.dart';
import '../../body_scan/views/widgets/body_calendar.dart';
import '../components/exercise_progress_list_row.dart';
import '../components/progress_exercise_header.dart';
import '../components/progress_surface.dart';
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
  final _scroll = ScrollController();
  Timer? _debounce;
  late final _repo = widget.repository ?? ProgressRepository.shared;
  late String _period;
  late BodyDateSelection _selection;
  List<ProgressJson> _items = [];
  String? _muscle, _cursor;
  bool _loading = true, _more = false, _failed = false, _pageFailed = false;
  int _request = 0;
  Map<String, dynamic> get _query => _datesChanged
      ? progressExerciseQuery(_selection, widget.query)
      : widget.query;
  bool _datesChanged = false;

  static const _defaultMuscles = [
    {'id': 'chest', 'label': 'Chest'},
    {'id': 'upper_back', 'label': 'Upper back'},
    {'id': 'lats', 'label': 'Lats'},
    {'id': 'quads', 'label': 'Quads'},
    {'id': 'hamstrings', 'label': 'Hamstrings'},
    {'id': 'shoulders', 'label': 'Shoulders'},
    {'id': 'biceps', 'label': 'Biceps'},
    {'id': 'triceps', 'label': 'Triceps'},
    {'id': 'core', 'label': 'Core'},
  ];

  @override
  void initState() {
    super.initState();
    _period = widget.period;
    _selection = progressExerciseSelection(_period, widget.query);
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _languageChanged() {
    _debounce?.cancel();
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false, bool refresh = false}) async {
    if (more && (_loading || _more || _cursor == null)) return;
    final request = ++_request;
    final cursor = _cursor;
    final query = {
      ..._query,
      'search': _search.text.trim(),
      if (_muscle != null) 'muscle': _muscle,
      if (more) 'cursor': cursor,
    };
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
      _pageFailed = false;
      if (!more) {
        _items = [];
        _cursor = null;
      }
    });
    try {
      final data = await _repo.load('/exercises', _period,
          refresh: refresh, query: query);
      if (!mounted || request != _request) return;
      final seen = <Object>{};
      setState(() {
        _items = [
          if (more) ..._items,
          ...progressRows(data['items']),
        ].where((row) => row['id'] == null || seen.add(row['id']!)).toList();
        _cursor = data['nextCursor'] as String?;
        if (!_datesChanged && _period != 'all' && data['range'] is Map) {
          _selection = progressExerciseSelection(_period, {
            ...widget.query,
            ...Map<String, dynamic>.from(data['range'] as Map)
          });
        }
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => more ? _pageFailed = true : _failed = true);
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

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _request++;
    setState(() {
      _loading = true;
      _more = false;
      _items = [];
      _cursor = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () => _load());
  }

  Future<void> _calendar() async {
    final selection = await showProgressExerciseCalendar(context, _selection);
    if (selection == null || !mounted) return;
    _debounce?.cancel();
    setState(() {
      _selection = selection;
      _datesChanged = true;
      _period = selection.mode == BodyDateMode.all ? 'all' : 'custom';
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _load(refresh: true);
  }

  Widget _muscleFilter() {
    final muscles = widget.muscles.isEmpty ? _defaultMuscles : widget.muscles;
    final selected = muscles.where((row) => row['id'] == _muscle).firstOrNull;
    return PopupMenuButton<String>(
        tooltip: fitnessText(context, 'All muscles'),
        initialValue: _muscle ?? '',
        color: DSColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
          final id = value.isEmpty ? null : value;
          if (id == _muscle) return;
          _debounce?.cancel();
          HapticFeedback.selectionClick();
          setState(() => _muscle = id);
          unawaited(_load());
        },
        itemBuilder: (_) => [
              CheckedPopupMenuItem(
                  value: '',
                  checked: _muscle == null,
                  child: Text(fitnessText(context, 'All muscles'))),
              for (final muscle in muscles)
                CheckedPopupMenuItem(
                    value: muscle['id'] as String,
                    checked: _muscle == muscle['id'],
                    child: Text(progressMuscleLabel(context, muscle))),
            ],
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                  child: Text(
                      selected == null
                          ? fitnessText(context, 'All muscles')
                          : progressMuscleLabel(context, selected),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: progressSilver, fontSize: 12))),
              const SizedBox(width: 7),
              const Icon(CupertinoIcons.chevron_down,
                  size: 11, color: progressMuted),
            ])));
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          body: SafeArea(
              bottom: false,
              child: Column(children: [
                ProgressExerciseHeader(
                    title: fitnessText(context, 'Exercise progress'),
                    rangeLabel: bodySelectionLabel(context, _selection),
                    onCalendar: _calendar),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                            fontSize: 13, color: progressSilver),
                        decoration: InputDecoration(
                            hintText:
                                fitnessText(context, 'Search your exercises'),
                            hintStyle: const TextStyle(color: progressMuted),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            prefixIcon: const Icon(CupertinoIcons.search,
                                size: 17, color: progressMuted),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: fitnessText(context, 'Clear'),
                                    onPressed: () {
                                      _search.clear();
                                      _onSearchChanged('');
                                    },
                                    icon: const Icon(CupertinoIcons.xmark,
                                        size: 14, color: progressMuted))))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Expanded(
                          child: Text(fitnessText(context, 'Exercises'),
                              style: const TextStyle(
                                  fontSize: 12, color: progressMuted))),
                      const SizedBox(width: 12),
                      Flexible(
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: _muscleFilter())),
                    ])),
                Expanded(
                    child: RefreshIndicator(
                        color: progressSilver,
                        onRefresh: () => _load(refresh: true),
                        child: _body())),
              ]))));

  Widget _body() {
    if (_loading) {
      return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: const [
            ProgressSkeleton(heights: [130, 130, 130])
          ]);
    }
    if (_items.isEmpty) {
      return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            ProgressSurface(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  ProgressEmpty(_failed
                      ? 'Could not load exercises'
                      : 'No logged exercises found'),
                  if (_failed)
                    TextButton(
                        onPressed: () => _load(refresh: true),
                        child: Text(fitnessText(context, 'Retry'))),
                ])),
          ]);
    }
    return ListView.separated(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
        itemCount: _items.length + (_cursor != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _more
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(color: progressSilver))
                : Center(
                    child: TextButton(
                        onPressed: () =>
                            _load(more: true, refresh: _pageFailed),
                        child: Text(
                            fitnessText(context,
                                _pageFailed ? 'Retry' : 'Load more exercises'),
                            style: const TextStyle(
                                color: progressSilver, fontSize: 12))));
          }
          final item = _items[index];
          return ExerciseProgressListRow(
              exercise: item,
              onTap: () => Navigator.of(context).push(AppPageRoute(
                  builder: (_) => ProgressDetailView(
                      repository: _repo,
                      title: item['name'] as String? ?? 'Exercise',
                      path:
                          '/exercises/${Uri.encodeComponent(item['id'] as String)}',
                      period: _period,
                      kind: 'exercise',
                      query: _query))));
        });
  }
}
