import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/working_toward_goal.dart';

// MARK: - Onboarding Screen 01 (Your Goal) ViewModel
class GoalViewModel extends ChangeNotifier {
  final int currentStep = 2;
  final int totalSteps = 8;

  WorkingTowardGoal? _selectedGoal;
  WorkingTowardGoal? get selectedGoal => _selectedGoal;

  OnboardingDraft draft = OnboardingDraft();
  bool _isDisposed = false;

  GoalViewModel() {
    _loadState();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  Future<void> _loadState() async {
    draft = await OnboardingDraft.load();
    if (_isDisposed) return;

    if (draft.workingToward != null) {
      _selectedGoal = WorkingTowardGoal.fromBackend(draft.workingToward);
    } else {
      // Default to first goal (Build Muscle) or null
      _selectedGoal = WorkingTowardGoal.buildMuscle;
      draft.workingToward = _selectedGoal!.backendValue;
      await draft.save();
    }
    notifyListeners();
  }

  Future<void> selectGoal(WorkingTowardGoal goal) async {
    if (_selectedGoal == goal) return;
    _selectedGoal = goal;
    draft.workingToward = goal.backendValue;
    draft.goal = goal.backendValue;
    draft.completedStep = currentStep;
    await draft.save();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> continueToNextStep() async {
    if (_selectedGoal == null) return;
    draft.workingToward = _selectedGoal!.backendValue;
    draft.goal = _selectedGoal!.backendValue;
    draft.completedStep = currentStep;
    await draft.save();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
