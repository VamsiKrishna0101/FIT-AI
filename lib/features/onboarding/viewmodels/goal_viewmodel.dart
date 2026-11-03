import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/working_toward_goal.dart';
import 'onboarding_controller.dart';

// MARK: - Onboarding Screen 01 (Your Goal) ViewModel
class GoalViewModel extends ChangeNotifier {
  final int currentStep = 2;
  final int totalSteps = 8;

  WorkingTowardGoal? _selectedGoal;
  WorkingTowardGoal? get selectedGoal => _selectedGoal;

  final OnboardingController controller;
  final bool _ownsController;
  final bool preselectGoal;
  OnboardingDraft get draft => controller.draft;
  bool _isDisposed = false;

  GoalViewModel({OnboardingController? controller, this.preselectGoal = true})
      : controller = controller ?? OnboardingController(),
        _ownsController = controller == null {
    _loadState();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> _loadState() async {
    if (!controller.ready) await controller.initialize();
    if (_isDisposed) return;

    if (draft.workingToward != null) {
      _selectedGoal = WorkingTowardGoal.fromBackend(draft.workingToward);
    } else if (preselectGoal) {
      // The legacy standalone flow can retain its default.
      _selectedGoal = WorkingTowardGoal.buildMuscle;
      draft.workingToward = _selectedGoal!.backendValue;
      controller.checkpoint();
    }
    notifyListeners();
  }

  Future<void> selectGoal(WorkingTowardGoal goal) async {
    if (_selectedGoal == goal) return;
    _selectedGoal = goal;
    draft.workingToward = goal.backendValue;
    draft.goal = goal.backendValue;
    draft.completedStep = currentStep;
    controller.checkpoint();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> continueToNextStep() async {
    if (_selectedGoal == null) return;
    draft.workingToward = _selectedGoal!.backendValue;
    draft.goal = _selectedGoal!.backendValue;
    draft.completedStep = currentStep;
    controller.checkpoint();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_ownsController) controller.dispose();
    super.dispose();
  }
}
