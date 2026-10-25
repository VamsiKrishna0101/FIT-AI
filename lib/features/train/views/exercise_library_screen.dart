import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_motion.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/add_exercise_sheet.dart';
import '../components/exercise_thumbnail.dart';
import '../models/exercise_catalog_page.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import 'exercise_detail_view.dart';

class ExerciseLibraryView extends StatefulWidget {
  final VoidCallback onExerciseAdded;
  final List<WorkoutExerciseModel>? initialExercises;
  final Future<bool> Function(WorkoutExerciseModel)? addToWorkout;
  final ValueChanged<WorkoutExerciseModel>? onSelect;
  final String? workoutDate;
  const ExerciseLibraryView(
      {super.key,
      required this.onExerciseAdded,
      this.initialExercises,
      this.addToWorkout,
      this.onSelect,
      this.workoutDate});
  @override
  State<ExerciseLibraryView> createState() => _ExerciseLibraryViewState();
}

class _ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<WorkoutExerciseModel> _exercises = [];
  bool _loading = true;
  String? _bodyPart, _equipment, _mediaGender, _error;
  String _lastSearch = '';
  int _page = 1, _total = 0, _totalPages = 0;
  static const _pageSize = 24;
  List<ExerciseFilterOption> _bodyParts = [], _equipmentOptions = [];
  String _locale = '';
  int _request = 0;
  final _added = <String>{}, _adding = <String>{};
  @override
  void initState() {
    super.initState();
    _locale = LanguageManager.shared.currentLanguage.code;
    _search.addListener(_searchChanged);
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _searchChanged() {
    // TextEditingController also reports cursor and composing-region changes.
    final query = _search.text.trim();
    if (query == _lastSearch) return;
    _lastSearch = query;
    _filterChanged();
  }

  void _filterChanged() {
    _debounce?.cancel();
    ++_request;
    setState(() {
      _page = 1;
      _loading = true;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _debounce =
        Timer(const Duration(milliseconds: 220), () => unawaited(_load()));
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) return;
    _locale = locale;
    setState(() {
      _exercises = [];
      _loading = true;
    });
    _debounce?.cancel();
    _page = 1;
    unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ExerciseCatalogPage result;
      if (widget.initialExercises != null) {
        final all = widget.initialExercises!;
        List<ExerciseFilterOption> options(Iterable<String> values) =>
            (values.toSet().toList()..sort())
                .map((s) => ExerciseFilterOption(s, s))
                .toList();
        final filtered = all
            .where(_matches)
            .map((exercise) => _mediaGender == null
                ? exercise
                : exercise.withDemo(_mediaGender!))
            .toList();
        result = ExerciseCatalogPage(
            exercises:
                filtered.skip((_page - 1) * _pageSize).take(_pageSize).toList(),
            page: _page,
            total: filtered.length,
            totalPages: (filtered.length / _pageSize).ceil(),
            bodyParts: options(all.map((e) => e.bodyPart)),
            equipment: options(all.map((e) => e.equipment)));
      } else {
        result = await WorkoutRepository.shared.getExercisePage(
            page: _page,
            pageSize: _pageSize,
            search: _search.text,
            bodyPart: _bodyPart,
            equipment: _equipment,
            mediaGender: _mediaGender,
            forceRefresh: refresh);
      }
      if (!mounted || request != _request) return;
      if (result.totalPages > 0 && _page > result.totalPages) {
        _page = result.totalPages;
        await _load(refresh: refresh);
        return;
      }
      setState(() {
        _exercises = result.exercises;
        _total = result.total;
        _totalPages = result.totalPages;
        _bodyParts = result.bodyParts;
        _equipmentOptions = result.equipment;
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load exercises.';
        });
      }
    }
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _search.removeListener(_searchChanged);
    _search.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _matches(WorkoutExerciseModel exercise) {
    final terms =
        '${exercise.bodyPart} ${exercise.target} ${exercise.muscleGroup ?? ''}'
            .toLowerCase();
    final categoryMatches =
        (_mediaGender == null || exercise.hasDemo(_mediaGender!)) &&
            (_bodyPart == null || exercise.bodyPart == _bodyPart) &&
            (_equipment == null || exercise.equipment == _equipment);
    final query = _search.text.trim().toLowerCase();
    return categoryMatches &&
        (query.isEmpty ||
            [
              exercise.displayName,
              exercise.canonicalName ?? '',
              exercise.bodyPartLabel ?? exercise.bodyPart,
              exercise.targetLabel ?? exercise.target,
              exercise.equipmentLabel ?? exercise.equipment,
              terms
            ].any((value) => value.toLowerCase().contains(query)));
  }

  Future<bool> _add(WorkoutExerciseModel exercise) async {
    if (widget.onSelect != null) {
      widget.onSelect!(exercise);
      return true;
    }
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
    } catch (_) {
      // Keep this row available for retry when saving fails.
    }
    if (!mounted) return success;
    setState(() {
      _adding.remove(exercise.id);
      if (success) _added.add(exercise.id);
    });
    if (success) widget.onExerciseAdded();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fitnessText(
            context,
            success
                ? 'Added to your plan'
                : 'Could not save. Please try again.'))));
    return success;
  }

  Future<void> _open(WorkoutExerciseModel exercise) async {
    var selected = false;
    final route = AppPageRoute<void>(
        page: ExerciseDetailView(
      exercise: exercise,
      mediaGender: _mediaGender,
      female: _mediaGender == null ? null : _mediaGender == 'female',
      addLabel: widget.onSelect != null
          ? 'Select'
          : widget.addToWorkout != null
              ? 'Add exercise'
              : 'Add to today',
      onAddToPlan: _added.contains(exercise.id)
          ? null
          : () async {
              if (widget.onSelect != null) {
                selected = true;
                return true;
              }
              return _add(exercise);
            },
    ));
    await Navigator.of(context).push(route);
    await route.completed;
    if (mounted && selected) widget.onSelect?.call(exercise);
  }

  void _custom() => showModalBottomSheet<void>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExerciseSheet(
          startCustom: true, onExerciseAdded: widget.onExerciseAdded));
  void _pageChanged(int page) {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    unawaited(_load());
  }

  Future<void> _filters() async {
    FocusScope.of(context).unfocus();
    var bodyPart = _bodyPart;
    var equipment = _equipment;
    var mediaGender = _mediaGender;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitnessTheme.surface,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, update) {
        String copy(String text) => fitnessText(context, text);
        Widget filter(String label, String? value,
            List<ExerciseFilterOption> options, ValueChanged<String?> changed) {
          return DropdownButtonFormField<String>(
            key: ValueKey('filter-$label-$value'),
            initialValue: value ?? '',
            isExpanded: true,
            dropdownColor: FitnessTheme.surface,
            style: const TextStyle(fontSize: 14, color: FitnessTheme.silver),
            decoration: InputDecoration(labelText: copy(label)),
            items: [const ExerciseFilterOption('', 'All'), ...options]
                .map((option) => DropdownMenuItem(
                    value: option.value,
                    child: Text(copy(option.label),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) =>
                update(() => changed(value == '' ? null : value)),
          );
        }

        return SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          color: FitnessTheme.muted,
                          borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 22),
              Text(copy('Filters'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              Text(copy('Demonstration'),
                  style:
                      const TextStyle(fontSize: 13, color: FitnessTheme.muted)),
              const SizedBox(height: 10),
              Row(children: [
                for (final entry in const {
                  '': 'All',
                  'male': 'Male',
                  'female': 'Female'
                }.entries)
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      key: ValueKey('demo-filter-${entry.key}'),
                      label: Center(child: Text(copy(entry.value))),
                      selected: (mediaGender ?? '') == entry.key,
                      showCheckmark: false,
                      selectedColor: FitnessTheme.silver,
                      labelStyle: TextStyle(
                          color: (mediaGender ?? '') == entry.key
                              ? FitnessTheme.canvas
                              : FitnessTheme.silver),
                      onSelected: (_) => update(() =>
                          mediaGender = entry.key.isEmpty ? null : entry.key),
                    ),
                  )),
              ]),
              const SizedBox(height: 24),
              filter('Body part', bodyPart, _bodyParts,
                  (value) => bodyPart = value),
              const SizedBox(height: 18),
              filter('Equipment', equipment, _equipmentOptions,
                  (value) => equipment = value),
              const SizedBox(height: 24),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: FitnessTheme.silver,
                      foregroundColor: FitnessTheme.canvas,
                      minimumSize: const Size(0, 48)),
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(copy('Apply filters'))),
              TextButton(
                  onPressed: () => update(() {
                        bodyPart = null;
                        equipment = null;
                        mediaGender = null;
                      }),
                  child: Text(copy('Reset filters'),
                      style: const TextStyle(color: FitnessTheme.muted))),
            ],
          )),
        ));
      }),
    );
    if (apply != true || !mounted) return;
    _debounce?.cancel();
    setState(() {
      _bodyPart = bodyPart;
      _equipment = equipment;
      _mediaGender = mediaGender;
      _exercises = [];
      _page = 1;
    });
    unawaited(_load());
  }

  void _reset() {
    _debounce?.cancel();
    _search.removeListener(_searchChanged);
    _search.clear();
    _lastSearch = '';
    _search.addListener(_searchChanged);
    setState(() {
      _bodyPart = null;
      _equipment = null;
      _mediaGender = null;
      _exercises = [];
      _page = 1;
    });
    unawaited(_load());
  }

  Widget _intro() {
    String copy(String text) => fitnessText(context, text);
    final filters =
        [_bodyPart, _equipment, _mediaGender].whereType<String>().length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            copy(widget.onSelect == null
                ? 'Find your next movement'
                : 'Make it your workout'),
            style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w500,
                letterSpacing: -.6,
                height: 1.2)),
        const SizedBox(height: 8),
        Text(widget.workoutDate ?? copy('Explore exercises'),
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('exercise-search'),
          controller: _search,
          style: const TextStyle(fontSize: 14),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            _debounce?.cancel();
            unawaited(_load());
          },
          decoration: InputDecoration(
            hintText: copy('Search exercises, muscles or equipment'),
            hintStyle: const TextStyle(fontSize: 12, color: FitnessTheme.muted),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            prefixIcon: const Icon(CupertinoIcons.search,
                size: 18, color: FitnessTheme.silver),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: copy('Clear search'),
                    onPressed: _search.clear,
                    icon:
                        const Icon(CupertinoIcons.xmark_circle_fill, size: 17)),
            filled: true,
            fillColor: FitnessTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: FitnessTheme.line)),
          ),
        ),
        const SizedBox(height: 12),
        if (filters > 0) ...[
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (_mediaGender != null)
              InputChip(
                key: const ValueKey('active-demo-filter'),
                label: Text(copy(_mediaGender == 'male' ? 'Male' : 'Female')),
                onDeleted: () {
                  _mediaGender = null;
                  _filterChanged();
                },
              ),
            if (_bodyPart != null)
              InputChip(
                  key: const ValueKey('active-body-filter'),
                  label: Text(_bodyParts
                      .firstWhere((option) => option.value == _bodyPart,
                          orElse: () =>
                              ExerciseFilterOption(_bodyPart!, _bodyPart!))
                      .label),
                  onDeleted: () {
                    _bodyPart = null;
                    _filterChanged();
                  }),
            if (_equipment != null)
              InputChip(
                  key: const ValueKey('active-equipment-filter'),
                  label: Text(_equipmentOptions
                      .firstWhere((option) => option.value == _equipment,
                          orElse: () =>
                              ExerciseFilterOption(_equipment!, _equipment!))
                      .label),
                  onDeleted: () {
                    _equipment = null;
                    _filterChanged();
                  }),
          ]),
          const SizedBox(height: 4),
        ],
        SizedBox(
            width: double.infinity,
            child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                          _loading
                              ? copy('Finding exercises…')
                              : fitnessText(context, '{count} exercises',
                                  values: {'count': _total}),
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted))),
                  if (filters > 0 || _search.text.isNotEmpty)
                    TextButton(
                        onPressed: _reset,
                        child: Text(copy('Reset filters'),
                            style: const TextStyle(
                                fontSize: 11, color: FitnessTheme.muted))),
                  OutlinedButton.icon(
                    key: const ValueKey('exercise-filters'),
                    onPressed: _filters,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: FitnessTheme.silver,
                        side: const BorderSide(color: FitnessTheme.line),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                    icon: const Icon(CupertinoIcons.slider_horizontal_3,
                        size: 15),
                    label: Text(
                        '${copy('Filters')}${filters == 0 ? '' : ' · $filters'}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ])),
      ]),
    );
  }

  Widget _card(WorkoutExerciseModel exercise) {
    final added = _added.contains(exercise.id);
    final adding = _adding.contains(exercise.id);
    final label = added
        ? 'Added'
        : widget.onSelect != null
            ? 'Select'
            : widget.addToWorkout != null
                ? 'Add exercise'
                : 'Add to today';
    return PremiumSurface(
      key: ValueKey('exercise-${exercise.id}'),
      color: FitnessTheme.surface,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
      onTap: adding || _loading ? null : () => _open(exercise),
      child: Row(children: [
        ExercisePoster(exercise: exercise, size: 72),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.displayName,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 5),
          Text(exercise.targetLabel ?? fitnessText(context, exercise.target),
              style: const TextStyle(fontSize: 11, color: FitnessTheme.silver)),
          const SizedBox(height: 3),
          Text(
              exercise.equipmentLabel ??
                  fitnessText(context, exercise.equipment),
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ])),
        const SizedBox(width: 6),
        IconButton(
          key: ValueKey('add-exercise-${exercise.id}'),
          tooltip: fitnessText(context, label),
          onPressed: added || adding || _loading ? null : () => _add(exercise),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .045),
              foregroundColor: FitnessTheme.silver),
          icon: adding
              ? const CupertinoActivityIndicator(radius: 8)
              : Icon(added ? CupertinoIcons.checkmark : CupertinoIcons.plus,
                  size: 18),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    String copy(String text) => fitnessText(context, text);
    return FitnessTheme(
        child: Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent,
          title: Text(copy('Exercises'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          leading: IconButton(
              tooltip: copy('Back'),
              icon: const Icon(CupertinoIcons.chevron_left, size: 21),
              onPressed: () => Navigator.of(context).maybePop()),
          actions: [
            if (widget.addToWorkout == null &&
                widget.onSelect == null &&
                MediaQuery.sizeOf(context).width >= 360 &&
                MediaQuery.textScalerOf(context).scale(12) <= 16)
              TextButton.icon(
                  onPressed: _custom,
                  icon: const Icon(CupertinoIcons.plus, size: 16),
                  label: Text(copy('Custom exercise'),
                      style: const TextStyle(fontSize: 12)))
            else if (widget.addToWorkout == null && widget.onSelect == null)
              IconButton(
                  tooltip: copy('Custom exercise'),
                  onPressed: _custom,
                  icon: const Icon(CupertinoIcons.plus, size: 19))
          ]),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: RefreshIndicator(
                    color: FitnessTheme.silver,
                    onRefresh: () => _load(refresh: true),
                    child: CustomScrollView(
                        controller: _scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(child: _intro()),
                          if (_loading && _exercises.isNotEmpty)
                            const SliverToBoxAdapter(
                                child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: LinearProgressIndicator(
                                  key: ValueKey('exercise-search-progress'),
                                  minHeight: 1,
                                  color: FitnessTheme.silver,
                                  backgroundColor: FitnessTheme.line),
                            )),
                          if (_loading && _exercises.isEmpty)
                            const SliverFillRemaining(
                                hasScrollBody: false,
                                child:
                                    Center(child: CupertinoActivityIndicator()))
                          else if (_error != null ||
                              (!_loading && _exercises.isEmpty))
                            SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(CupertinoIcons.search,
                                              size: 28,
                                              color: FitnessTheme.muted),
                                          const SizedBox(height: 12),
                                          Text(
                                              copy(_error ??
                                                  'No exercises found'),
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          Text(
                                              copy(_error == null
                                                  ? 'Try another search or filter.'
                                                  : 'Check your connection and try again.'),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: FitnessTheme.muted,
                                                  fontSize: 13,
                                                  height: 1.5)),
                                          if (_error != null)
                                            TextButton(
                                                onPressed: () =>
                                                    _load(refresh: true),
                                                child: Text(copy('Retry'))),
                                        ])))
                          else
                            SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                sliver: SliverList.separated(
                                    itemCount: _exercises.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, index) =>
                                        _card(_exercises[index]))),
                        ]))),
            Container(
                key: const ValueKey('exercise-pagination'),
                decoration: const BoxDecoration(
                    color: FitnessTheme.canvas,
                    border: Border(top: BorderSide(color: FitnessTheme.line))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  IconButton(
                      key: const ValueKey('exercise-previous'),
                      tooltip: copy('Previous page'),
                      onPressed: _loading || _error != null || _page <= 1
                          ? null
                          : () => _pageChanged(_page - 1),
                      icon: const Icon(CupertinoIcons.chevron_left, size: 18)),
                  Expanded(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        _loading
                            ? copy('Loading…')
                            : _error != null
                                ? '—'
                                : _totalPages == 0
                                    ? fitnessText(context, '{count} exercises',
                                        values: {'count': 0})
                                    : fitnessText(
                                        context, 'Page {page} of {total}',
                                        values: {
                                            'page':
                                                _totalPages == 0 ? 0 : _page,
                                            'total': _totalPages
                                          }),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    if (_total > 0 && !_loading && _error == null) ...[
                      const SizedBox(height: 3),
                      Text(
                          '${(_page - 1) * _pageSize + 1}–${((_page - 1) * _pageSize + _exercises.length)} / $_total',
                          style: const TextStyle(
                              fontSize: 10, color: FitnessTheme.muted)),
                    ],
                  ])),
                  IconButton(
                      key: const ValueKey('exercise-next'),
                      tooltip: copy('Next page'),
                      onPressed:
                          _loading || _error != null || _page >= _totalPages
                              ? null
                              : () => _pageChanged(_page + 1),
                      icon: const Icon(CupertinoIcons.chevron_right, size: 18)),
                ])),
          ])),
    ));
  }
}

class ExercisePoster extends StatelessWidget {
  final WorkoutExerciseModel exercise;
  final double size;
  const ExercisePoster({super.key, required this.exercise, this.size = 78});
  @override
  Widget build(BuildContext context) =>
      ExerciseThumbnail(exercise: exercise, size: size);
}
