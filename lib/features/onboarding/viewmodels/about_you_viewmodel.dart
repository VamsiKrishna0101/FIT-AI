import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/experience_level.dart';

// MARK: - Onboarding Screen 02 & 03 (About You & Experience) ViewModel
class AboutYouViewModel extends ChangeNotifier {
  final int currentStep = 3;
  final int totalSteps = 8;

  OnboardingDraft draft = OnboardingDraft();
  bool _isDisposed = false;

  String _name = '';
  String get name => _name;

  String _gender = 'MALE';
  String get gender => _gender;

  int _age = 27; // Prompt default: 27
  int get age => _age;

  bool _isImperial = true; // Prompt default: 5'10" and 178 lb
  bool get isImperial => _isImperial;

  // Canonical metric values stored in database (Mifflin-St Jeor requirements)
  double _heightCm = 177.8; // 5 ft 10 in = 177.8 cm
  double get heightCm => _heightCm;

  double _weightKg = 80.7; // 178 lb = 80.7394 kg
  double get weightKg => _weightKg;

  double _targetWeightKg = 74.8; // ~165 lb default
  double get targetWeightKg => _targetWeightKg;

  ExperienceLevel? _selectedExperience = ExperienceLevel.intermediate;
  ExperienceLevel? get selectedExperience => _selectedExperience;

  AboutYouViewModel() {
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

    if (draft.name != null && draft.name!.isNotEmpty) {
      _name = draft.name!;
    }
    if (draft.gender != null) {
      _gender = draft.gender!;
    }
    if (draft.age != null) {
      _age = draft.age!;
    }
    if (draft.heightCm != null && draft.heightCm! > 0) {
      _heightCm = draft.heightCm!;
    }
    if (draft.weightKg != null && draft.weightKg! > 0) {
      _weightKg = draft.weightKg!;
    }
    if (draft.targetWeightKg != null && draft.targetWeightKg! > 0) {
      _targetWeightKg = draft.targetWeightKg!;
    } else {
      if (draft.workingToward == 'LOSE_WEIGHT' ||
          draft.workingToward == 'LOSE_BODY_FAT') {
        _targetWeightKg = (_weightKg - 5.9).clamp(30.0, 250.0);
      } else if (draft.workingToward == 'BUILD_MUSCLE') {
        _targetWeightKg = (_weightKg + 3.2).clamp(30.0, 250.0);
      } else {
        _targetWeightKg = _weightKg;
      }
    }
    if (draft.experienceLevel != null) {
      _selectedExperience = ExperienceLevel.fromBackend(draft.experienceLevel);
    }

    notifyListeners();
  }

  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  String get countryCode => draft.countryCode;

  void setCountry(String value) {
    draft.countryCode = value;
    notifyListeners();
  }

  void setGender(String val) {
    if (_gender == val) return;
    _gender = val;
    notifyListeners();
  }

  void setImperial(bool val) {
    if (_isImperial == val) return;
    _isImperial = val;
    notifyListeners();
  }

  void setAge(double value) {
    _age = value.round().clamp(13, 100);
    notifyListeners();
  }

  void setHeight(double value) {
    _heightCm = (_isImperial ? value * 2.54 : value).clamp(120.0, 230.0);
    notifyListeners();
  }

  void setWeight(double value) {
    _weightKg = (_isImperial ? value / 2.20462 : value).clamp(30.0, 250.0);
    notifyListeners();
  }

  void setTargetWeight(double value) {
    _targetWeightKg =
        (_isImperial ? value / 2.20462 : value).clamp(30.0, 250.0);
    notifyListeners();
  }

  // ── Height Handlers ──────────────────────────────────────────────────────
  String get heightDisplay {
    if (_isImperial) {
      final totalInches = (_heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet' $inches\"";
    } else {
      return "${_heightCm.round()}";
    }
  }

  String? get heightUnitDisplay => _isImperial ? null : 'cm';

  String? get secondaryHeightDisplay {
    if (_isImperial) {
      return "${_heightCm.round()} cm";
    } else {
      final totalInches = (_heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet' $inches\"";
    }
  }

  // ── Weight Handlers ──────────────────────────────────────────────────────
  String get weightDisplay {
    if (_isImperial) {
      final lbs = (_weightKg * 2.20462).round();
      return "$lbs";
    } else {
      return _weightKg.toStringAsFixed(1);
    }
  }

  String get weightUnitDisplay => _isImperial ? 'lb' : 'kg';

  String get secondaryWeightDisplay {
    if (_isImperial) {
      return "${_weightKg.toStringAsFixed(1)} kg";
    } else {
      final lbs = (_weightKg * 2.20462).round();
      return "$lbs lb";
    }
  }

  // ── Target Weight Handlers ───────────────────────────────────────────────
  String get targetWeightDisplay {
    if (_isImperial) {
      final lbs = (_targetWeightKg * 2.20462).round();
      return "$lbs";
    } else {
      return _targetWeightKg.toStringAsFixed(1);
    }
  }

  String get secondaryTargetWeightDisplay {
    if (_isImperial) {
      return "${_targetWeightKg.toStringAsFixed(1)} kg";
    } else {
      final lbs = (_targetWeightKg * 2.20462).round();
      return "$lbs lb";
    }
  }

  String get weightGoalSummary {
    final diffKg = _targetWeightKg - _weightKg;
    if (_isImperial) {
      final diffLbs = (diffKg * 2.20462).round();
      if (diffLbs < 0) {
        return "${diffLbs.abs()} lb to lose for your goal";
      } else if (diffLbs > 0) {
        return "+$diffLbs lb lean gain target";
      } else {
        return "Maintain your current weight";
      }
    } else {
      final diff = double.parse(diffKg.abs().toStringAsFixed(1));
      if (diffKg < -0.2) {
        return "$diff kg to lose for your goal";
      } else if (diffKg > 0.2) {
        return "+$diff kg lean gain target";
      } else {
        return "Maintain your current weight";
      }
    }
  }

  // ── Experience Selection ─────────────────────────────────────────────────
  void selectExperience(ExperienceLevel level) {
    if (_selectedExperience == level) return;
    _selectedExperience = level;
    notifyListeners();
  }

  // ── Validation & Persistence ─────────────────────────────────────────────
  bool get isValid {
    final trimmedName = _name.trim();
    return trimmedName.length >= 2 &&
        trimmedName.length <= 50 &&
        _age >= 13 &&
        _age <= 100 &&
        _heightCm > 0 &&
        _weightKg > 0 &&
        _targetWeightKg > 0 &&
        _selectedExperience != null;
  }

  Future<void> continueToNextStep() async {
    draft.name = _name.trim();
    draft.gender = _gender;
    draft.age = _age;
    draft.heightCm = double.parse(_heightCm.toStringAsFixed(1));
    draft.weightKg = double.parse(_weightKg.toStringAsFixed(1));
    draft.targetWeightKg = double.parse(_targetWeightKg.toStringAsFixed(1));
    if (_selectedExperience != null) {
      draft.experienceLevel = _selectedExperience!.backendValue;
    }
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
