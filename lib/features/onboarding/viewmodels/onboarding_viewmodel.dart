import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';

// MARK: - Onboarding Screen 1 ViewModel
class OnboardingViewModel extends ChangeNotifier {
  int currentStep = 1;
  final int totalSteps = 8;
  bool hasDropped = false;
  OnboardingDraft draft = OnboardingDraft();
  bool _isDisposed = false;

  OnboardingViewModel() {
    _loadState();
  }

  Future<void> _loadState() async {
    final loadedDraft = await OnboardingDraft.load();
    if (_isDisposed) return;
    draft = loadedDraft;
    // This view is the language-selection page (step one). Persisted progress
    // cannot advance its indicator while the user is still on this page.
    currentStep = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> selectLanguage(AppLanguage language) async {
    await LanguageManager.shared.selectLanguage(language);
    draft.languageCode = language.code;
    await draft.save();
    if (!_isDisposed) notifyListeners();
  }

  void triggerGravityDrop() {
    if (!hasDropped) {
      hasDropped = true;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> continueToNextStep() async {
    // Save this page before the route advances to goal selection.
    draft.completedStep = currentStep;
    await draft.save();
  }
}
