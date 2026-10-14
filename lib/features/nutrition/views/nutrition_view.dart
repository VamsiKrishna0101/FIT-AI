import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import 'food_library_view.dart';
import '../components/food_detail_sheet.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';

class NutritionView extends StatefulWidget {
  final TodayDietPlanModel? initial;
  final DateTime? date;
  const NutritionView({super.key, this.initial, this.date});
  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  TodayDietPlanModel? _plan;
  StreamSubscription<TodayDietPlanModel?>? _updates;
  bool _loading = true, _failed = false, _waterBusy = false;
  int _request = 0;
  bool get _readOnly =>
      widget.date != null && !DateUtils.isSameDay(widget.date, DateTime.now());
  @override
  void initState() {
    super.initState();
    _plan = widget.initial ??
        (_readOnly ? null : NutritionRepository.shared.currentPlan);
    if (widget.initial != null) {
      _loading = false;
      return;
    }
    _updates = NutritionRepository.shared.dietPlanStream.listen((plan) {
      if (mounted && !_readOnly && plan != null) {
        setState(() {
          _plan = plan;
          _loading = false;
          _failed = false;
        });
      }
    });
    AppDataMode.shared.addListener(_modeChanged);
    _load();
  }

  void _modeChanged() {
    setState(() => _plan = null);
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    setState(() {
      _loading = _plan == null;
      _failed = false;
    });
    try {
      final plan = await NutritionRepository.shared
          .loadDate(widget.date ?? DateTime.now(), forceRefresh: refresh);
      if (mounted && request == _request) {
        setState(() {
          _plan = plan;
          _failed = plan == null;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _add([String slot = 'LUNCH']) {
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => FoodLibraryView(
            initialMealType: slot, onMealAdded: () => _load(refresh: true))));
  }

  void _detail(UserMealLogItemModel meal) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FitnessTheme.canvas,
        showDragHandle: true,
        builder: (_) => FoodDetailSheet(
            mealLog: meal, onUpdated: () => _load(refresh: true)));
  }

  Future<void> _water(int ml) async {
    setState(() => _waterBusy = true);
    final ok = await NutritionRepository.shared.logWater(ml);
    if (!mounted) return;
    setState(() => _waterBusy = false);
    if (ok) {
      await _load(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: FitnessText('Could not save. Try again.')));
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    AppDataMode.shared.removeListener(_modeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            title: const FitnessText('Nutrition',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
        bottomNavigationBar: _readOnly
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    child: FitnessSubmit(
                        label: 'Add meal', onPressed: () => _add()))),
        body: RefreshIndicator(
            color: FitnessTheme.silver,
            onRefresh: () => _load(refresh: true),
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                            DateFormat.MMMMEEEEd(Localizations.localeOf(context)
                                    .toLanguageTag())
                                .format(widget.date ?? DateTime.now()),
                            style: const TextStyle(
                                color: FitnessTheme.muted, fontSize: 12))),
                  ]),
                  const SizedBox(height: 20),
                  if (_failed)
                    FitnessCard(
                        child: Row(children: [
                      const Expanded(
                          child: FitnessText('Could not load nutrition.',
                              style: TextStyle(
                                  color: FitnessTheme.muted, fontSize: 13))),
                      TextButton(
                          onPressed: () => _load(refresh: true),
                          child: const FitnessText('Retry')),
                    ])),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(child: CupertinoActivityIndicator()))
                  else if (_plan case final plan?) ...[
                    _EnergyCard(plan: plan),
                    const SizedBox(height: 16),
                    _Macros(plan: plan),
                    const SizedBox(height: 16),
                    FitnessCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            const Icon(CupertinoIcons.drop,
                                color: Color(0xFF72D9ED), size: 21),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: FitnessText('Water',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500))),
                            Text(
                                '${(plan.waterConsumed / 1000).toStringAsFixed(2)} L',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -.5)),
                            if (plan.waterTarget > 0)
                              Text(
                                  ' / ${(plan.waterTarget / 1000).toStringAsFixed(1)} L',
                                  style: const TextStyle(
                                      color: FitnessTheme.muted, fontSize: 12)),
                          ]),
                          const SizedBox(height: 15),
                          _ThinBar(
                              value: plan.waterProgress,
                              color: const Color(0xFF72D9ED)),
                          if (!_readOnly) ...[
                            const SizedBox(height: 13),
                            Row(children: [
                              for (final ml in [250, 500])
                                Expanded(
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: OutlinedButton(
                                            onPressed: _waterBusy
                                                ? null
                                                : () => _water(ml),
                                            style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF2C2C2C),
                                                side: BorderSide.none,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12))),
                                            child: _waterBusy
                                                ? const CupertinoActivityIndicator()
                                                : Text('+ $ml ml',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.white))))),
                            ]),
                          ],
                        ])),
                    const SizedBox(height: 26),
                    const FitnessText('Your meals',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.5)),
                    const SizedBox(height: 12),
                    for (final slot in [
                      'BREAKFAST',
                      'LUNCH',
                      'DINNER',
                      'SNACK'
                    ]) ...[
                      _MealGroup(
                          slot: slot,
                          meals: plan.logs
                              .where((meal) => slot == 'SNACK'
                                  ? !['BREAKFAST', 'LUNCH', 'DINNER']
                                      .contains(meal.mealType)
                                  : meal.mealType == slot)
                              .toList(),
                          preview: _readOnly,
                          onAdd: () => _add(slot),
                          onDetail: _detail),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    const FitnessText(
                        'Targets are estimated from your profile. Logged portions update your totals.',
                        style: TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 12,
                            height: 1.5)),
                  ],
                ])),
      ));
}

class _EnergyCard extends StatelessWidget {
  final TodayDietPlanModel plan;
  const _EnergyCard({required this.plan});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: DSColors.bgCard,
          border: Border.all(color: const Color(0x18FFFFFF), width: .7)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FitnessText('Daily intake',
            style: TextStyle(color: FitnessTheme.muted, fontSize: 13)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(plan.caloriesConsumed.round().toString(),
              style: const TextStyle(
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.8)),
          const Padding(
              padding: EdgeInsets.only(left: 7, bottom: 4),
              child: FitnessText('kcal',
                  style: TextStyle(fontSize: 14, color: FitnessTheme.muted))),
        ]),
        const SizedBox(height: 21),
        _ThinBar(value: plan.calorieProgress, color: FitnessTheme.silver),
        const SizedBox(height: 13),
        Row(children: [
          const Expanded(
              child: FitnessText('Profile target',
                  style: TextStyle(color: FitnessTheme.muted, fontSize: 12))),
          Text(
              plan.caloriesTarget > 0
                  ? '${plan.caloriesTarget.round()} kcal'
                  : '—',
              style: const TextStyle(fontSize: 13)),
        ]),
      ]));
}

class _Macros extends StatelessWidget {
  final TodayDietPlanModel plan;
  const _Macros({required this.plan});
  @override
  Widget build(BuildContext context) => FitnessCard(
          child: Row(children: [
        for (final (index, label, value, target, progress, color) in [
          (
            0,
            'Protein',
            plan.proteinConsumed,
            plan.proteinTarget,
            plan.proteinProgress,
            const Color(0xFF6AA9FF)
          ),
          (
            1,
            'Carbs',
            plan.carbsConsumed,
            plan.carbsTarget,
            plan.carbsProgress,
            const Color(0xFFB29AF7)
          ),
          (
            2,
            'Fat',
            plan.fatConsumed,
            plan.fatTarget,
            plan.fatProgress,
            const Color(0xFFEBC487)
          ),
        ]) ...[
          if (index > 0) const SizedBox(width: 18),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText(label,
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 12)),
                const SizedBox(height: 9),
                Text('${value.round()} g',
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.4)),
                const SizedBox(height: 10),
                _ThinBar(value: progress, color: color),
                const SizedBox(height: 6),
                Text(target > 0 ? '/ ${target.round()} g' : '—',
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 11)),
              ])),
        ],
      ]));
}

class _ThinBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ThinBar({required this.value, required this.color});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
          value: value,
          minHeight: 4,
          color: color,
          backgroundColor: const Color(0xFF383838)));
}

class _MealGroup extends StatelessWidget {
  final String slot;
  final List<UserMealLogItemModel> meals;
  final bool preview;
  final VoidCallback onAdd;
  final ValueChanged<UserMealLogItemModel> onDetail;
  const _MealGroup(
      {required this.slot,
      required this.meals,
      required this.preview,
      required this.onAdd,
      required this.onDetail});
  String get label => switch (slot) {
        'BREAKFAST' => 'Breakfast',
        'LUNCH' => 'Lunch',
        'DINNER' => 'Dinner',
        _ => 'Snacks'
      };
  IconData get icon => switch (slot) {
        'BREAKFAST' => CupertinoIcons.sunrise,
        'LUNCH' => CupertinoIcons.sun_max,
        'DINNER' => CupertinoIcons.moon,
        _ => CupertinoIcons.leaf_arrow_circlepath
      };
  @override
  Widget build(BuildContext context) => FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: FitnessTheme.muted),
          const SizedBox(width: 10),
          Expanded(
              child: FitnessText(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
          if (!preview)
            IconButton(
                onPressed: onAdd,
                tooltip: 'Add meal',
                icon: const Icon(CupertinoIcons.add, size: 19),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero),
        ]),
        if (meals.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: FitnessText('Nothing logged yet',
                  style: TextStyle(color: FitnessTheme.muted, fontSize: 12))),
        for (final meal in meals)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InkWell(
                  onTap: () => onDetail(meal),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(meal.food.name,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4)),
                              const SizedBox(height: 4),
                              Text(
                                  '${meal.protein.round()} g · ${meal.carbs.round()} g · ${meal.fat.round()} g',
                                  style: const TextStyle(
                                      color: FitnessTheme.muted, fontSize: 11)),
                            ])),
                        const SizedBox(width: 12),
                        Text('${meal.calories.round()}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right,
                            color: FitnessTheme.muted, size: 12),
                      ]))),
      ]));
}
