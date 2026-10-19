import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/food_art.dart';
import '../models/food_catalog_page.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';
import 'food_preferences_view.dart';
import 'meal_portion_view.dart';

typedef FoodPageLoader = Future<FoodCatalogPage> Function(int page,
    String search, String? category, String focus, String sort, String source);

class FoodLibraryView extends StatefulWidget {
  final String initialMealType;
  final VoidCallback onMealAdded;
  final List<NutritionFoodItemModel>? initialFoods;
  final FoodPageLoader? pageLoader;
  final Future<bool> Function(Map<String, dynamic>)? saveMeal;
  const FoodLibraryView(
      {super.key,
      required this.onMealAdded,
      this.initialMealType = 'LUNCH',
      this.initialFoods,
      this.pageLoader,
      this.saveMeal});
  @override
  State<FoodLibraryView> createState() => _FoodLibraryViewState();
}

class _FoodLibraryViewState extends State<FoodLibraryView> {
  final _search = TextEditingController(), _scroll = ScrollController();
  Timer? _debounce;
  List<NutritionFoodItemModel> _foods = [];
  String? _category, _error;
  String _focus = 'ALL', _sort = 'NAME', _source = 'LIBRARY';
  late String _slot;
  int _page = 1, _total = 0, _pages = 0, _request = 0;
  bool _loading = true;
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

  void _filter(VoidCallback change) {
    _debounce?.cancel();
    setState(() {
      change();
      _page = 1;
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      FoodCatalogPage result;
      if (widget.initialFoods != null) {
        final terms = _search.text
            .trim()
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty);
        final filtered = widget.initialFoods!.where((f) {
          final per100 = f.servingUnit == 'g' && f.servingSize > 0
              ? 100 / f.servingSize
              : 0.0;
          final text = '${f.name} ${f.brand ?? ''}'.toLowerCase();
          return (_category == null || _category == f.category) &&
              terms.every(text.contains) &&
              (_focus == 'ALL' ||
                  per100 > 0 &&
                      switch (_focus) {
                        'PROTEIN' => f.proteinPerServing * per100 >= 15,
                        'FIBRE' => f.fiberPerServing * per100 >= 3,
                        _ => f.caloriesPerServing * per100 <= 100,
                      });
        }).toList();
        double value(NutritionFoodItemModel f) => f.servingUnit == 'g' &&
                f.servingSize > 0
            ? (_sort == 'PROTEIN'
                    ? f.proteinPerServing
                    : f.caloriesPerServing) *
                100 /
                f.servingSize
            : (_sort == 'PROTEIN' ? double.negativeInfinity : double.infinity);
        filtered.sort((a, b) {
          final comparison = _sort == 'NAME'
              ? 0
              : _sort == 'PROTEIN'
                  ? value(b).compareTo(value(a))
                  : value(a).compareTo(value(b));
          return comparison != 0 ? comparison : a.name.compareTo(b.name);
        });
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
      setState(() {
        _foods = result.foods;
        _page = result.page;
        _total = result.total;
        _pages = result.totalPages;
        _loading = false;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load foods. Retry or add a custom meal.';
        });
      }
    }
  }

  Future<void> _portion([NutritionFoodItemModel? food]) async {
    FocusScope.of(context).unfocus();
    final saved = await Navigator.of(context).push<bool>(CupertinoPageRoute(
        builder: (_) => MealPortionView(
            food: food, initialMealType: _slot, saveMeal: widget.saveMeal)));
    if (!mounted || saved != true) return;
    widget.onMealAdded();
    Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          appBar: AppBar(
              backgroundColor: FitnessTheme.canvas,
              surfaceTintColor: Colors.transparent,
              title: const FitnessText('Add meal',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              actions: [
                TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                            builder: (_) => const FoodPreferencesView())),
                    icon: const Icon(CupertinoIcons.slider_horizontal_3,
                        size: 17),
                    label: const FitnessText('Preferences',
                        style: TextStyle(fontSize: 12))),
                const SizedBox(width: 8)
              ]),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: FitnessTheme.line))),
                  child: Row(children: [
                    IconButton(
                        tooltip: fitnessText(context, 'Previous page'),
                        onPressed: !_loading && _error == null && _page > 1
                            ? () => _move(_page - 1)
                            : null,
                        icon:
                            const Icon(CupertinoIcons.chevron_left, size: 18)),
                    Expanded(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      FitnessText('Page {page} of {pages}',
                          values: {
                            'page': _pages == 0 ? 0 : _page,
                            'pages': _pages
                          },
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 3),
                      const FitnessText('24 foods per page',
                          style: TextStyle(
                              fontSize: 10, color: FitnessTheme.muted)),
                    ])),
                    IconButton(
                        tooltip: fitnessText(context, 'Next page'),
                        onPressed: !_loading && _error == null && _page < _pages
                            ? () => _move(_page + 1)
                            : null,
                        icon:
                            const Icon(CupertinoIcons.chevron_right, size: 18))
                  ]))),
          body: RefreshIndicator(
              onRefresh: _load,
              color: FitnessTheme.silver,
              child: CustomScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                        sliver: SliverToBoxAdapter(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const FitnessText('Everyday food.\nMade simple.',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                      letterSpacing: -.9)),
                              const SizedBox(height: 10),
                              const FitnessText(
                                  'Eggs, milk, oats and the foods you eat every day.',
                                  style: TextStyle(
                                      fontSize: 13, color: FitnessTheme.muted)),
                              const SizedBox(height: 20),
                              Wrap(spacing: 5, runSpacing: 5, children: [
                                for (final s in [
                                  'BREAKFAST',
                                  'LUNCH',
                                  'DINNER',
                                  'SNACK'
                                ])
                                  ChoiceChip(
                                      labelPadding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      visualDensity: VisualDensity.compact,
                                      label: FitnessText(mealSlotLabel(s),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: _slot == s
                                                  ? Colors.white
                                                  : FitnessTheme.muted)),
                                      selected: _slot == s,
                                      showCheckmark: false,
                                      selectedColor: const Color(0xFF3B3B3B),
                                      side: BorderSide(
                                          color: _slot == s
                                              ? Colors.white30
                                              : FitnessTheme.line),
                                      onSelected: (_) =>
                                          setState(() => _slot = s))
                              ]),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _search,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                      hintText:
                                          fitnessText(context, 'Search foods'),
                                      prefixIcon: const Icon(
                                          CupertinoIcons.search,
                                          size: 19),
                                      suffixIcon: _search.text.isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: fitnessText(
                                                  context, 'Clear search'),
                                              onPressed: _search.clear,
                                              icon: const Icon(
                                                  CupertinoIcons
                                                      .xmark_circle_fill,
                                                  size: 18)))),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(children: [
                                    for (final entry in const {
                                      'LIBRARY': 'Everyday',
                                      'RECENT': 'Recent',
                                      'MY_FOODS': 'My foods',
                                      'MY_MEALS': 'My meals',
                                    }.entries)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                              selectedColor:
                                                  const Color(0xFF3B3B3B),
                                              side: BorderSide(
                                                  color: _source == entry.key
                                                      ? Colors.white30
                                                      : FitnessTheme.line),
                                              labelPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 2),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              label: FitnessText(entry.value,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          _source == entry.key
                                                              ? Colors.white
                                                              : FitnessTheme
                                                                  .muted)),
                                              selected: _source == entry.key,
                                              showCheckmark: false,
                                              onSelected: (_) => _filter(() {
                                                    _source = entry.key;
                                                    _category = null;
                                                  }))),
                                  ])),
                              const SizedBox(height: 12),
                              const SizedBox(height: 18),
                              Row(children: [
                                Expanded(
                                    child: FitnessText('{count} foods',
                                        values: {'count': _total},
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted))),
                                IconButton(
                                    tooltip: fitnessText(context, 'Filters'),
                                    onPressed: _showFilters,
                                    icon: const Icon(
                                        CupertinoIcons.slider_horizontal_3,
                                        size: 19)),
                                TextButton.icon(
                                    onPressed: () => _portion(),
                                    icon: const Icon(CupertinoIcons.plus,
                                        size: 15),
                                    label: const FitnessText('Create food',
                                        style: TextStyle(fontSize: 12)))
                              ]),
                            ]))),
                    if (_loading)
                      const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(40),
                              child:
                                  Center(child: CupertinoActivityIndicator())))
                    else if (_error != null)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(children: [
                                FitnessText(_error!,
                                    style: const TextStyle(
                                        color: FitnessTheme.muted,
                                        fontSize: 13)),
                                TextButton(
                                    onPressed: _load,
                                    child: const FitnessText('Retry'))
                              ])))
                    else if (_foods.isEmpty)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 40),
                              child: Column(children: [
                                const Icon(CupertinoIcons.search,
                                    size: 30, color: FitnessTheme.muted),
                                const SizedBox(height: 16),
                                const FitnessText('No foods found',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(height: 8),
                                FitnessText(
                                    switch (_source) {
                                      'MY_FOODS' =>
                                        'Create a food once, then reuse it here.',
                                      'MY_MEALS' =>
                                        'Save a custom entry as a meal to reuse it here.',
                                      'RECENT' =>
                                        'Foods you have logged will appear here.',
                                      _ =>
                                        'Try another search or clear your filters.',
                                    },
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted)),
                                TextButton(
                                    onPressed: () {
                                      _search.clear();
                                      _filter(() {
                                        _category = null;
                                        _focus = 'ALL';
                                      });
                                    },
                                    child: const FitnessText('Clear filters')),
                              ])))
                    else
                      SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                          sliver: SliverList.builder(
                              itemCount: _foods.length,
                              itemBuilder: (context, index) {
                                final food = _foods[index];
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                        color: FitnessTheme.surface,
                                        borderRadius: BorderRadius.circular(22),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                            onTap: () => _portion(food),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Row(children: [
                                                  FoodArt(food: food, size: 52),
                                                  const SizedBox(width: 13),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        Text(food.name,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                height: 1.35)),
                                                        const SizedBox(
                                                            height: 6),
                                                        Text(
                                                            '${foodPortionLabel(context, food)} · ${(food.caloriesPerServing * food.previewFactor).round()} kcal',
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    FitnessTheme
                                                                        .muted)),
                                                        const SizedBox(
                                                            height: 4),
                                                        FitnessText(
                                                            '{amount} g protein',
                                                            values: {
                                                              'amount': (food
                                                                          .proteinPerServing *
                                                                      food
                                                                          .previewFactor)
                                                                  .toStringAsFixed(
                                                                      1)
                                                            },
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Color(
                                                                    0xFFC4B7A8))),
                                                      ])),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                      CupertinoIcons
                                                          .chevron_right,
                                                      size: 13,
                                                      color: FitnessTheme.muted)
                                                ])))));
                              })),
                  ]))));
  Future<void> _showFilters() async {
    var category = _category;
    var focus = _focus;
    var sort = _sort;
    final apply = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: FitnessTheme.surface,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
            builder: (context, change) => SafeArea(
                top: false,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FitnessText('Find your food',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          _dropdown(
                              'Food type',
                              category ?? 'ALL',
                              {'ALL': 'All foods', ...foodCategories},
                              (value) => change(() =>
                                  category = value == 'ALL' ? null : value)),
                          const SizedBox(height: 16),
                          _dropdown(
                              'Nutrition focus',
                              focus,
                              const {
                                'ALL': 'Any nutrition',
                                'PROTEIN': 'Higher protein',
                                'FIBRE': 'More fibre',
                                'LIGHTER': 'Lighter foods'
                              },
                              (value) => change(() => focus = value)),
                          const SizedBox(height: 16),
                          _dropdown(
                              'Sort by',
                              sort,
                              const {
                                'NAME': 'Name A–Z',
                                'PROTEIN': 'Most protein',
                                'CALORIES': 'Fewest calories'
                              },
                              (value) => change(() => sort = value)),
                          if (focus != 'ALL')
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: FitnessText(
                                    switch (focus) {
                                      'PROTEIN' =>
                                        'At least 15 g protein per 100 g.',
                                      'FIBRE' =>
                                        'At least 3 g fibre per 100 g.',
                                      _ => 'Up to 100 kcal per 100 g.',
                                    },
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))),
                          const SizedBox(height: 24),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const FitnessText('Apply filters'))),
                          Center(
                              child: TextButton(
                                  onPressed: () => change(() {
                                        category = null;
                                        focus = 'ALL';
                                        sort = 'NAME';
                                      }),
                                  child: const FitnessText('Clear filters'))),
                        ])))));
    if (apply == true && mounted) {
      _filter(() {
        _category = category;
        _focus = focus;
        _sort = sort;
      });
    }
  }

  Widget _dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> changed) =>
      DropdownButtonFormField<String>(
          key: ValueKey('$label:$value'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: fitnessText(context, label),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelStyle: const TextStyle(fontSize: 11)),
          dropdownColor: FitnessTheme.surface,
          items: options.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: FitnessText(e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) {
            if (v != null) changed(v);
          });
}
