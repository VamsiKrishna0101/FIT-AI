import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/duration_grid_chips.dart';
import '../components/location_apple_card.dart';
import '../components/onboarding_scaffold.dart';
import '../components/schedule_frequency_pills.dart';
import '../viewmodels/schedule_location_viewmodel.dart';
import 'equipment_selection_view.dart';

// MARK: - Combined Screen 04 & 05: Your Schedule & Space (Apple iOS Premium)
class ScheduleLocationView extends StatefulWidget {
  const ScheduleLocationView({super.key});

  @override
  State<ScheduleLocationView> createState() => _ScheduleLocationViewState();
}

class _ScheduleLocationViewState extends State<ScheduleLocationView> {
  late final ScheduleLocationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleLocationViewModel()..addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onContinue() async {
    await _viewModel.continueToNextStep();
    if (!mounted) return;
    Navigator.of(context).push(
      OnboardingPageRoute(page: const EquipmentSelectionView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selectedDays = _viewModel.selectedDays;
    final selectedDuration = _viewModel.selectedDuration;
    final selectedLocation = _viewModel.selectedLocation;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      title: language.headlineScheduleAndLocation,
      subtitle: 'Choose a rhythm that fits your life.',
      actionTitle: language.continueButtonTitle,
      onBack: _onBack,
      onContinue: _viewModel.isValid ? _onContinue : null,
      children: [
        // ── 1. Weekly Commitment ─────────────────────────────
        FitnessText(
          language.weeklyCommitmentQuestion
              .replaceAll('?', '')
              .trim()
              .toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        ScheduleFrequencyPills(
          selectedOption: selectedDays,
          onSelected: _viewModel.selectDays,
        ),

        const SizedBox(height: 24),

        // ── 2. Session Duration ──────────────────────────────
        FitnessText(
          language.sessionDurationQuestion
              .replaceAll('?', '')
              .trim()
              .toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        DurationGridChips(
          selectedDuration: selectedDuration,
          onSelected: _viewModel.selectDuration,
          titleBuilder: language.durationOptionTitle,
        ),

        const SizedBox(height: 24),

        // ── 3. Training Location / Space ─────────────────────
        FitnessText(
          language.trainingLocationQuestion
              .replaceAll('?', '')
              .trim()
              .toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        LocationGridCards(
          selectedLocation: selectedLocation,
          onSelected: _viewModel.selectLocation,
          titleBuilder: language.locationOptionTitle,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
