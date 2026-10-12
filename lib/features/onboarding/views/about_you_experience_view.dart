import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../core/components/fit_toast.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/about_you_controls.dart';
import '../components/experience_card.dart';
import '../components/onboarding_scaffold.dart';
import '../models/experience_level.dart';
import '../viewmodels/about_you_viewmodel.dart';
import 'schedule_location_view.dart';

// MARK: - Combined Screen 02 & 03: About You & Your Experience (Apple iOS Premium)
class AboutYouExperienceView extends StatefulWidget {
  const AboutYouExperienceView({super.key});

  @override
  State<AboutYouExperienceView> createState() => _AboutYouExperienceViewState();
}

class _AboutYouExperienceViewState extends State<AboutYouExperienceView>
    with TickerProviderStateMixin {
  late final AboutYouViewModel _viewModel;
  late final TextEditingController _nameController;
  late final AnimationController _expStaggerCtrl;

  @override
  void initState() {
    super.initState();
    _viewModel = AboutYouViewModel()..addListener(_rebuild);
    _nameController = TextEditingController(text: _viewModel.name);
    _expStaggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _expStaggerCtrl.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_viewModel.name.isNotEmpty) {
          _nameController.text = _viewModel.name;
        }
      }
    });
  }

  void _rebuild() {
    if (!mounted) return;
    if (_nameController.text != _viewModel.name && _viewModel.name.isNotEmpty) {
      _nameController.text = _viewModel.name;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    _nameController.dispose();
    _expStaggerCtrl.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onContinue() async {
    final language = _viewModel.selectedLanguage;
    if (!_viewModel.isValid) {
      HapticFeedback.mediumImpact();
      final String msg = _viewModel.name.trim().length < 2
          ? language.nameValidationPrompt
          : 'Please pick your experience level to continue.';
      FitToast.show(
        context,
        message: msg,
        icon: _viewModel.name.trim().length < 2
            ? CupertinoIcons.person
            : CupertinoIcons.sparkles,
      );
      return;
    }

    await _viewModel.continueToNextStep();
    if (!mounted) return;
    Navigator.of(context).push(
      OnboardingPageRoute(page: const ScheduleLocationView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selectedExperience = _viewModel.selectedExperience;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      title: language.headlineAboutYou,
      subtitle: 'A few details to build a plan around you.',
      actionTitle: language.continueButtonTitle,
      onBack: _onBack,
      onContinue: _onContinue,
      children: [
        // ── SECTION 1: ABOUT YOU ─────────────────────────────
        // Name Input (Zero icons, Apple liquid glass)
        LiquidNameInput(
          controller: _nameController,
          label: language.nameLabel,
          placeholder: language.namePlaceholder,
          onChanged: _viewModel.setName,
        ),

        const SizedBox(height: 12),

        // Full-Width Apple Gender Selector (Male / Female)
        AppleGenderSelector(
          selectedGender: _viewModel.gender,
          maleLabel: language.genderMale,
          femaleLabel: language.genderFemale,
          onSelected: _viewModel.setGender,
        ),

        const SizedBox(height: 24),

        // ── BIOMETRICS SECTION WITH APPLE UNIT SWITCHER ──────
        BiometricsHeaderWithUnits(
          title: language.biometricsSectionTitle,
          isImperial: _viewModel.isImperial,
          imperialLabel: language.unitImperialLabel,
          metricLabel: language.unitMetricLabel,
          onUnitChanged: _viewModel.setImperial,
        ),

        const SizedBox(height: 10),

        // Age Stepper Card
        AppleBiometricCard(
          label: language.ageLabel,
          valueDisplay: '${_viewModel.age}',
          unitDisplay: language.yearsUnit,
          onDecrement: _viewModel.decrementAge,
          onIncrement: _viewModel.incrementAge,
        ),

        const SizedBox(height: 10),

        // Height Stepper Card
        AppleBiometricCard(
          label: language.heightLabel,
          valueDisplay: _viewModel.heightDisplay,
          unitDisplay: _viewModel.heightUnitDisplay,
          secondaryDisplay: _viewModel.secondaryHeightDisplay,
          onDecrement: _viewModel.decrementHeight,
          onIncrement: _viewModel.incrementHeight,
        ),

        const SizedBox(height: 10),

        // Weight Stepper Card
        AppleBiometricCard(
          label: language.weightLabel,
          valueDisplay: _viewModel.weightDisplay,
          unitDisplay: _viewModel.weightUnitDisplay,
          secondaryDisplay: _viewModel.secondaryWeightDisplay,
          onDecrement: _viewModel.decrementWeight,
          onIncrement: _viewModel.incrementWeight,
        ),

        const SizedBox(height: 10),

        // Target Weight Stepper Card
        AppleBiometricCard(
          label: language.targetWeightLabel,
          valueDisplay: _viewModel.targetWeightDisplay,
          unitDisplay: _viewModel.weightUnitDisplay,
          secondaryDisplay: _viewModel.secondaryTargetWeightDisplay,
          onDecrement: _viewModel.decrementTargetWeight,
          onIncrement: _viewModel.incrementTargetWeight,
        ),

        const SizedBox(height: 10),

        // Goal Delta Summary Badge
        AppleGoalSummaryBadge(
          text: _viewModel.weightGoalSummary,
        ),

        const SizedBox(height: 28),

        // ── SECTION 2: YOUR EXPERIENCE (Text-only header, no stars) ──
        FitnessText(
          language.experienceSectionTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 12),

        // 3 Experience Cards — staggered slide-up entrance
        ...List.generate(ExperienceLevel.values.length, (index) {
          final level = ExperienceLevel.values[index];
          final isSelected = selectedExperience == level;
          final title = language.experienceTitle(level);
          final subtitle = language.experienceSubtitle(level);
          final start = index * 0.20;
          final end = (start + 0.55).clamp(0.0, 1.0);
          final cardAnim = CurvedAnimation(
            parent: _expStaggerCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeTransition(
              opacity: cardAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.22),
                  end: Offset.zero,
                ).animate(cardAnim),
                child: ExperienceCard(
                  level: level,
                  title: title,
                  subtitle: subtitle,
                  isSelected: isSelected,
                  onTap: () => _viewModel.selectExperience(level),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}
