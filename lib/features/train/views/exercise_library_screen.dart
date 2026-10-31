import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/components/library_new_button.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/add_exercise_sheet.dart';
import '../components/exercise_thumbnail.dart';
import '../components/exercise_filters_sheet.dart';
import '../components/exercise_library_card.dart';
import '../models/exercise_catalog_page.dart';
import '../models/exercise_library_copy.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import 'exercise_detail_view.dart';

typedef ExercisePageLoader = Future<ExerciseCatalogPage> Function(
    int page,
    String search,
    String? bodyPart,
    String? equipment,
    String? mediaGender,
    bool refresh);

class ExerciseLibraryView extends StatefulWidget {
  final VoidCallback onExerciseAdded;
  final List<WorkoutExerciseModel>? initialExercises;
  final Future<bool> Function(WorkoutExerciseModel)? addToWorkout;
  final ValueChanged<WorkoutExerciseModel>? onSelect;
  final ValueChanged<List<WorkoutExerciseModel>>? onSelectMany;
  final ExercisePageLoader? pageLoader;
  // Kept for callers that select a dated workout; dates are never shown here.
  final String? workoutDate;
  const ExerciseLibraryView(
      {super.key,
      required this.onExerciseAdded,
      this.initialExercises,
      this.addToWorkout,
      this.onSelect,
      this.onSelectMany,
      this.pageLoader,
      this.workoutDate});
  @override
  State<ExerciseLibraryView> createState() => _ExerciseLibraryViewState();
}

class _ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  final _search = TextEditingController(), _scroll = ScrollController();
  Timer? _debounce;
  List<WorkoutExerciseModel> _exercises = [];
  List<ExerciseFilterOption> _bodyParts = [], _equipmentOptions = [];
  final _selected = <String, WorkoutExerciseModel>{};
  final _added = <String>{}, _adding = <String>{};
  String? _bodyPart, _equipment, _mediaGender, _error, _moreError, _saveError;
  String _lastSearch = '', _locale = '';
  int _page = 0, _totalPages = 0, _request = 0;
  bool _loading = true,
      _loadingMore = false,
      _committing = false,
      _handedOff = false;
  static const _pageSize = 24;
  bool get _picker =>
      widget.onSelect != null ||
      widget.onSelectMany != null ||
      widget.addToWorkout != null;
  bool get _multiple =>
      widget.onSelectMany != null || widget.addToWorkout != null;
  bool get _filtered =>
      _bodyPart != null || _equipment != null || _mediaGender != null;
  String copy(String text) => exerciseLibraryText(context, text);

  @override
  void initState() {
    super.initState();
    _locale = LanguageManager.shared.currentLanguage.code;
    _search.addListener(_searchChanged);
    _scroll.addListener(_scrolled);
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _searchChanged() {
    final query = _search.text.trim();
    if (query == _lastSearch) {
      return;
    }
    _lastSearch = query;
    _reload(debounce: true);
  }

  void _reload({bool debounce = false}) {
    _debounce?.cancel();
    ++_request; // Invalidate both a previous search and any pending next page.
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _moreError = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (debounce) {
      _debounce =
          Timer(const Duration(milliseconds: 220), () => unawaited(_load()));
    } else {
      unawaited(_load());
    }
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    _exercises = [];
    _selected.clear();
    _reload();
  }

  Future<ExerciseCatalogPage> _fetchPage(int page,
      {bool refresh = false}) async {
    if (widget.pageLoader != null) {
      return widget.pageLoader!(page, _search.text.trim(), _bodyPart,
          _equipment, _mediaGender, refresh);
    }
    if (widget.initialExercises == null) {
      return WorkoutRepository.shared.getExercisePage(
          page: page,
          pageSize: _pageSize,
          search: _search.text.trim(),
          bodyPart: _bodyPart,
          equipment: _equipment,
          mediaGender: _mediaGender,
          forceRefresh: refresh);
    }
    final all = widget.initialExercises!;
    final filtered = all
        .where(_matches)
        .map((e) => _mediaGender == null ? e : e.withDemo(_mediaGender!))
        .toList();
    List<ExerciseFilterOption> options(Iterable<String> values) =>
        (values.toSet().toList()..sort())
            .map((s) => ExerciseFilterOption(s, s))
            .toList();
    return ExerciseCatalogPage(
        exercises:
            filtered.skip((page - 1) * _pageSize).take(_pageSize).toList(),
        page: page,
        total: filtered.length,
        totalPages: (filtered.length / _pageSize).ceil(),
        bodyParts: options(all.map((e) => e.bodyPart)),
        equipment: options(all.map((e) => e.equipment)));
  }

  Future<void> _load({bool refresh = false}) async {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _moreError = null;
    });
    try {
      final result = await _fetchPage(1, refresh: refresh);
      if (!mounted || request != _request) {
        return;
      }
      setState(() {
        _exercises = result.exercises;
        _page = 1;
        _totalPages = result.exercises.isEmpty ? 1 : result.totalPages;
        _bodyParts = result.bodyParts;
        _equipmentOptions = result.equipment;
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _exercises = [];
          _error = 'Could not load exercises.';
        });
      }
    }
  }

  void _scrolled() {
    if (_scroll.hasClients &&
        _scroll.position.hasContentDimensions &&
        _scroll.position.extentAfter < 360 &&
        ModalRoute.of(context)?.isCurrent != false) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore({bool retry = false}) async {
    if (_loading ||
        _error != null ||
        _exercises.isEmpty ||
        _loadingMore ||
        _committing ||
        _page >= _totalPages ||
        (!retry && _moreError != null)) {
      return;
    }
    final request = _request, next = _page + 1;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final result = await _fetchPage(next, refresh: retry);
      if (!mounted || request != _request) {
        return;
      }
      final ids = _exercises.map((e) => e.id).toSet();
      setState(() {
        _exercises = [
          ..._exercises,
          ...result.exercises.where((e) => ids.add(e.id))
        ];
        _page = next;
        _totalPages = result.exercises.isEmpty ? next : result.totalPages;
      });
      // Keep the request locked until the appended rows have updated the scroll
      // dimensions. A bounce at the old end must not fetch another page.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && request == _request) {
        setState(() => _loadingMore = false);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loadingMore = false;
          _moreError = 'Could not load more exercises.';
        });
      }
    }
  }

  bool _matches(WorkoutExerciseModel exercise) {
    final query = _search.text.trim().toLowerCase();
    return (_mediaGender == null || exercise.hasDemo(_mediaGender!)) &&
        (_bodyPart == null || exercise.bodyPart == _bodyPart) &&
        (_equipment == null || exercise.equipment == _equipment) &&
        (query.isEmpty ||
            [
              exercise.displayName,
              exercise.canonicalName ?? '',
              exercise.bodyPartLabel ?? exercise.bodyPart,
              exercise.targetLabel ?? exercise.target,
              exercise.equipmentLabel ?? exercise.equipment,
              exercise.muscleGroup ?? ''
            ].any((text) => text.toLowerCase().contains(query)));
  }

  void _toggle(WorkoutExerciseModel exercise) {
    if (_committing || _handedOff || _loading || _added.contains(exercise.id)) {
      return;
    }
    setState(() {
      _saveError = null;
      if (_selected.remove(exercise.id) == null) {
        if (!_multiple) _selected.clear();
        _selected[exercise.id] = exercise;
      }
    });
  }

  Future<bool> _saveOne(WorkoutExerciseModel exercise) async {
    if (_adding.contains(exercise.id) || _added.contains(exercise.id)) {
      return false;
    }
    setState(() => _adding.add(exercise.id));
    var success = false;
    try {
      success = widget.addToWorkout != null
          ? await widget.addToWorkout!(exercise)
          : await WorkoutRepository.shared.addWorkoutItem(
              workoutId: exercise.id,
              targetSets: 3,
              targetReps: '10',
              targetWeight: 0,
              restSeconds: 90);
    } catch (_) {/* Keep an unconfirmed exercise available for retry. */}
    if (mounted) {
      setState(() {
        _adding.remove(exercise.id);
        if (success) _added.add(exercise.id);
      });
    }
    return success;
  }

  Future<bool> _addFromDetail(WorkoutExerciseModel exercise) async {
    final success = await _saveOne(exercise);
    if (!mounted) {
      return success;
    }
    if (success) widget.onExerciseAdded();
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(copy('Added to your plan'))));
    }
    return success;
  }

  Future<void> _confirmSelection() async {
    if (_committing || _handedOff || _selected.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    final chosen = _selected.values.toList();
    setState(() {
      _committing = true;
      _saveError = null;
    });
    try {
      if (widget.onSelectMany != null) {
        _handedOff = true;
        widget.onSelectMany!(chosen);
        return;
      }
      if (widget.onSelect != null) {
        _handedOff = true;
        widget.onSelect!(chosen.single);
        return;
      }
      var saved = 0;
      for (final exercise in chosen) {
        if (await _saveOne(exercise)) {
          saved++;
          if (mounted) {
            setState(() => _selected.remove(exercise.id));
          }
        } else {
          break;
        }
        if (!mounted) {
          return;
        }
      }
      if (saved > 0) widget.onExerciseAdded();
      if (!mounted) {
        return;
      }
      if (_selected.isEmpty) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(copy('Added to your plan'))));
        }
      } else {
        setState(
            () => _saveError = 'Some exercises could not be added. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _committing = false);
      }
    }
  }

  Future<void> _open(WorkoutExerciseModel exercise) async {
    var selected = false;
    final route = AppPageRoute<void>(
        page: ExerciseDetailView(
      exercise: exercise,
      mediaGender: _mediaGender,
      female: _mediaGender == null ? null : _mediaGender == 'female',
      addLabel: _picker ? 'Select exercise' : 'Add to today',
      onAddToPlan: _added.contains(exercise.id)
          ? null
          : () async {
              if (_picker) {
                selected = true;
                return true;
              }
              return _addFromDetail(exercise);
            },
    ));
    await Navigator.of(context).push(route);
    await route.completed;
    if (!mounted) {
      return;
    }
    if (selected && !_selected.containsKey(exercise.id)) _toggle(exercise);
    _scrolled();
  }

  Future<void> _filters() async {
    if (_committing) {
      return;
    }
    FocusScope.of(context).unfocus();
    final selection = await showModalBottomSheet<ExerciseFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: FitnessTheme.canvas,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: FitnessTheme.line)),
      builder: (_) => ExerciseFiltersSheet(
          bodyParts: _bodyParts,
          equipmentOptions: _equipmentOptions,
          initial:
              ExerciseFilterSelection(_bodyPart, _equipment, _mediaGender)),
    );
    if (!mounted || selection == null) {
      return;
    }
    setState(() {
      _bodyPart = selection.bodyPart;
      _equipment = selection.equipment;
      _mediaGender = selection.mediaGender;
      if (_mediaGender != null) {
        final available = _selected.values
            .where((e) => e.hasDemo(_mediaGender!))
            .map((e) => e.withDemo(_mediaGender!))
            .toList();
        _selected
          ..clear()
          ..addEntries(available.map((e) => MapEntry(e.id, e)));
      }
    });
    _reload();
  }

  void _reset() {
    if (_committing) return;
    setState(() {
      _bodyPart = null;
      _equipment = null;
      _mediaGender = null;
    });
    _reload();
  }

  void _custom() => showModalBottomSheet<void>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FitnessTheme(
          child: AddExerciseSheet(
              startCustom: true, onExerciseAdded: widget.onExerciseAdded)));

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _search.removeListener(_searchChanged);
    _search.dispose();
    _scroll.removeListener(_scrolled);
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _toolbar() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: TextField(
          key: const ValueKey('exercise-search'),
          controller: _search,
          enabled: !_committing,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14),
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            unawaited(_load());
          },
          decoration: InputDecoration(
            hintText: copy('Search exercises'),
            hintStyle: const TextStyle(color: FitnessTheme.muted, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            prefixIcon: const Icon(CupertinoIcons.search,
                size: 18, color: FitnessTheme.muted),
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_search.text.isNotEmpty)
                IconButton(
                    tooltip: copy('Clear search'),
                    onPressed: _committing ? null : _search.clear,
                    icon: const Icon(CupertinoIcons.xmark_circle_fill,
                        size: 17, color: FitnessTheme.muted)),
              IconButton(
                  key: const ValueKey('exercise-filters'),
                  tooltip: copy('Filters'),
                  onPressed: _committing ? null : _filters,
                  icon: Stack(clipBehavior: Clip.none, children: [
                    const Icon(CupertinoIcons.slider_horizontal_3,
                        size: 19, color: FitnessTheme.silver),
                    if (_filtered)
                      const Positioned(
                          key: ValueKey('exercise-filters-active'),
                          right: -3,
                          top: -3,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: FitnessTheme.silver,
                                  shape: BoxShape.circle),
                              child: SizedBox(width: 5, height: 5))),
                  ])),
            ]),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: FitnessTheme.line, width: .7)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: FitnessTheme.line, width: .7)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: DSColors.borderHi)),
          )));

  Widget _row(WorkoutExerciseModel exercise) => ExerciseLibraryCard(
      key: ValueKey('exercise-${exercise.id}'),
      exercise: exercise,
      picker: _picker,
      selected: _selected.containsKey(exercise.id),
      added: _added.contains(exercise.id),
      enabled: !_committing && !_loading && !_handedOff,
      onOpen: () => _open(exercise),
      onToggle: () => _toggle(exercise));

  Widget _empty() => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(copy(_error ?? 'No exercises found'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(
              copy(_error == null
                  ? 'Try another search or filter.'
                  : 'Check your connection and try again.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: FitnessTheme.muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          if (_error != null)
            TextButton(
                onPressed: () => _load(refresh: true),
                child: Text(copy('Retry')))
          else if (_bodyPart != null ||
              _equipment != null ||
              _mediaGender != null)
            TextButton(onPressed: _reset, child: Text(copy('Reset filters')))
          else if (_search.text.isNotEmpty)
            TextButton(
                onPressed: _search.clear, child: Text(copy('Clear search'))),
        ],
      ));

  Widget _selectionFooter() {
    final label = _selected.isEmpty
        ? copy(_multiple ? 'Select exercises' : 'Select an exercise')
        : exerciseLibraryText(
            context,
            _selected.length == 1
                ? 'Add {count} exercise'
                : 'Add {count} exercises',
            values: {'count': _selected.length});
    return DecoratedBox(
        decoration: const BoxDecoration(
            color: FitnessTheme.canvas,
            border:
                Border(top: BorderSide(color: FitnessTheme.line, width: .7))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_saveError != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(copy(_saveError!),
                                style: const TextStyle(
                                    color: FitnessTheme.coral,
                                    fontSize: 12,
                                    height: 1.35))),
                      FilledButton(
                          key: const ValueKey('confirm-exercise-selection'),
                          onPressed:
                              _committing || _handedOff || _selected.isEmpty
                                  ? null
                                  : _confirmSelection,
                          style: FilledButton.styleFrom(
                              backgroundColor: FitnessTheme.silver,
                              foregroundColor: FitnessTheme.canvas,
                              disabledBackgroundColor: DSColors.bgRaised,
                              disabledForegroundColor: FitnessTheme.muted,
                              minimumSize: const Size(double.infinity, 50),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: _committing
                              ? const CupertinoActivityIndicator()
                              : Text(label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600))),
                    ]))));
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: PopScope<Object?>(
        canPop: !_committing,
        child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            title: Text(copy('Exercises'),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            leading: IconButton(
                tooltip: copy('Back'),
                icon: const Icon(CupertinoIcons.chevron_left, size: 21),
                onPressed: _committing
                    ? null
                    : () => Navigator.of(context).maybePop()),
            actions: [
              if (!_picker)
                LibraryNewButton(
                    key: const ValueKey('new-exercise'),
                    label: copy('New'),
                    onPressed: _committing ? null : _custom)
            ],
          ),
          body: SafeArea(
              top: false,
              bottom: !_picker,
              child: Column(children: [
                _toolbar(),
                SizedBox(
                    height: 1,
                    child: _loading && _exercises.isNotEmpty
                        ? const LinearProgressIndicator(
                            key: ValueKey('exercise-search-progress'),
                            minHeight: 1,
                            color: FitnessTheme.silver,
                            backgroundColor: FitnessTheme.line)
                        : const ColoredBox(color: FitnessTheme.line)),
                Expanded(
                    child: RefreshIndicator(
                  color: FitnessTheme.silver,
                  onRefresh: () => _load(refresh: true),
                  child: CustomScrollView(
                    key: const ValueKey('exercise-scroll'),
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      if (_loading && _exercises.isEmpty)
                        const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CupertinoActivityIndicator()))
                      else if (_error != null || _exercises.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false, child: _empty())
                      else ...[
                        SliverList.separated(
                            itemCount: _exercises.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 2),
                            itemBuilder: (_, index) => _row(_exercises[index])),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: _loadingMore
                                    ? const Center(
                                        child: CupertinoActivityIndicator())
                                    : _moreError != null
                                        ? Column(children: [
                                            Text(copy(_moreError!),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: FitnessTheme.muted)),
                                            TextButton(
                                                key: const ValueKey(
                                                    'retry-exercise-page'),
                                                onPressed: () =>
                                                    _loadMore(retry: true),
                                                child: Text(copy('Retry')))
                                          ])
                                        : const SizedBox(height: 8))),
                      ],
                    ],
                  ),
                )),
              ])),
          bottomNavigationBar: _picker ? _selectionFooter() : null,
        ),
      ));
}

class ExercisePoster extends StatelessWidget {
  final WorkoutExerciseModel exercise;
  final double size;
  const ExercisePoster({super.key, required this.exercise, this.size = 52});
  @override
  Widget build(BuildContext context) =>
      ExerciseThumbnail(exercise: exercise, size: size);
}
