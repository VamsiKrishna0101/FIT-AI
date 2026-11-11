import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/lifestyle_nutrition_models.dart';
import '../components/onboarding_scaffold.dart';
import '../components/nutrition_budget_controls.dart';
import '../viewmodels/lifestyle_nutrition_viewmodel.dart';
import '../../auth/views/auth_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/navigation/prepare_authenticated_home.dart';
import '../components/onboarding_coach.dart';
import '../components/welcome_buddies.dart';

class _FoodItem {
  final String key;
  final String emoji;
  final String title;
  final String subtitle;

  const _FoodItem({
    required this.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

const omnivoreProteinStaples = [
  _FoodItem(
    key: 'chicken_breast',
    emoji: '🍗',
    title: 'Chicken & Turkey',
    subtitle: 'Breast, tenderloin, lean mince',
  ),
  _FoodItem(
    key: 'eggs',
    emoji: '🥚',
    title: 'Eggs & Whites',
    subtitle: 'Whole eggs, liquid whites',
  ),
  _FoodItem(
    key: 'lean_beef_mince',
    emoji: '🥩',
    title: 'Lean Beef & Steak',
    subtitle: 'Mince, medallions, steak cuts',
  ),
  _FoodItem(
    key: 'salmon_fish',
    emoji: '🐟',
    title: 'Salmon & Fish',
    subtitle: 'Salmon fillets, tuna, cod',
  ),
  _FoodItem(
    key: 'skyr_greek_yogurt',
    emoji: '🥛',
    title: 'Skyr & Greek Yogurt',
    subtitle: 'Quark, greek yogurt, cottage cheese',
  ),
  _FoodItem(
    key: 'tofu',
    emoji: '🫘',
    title: 'Plant Protein & Tofu',
    subtitle: 'Tofu, tempeh, edamame, lentils',
  ),
];

const vegetarianProteinStaples = [
  _FoodItem(
    key: 'eggs',
    emoji: '🥚',
    title: 'Eggs & Whites',
    subtitle: 'Whole eggs, liquid whites',
  ),
  _FoodItem(
    key: 'skyr_greek_yogurt',
    emoji: '🥛',
    title: 'Skyr & Greek Yogurt',
    subtitle: 'Quark, greek yogurt, cottage cheese',
  ),
  _FoodItem(
    key: 'tofu',
    emoji: '🫘',
    title: 'Tofu & Tempeh',
    subtitle: 'Firm tofu, smoked tempeh',
  ),
  _FoodItem(
    key: 'lentils_chickpeas',
    emoji: '🌱',
    title: 'Lentils & Chickpeas',
    subtitle: 'Puy lentils, hummus, chickpeas',
  ),
  _FoodItem(
    key: 'whey_protein',
    emoji: '🥤',
    title: 'Protein Powder',
    subtitle: 'Whey, casein, plant blend',
  ),
];

const veganProteinStaples = [
  _FoodItem(
    key: 'tofu',
    emoji: '🫘',
    title: 'Tofu & Tempeh',
    subtitle: 'Firm tofu, smoked tempeh',
  ),
  _FoodItem(
    key: 'lentils_chickpeas',
    emoji: '🌱',
    title: 'Lentils & Beans',
    subtitle: 'Chickpeas, black & kidney beans',
  ),
  _FoodItem(
    key: 'seitan',
    emoji: '🌾',
    title: 'Seitan & Edamame',
    subtitle: 'Wheat gluten, edamame beans',
  ),
  _FoodItem(
    key: 'plant_protein',
    emoji: '🥤',
    title: 'Plant Protein Powder',
    subtitle: 'Pea, rice, hemp isolate',
  ),
];

const curatedCarbStaples = [
  _FoodItem(
    key: 'oats',
    emoji: '🥣',
    title: 'Oats & Porridge',
    subtitle: 'Rolled oats, overnight oats',
  ),
  _FoodItem(
    key: 'rice',
    emoji: '🍚',
    title: 'Rice & Grains',
    subtitle: 'Basmati, jasmine, brown rice, quinoa',
  ),
  _FoodItem(
    key: 'potatoes',
    emoji: '🥔',
    title: 'Potatoes & Sweet Potatoes',
    subtitle: 'Baby potatoes, sweet potatoes',
  ),
  _FoodItem(
    key: 'pasta',
    emoji: '🍝',
    title: 'Pasta',
    subtitle: 'Penne, spaghetti, wholewheat',
  ),
  _FoodItem(
    key: 'sourdough_bread',
    emoji: '🍞',
    title: 'Bread & Wraps',
    subtitle: 'Sourdough, wholemeal, tortilla',
  ),
];

const curatedDietaryExclusions = [
  _FoodItem(
    key: 'dairy_free',
    emoji: '🥛',
    title: 'Dairy-free',
    subtitle: 'No cow milk, cheese, or lactose',
  ),
  _FoodItem(
    key: 'gluten_free',
    emoji: '🌾',
    title: 'Gluten-free',
    subtitle: 'Celiac or wheat sensitivity',
  ),
  _FoodItem(
    key: 'nut_free',
    emoji: '🥜',
    title: 'Nut allergy',
    subtitle: 'Peanut and tree nut free',
  ),
  _FoodItem(
    key: 'no_pork',
    emoji: '🥩',
    title: 'No pork / Halal',
    subtitle: 'Poultry, beef, fish and plant protein only',
  ),
  _FoodItem(
    key: 'seafood_free',
    emoji: '🐟',
    title: 'No seafood',
    subtitle: 'No fish, shellfish, or ocean products',
  ),
];

// MARK: - Apple iOS Lifestyle & Recovery Preferences
class LifestyleNutritionLimitationsView extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  const LifestyleNutritionLimitationsView(
      {super.key, this.controller, this.onContinue});

  @override
  State<LifestyleNutritionLimitationsView> createState() =>
      _LifestyleNutritionLimitationsViewState();
}

class _LifestyleNutritionLimitationsViewState
    extends State<LifestyleNutritionLimitationsView> {
  bool _advancing = false;
  int _part = 0;
  late final LifestyleNutritionViewModel _viewModel;
  late final TextEditingController _customDietController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _viewModel = LifestyleNutritionViewModel(controller: widget.controller)
      ..addListener(_rebuild);
    _customDietController =
        TextEditingController(text: _viewModel.customEatingStyle);
    _notesController =
        TextEditingController(text: _viewModel.customLimitations);
  }

  void _rebuild() {
    if (!mounted) return;
    if (_customDietController.text != _viewModel.customEatingStyle) {
      _customDietController.value = TextEditingValue(
        text: _viewModel.customEatingStyle,
        selection: TextSelection.collapsed(
          offset: _viewModel.customEatingStyle.length,
        ),
      );
    }
    if (_notesController.text != _viewModel.customLimitations) {
      _notesController.value = TextEditingValue(
        text: _viewModel.customLimitations,
        selection: TextSelection.collapsed(
          offset: _viewModel.customLimitations.length,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    _customDietController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_part > 0) {
      setState(() => _part--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onContinue() async {
    if (_advancing) return;
    if (_part < 3) {
      FocusScope.of(context).unfocus();
      setState(() => _part++);
      return;
    }
    setState(() => _advancing = true);
    try {
      await _viewModel.continueToNextStep();
      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
        return;
      }
      await _viewModel.controller.flush();
      final token = await SecureSessionStore.shared.accessToken;
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        await OnboardingPageRoute<void>(
                page: AuthView(controller: _viewModel.controller))
            .open(context);
      } else {
        await AuthRepository().completeMissingProfile(_viewModel.draft);
        _viewModel.controller.finish();
        final destination = await prepareAuthenticatedHome();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil<void>(
            OnboardingPageRoute<void>(page: destination), (_) => false);
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  List<_FoodItem> get _curatedProteins {
    if (_viewModel.eatingStyle == EatingStyleOption.vegan) {
      return veganProteinStaples;
    }
    if (_viewModel.eatingStyle == EatingStyleOption.vegetarian) {
      return vegetarianProteinStaples;
    }
    return omnivoreProteinStaples;
  }

  bool get _allCommonStaplesSelected {
    final proteins = _curatedProteins;
    final allProteins =
        proteins.every((p) => _viewModel.stapleProteins.contains(p.key));
    final allCarbs =
        curatedCarbStaples.every((c) => _viewModel.stapleCarbs.contains(c.key));
    return allProteins && allCarbs;
  }

  void _toggleAllCommonStaples() {
    final select = !_allCommonStaplesSelected;
    for (final item in _curatedProteins) {
      final has = _viewModel.stapleProteins.contains(item.key);
      if (select && !has) {
        _viewModel.toggleStapleProtein(item.key);
      } else if (!select && has) {
        _viewModel.toggleStapleProtein(item.key);
      }
    }
    for (final item in curatedCarbStaples) {
      final has = _viewModel.stapleCarbs.contains(item.key);
      if (select && !has) {
        _viewModel.toggleStapleCarb(item.key);
      } else if (!select && has) {
        _viewModel.toggleStapleCarb(item.key);
      }
    }
  }

  Widget _sectionHeader(String title, String countText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: FitnessText(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          FitnessText(
            countText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: FitnessTheme.silver,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleepPill(SleepDurationOption option) {
    final selected = _viewModel.sleepDuration == option;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () {
            OnboardingCoach.select();
            _viewModel.selectSleep(option);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : const Color(0xFF141517),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.white : const Color(0xFF26272B),
                width: selected ? 1.0 : 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.defaultLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.black : Colors.white,
                  ),
                ),
                if (option.isRecommended) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Optimal',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF333333)
                          : FitnessTheme.silver,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'Fuel & recovery',
      // Heart buddy for everyday activity, apple buddy for food.
      buddy: switch (_part) {
        0 => BuddyKind.heart,
        1 || 2 => BuddyKind.apple,
        _ => null,
      },
      part: _part,
      parts: 4,
      canPop: _part == 0,
      title: switch (_part) {
        0 => language.activityLevelQuestion,
        1 => language.eatingStyleQuestion,
        2 => 'Everyday food staples',
        _ => language.limitationsSectionTitle,
      },
      subtitle: switch (_part) {
        0 => language.activityLevelSubtitle,
        1 => 'We’ll build your meals around this',
        2 => 'Pick what you regularly buy in local shops',
        3 => 'Choose any areas needing care, and note any movements to avoid',
        _ => '',
      },
      actionTitle: _part < 3 ? language.continueButtonTitle : 'Build my plan',
      loading: _advancing,
      onBack: _onBack,
      onContinue: _viewModel.controller.ready ? _onContinue : null,
      children: [
        if (_part == 0) ...[
          for (final option in ActivityLevelOption.values)
            _choice(
              option.defaultLabel,
              option.defaultSubtitle,
              _viewModel.activityLevel == option,
              () => _viewModel.selectActivity(option),
            ),
          const SizedBox(height: 20),
          FitnessText(
            language.sleepDurationQuestion,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: FitnessTheme.silver,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < SleepDurationOption.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _sleepPill(SleepDurationOption.values[i]),
              ],
            ],
          ),
        ],
        if (_part == 1) ...[
          for (final option in EatingStyleOption.values)
            _choice(
              '${option.emoji}  ${language.eatingStyleLabel(option.backendValue)}',
              option.defaultSubtitle,
              _viewModel.eatingStyle == option,
              () => _viewModel.selectEatingStyle(option),
            ),
          if (_viewModel.eatingStyle.isCustom)
            OtherDietInput(
              controller: _customDietController,
              placeholder: language.customDietPlaceholder,
              onChanged: _viewModel.setCustomEatingStyle,
            ),
        ],
        if (_part == 2) ...[
          // Quick Setup Action
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141517),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF26272B), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick setup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Select all everyday local staples',
                        style: TextStyle(
                          fontSize: 11,
                          color: FitnessTheme.silver,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _toggleAllCommonStaples();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _allCommonStaplesSelected
                          ? const Color(0xFF2E2F34)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _allCommonStaplesSelected ? 'RESET' : 'SELECT ALL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _allCommonStaplesSelected
                            ? Colors.white
                            : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1. Proteins
          _sectionHeader(
            'PROTEINS YOU REGULARLY BUY',
            '${_viewModel.stapleProteins.length} selected',
          ),
          for (final item in _curatedProteins)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StapleCard(
                item: item,
                selected: _viewModel.stapleProteins.contains(item.key),
                onTap: () => _viewModel.toggleStapleProtein(item.key),
              ),
            ),
          const SizedBox(height: 18),

          // 2. Carbs & Staples
          _sectionHeader(
            'CARBS & STAPLES',
            '${_viewModel.stapleCarbs.length} selected',
          ),
          for (final item in curatedCarbStaples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StapleCard(
                item: item,
                selected: _viewModel.stapleCarbs.contains(item.key),
                onTap: () => _viewModel.toggleStapleCarb(item.key),
              ),
            ),
          const SizedBox(height: 18),

          // 3. Dietary Restrictions
          _sectionHeader(
            'DIETARY RESTRICTIONS',
            _viewModel.dietaryExclusions.isEmpty
                ? 'None'
                : '${_viewModel.dietaryExclusions.length} active',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StapleCard(
              item: const _FoodItem(
                key: '__none__',
                emoji: '✨',
                title: 'No dietary restrictions',
                subtitle: 'I eat everything · No allergies or exclusions',
              ),
              selected: _viewModel.dietaryExclusions.isEmpty,
              onTap: () {
                if (_viewModel.dietaryExclusions.isNotEmpty) {
                  for (final key in _viewModel.dietaryExclusions.toList()) {
                    _viewModel.toggleDietaryExclusion(key);
                  }
                }
              },
            ),
          ),
          for (final item in curatedDietaryExclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StapleCard(
                item: item,
                selected: _viewModel.dietaryExclusions.contains(item.key),
                onTap: () => _viewModel.toggleDietaryExclusion(item.key),
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (_part == 3) ...[
          for (final option in BodyLimitationOption.values)
            _choice(
              option.defaultLabel,
              option.defaultSubtitle.isNotEmpty
                  ? option.defaultSubtitle
                  : null,
              _viewModel.limitations.contains(option),
              () => _viewModel.toggleLimitation(option),
            ),
          const SizedBox(height: 18),
          const FitnessText(
            'MOVEMENT NOTES & INJURIES (OPTIONAL)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF141517),
              counterText: '',
              hintText:
                  'Lower back pain, avoid barbell squats, bad shoulder',
              hintStyle:
                  const TextStyle(color: Color(0xFF666666), fontSize: 13),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF28292C), width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF28292C), width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.white, width: 1.0),
              ),
            ),
            onChanged: _viewModel.setCustomLimitations,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _choice(
          String title, String? subtitle, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OnboardingChoice(
          title: title,
          subtitle: subtitle,
          selected: selected,
          onTap: onTap,
        ),
      );
}

class _StapleCard extends StatelessWidget {
  final _FoodItem item;
  final bool selected;
  final VoidCallback onTap;

  const _StapleCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          OnboardingCoach.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF222327) : const Color(0xFF141517),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF242528),
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Text(
                item.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FitnessTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: selected ? Colors.white : const Color(0xFF383A3E),
                    width: 1.2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.black,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
