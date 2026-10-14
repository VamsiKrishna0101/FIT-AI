import '../../../core/theme/ds_motion.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/add_exercise_sheet.dart';
import '../models/exercise_catalog_page.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import 'exercise_detail_view.dart';

class ExerciseLibraryView extends StatefulWidget {
  final VoidCallback onExerciseAdded;
  final List<WorkoutExerciseModel>? initialExercises;
  final Future<bool> Function(WorkoutExerciseModel)? addToWorkout;
  final ValueChanged<WorkoutExerciseModel>? onSelect;
  const ExerciseLibraryView(
      {super.key,
      required this.onExerciseAdded,
      this.initialExercises,
      this.addToWorkout,
      this.onSelect});
  @override
  State<ExerciseLibraryView> createState() => _ExerciseLibraryViewState();
}

class _ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<WorkoutExerciseModel> _exercises = [];
  bool _loading = true;
  String? _bodyPart, _equipment, _error;
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
    _search.addListener(_filterChanged);
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _filterChanged() {
    _debounce?.cancel();
    ++_request;
    setState(() {
      _page = 1;
      _loading = true;
      _error = null;
    });
    _debounce =
        Timer(const Duration(milliseconds: 300), () => unawaited(_load()));
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
        final filtered = all.where(_matches).toList();
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
    _search.removeListener(_filterChanged);
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
    final success = widget.addToWorkout != null
        ? await widget.addToWorkout!(exercise)
        : await WorkoutRepository.shared.addWorkoutItem(
            workoutId: exercise.id,
            targetSets: 3,
            targetReps: '10',
            targetWeight: 0,
            restSeconds: 60);
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

  void _open(WorkoutExerciseModel exercise) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(
          builder: (_) => ExerciseDetailView(
              exercise: exercise,
              onAddToPlan:
                  _added.contains(exercise.id) ? null : () => _add(exercise))));
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

  Widget _filter(String label, String? value,
          List<ExerciseFilterOption> options, ValueChanged<String?> changed) =>
      InputDecorator(
        decoration: InputDecoration(
          labelText: fitnessText(context, label),
          filled: true,
          fillColor: FitnessTheme.surface,
          contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: FitnessTheme.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: FitnessTheme.muted, width: .8)),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          key: ValueKey('filter-$label'),
          value: value ?? '',
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: 360,
          dropdownColor: FitnessTheme.surface,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(CupertinoIcons.chevron_down,
              size: 14, color: FitnessTheme.silver),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 13, color: FitnessTheme.silver),
          items: [
            const ExerciseFilterOption('', 'All'),
            ...options,
            if (value != null &&
                !options.any((option) => option.value == value))
              ExerciseFilterOption(value, value)
          ]
              .map((option) => DropdownMenuItem(
                  value: option.value,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(fitnessText(context, option.label),
                          maxLines: 2, overflow: TextOverflow.ellipsis))))
              .toList(),
          onChanged: (selected) {
            _debounce?.cancel();
            setState(() {
              changed(selected == '' ? null : selected);
              _page = 1;
            });
            unawaited(_load());
          },
        )),
      );

  Widget _intro() {
    String copy(String text) => fitnessText(context, text);
    final compact = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(12) > 16;
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(copy('Explore exercises'),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.8,
                  height: 1.12)),
          const SizedBox(height: 9),
          Text(copy('Find your next movement. Make it part of your plan.'),
              style: const TextStyle(
                  fontSize: 13, color: FitnessTheme.muted, height: 1.5)),
          if (compact &&
              widget.addToWorkout == null &&
              widget.onSelect == null) ...[
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                    onPressed: _custom,
                    style: TextButton.styleFrom(
                        backgroundColor: FitnessTheme.surface,
                        foregroundColor: FitnessTheme.silver,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: Row(children: [
                      const Icon(CupertinoIcons.plus, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(copy('Custom exercise'),
                              style: const TextStyle(fontSize: 12))),
                    ]))),
          ],
          const SizedBox(height: 22),
          TextField(
              key: const ValueKey('exercise-search'),
              controller: _search,
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _debounce?.cancel();
                unawaited(_load());
              },
              decoration: InputDecoration(
                  hintText: copy('Search exercises, muscles or equipment'),
                  hintStyle:
                      const TextStyle(fontSize: 13, color: FitnessTheme.muted),
                  prefixIcon: const Icon(CupertinoIcons.search,
                      size: 19, color: FitnessTheme.silver),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: copy('Clear search'),
                          icon: const Icon(CupertinoIcons.xmark_circle_fill,
                              size: 18),
                          onPressed: _search.clear),
                  filled: true,
                  fillColor: FitnessTheme.surface,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: FitnessTheme.line)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: FitnessTheme.muted, width: .8)))),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final body = _filter('Body part', _bodyPart, _bodyParts,
                (value) => _bodyPart = value);
            final equipment = _filter('Equipment', _equipment,
                _equipmentOptions, (value) => _equipment = value);
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(13) > 18) {
              return Column(
                  children: [body, const SizedBox(height: 14), equipment]);
            }
            return Row(children: [
              Expanded(child: body),
              const SizedBox(width: 12),
              Expanded(child: equipment)
            ]);
          }),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text(
                    _loading
                        ? copy('Finding exercises…')
                        : fitnessText(context, '{count} exercises',
                            values: {'count': _total}),
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted))),
            if (_bodyPart != null ||
                _equipment != null ||
                _search.text.isNotEmpty)
              TextButton(
                  onPressed: () {
                    _debounce?.cancel();
                    _search.removeListener(_filterChanged);
                    _search.clear();
                    _search.addListener(_filterChanged);
                    setState(() {
                      _bodyPart = null;
                      _equipment = null;
                      _page = 1;
                    });
                    unawaited(_load());
                  },
                  child: Text(copy('Reset filters'),
                      style: const TextStyle(fontSize: 12))),
          ]),
        ]));
  }

  Widget _card(WorkoutExerciseModel exercise) {
    String copy(String text) => fitnessText(context, text);
    final added = _added.contains(exercise.id);
    return PremiumSurface(
        key: ValueKey('exercise-${exercise.id}'),
        color: FitnessTheme.surface,
        radius: 20,
        padding: const EdgeInsets.all(14),
        onTap: () => widget.onSelect != null
            ? widget.onSelect!(exercise)
            : _open(exercise),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExercisePoster(exercise: exercise, size: 82),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(exercise.displayName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -.2)),
                const SizedBox(height: 6),
                Text(exercise.targetLabel ?? copy(exercise.target),
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted, height: 1.4)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(exercise.equipmentLabel ?? copy(exercise.equipment),
                          style: const TextStyle(
                              fontSize: 11, color: FitnessTheme.muted)),
                      TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: FitnessTheme.silver,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 44)),
                          onPressed: added || _adding.contains(exercise.id)
                              ? null
                              : () => _add(exercise),
                          icon: _adding.contains(exercise.id)
                              ? const CupertinoActivityIndicator(radius: 8)
                              : Icon(
                                  added
                                      ? CupertinoIcons.checkmark
                                      : CupertinoIcons.plus,
                                  size: 15),
                          label: Text(
                              copy(added
                                  ? 'Added'
                                  : widget.onSelect != null
                                      ? 'Select'
                                      : 'Add to today'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500))),
                    ]),
              ])),
        ]));
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
                          if (_loading)
                            const SliverFillRemaining(
                                hasScrollBody: false,
                                child:
                                    Center(child: CupertinoActivityIndicator()))
                          else if (_error != null || _exercises.isEmpty)
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
                                        const SizedBox(height: 12),
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
  Widget build(BuildContext context) {
    final url = exercise.thumbnailUrl?.trim() ?? '';
    const fallback = Center(
        child: Icon(CupertinoIcons.person, color: Color(0xFF969696), size: 26));
    return RepaintBoundary(
        child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
                width: size,
                height: size,
                child: ColoredBox(
                    color: const Color(0xFF2A2A2A),
                    child: url.isEmpty
                        ? fallback
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            memCacheWidth:
                                (size * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            fadeInDuration: const Duration(milliseconds: 120),
                            placeholder: (_, __) => fallback,
                            errorWidget: (_, __, ___) => fallback)))));
  }
}
