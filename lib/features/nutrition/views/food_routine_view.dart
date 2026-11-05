import 'package:flutter/material.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/food_planning_repository.dart';
import 'meal_portion_view.dart';
import 'saved_meal_editor_view.dart';
import '../../profile/views/ai_sharing_consent.dart';
import '../../profile/repositories/settings_account_repository.dart';

const foodSlots = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];
const foodDays = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY'
];
String foodModeLabel(String mode) => switch (mode) {
      'AI' => 'Suggest meals for me',
      'TRACK' => 'I’ll track myself',
      _ => 'Keep my routine'
    };

class FoodRoutineView extends StatefulWidget {
  const FoodRoutineView({super.key});
  @override
  State<FoodRoutineView> createState() => _FoodRoutineViewState();
}

class _FoodRoutineViewState extends State<FoodRoutineView> {
  List<NutritionFoodItemModel> _meals = [];
  List<Map<String, dynamic>> _routines = [];
  Map<String, dynamic> _settings = {'mode': 'ROUTINE', 'mealSlots': foodSlots};
  bool _loading = true, _busy = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        FoodPlanningRepository.shared.meals(),
        FoodPlanningRepository.shared.routines(),
        FoodPlanningRepository.shared.settings()
      ]);
      if (mounted) {
        setState(() {
          _meals = results[0] as List<NutritionFoodItemModel>;
          _routines = results[1] as List<Map<String, dynamic>>;
          _settings = results[2] as Map<String, dynamic>;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final meal = await Navigator.push<NutritionFoodItemModel>(
        context, AppPageRoute(page: const SavedMealEditorView()));
    if (meal != null) await _load();
  }

  Future<void> _edit([Map<String, dynamic>? routine]) async {
    if (_meals.isEmpty) {
      await _create();
      if (!mounted || _meals.isEmpty) return;
    }
    await Navigator.push<void>(
        context,
        AppPageRoute(
            page: MealRoutineEditorView(meals: _meals, routine: routine)));
    if (mounted) await _load();
  }

  Future<void> _remove(Map<String, dynamic> routine) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const FitnessText('Remove this routine?'),
                content: const FitnessText(
                    'Previously logged meals stay in your diary.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const FitnessText('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const FitnessText('Remove'))
                ]));
    if (yes != true || !mounted) return;
    try {
      await FoodPlanningRepository.shared
          .removeRoutine(routine['id'] as String);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _support() async {
    String mode = _settings['mode'] as String? ?? 'ROUTINE';
    final selected =
        Set<String>.from(_settings['mealSlots'] as List? ?? foodSlots);
    final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
            builder: (sheet, update) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FitnessText('Food support',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      for (final value in ['ROUTINE', 'AI', 'TRACK'])
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: FitnessText(foodModeLabel(value)),
                            subtitle: FitnessText(switch (value) {
                              'AI' =>
                                'Keep your routine and suggest meals for the remaining slots.',
                              'TRACK' =>
                                'Use daily targets and log what you choose.',
                              _ =>
                                'Repeat the meals you saved. Change any day when needed.'
                            }),
                            leading: Icon(mode == value
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off),
                            onTap: () => update(() => mode = value)),
                      const SizedBox(height: 14),
                      const FitnessText('Meal slots'),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          children: foodSlots
                              .map((s) => FilterChip(
                                  selectedColor: const Color(0xFF3B3B3B),
                                  checkmarkColor: Colors.white,
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  label: FitnessText(mealSlotLabel(s)),
                                  selected: selected.contains(s),
                                  onSelected: (on) => update(() {
                                        if (on) {
                                          selected.add(s);
                                        } else if (selected.length > 1) {
                                          selected.remove(s);
                                        }
                                      })))
                              .toList()),
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: () => Navigator.pop(sheet, true),
                          child: const FitnessText('Save food support')),
                    ]))));
    if (result != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await FoodPlanningRepository.shared.saveSettings(mode, selected.toList());
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suggest() async {
    if (_busy) return;
    try {
      if (!await ensureAiSharingConsent(context)) return;
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = 'Preparing food suggestions. Your workouts stay as they are.';
    });
    try {
      final message =
          await FoodPlanningRepository.shared.suggest(DateTime.now());
      if (mounted) setState(() => _notice = message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(title: const FitnessText('Meals & routine')),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const FitnessText('Make eating easier',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const FitnessText(
                  'Save meals you enjoy. Repeat them on your days, then confirm what you actually ate.',
                  style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
              const SizedBox(height: 20),
              FitnessCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text(
                        foodModeLabel(
                            _settings['mode'] as String? ?? 'ROUTINE'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    TextButton(
                        onPressed: _busy || AppDataMode.shared.preview
                            ? null
                            : _support,
                        child: const FitnessText('Change food support')),
                    if (_settings['mode'] == 'AI')
                      OutlinedButton(
                          onPressed: _busy || AppDataMode.shared.preview
                              ? null
                              : _suggest,
                          child: FitnessText(_busy
                              ? 'Preparing suggestions…'
                              : 'Refresh this week’s food')),
                  ])),
              if (_notice != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FitnessText(_notice!,
                        style: const TextStyle(color: FitnessTheme.muted))),
              if (_error != null) ...[
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FitnessText(_error!,
                        style: const TextStyle(color: FitnessTheme.coral))),
                TextButton(onPressed: _load, child: const FitnessText('Retry'))
              ],
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 26),
              Row(children: [
                const Expanded(
                    child: FitnessText('Your routine',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600))),
                TextButton(
                    onPressed:
                        _busy || AppDataMode.shared.preview ? null : _edit,
                    child: const FitnessText('Add routine'))
              ]),
              if (!_loading && _routines.isEmpty)
                const FitnessText(
                    'Choose a saved meal, a meal slot and the days to repeat it.',
                    style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
              for (final routine in _routines)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FitnessCard(
                        child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                                '${(routine['nutrition'] as Map?)?['name'] ?? 'Saved meal'}'),
                            subtitle: Text(
                                '${mealSlotLabel(routine['mealType'] as String)} · ${(routine['days'] as List).map((d) => '$d'.substring(0, 3)).join(', ')}${routine['paused'] == true ? ' · Paused' : ''}'),
                            trailing: PopupMenuButton<String>(
                                onSelected: (v) => v == 'edit'
                                    ? _edit(routine)
                                    : _remove(routine),
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: FitnessText('Edit routine')),
                                      PopupMenuItem(
                                          value: 'remove',
                                          child: FitnessText('Remove routine'))
                                    ])))),
              const SizedBox(height: 26),
              const FitnessText('My meals',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: AppDataMode.shared.preview ? null : _create,
                  icon: const Icon(Icons.add),
                  label: const FitnessText('Create meal · no photo needed')),
              for (final meal in _meals)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FitnessCard(
                        child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.restaurant_outlined),
                            title: Text(meal.name),
                            subtitle: Text(
                                '${meal.caloriesPerServing.round()} kcal · ${meal.proteinPerServing.toStringAsFixed(1)} g protein per portion'),
                            onTap: AppDataMode.shared.preview
                                ? null
                                : () async {
                                    await Navigator.push(
                                        context,
                                        AppPageRoute(
                                            page: MealPortionView(food: meal)));
                                    if (mounted) await _load();
                                  }))),
              if (!_loading && _meals.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: FitnessText(
                        'Build a meal from foods, or enter the nutrition for your own meal.',
                        style: TextStyle(color: FitnessTheme.muted))),
              const SizedBox(height: 32),
            ])),
      ));
}

class MealRoutineEditorView extends StatefulWidget {
  final List<NutritionFoodItemModel> meals;
  final Map<String, dynamic>? routine;
  final Future<void> Function(Map<String, dynamic>)? save;
  const MealRoutineEditorView(
      {super.key, required this.meals, this.routine, this.save});
  @override
  State<MealRoutineEditorView> createState() => _MealRoutineEditorViewState();
}

class _MealRoutineEditorViewState extends State<MealRoutineEditorView> {
  late String _food, _slot;
  late Set<String> _days;
  late DateTime _start;
  final _servings = TextEditingController();
  bool _paused = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _food = widget.meals.any((m) => m.id == r?['nutritionId'])
        ? r!['nutritionId'] as String
        : widget.meals.first.id;
    _slot = r?['mealType'] as String? ?? 'BREAKFAST';
    _days = Set<String>.from(r?['days'] as List? ?? []);
    _start =
        DateTime.tryParse(r?['startsOn'] as String? ?? '') ?? DateTime.now();
    _paused = r?['paused'] == true;
    _servings.text = '${r?['servings'] ?? 1}';
  }

  @override
  void dispose() {
    _servings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = inputNumber(_servings.text);
    if (_days.isEmpty || amount == null || amount <= 0 || amount > 100) {
      setState(() =>
          _error = 'Choose at least one day and a valid number of portions.');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = {
      'nutritionId': _food,
      'mealType': _slot,
      'days': _days.toList(),
      'servings': amount,
      'startsOn': CacheScope.todayKey(_start),
      'paused': _paused
    };
    try {
      if (widget.save != null) {
        await widget.save!(data);
      } else {
        await FoodPlanningRepository.shared
            .saveRoutine(data, id: widget.routine?['id'] as String?);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
            title: FitnessText(
                widget.routine == null ? 'Add routine' : 'Edit routine')),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: FitnessSubmit(
                    label: 'Save routine', busy: _busy, onPressed: _save))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const FitnessText('Your usual meal',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
              initialValue: _food,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Saved meal'),
              items: widget.meals
                  .map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _food = v!)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              initialValue: _slot,
              decoration: const InputDecoration(labelText: 'Meal slot'),
              items: foodSlots
                  .map((s) => DropdownMenuItem(
                      value: s, child: FitnessText(mealSlotLabel(s))))
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _slot = v!)),
          const SizedBox(height: 16),
          FitnessInput(label: 'Portions', controller: _servings, numeric: true),
          const SizedBox(height: 24),
          const FitnessText('Repeat each week on'),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 6,
              children: foodDays
                  .map((d) => FilterChip(
                      selectedColor: const Color(0xFF3B3B3B),
                      checkmarkColor: Colors.white,
                      labelStyle: const TextStyle(color: Colors.white),
                      label: FitnessText(d.substring(0, 3)),
                      selected: _days.contains(d),
                      onSelected: _busy
                          ? null
                          : (on) => setState(
                              () => on ? _days.add(d) : _days.remove(d))))
                  .toList()),
          const SizedBox(height: 16),
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: const FitnessText('Starts on'),
              subtitle: Text(CacheScope.todayKey(_start)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: _start,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (mounted && picked != null) {
                        setState(() => _start = picked);
                      }
                    }),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const FitnessText('Pause routine'),
              value: _paused,
              onChanged: _busy ? null : (v) => setState(() => _paused = v)),
          const SizedBox(height: 12),
          const FitnessText(
              'This schedules a meal. Only confirming it in Nutrition adds it to your daily intake.',
              style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FitnessText(_error!,
                    style: const TextStyle(color: FitnessTheme.coral))),
        ]),
      ));
}
