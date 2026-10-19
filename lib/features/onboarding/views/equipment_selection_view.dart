import '../viewmodels/onboarding_controller.dart';
import '../../../core/theme/ds_motion.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final EquipmentRepository? repository;
  final OnboardingController? controller;
  const EquipmentSelectionView(
      {super.key,
      this.onContinue,
      this.editProfile = false,
      this.repository,
      this.controller});
  @override
  State<EquipmentSelectionView> createState() => _EquipmentSelectionViewState();
}

class _EquipmentSelectionViewState extends State<EquipmentSelectionView> {
  late final EquipmentViewModel _viewModel;
  EquipmentGroup _group = EquipmentGroup.weights;
  bool _moreMachinesExpanded = false, _submitting = false;
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

  Widget _grid(List<EquipmentItem> items) {
    final scale = MediaQuery.textScalerOf(context);
    return GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 178 + (scale.scale(13) - 13) * 3.6),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _EquipmentCard(
              key: ValueKey(item.id),
              item: item,
              title: EquipmentCopy.item(_viewModel.selectedLanguage, item.id),
              selected: _viewModel.selectedIds.contains(item.id),
              onTap: _viewModel.isReady && !_submitting
                  ? () => _toggle(item.id)
                  : null);
        });
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selected = _viewModel.selectedIds;
    final noEquipment = selected.contains('bodyweight_only');
    final primary = EquipmentCatalog.mainItems
        .where((item) => item.group == _group)
        .toList();
    final machineCount = EquipmentCatalog.additionalMachines
        .where((item) => selected.contains(item.id))
        .length;
    return OnboardingScaffold(
        step: _viewModel.currentStep,
        totalSteps: _viewModel.totalSteps,
        showProgress: !widget.editProfile,
        title: EquipmentCopy.equipmentTitle(language),
        subtitle: EquipmentCopy.subtitle(language),
        actionTitle: widget.editProfile
            ? EquipmentCopy.saveLabel(language)
            : language.continueButtonTitle,
        onBack: _submitting ? null : () => Navigator.of(context).maybePop(),
        onContinue: _viewModel.isReady && _viewModel.isValid && !_submitting
            ? _onContinue
            : null,
        loading: _submitting,
        footer: EquipmentCopy.editLater(language),
        children: [
          if (_viewModel.loadError != null) ...[
            FitnessText(_viewModel.loadError!,
                style: const TextStyle(color: FitnessTheme.muted)),
            TextButton(
                onPressed: _viewModel.loadState,
                child: const FitnessText('Retry')),
          ] else if (!_viewModel.isReady)
            const Center(
                child: CupertinoActivityIndicator(color: FitnessTheme.silver))
          else ...[
            if (_viewModel.needsExactSelection) ...[
              const FitnessText(
                  'Choose your exact equipment to update your saved setup.',
                  style: TextStyle(
                      fontSize: 13, color: FitnessTheme.muted, height: 1.4)),
              const SizedBox(height: 14),
            ],
            OnboardingChoice(
                title: EquipmentCopy.item(language, 'bodyweight_only'),
                selected: noEquipment,
                onTap: () => _toggle('bodyweight_only')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: FitnessText(EquipmentCopy.group(language, _group),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.3))),
              const SizedBox(width: 8),
              FitnessText(
                  EquipmentCopy.selectionCount(
                      language, noEquipment ? 0 : selected.length),
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final group in EquipmentGroup.values)
                _CategoryChip(
                    title: EquipmentCopy.tab(language, group),
                    selected: group == _group,
                    count: selected
                        .where((id) =>
                            id != 'bodyweight_only' &&
                            EquipmentCatalog.byId[id]?.group == group)
                        .length,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _group = group);
                    }),
            ]),
            const SizedBox(height: 16),
            _grid(primary),
            if (_group == EquipmentGroup.machines) ...[
              const SizedBox(height: 12),
              Material(
                  color: FitnessTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(
                          () => _moreMachinesExpanded = !_moreMachinesExpanded),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Expanded(
                                child: FitnessText(
                                    EquipmentCopy.moreMachinesLabel(language),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500))),
                            if (machineCount > 0) ...[
                              FitnessText('$machineCount',
                                  style: const TextStyle(
                                      color: FitnessTheme.silver,
                                      fontSize: 12)),
                              const SizedBox(width: 10),
                            ],
                            Icon(
                                _moreMachinesExpanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.chevron_down,
                                size: 14,
                                color: FitnessTheme.muted),
                          ])))),
              if (_moreMachinesExpanded) ...[
                const SizedBox(height: 12),
                _grid(EquipmentCatalog.additionalMachines),
              ],
            ],
          ],
          if (_saveError != null) ...[
            const SizedBox(height: 14),
            FitnessText(_saveError!,
                style:
                    const TextStyle(color: FitnessTheme.coral, fontSize: 13)),
          ],
        ]);
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.title,
      required this.selected,
      required this.count,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      child: Material(
          color: selected ? const Color(0xFF333333) : FitnessTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(
                  color:
                      selected ? const Color(0xFF767676) : Colors.transparent,
                  width: .7)),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: FitnessText(count == 0 ? title : '$title · $count',
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : FitnessTheme.muted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400))))));
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final String title;
  final bool selected;
  final VoidCallback? onTap;
  const _EquipmentCard(
      {super.key,
      required this.item,
      required this.title,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final path = item.assetPath;
    return Semantics(
        button: true,
        selected: selected,
        label: title,
        child: AnimatedContainer(
            key: ValueKey('equipment-${item.id}'),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DSMotion.press,
            decoration: BoxDecoration(
                color: FitnessTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected
                        ? const Color(0xFFBDBDBD)
                        : const Color(0x14FFFFFF),
                    width: 1)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        onTap: onTap == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onTap!();
                              },
                        child: Column(children: [
                          Expanded(
                              child: Stack(fit: StackFit.expand, children: [
                            Container(
                                color: const Color(0xFF151515),
                                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                                child: path == null
                                    ? Icon(item.fallbackIcon,
                                        color: FitnessTheme.muted)
                                    : LayoutBuilder(
                                        builder: (context, bounds) => Image.asset(
                                            path,
                                            fit: BoxFit.contain,
                                            excludeFromSemantics: true,
                                            gaplessPlayback: true,
                                            // Decode by width only to preserve the source aspect ratio.
                                            cacheWidth: (bounds.maxWidth *
                                                    MediaQuery
                                                        .devicePixelRatioOf(
                                                            context))
                                                .ceil(),
                                            filterQuality: FilterQuality.medium,
                                            errorBuilder: (_, __, ___) => Icon(
                                                item.fallbackIcon,
                                                size: 36,
                                                color: FitnessTheme.muted)))),
                            Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected
                                            ? FitnessTheme.silver
                                            : const Color(0xAA171717),
                                        border: Border.all(
                                            color: selected
                                                ? FitnessTheme.silver
                                                : const Color(0xFF656565),
                                            width: .8)),
                                    child: selected
                                        ? const Icon(CupertinoIcons.check_mark,
                                            size: 13, color: Color(0xFF161616))
                                        : null)),
                          ])),
                          Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 12, 10, 12),
                              child: SizedBox(
                                  height: MediaQuery.textScalerOf(context)
                                          .scale(13) *
                                      2.5,
                                  child: Center(
                                      child: FitnessText(title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              height: 1.2,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              letterSpacing: -.15,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFFDFDFDF)))))),
                        ]))))));
  }
}
