import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/training_schedule_models.dart';

// MARK: - Schedule & Location ViewModel (Step 4 of 8)
class ScheduleLocationViewModel extends ChangeNotifier {
  final int currentStep = 4;
  final int totalSteps = 8;

  OnboardingDraft draft = OnboardingDraft();
  bool _isDisposed = false;

  DaysPerWeekOption? _selectedDays;
  DaysPerWeekOption? get selectedDays => _selectedDays;

  WorkoutDurationOption? _selectedDuration;
  WorkoutDurationOption? get selectedDuration => _selectedDuration;

  TrainingLocationOption? _selectedLocation;
  TrainingLocationOption? get selectedLocation => _selectedLocation;

  ScheduleLocationViewModel() {
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

    // Respect language from draft if configured
    if (draft.languageCode.isNotEmpty) {
      final match = AppLanguage.values.firstWhere(
        (l) => l.code == draft.languageCode,
        orElse: () => LanguageManager.shared.currentLanguage,
      );
      if (LanguageManager.shared.currentLanguage != match) {
        LanguageManager.shared.selectLanguage(match);
      }
    }

    if (draft.daysPerWeek != null) {
      _selectedDays = DaysPerWeekOption.fromBackend(draft.daysPerWeek);
    }
    if (draft.workoutDuration != null) {
      _selectedDuration =
          WorkoutDurationOption.fromBackend(draft.workoutDuration);
    }
    if (draft.trainingLocation != null) {
      _selectedLocation =
          TrainingLocationOption.fromBackend(draft.trainingLocation);
    }

    notifyListeners();
  }

  void selectDays(DaysPerWeekOption opt) {
    if (_selectedDays == opt) return;
    _selectedDays = opt;
    notifyListeners();
  }

  void selectDuration(WorkoutDurationOption opt) {
    if (_selectedDuration == opt) return;
    _selectedDuration = opt;
    notifyListeners();
  }

  void selectLocation(TrainingLocationOption opt) {
    if (_selectedLocation == opt) return;
    _selectedLocation = opt;
    notifyListeners();
  }

  bool get isValid =>
      _selectedDays != null &&
      _selectedDuration != null &&
      _selectedLocation != null;

  Future<void> continueToNextStep() async {
    if (!isValid) return;
    draft.daysPerWeek = _selectedDays!.backendValue;
    draft.workoutDuration = _selectedDuration!.backendValue;
    draft.trainingLocation = _selectedLocation!.backendValue;
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
