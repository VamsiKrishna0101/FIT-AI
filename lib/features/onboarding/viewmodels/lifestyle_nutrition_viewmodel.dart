import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/lifestyle_nutrition_models.dart';

// MARK: - Lifestyle preferences view model
class LifestyleNutritionViewModel extends ChangeNotifier {
  final int currentStep = 6;
  final int totalSteps = 8;

  OnboardingDraft draft = OnboardingDraft();
  bool _isDisposed = false;

  ActivityLevelOption _activityLevel = ActivityLevelOption.moderate;
  ActivityLevelOption get activityLevel => _activityLevel;

  SleepDurationOption _sleepDuration = SleepDurationOption.hours7To8;
  SleepDurationOption get sleepDuration => _sleepDuration;

  EatingStyleOption _eatingStyle = EatingStyleOption.noPreference;
  EatingStyleOption get eatingStyle => _eatingStyle;
  String _customEatingStyle = '';
  String get customEatingStyle => _customEatingStyle;

  Set<BodyLimitationOption> _limitations = {BodyLimitationOption.none};
  Set<BodyLimitationOption> get limitations => _limitations;

  LifestyleNutritionViewModel() {
    LanguageManager.shared.addListener(_onLanguageChanged);
    _loadState();
  }

  void _onLanguageChanged() {
    if (!_isDisposed) notifyListeners();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> _loadState() async {
    draft = await OnboardingDraft.load();
    if (_isDisposed) return;

    if (draft.languageCode.isNotEmpty) {
      final match = AppLanguage.values.firstWhere(
        (l) => l.code == draft.languageCode,
        orElse: () => LanguageManager.shared.currentLanguage,
      );
      if (LanguageManager.shared.currentLanguage != match) {
        LanguageManager.shared.selectLanguage(match);
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
    notifyListeners();
  }

  void selectSleep(SleepDurationOption opt) {
    if (_sleepDuration == opt) return;
    _sleepDuration = opt;
    notifyListeners();
  }

  void selectEatingStyle(EatingStyleOption opt) {
    if (_eatingStyle == opt) return;
    _eatingStyle = opt;
    notifyListeners();
  }

  void setCustomEatingStyle(String value) {
    _customEatingStyle = value;
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
    notifyListeners();
  }

  bool get isValid => true;

  Future<void> continueToNextStep() async {
    draft.activityLevel = _activityLevel.backendValue;
    draft.sleepDuration = _sleepDuration.backendValue;
    draft.eatingStyle = _eatingStyle.backendValue;
    // Budget is optional; don't persist the old hard-coded dollar default.
    draft.weeklyFoodBudget = null;
    draft.limitations = _limitations.map((e) => e.backendValue).toList();
    draft.customEatingStyle = _eatingStyle == EatingStyleOption.other
        ? _customEatingStyle.trim()
        : null;
    draft.completedStep = currentStep;
    await draft.save();
  }

  @override
  void dispose() {
    _isDisposed = true;
    LanguageManager.shared.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
