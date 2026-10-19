import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import 'onboarding_controller.dart';

// MARK: - Onboarding Screen 1 ViewModel
class OnboardingViewModel extends ChangeNotifier {
  int currentStep = 1;
  final int totalSteps = 8;
  bool hasDropped = false;
  final OnboardingController controller;
  final bool _ownsController;
  OnboardingDraft get draft => controller.draft;
  bool get ready => controller.ready;
  bool _isDisposed = false;

  OnboardingViewModel({OnboardingController? controller})
      : controller = controller ?? OnboardingController(),
        _ownsController = controller == null {
    _loadState();
  }

  Future<void> _loadState() async {
    await controller.initialize();
    if (_isDisposed) return;
    // This view is the language-selection page (step one). Persisted progress
    // cannot advance its indicator while the user is still on this page.
    currentStep = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> selectLanguage(AppLanguage language) async {
    if (!ready) return;
    draft.languageCode = language.code;
    controller.checkpoint();
    await LanguageManager.shared.selectLanguage(language, persistDraft: false);
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
    controller.checkpoint();
  }
}
