import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../models/equipment_models.dart';
import '../data/equipment_repository.dart';

class EquipmentViewModel extends ChangeNotifier {
  final bool editProfile;
  final EquipmentRepository repository;
  bool needsExactSelection = false;
  String? loadError;
  final int currentStep = 5;
  final int totalSteps = 8;

  OnboardingDraft draft = OnboardingDraft();
  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isValid => _selectedIds.isNotEmpty;
  int _pendingSaves = 0;
  bool get isSaving => _pendingSaves > 0;
  bool _isReady = false;
  bool get isReady => _isReady;
  bool _isDisposed = false;
  Future<void> _saveQueue = Future<void>.value();

  EquipmentViewModel(
      {this.editProfile = false, EquipmentRepository? repository})
      : repository = repository ?? EquipmentRepository() {
    LanguageManager.shared.addListener(_onLanguageChanged);
    loadState();
  }

  AppLanguage get selectedLanguage => LanguageManager.shared.currentLanguage;

  void _onLanguageChanged() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> loadState() async {
    loadError = null;
    _isReady = false;
    if (!_isDisposed) notifyListeners();
    try {
      if (editProfile) {
        final profile = await repository.load();
        if (_isDisposed) return;
        _selectedIds
          ..clear()
          ..addAll(profile.ids);
        needsExactSelection = profile.needsExactSelection;
        _isReady = true;
        notifyListeners();
        return;
      }
      draft = await OnboardingDraft.load();
      if (_isDisposed) return;

      if (draft.languageCode.isNotEmpty) {
        final match = AppLanguage.values.firstWhere(
          (language) => language.code == draft.languageCode,
          orElse: () => LanguageManager.shared.currentLanguage,
        );
        if (LanguageManager.shared.currentLanguage != match) {
          await LanguageManager.shared.selectLanguage(match);
          if (_isDisposed) return;
        }
      }

      _selectedIds
        ..clear()
        ..addAll(EquipmentCatalog.normalizeIds(draft.equipmentIds));
      // A conservative starting point. Never assume access to gym equipment.
      if (_selectedIds.isEmpty) _selectedIds.add('bodyweight_only');
      _isReady = true;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) return;
      loadError = 'Could not load your equipment. Please retry.';
      notifyListeners();
    }
  }

  void toggleEquipment(String id) {
    if (!_isReady || !EquipmentCatalog.byId.containsKey(id)) return;

    if (id == 'bodyweight_only') {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds
          ..clear()
          ..add(id);
      }
    } else {
      _selectedIds.remove('bodyweight_only');
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    }

    notifyListeners();
    if (!editProfile) unawaited(_persistSelection());
  }

  List<String> get backendEquipment =>
      EquipmentCatalog.backendCategories(_selectedIds);

  Future<void> _persistSelection() async {
    draft.equipmentIds = _selectedIds.toList()..sort();
    _pendingSaves++;
    notifyListeners();

    final save = _saveQueue.catchError((_) {}).then((_) => draft.save());
    _saveQueue = save;
    try {
      await save;
    } catch (_) {
      // Continue can retry saving; retain the selection in memory meanwhile.
    } finally {
      _pendingSaves--;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> continueToNextStep() async {
    if (!isValid) return;
    if (editProfile) {
      await repository.save(_selectedIds);
      return;
    }
    draft.equipmentIds = _selectedIds.toList()..sort();
    draft.completedStep = currentStep;
    await _saveQueue.catchError((_) {});
    await draft.save();
  }

  @override
  void dispose() {
    _isDisposed = true;
    LanguageManager.shared.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
