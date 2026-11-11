import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import 'onboarding_controller.dart';
import '../models/lifestyle_nutrition_models.dart';

// MARK: - Lifestyle preferences view model
class LifestyleNutritionViewModel extends ChangeNotifier {
  final int currentStep = 7;
  final int totalSteps = 7;

  final OnboardingController controller;
  final bool _ownsController;
  OnboardingDraft get draft => controller.draft;
  bool _isDisposed = false;

  ActivityLevelOption _activityLevel = ActivityLevelOption.moderate;
  ActivityLevelOption get activityLevel => _activityLevel;

  SleepDurationOption _sleepDuration = SleepDurationOption.hours7To8;
  SleepDurationOption get sleepDuration => _sleepDuration;

  EatingStyleOption _eatingStyle = EatingStyleOption.noPreference;
  EatingStyleOption get eatingStyle => _eatingStyle;
  String _customEatingStyle = '';
  String get customEatingStyle => _customEatingStyle;

  String _customLimitations = '';
  String get customLimitations => _customLimitations;

  Set<String> _dietaryExclusions = {};
  Set<String> get dietaryExclusions => _dietaryExclusions;

  Set<String> _stapleProteins = {};
  Set<String> get stapleProteins => _stapleProteins;

  Set<String> _stapleCarbs = {};
  Set<String> get stapleCarbs => _stapleCarbs;

  Set<BodyLimitationOption> _limitations = {BodyLimitationOption.none};
  Set<BodyLimitationOption> get limitations => _limitations;

  LifestyleNutritionViewModel({OnboardingController? controller})
      : controller = controller ?? OnboardingController(),
        _ownsController = controller == null {
    LanguageManager.shared.addListener(_onLanguageChanged);
    _loadState();
  }

  void _onLanguageChanged() {
    if (!_isDisposed) notifyListeners();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> _loadState() async {
    if (!controller.ready) await controller.initialize();
    if (_isDisposed) return;

    if (draft.languageCode.isNotEmpty) {
      final match = AppLanguage.values.firstWhere(
        (l) => l.code == draft.languageCode,
        orElse: () => LanguageManager.shared.currentLanguage,
      );
      if (LanguageManager.shared.currentLanguage != match) {
        LanguageManager.shared.selectLanguage(match, persistDraft: false);
      }
    }

    if (draft.activityLevel != null) {
      _activityLevel = ActivityLevelOption.fromBackend(draft.activityLevel);
    }
    if (draft.sleepDuration != null) {
      _sleepDuration = SleepDurationOption.fromBackend(draft.sleepDuration);
    }
    if (draft.eatingStyle != null) {
      _eatingStyle = EatingStyleOption.fromBackend(draft.eatingStyle);
    }
    _customEatingStyle = draft.customEatingStyle ?? '';
    _customLimitations = draft.customLimitations ?? '';
    _dietaryExclusions = draft.dietaryExclusions.toSet();
    _stapleProteins = draft.stapleProteins.toSet();
    _stapleCarbs = draft.stapleCarbs.toSet();
    if (draft.limitations.isNotEmpty) {
      _limitations =
          draft.limitations.map(BodyLimitationOption.fromBackend).toSet();
      if (_limitations.isEmpty) _limitations = {BodyLimitationOption.none};
    }
    notifyListeners();
  }

  void selectActivity(ActivityLevelOption opt) {
    if (_activityLevel == opt) return;
    _activityLevel = opt;
    draft.activityLevel = opt.backendValue;
    controller.checkpoint();
    notifyListeners();
  }

  void selectSleep(SleepDurationOption opt) {
    if (_sleepDuration == opt) return;
    _sleepDuration = opt;
    draft.sleepDuration = opt.backendValue;
    controller.checkpoint();
    notifyListeners();
  }

  void selectEatingStyle(EatingStyleOption opt) {
    if (_eatingStyle == opt) return;
    _eatingStyle = opt;
    draft.eatingStyle = opt.backendValue;
    draft.customEatingStyle =
        opt == EatingStyleOption.other ? _customEatingStyle.trim() : null;
    controller.checkpoint();
    notifyListeners();
  }

  void setCustomEatingStyle(String value) {
    _customEatingStyle = value;
    draft.customEatingStyle = value.trim();
    controller.checkpoint();
  }

  void setCustomLimitations(String value) {
    _customLimitations = value;
    draft.customLimitations = value.trim();
    controller.checkpoint();
  }

  void toggleDietaryExclusion(String key) {
    if (_dietaryExclusions.contains(key)) {
      _dietaryExclusions.remove(key);
    } else {
      _dietaryExclusions.add(key);
    }
    draft.dietaryExclusions = _dietaryExclusions.toList();
    controller.checkpoint();
    notifyListeners();
  }

  void toggleStapleProtein(String key) {
    if (_stapleProteins.contains(key)) {
      _stapleProteins.remove(key);
    } else {
      _stapleProteins.add(key);
    }
    draft.stapleProteins = _stapleProteins.toList();
    controller.checkpoint();
    notifyListeners();
  }

  void toggleStapleCarb(String key) {
    if (_stapleCarbs.contains(key)) {
      _stapleCarbs.remove(key);
    } else {
      _stapleCarbs.add(key);
    }
    draft.stapleCarbs = _stapleCarbs.toList();
    controller.checkpoint();
    notifyListeners();
  }

  void toggleLimitation(BodyLimitationOption opt) {
    if (opt.isExclusive) {
      _limitations = {BodyLimitationOption.none};
    } else {
      _limitations.remove(BodyLimitationOption.none);
      if (_limitations.contains(opt)) {
        _limitations.remove(opt);
        if (_limitations.isEmpty) {
          _limitations = {BodyLimitationOption.none};
        }
      } else {
        _limitations.add(opt);
      }
    }
    draft.limitations =
        _limitations.map((value) => value.backendValue).toList();
    controller.checkpoint();
    notifyListeners();
  }

  bool get isValid => true;

  Future<void> continueToNextStep() async {
    draft.activityLevel = _activityLevel.backendValue;
    draft.sleepDuration = _sleepDuration.backendValue;
    draft.eatingStyle = _eatingStyle.backendValue;
    draft.dietaryExclusions = _dietaryExclusions.toList();
    draft.stapleProteins = _stapleProteins.toList();
    draft.stapleCarbs = _stapleCarbs.toList();
    // Budget is optional; don't persist the old hard-coded dollar default.
    draft.weeklyFoodBudget = null;
    draft.limitations = _limitations.map((e) => e.backendValue).toList();
    draft.customLimitations = _customLimitations.trim();
    draft.customEatingStyle = _eatingStyle == EatingStyleOption.other
        ? _customEatingStyle.trim()
        : null;
    draft.completedStep = currentStep;
    controller.checkpoint();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_ownsController) controller.dispose();
    LanguageManager.shared.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
