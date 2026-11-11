import 'package:setcraft/core/theme/ds_motion.dart';
import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/food_library_card.dart';
import '../components/food_library_filters.dart';
import '../models/food_catalog_page.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';
import '../utils/food_search_helper.dart';
import '../../../core/components/library_new_button.dart';
import '../components/new_food_sheet.dart';
import 'meal_portion_view.dart';
import 'saved_meal_editor_view.dart';

typedef FoodPageLoader = Future<FoodCatalogPage> Function(int page,
    String search, String? category, String focus, String sort, String source);

class FoodLibraryView extends StatefulWidget {
  final String initialMealType;
  final DateTime? initialDate;
  final VoidCallback onMealAdded;
  final List<NutritionFoodItemModel>? initialFoods;
  final FoodPageLoader? pageLoader;
  final Future<bool> Function(Map<String, dynamic>)? saveMeal;
  final ValueChanged<NutritionFoodItemModel>? onFoodSelected;
  const FoodLibraryView(
      {super.key,
      required this.onMealAdded,
      this.initialMealType = 'LUNCH',
      this.initialDate,
      this.initialFoods,
      this.pageLoader,
      this.saveMeal,
      this.onFoodSelected});
  @override
  State<FoodLibraryView> createState() => _FoodLibraryViewState();
}

class _FoodLibraryViewState extends State<FoodLibraryView> {
  final _search = TextEditingController(), _scroll = ScrollController();
  Timer? _debounce;
  List<NutritionFoodItemModel> _foods = [];
  String? _category, _error;
  String _focus = 'ALL', _sort = 'NAME', _source = 'LIBRARY', _lastSearch = '';
  late final String _slot;
  int _page = 1, _total = 0, _pages = 0, _request = 0;
  bool _loading = true, _opening = false;
  static const _size = 24;
  @override
  void initState() {
    super.initState();
    _slot = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK']
            .contains(widget.initialMealType)
        ? widget.initialMealType
        : 'SNACK';
    _search.addListener(_searchChanged);
    unawaited(_load());
  }

  void _searchChanged() {
    final query = _search.text.trim();
    if (query == _lastSearch) return;
    _lastSearch = query;
    _debounce?.cancel();
    ++_request;
    setState(() {
      _page = 1;
      _loading = true;
      _error = null;
    });
    _debounce =
        Timer(const Duration(milliseconds: 220), () => unawaited(_load()));
  }

  void _filter(VoidCallback change) {
    _debounce?.cancel();
    setState(() {
      change();
      _page = 1;
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      FoodCatalogPage result;
      if (widget.initialFoods != null) {
        final query = _search.text.trim();
        final filtered = FoodSearchHelper.filterAndRank(
            foods: widget.initialFoods!,
            query: query,
            category: _category,
            focus: _focus,
            sort: _sort);
        final pages = (filtered.length / _size).ceil();
        final page = _page.clamp(1, pages == 0 ? 1 : pages);
        result = FoodCatalogPage(
            foods: filtered.skip((page - 1) * _size).take(_size).toList(),
            page: page,
            total: filtered.length,
            totalPages: pages);
      } else if (widget.pageLoader != null) {
        result = await widget.pageLoader!(
            _page, _search.text, _category, _focus, _sort, _source);
      } else {
        result = await NutritionRepository.shared.getFoodPage(
            page: _page,
            search: _search.text,
            category: _category,
            focus: _focus,
            sort: _sort,
            source: _source);
      }
      if (!mounted || request != _request) return;

      var displayedFoods = result.foods;
      var total = result.total;
      var pages = result.totalPages;

      final queryText = _search.text.trim();
      if (queryText.isNotEmpty && displayedFoods.isNotEmpty && widget.initialFoods == null) {
        final clientRanked = FoodSearchHelper.filterAndRank(
          foods: displayedFoods,
          query: queryText,
          category: _category,
          focus: _focus,
          sort: _sort,
        );
        if (clientRanked.isNotEmpty) {
          displayedFoods = clientRanked;
        } else if (_sort == 'NAME') {
          displayedFoods = List<NutritionFoodItemModel>.from(displayedFoods);
          displayedFoods.sort((a, b) {
            final sa = FoodSearchHelper.scoreFood(a, queryText);
            final sb = FoodSearchHelper.scoreFood(b, queryText);
            return sb.compareTo(sa);
          });
        }
      }

      setState(() {
        _foods = displayedFoods;
        _page = result.page;
        _total = total;
        _pages = pages;
        _loading = false;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load foods · Retry or add a custom meal';
        });
      }
    }
  }

  Future<void> _portion([NutritionFoodItemModel? food]) async {
    if (_opening) return;
    setState(() => _opening = true);
    if (widget.onFoodSelected != null) {
      if (food != null) {
        widget.onFoodSelected!(food);
        Navigator.of(context).pop();
      }
      return;
    }
    FocusScope.of(context).unfocus();
    final route = AppPageRoute<bool>(
        builder: (_) => MealPortionView(
            food: food,
            initialMealType: _slot,
            saveMeal: widget.saveMeal,
            date: widget.initialDate));
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    if (!mounted) return;
    setState(() => _opening = false);
    if (saved != true) return;
    widget.onMealAdded();
    Navigator.of(context).pop(true);
  }

  Future<void> _newEntry() async {
    if (_opening) return;
    FocusScope.of(context).unfocus();
    setState(() => _opening = true);
    final route = ModalBottomSheetRoute<NewFoodAction>(
        builder: (_) => const NewFoodSheet(),
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: FitnessTheme.canvas,
        modalBarrierColor: Colors.black54,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: FitnessTheme.line)));
    final action = await Navigator.of(context).push(route);
    await route.completed;
    if (!mounted) return;
    setState(() => _opening = false);
    switch (action) {
      case NewFoodAction.enterNutrition:
        await _portion();
      case NewFoodAction.combineFoods:
        await _createMeal();
      case null:
        break;
    }
  }

  Future<void> _createMeal() async {
    if (_opening) return;
    setState(() => _opening = true);
    final route =
        AppPageRoute<NutritionFoodItemModel>(page: const SavedMealEditorView());
    final food = await Navigator.of(context).push(route);
    await route.completed;
    if (!mounted) return;
    setState(() => _opening = false);
    if (mounted && food != null) await _portion(food);
  }

  void _move(int page) {
    setState(() => _page = page);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _filtered =>
      _category != null ||
      _focus != 'ALL' ||
      _sort != 'NAME' ||
      _source != 'LIBRARY';

  Future<void> _showFilters() async {
    FocusScope.of(context).unfocus();
    final selection = await showModalBottomSheet<FoodFilterSelection>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: FitnessTheme.canvas,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: FitnessTheme.line)),
        builder: (_) => FoodLibraryFilters(
            initial: FoodFilterSelection(_category, _focus, _sort,
                source: _source)));
    if (!mounted || selection == null) return;
    _filter(() {
      _category = selection.category;
      _focus = selection.focus;
      _sort = selection.sort;
      _source = selection.source;
    });
  }

  Widget _toolbar() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: TextField(
        key: const ValueKey('food-search'),
        controller: _search,
        enabled: !_opening,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          unawaited(_load());
        },
        decoration: InputDecoration(
          hintText: fitnessText(context, 'Search foods'),
          hintStyle: const TextStyle(fontSize: 13, color: FitnessTheme.muted),
          filled: true,
          fillColor: const Color(0xFF0D0D0D),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          prefixIcon: const Icon(CupertinoIcons.search,
              size: 18, color: FitnessTheme.muted),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_search.text.isNotEmpty)
              IconButton(
                  tooltip: fitnessText(context, 'Clear search'),
                  onPressed: _search.clear,
                  icon: const Icon(CupertinoIcons.xmark_circle_fill,
                      size: 17, color: FitnessTheme.muted)),
            IconButton(
                key: const ValueKey('food-filters'),
                tooltip: fitnessText(context, 'Filters'),
                onPressed: _opening ? null : _showFilters,
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(CupertinoIcons.slider_horizontal_3,
                      size: 19, color: FitnessTheme.silver),
                  if (_filtered)
                    const Positioned(
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
              borderSide: const BorderSide(color: FitnessTheme.muted)),
        ),
      ));

  Widget _pager() => DecoratedBox(
        decoration: const BoxDecoration(
            color: FitnessTheme.canvas,
            border:
                Border(top: BorderSide(color: FitnessTheme.line, width: .7))),
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Row(children: [
                IconButton(
                    tooltip: fitnessText(context, 'Previous page'),
                    onPressed: !_loading && _error == null && _page > 1
                        ? () => _move(_page - 1)
                        : null,
                    icon: const Icon(CupertinoIcons.chevron_left, size: 17)),
                Expanded(
                    child: Center(
                        heightFactor: 1,
                        child: Semantics(
                          label:
                              '${fitnessText(context, 'Page {page} of {pages}', values: {
                                'page': _page,
                                'pages': _pages
                              })}, ${fitnessText(context, '{count} foods', values: {
                                'count': _total
                              })}',
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                            key: const ValueKey('food-page-selector'),
                            value: _page,
                            dropdownColor: FitnessTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            style: TextStyle(
                                fontSize: 12,
                                color: FitnessTheme.silver,
                                fontFamily: Theme.of(context).platform ==
                                        TargetPlatform.iOS
                                    ? 'CupertinoSystemText'
                                    : 'Inter'),
                            icon: const Padding(
                                padding: EdgeInsetsDirectional.only(start: 8),
                                child: Icon(CupertinoIcons.chevron_down,
                                    size: 10, color: FitnessTheme.muted)),
                            items: [
                              for (var page = 1; page <= _pages; page++)
                                DropdownMenuItem(
                                    value: page, child: Text('$page / $_pages'))
                            ],
                            onChanged: _loading || _error != null
                                ? null
                                : (page) {
                                    if (page != null && page != _page) {
                                      _move(page);
                                    }
                                  },
                          )),
                        ))),
                IconButton(
                    tooltip: fitnessText(context, 'Next page'),
                    onPressed: !_loading && _error == null && _page < _pages
                        ? () => _move(_page + 1)
                        : null,
                    icon: const Icon(CupertinoIcons.chevron_right, size: 17)),
              ]),
            )),
      );

  Widget _empty() => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FitnessText(
                _error == null ? 'No foods found' : 'Could not load foods.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const FitnessText('Retry')),
            ] else if (_filtered || _search.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () {
                    _search.clear();
                    _filter(() {
                      _category = null;
                      _focus = 'ALL';
                      _sort = 'NAME';
                      _source = 'LIBRARY';
                    });
                  },
                  child: const FitnessText('Clear filters')),
            ],
          ]));

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        backgroundColor: FitnessTheme.canvas,
        appBar: AppBar(
            centerTitle: true,
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            title: FitnessText(
                widget.onFoodSelected == null ? 'Add meal' : 'Choose food',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            actions: [
              if (widget.onFoodSelected == null)
                LibraryNewButton(
                    key: const ValueKey('new-food-menu'),
                    label: fitnessText(context, 'New'),
                    onPressed: _opening ? null : _newEntry),
            ]),
        bottomNavigationBar:
            _pages > 1 && MediaQuery.viewInsetsOf(context).bottom == 0
                ? _pager()
                : null,
        body: SafeArea(
            top: false,
            bottom: _pages <= 1,
            child: Column(children: [
              _toolbar(),
              SizedBox(
                  height: 1,
                  child: _loading && _foods.isNotEmpty
                      ? const LinearProgressIndicator(
                          minHeight: 1,
                          color: FitnessTheme.silver,
                          backgroundColor: FitnessTheme.line)
                      : const ColoredBox(color: FitnessTheme.line)),
              Expanded(
                  child: RefreshIndicator(
                onRefresh: _load,
                color: FitnessTheme.silver,
                child: CustomScrollView(
                    key: const ValueKey('food-scroll'),
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      if (_loading && _foods.isEmpty)
                        const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CupertinoActivityIndicator()))
                      else if (_error != null || _foods.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false, child: _empty())
                      else
                        SliverPadding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            sliver: SliverList.builder(
                                itemCount: _foods.length,
                                itemBuilder: (_, index) => FoodLibraryCard(
                                    key: ValueKey(
                                        'food-row-${_foods[index].id}'),
                                    food: _foods[index],
                                    onTap: _loading || _opening
                                        ? null
                                        : () => _portion(_foods[index])))),
                    ]),
              )),
            ])),
      ));
}
