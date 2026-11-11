import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import 'onboarding_controller.dart';
import '../models/training_schedule_models.dart';

// MARK: - Schedule & Location ViewModel (Step 4 of 8)
class ScheduleLocationViewModel extends ChangeNotifier {
  final int currentStep = 4;
  final int totalSteps = 7;

  final OnboardingController controller;
  final bool _ownsController;
  OnboardingDraft get draft => controller.draft;
  bool _isDisposed = false;

  DaysPerWeekOption? get selectedDays => draft.daysPerWeek == null
      ? null
      : DaysPerWeekOption.fromBackend(draft.daysPerWeek!);
  WorkoutDurationOption? get selectedDuration => draft.workoutDuration == null
      ? null
      : WorkoutDurationOption.fromBackend(draft.workoutDuration!);
  TrainingLocationOption? get selectedLocation => draft.trainingLocation == null
      ? null
      : TrainingLocationOption.fromBackend(draft.trainingLocation!);

  ScheduleLocationViewModel({OnboardingController? controller})
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

    // Respect language from draft if configured
    if (draft.languageCode.isNotEmpty) {
      final match = AppLanguage.values.firstWhere(
        (l) => l.code == draft.languageCode,
        orElse: () => LanguageManager.shared.currentLanguage,
      );
      if (LanguageManager.shared.currentLanguage != match) {
        LanguageManager.shared.selectLanguage(match, persistDraft: false);
      }
    }

    notifyListeners();
  }

  void selectDays(DaysPerWeekOption opt) {
    if (selectedDays == opt) return;
    draft.daysPerWeek = opt.backendValue;
    final defaultDaysMap = <int, List<String>>{
      2: ['MONDAY', 'THURSDAY'],
      3: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      4: ['MONDAY', 'TUESDAY', 'THURSDAY', 'FRIDAY'],
      5: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'],
      6: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'],
    };
    final defaults = defaultDaysMap[opt.daysCount];
    if (defaults != null) {
      draft.trainingDays = defaults;
    }
    controller.checkpoint();
    notifyListeners();
  }

  void selectDuration(WorkoutDurationOption opt) {
    if (selectedDuration == opt) return;
    draft.workoutDuration = opt.backendValue;
    controller.checkpoint();
    notifyListeners();
  }

  void selectLocation(TrainingLocationOption opt) {
    if (selectedLocation == opt) return;
    draft.trainingLocation = opt.backendValue;
    controller.checkpoint();
    notifyListeners();
  }

  bool get isValid =>
      selectedDays != null &&
      selectedDuration != null &&
      selectedLocation != null;

  Future<void> continueToNextStep() async {
    if (!isValid) return;
    draft.daysPerWeek = selectedDays!.backendValue;
    draft.workoutDuration = selectedDuration!.backendValue;
    draft.trainingLocation = selectedLocation!.backendValue;
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
