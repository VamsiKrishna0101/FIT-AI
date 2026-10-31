import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import 'food_art.dart';

const foodSources = {
  'LIBRARY': 'Food library',
  'RECENT': 'Recent',
  'MY_FOODS': 'My foods',
  'MY_MEALS': 'My meals'
};
const foodFocusOptions = {
  'ALL': 'Any nutrition',
  'PROTEIN': 'Higher protein',
  'FIBRE': 'More fibre',
  'LIGHTER': 'Lighter foods'
};
const foodSortOptions = {
  'NAME': 'Name A–Z',
  'PROTEIN': 'Most protein',
  'CALORIES': 'Fewest calories'
};

class FoodFilterSelection {
  const FoodFilterSelection(this.category, this.focus, this.sort,
      {this.source = 'LIBRARY'});
  final String? category;
  final String focus, sort;
  final String source;
}

class FoodLibraryFilters extends StatefulWidget {
  const FoodLibraryFilters({super.key, required this.initial});
  final FoodFilterSelection initial;
  @override
  State<FoodLibraryFilters> createState() => _FoodLibraryFiltersState();
}

class _FoodLibraryFiltersState extends State<FoodLibraryFilters> {
  late String? _category = widget.initial.category;
  late String _focus = widget.initial.focus, _sort = widget.initial.sort;
  late String _source = widget.initial.source;

  Widget _dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> changed) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FitnessText(label,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('food-filter-$label-$value'),
          initialValue: value,
          isExpanded: true,
          dropdownColor: FitnessTheme.surface,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(CupertinoIcons.chevron_down,
              size: 12, color: FitnessTheme.silver),
          decoration: InputDecoration(
              filled: true,
              fillColor: FitnessTheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: FitnessTheme.line, width: .7)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: FitnessTheme.line, width: .7)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
          style: TextStyle(
              fontSize: 14,
              color: FitnessTheme.silver,
              fontFamily: Theme.of(context).platform == TargetPlatform.iOS
                  ? 'CupertinoSystemText'
                  : 'Inter'),
          items: options.entries
              .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: FitnessText(entry.value,
                      maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => changed(value));
          },
        )
      ]);

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 18, end: 8),
                    child: Row(children: [
                      const Expanded(
                          child: FitnessText('Filters',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -.5))),
                      CloseButton(onPressed: () => Navigator.pop(context)),
                    ])),
                Flexible(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _dropdown('Show', _source, foodSources, (value) {
                                _source = value;
                                _category = null;
                              }),
                              const SizedBox(height: 18),
                              _dropdown(
                                  'Food type',
                                  _category ?? 'ALL',
                                  {'ALL': 'All categories', ...foodCategories},
                                  (value) => _category =
                                      value == 'ALL' ? null : value),
                              const SizedBox(height: 18),
                              _dropdown('Nutrition focus', _focus,
                                  foodFocusOptions, (value) => _focus = value),
                              const SizedBox(height: 18),
                              _dropdown('Sort by', _sort, foodSortOptions,
                                  (value) => _sort = value),
                            ]))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                              onPressed: () => Navigator.pop(
                                  context,
                                  FoodFilterSelection(_category, _focus, _sort,
                                      source: _source)),
                              style: FilledButton.styleFrom(
                                  backgroundColor: FitnessTheme.silver,
                                  foregroundColor: FitnessTheme.canvas,
                                  minimumSize: const Size(double.infinity, 50),
                                  padding: const EdgeInsets.all(14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const FitnessText('Apply filters',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600))),
                          TextButton(
                              onPressed: () => setState(() {
                                    _category = null;
                                    _source = 'LIBRARY';
                                    _focus = 'ALL';
                                    _sort = 'NAME';
                                  }),
                              child: const FitnessText('Clear filters',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: FitnessTheme.muted))),
                        ])),
              ]),
        ),
      ));
}
