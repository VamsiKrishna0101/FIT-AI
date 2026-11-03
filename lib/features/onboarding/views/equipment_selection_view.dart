import '../viewmodels/onboarding_controller.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/app_language.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/onboarding_scaffold.dart';
import '../data/equipment_repository.dart';
import '../models/equipment_copy.dart';
import '../models/equipment_models.dart';
import '../viewmodels/equipment_viewmodel.dart';
import 'lifestyle_nutrition_limitations_view.dart';

class EquipmentSelectionView extends StatefulWidget {
  final VoidCallback? onContinue;
  final bool editProfile;
  final bool coaching;
  final String? previousAnswer;
  final EquipmentRepository? repository;
  final OnboardingController? controller;
  const EquipmentSelectionView(
      {super.key,
      this.onContinue,
      this.editProfile = false,
      this.coaching = false,
      this.previousAnswer,
      this.repository,
      this.controller});
  @override
  State<EquipmentSelectionView> createState() => _EquipmentSelectionViewState();
}

class _EquipmentSelectionViewState extends State<EquipmentSelectionView> {
  late final EquipmentViewModel _viewModel;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  bool _submitting = false;
  static const _sections = <String, List<String>>{
    'Free weights': ['dumbbells', 'kettlebells', 'barbell'],
    'Benches & racks': ['adjustable_bench', 'squat_rack'],
    'Machines & cables': [
      'cable_station',
      'smith_machine',
      'leg_press',
      'hack_squat',
      'chest_press',
      'shoulder_press',
      'leg_extension',
      'leg_curl',
      'lat_pulldown',
      'seated_row',
      'pec_deck',
      'rear_delt',
      'assisted_pullup_dip'
    ],
    'Bands & bodyweight': ['resistance_bands', 'pullup_bar', 'dip_bars'],
  };
  String? _saveError;
  @override
  void initState() {
    super.initState();
    _viewModel = EquipmentViewModel(
        editProfile: widget.editProfile,
        repository: widget.repository,
        controller: widget.controller)
      ..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_submitting || !_viewModel.isReady || !_viewModel.isValid) return;
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      await _viewModel.continueToNextStep();
      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
      } else if (widget.editProfile) {
        Navigator.of(context).pop(true);
      } else {
        await OnboardingPageRoute(
                page: LifestyleNutritionLimitationsView(
                    controller: _viewModel.controller))
            .open(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _saveError = 'Could not save equipment. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: FitnessText(_saveError!),
            backgroundColor: FitnessTheme.surface,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toggle(String id) {
    if (_submitting) return;
    setState(() => _saveError = null);
    _viewModel.toggleEquipment(id);
  }

  void _searchChanged(String query) {
    setState(() => _query = query.trim().toLowerCase());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool _matches(EquipmentItem item) =>
      _query.isEmpty ||
      EquipmentCopy.item(_viewModel.selectedLanguage, item.id)
          .toLowerCase()
          .contains(_query) ||
      EquipmentCopy.item(AppLanguage.uk, item.id)
          .toLowerCase()
          .contains(_query) ||
      item.id.contains(_query) ||
      item.id.replaceAll('_', ' ').contains(_query);
  Widget _row(EquipmentItem item) => _EquipmentRow(
      key: ValueKey('equipment-${item.id}'),
      item: item,
      title: EquipmentCopy.item(_viewModel.selectedLanguage, item.id),
      selected: _viewModel.selectedIds.contains(item.id),
      onTap:
          _viewModel.isReady && !_submitting ? () => _toggle(item.id) : null);
  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selected = _viewModel.selectedIds;
    final sections = <String, List<EquipmentItem>>{
      for (final section in _sections.entries)
        section.key: [
          for (final id in section.value)
            if (_matches(EquipmentCatalog.byId[id]!)) EquipmentCatalog.byId[id]!
        ],
    };
    final showBodyweight = _matches(EquipmentCatalog.noEquipment);
    final hasResults =
        showBodyweight || sections.values.any((items) => items.isNotEmpty);
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'Your equipment',
      catalogue: true,
      scrollController: _scroll,
      title: 'Review your equipment',
      subtitle: _viewModel.needsExactSelection
          ? 'Choose your exact equipment to update your saved setup.'
          : 'Choose the equipment available to you',
      actionTitle:
          widget.editProfile ? EquipmentCopy.saveLabel(language) : 'Done',
      onBack: _submitting ? null : () => Navigator.of(context).maybePop(),
      onContinue: _viewModel.isReady && _viewModel.isValid && !_submitting
          ? _onContinue
          : null,
      loading: _submitting,
      actionMessage: _saveError,
      footer: _viewModel.isReady
          ? (_viewModel.isValid
              ? EquipmentCopy.selectionCount(language,
                  selected.contains('bodyweight_only') ? 0 : selected.length)
              : EquipmentCopy.requiredSelectionHint(language))
          : null,
      bottomAccessory: TextField(
          key: const ValueKey('equipment-search'),
          controller: _search,
          readOnly: _submitting,
          onChanged: _searchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
              hintText: fitnessText(context, 'Search equipment'),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 21, color: Color(0xFFB5B5BC)),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('equipment-clear-search'),
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                      onPressed: _submitting
                          ? null
                          : () {
                              _search.clear();
                              _searchChanged('');
                            },
                      icon: const Icon(Icons.close_rounded, size: 18)),
              filled: true,
              fillColor: const Color(0xFF242427),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFF797980))))),
      children: [
        if (_viewModel.loadError != null)
          Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                FitnessText(_viewModel.loadError!),
                TextButton(
                    onPressed: _viewModel.loadState,
                    child: const FitnessText('Retry'))
              ]))
        else if (!_viewModel.isReady)
          const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child:
                      CupertinoActivityIndicator(color: FitnessTheme.silver)))
        else ...[
          if (showBodyweight) _row(EquipmentCatalog.noEquipment),
          for (final section in sections.entries)
            if (section.value.isNotEmpty) ...[
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                  child: Semantics(
                      header: true,
                      child: FitnessText(section.key,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                              letterSpacing: -.3)))),
              for (final item in section.value) _row(item),
            ],
          if (!hasResults)
            const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FitnessText('No equipment found',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      FitnessText('Try another name.',
                          style: TextStyle(
                              fontSize: 14, color: FitnessTheme.muted)),
                    ])),
        ],
      ],
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  final EquipmentItem item;
  final String title;
  final bool selected;
  final VoidCallback? onTap;
  const _EquipmentRow(
      {super.key,
      required this.item,
      required this.title,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        checked: selected,
        enabled: onTap != null,
        label: title,
        onTap: onTap,
        child: ExcludeSemantics(
            child: Material(
          color: const Color(0xFF171719),
          child: InkWell(
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 94),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Color(0xFF303034), width: .6))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(children: [
                  Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                          color: const Color(0xFF242427),
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(6),
                      child: item.assetPath == null
                          ? Icon(item.fallbackIcon,
                              size: 29, color: FitnessTheme.silver)
                          : Image.asset(item.assetPath!,
                              fit: BoxFit.contain,
                              cacheWidth: 192,
                              excludeFromSemantics: true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: FitnessText(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: Color(0xFFF3F3F5)))),
                  const SizedBox(width: 12),
                  IgnorePointer(
                      child: Checkbox(
                          value: selected,
                          onChanged: onTap == null ? null : (_) => onTap!(),
                          activeColor: FitnessTheme.silver,
                          checkColor: Colors.black,
                          side: const BorderSide(
                              color: Color(0xFF818187), width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap)),
                ]),
              )),
        )),
      );
}
