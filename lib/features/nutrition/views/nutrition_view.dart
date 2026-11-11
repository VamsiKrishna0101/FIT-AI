import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_motion.dart';
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
import '../components/planned_meals_section.dart';
import '../components/nutrition_summary_card.dart';
import '../components/nutrition_meal_diary.dart';
import '../../../core/localization/fitness_copy.dart';

class NutritionView extends StatefulWidget {
  final TodayDietPlanModel? initial;
  final DateTime? date;
  final bool openAddMeal;
  final Future<Map<String, dynamic>> Function()? plannedMealsLoader;
  const NutritionView(
      {super.key,
      this.initial,
      this.date,
      this.openAddMeal = false,
      this.plannedMealsLoader});
  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  TodayDietPlanModel? _plan;
  StreamSubscription<TodayDietPlanModel?>? _updates;
  bool _loading = true, _failed = false;
  int _request = 0, _planRevision = 0;
  bool _showPlan = false, _planVisited = false;
  bool get _readOnly =>
      widget.date != null && !DateUtils.isSameDay(widget.date, DateTime.now());
  @override
  void initState() {
    super.initState();
    if (widget.openAddMeal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_readOnly) _add();
      });
    }
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
    if (!mounted || _readOnly) return;
    Navigator.of(context).push(AppPageRoute(
        builder: (_) => FoodLibraryView(
            initialMealType: slot, onMealAdded: () => _load(refresh: true))));
  }

  void _detail(UserMealLogItemModel meal) {
    showModalBottomSheet<void>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FitnessTheme.canvas,
        showDragHandle: true,
        builder: (_) => FoodDetailSheet(
            mealLog: meal,
            readOnly: _readOnly,
            onUpdated: () => _load(refresh: true)));
  }

  @override
  void dispose() {
    _updates?.cancel();
    AppDataMode.shared.removeListener(_modeChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    await _load(refresh: true);
    if (mounted) setState(() => _planRevision++);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const FitnessText('Nutrition',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
          bottomNavigationBar: _readOnly
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                      color: FitnessTheme.canvas,
                      border: Border(
                          top:
                              BorderSide(color: Color(0xFF222222), width: .5))),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                      child: FitnessSubmit(
                          label: 'Add meal', onPressed: () => _add()),
                    ),
                  ),
                ),
          body: RefreshIndicator(
            color: FitnessTheme.silver,
            backgroundColor: FitnessTheme.surface,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              children: [
                _DateHeading(
                    date: widget.date ?? DateTime.now(), readOnly: _readOnly),
                const SizedBox(height: 18),
                if (_failed) ...[
                  FitnessCard(
                    child: Row(children: [
                      const Expanded(
                        child: FitnessText('Could not load nutrition',
                            style: TextStyle(
                                color: FitnessTheme.muted, fontSize: 13)),
                      ),
                      TextButton(
                          onPressed: _refresh,
                          child: const FitnessText('Retry')),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CupertinoActivityIndicator()))
                else if (_plan case final plan?) ...[
                  NutritionSummaryCard(
                    calories: plan.caloriesConsumed,
                    calorieTarget: plan.caloriesTarget,
                    protein: plan.proteinConsumed,
                    proteinTarget: plan.proteinTarget,
                    carbs: plan.carbsConsumed,
                    carbTarget: plan.carbsTarget,
                    fat: plan.fatConsumed,
                    fatTarget: plan.fatTarget,
                    fiber: plan.fiberConsumed,
                  ),
                  const SizedBox(height: 22),
                  _NutritionTabs(
                    showPlan: _showPlan,
                    onChanged: (value) => setState(() {
                      _showPlan = value;
                      _planVisited |= value;
                    }),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    duration: DSMotion.duration(context, DSMotion.regular),
                    firstCurve: DSMotion.standard,
                    secondCurve: DSMotion.standard,
                    sizeCurve: DSMotion.standard,
                    alignment: Alignment.topCenter,
                    crossFadeState: _showPlan
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: NutritionMealDiary(
                      key: const ValueKey('nutrition-diary'),
                      logs: plan.logs,
                      readOnly: _readOnly,
                      onAdd: _add,
                      onDetail: _detail,
                    ),
                    // Keep submissions and their busy state alive across tabs.
                    secondChild: _planVisited
                        ? PlannedMealsSection(
                            key: ValueKey(
                                'planned-${DateUtils.dateOnly(widget.date ?? DateTime.now())}'),
                            refreshVersion: _planRevision,
                            date: widget.date ?? DateTime.now(),
                            loader: widget.plannedMealsLoader,
                            onChanged: () => _load(refresh: true),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.date, required this.readOnly});
  final DateTime date;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          FitnessText(readOnly ? 'Recorded intake' : 'Today',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.6)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              DateFormat.yMMMEd(Localizations.localeOf(context).toLanguageTag())
                  .format(date),
              style: const TextStyle(color: FitnessTheme.muted, fontSize: 11),
            ),
            if (readOnly) ...[
              const SizedBox(height: 4),
              const FitnessText('Read-only',
                  style: TextStyle(color: FitnessTheme.muted, fontSize: 10)),
            ],
          ]),
        ],
      );
}

class _NutritionTabs extends StatelessWidget {
  const _NutritionTabs({required this.showPlan, required this.onChanged});
  final bool showPlan;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xFF111111),
            border: Border.all(color: const Color(0xFF252525), width: .7),
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            for (final (label, isPlan) in const [
              ('Diary', false),
              ('Meal plan', true)
            ])
              Expanded(
                child: Semantics(
                  selected: showPlan == isPlan,
                  button: true,
                  label: fitnessText(context, label),
                  onTap: () => onChanged(isPlan),
                  excludeSemantics: true,
                  child: Tooltip(
                    message: fitnessText(context, label),
                    child: AnimatedContainer(
                      duration: DSMotion.duration(context, DSMotion.selection),
                      curve: DSMotion.standard,
                      decoration: BoxDecoration(
                          color: showPlan == isPlan
                              ? const Color(0xFF303030)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onChanged(isPlan),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: FitnessText(label,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                        color: showPlan == isPlan
                                            ? FitnessTheme.silver
                                            : FitnessTheme.muted)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}
