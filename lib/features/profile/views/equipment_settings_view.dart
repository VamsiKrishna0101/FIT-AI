import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../../onboarding/models/equipment_copy.dart';
import '../../onboarding/models/equipment_models.dart';
import '../repositories/settings_repository.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';

class EquipmentSettingsView extends StatefulWidget {
  final SettingsRepository? repository;
  const EquipmentSettingsView({super.key, this.repository});

  @override
  State<EquipmentSettingsView> createState() => _EquipmentSettingsViewState();
}

class _EquipmentSettingsViewState extends State<EquipmentSettingsView> {
  late final _repository = widget.repository ?? SettingsRepository();
  Set<String> _selected = {};
  EquipmentGroup _group = EquipmentGroup.weights;
  String? _location, _owner, _error;
  bool _loading = true, _loadFailed = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final owner = await CacheScope.userId();
      final data = await _repository.profile();
      if (await CacheScope.userId() != owner) {
        throw StateError('Your session changed. Reopen Settings.');
      }
      if (!mounted) return;
      _owner = owner;
      _selected = EquipmentCatalog.normalizeIds(
              (data['equipmentIds'] as List? ?? []).whereType<String>())
          .toSet();
      _location = data['trainingLocation'] as String?;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _error = BodyAssessmentRepository.message(error);
      });
    }
  }

  void _toggle(String id) {
    if (_saving) return;
    setState(() {
      _error = null;
      if (id == 'bodyweight_only') {
        _selected = _selected.contains(id) ? {} : {id};
      } else {
        _selected.remove('bodyweight_only');
        if (!_selected.add(id)) _selected.remove(id);
      }
    });
  }

  Future<void> _save() async {
    if (_loading || _loadFailed || _saving || _selected.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (await CacheScope.userId() != _owner) {
        throw StateError('Your session changed. Reopen Settings.');
      }
      final ids = EquipmentCatalog.normalizeIds(_selected);
      await _repository.saveProfile({
        'equipmentIds': ids,
        'equipment': EquipmentCatalog.backendCategories(ids),
        if (_location != null) 'trainingLocation': _location,
      });
      if (mounted) Navigator.pop(context, ids);
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _tile(EquipmentItem item, {bool horizontal = false}) =>
      EquipmentSettingsTile(
        key: ValueKey('equipment-${item.id}'),
        item: item,
        title:
            EquipmentCopy.item(LanguageManager.shared.currentLanguage, item.id),
        selected: _selected.contains(item.id),
        horizontal: horizontal,
        onTap: _saving ? null : () => _toggle(item.id),
      );

  Widget _equipmentGrid(List<EquipmentItem> items) =>
      LayoutBuilder(builder: (context, bounds) {
        final singleColumn = bounds.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        return Column(children: [
          for (var i = 0; i < items.length; i += singleColumn ? 1 : 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: singleColumn
                  ? _tile(items[i], horizontal: true)
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _tile(items[i])),
                          const SizedBox(width: 12),
                          Expanded(
                              child: i + 1 < items.length
                                  ? _tile(items[i + 1])
                                  : const SizedBox.shrink()),
                        ],
                      ),
                    ),
            ),
        ]);
      });

  @override
  Widget build(BuildContext context) {
    final language = LanguageManager.shared.currentLanguage;
    final items = [
      ...EquipmentCatalog.mainItems,
      ...EquipmentCatalog.additionalMachines,
    ].where((item) => item.group == _group).toList();
    return SettingsPage(
      title: 'Equipment',
      centerTitle: true,
      subtitle: '',
      bottom: _loading || _loadFailed
          ? null
          : SettingsSaveButton(
              buttonKey: const ValueKey('equipment-save'),
              saving: _saving,
              onPressed: _selected.isEmpty ? null : _save),
      children: [
        if (_loading)
          const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CupertinoActivityIndicator()))
        else if (_loadFailed) ...[
          SettingsNotice(_error!, error: true),
          TextButton(onPressed: _load, child: const FitnessText('Try again')),
        ] else ...[
          if (_error != null) SettingsNotice(_error!, error: true),
          SettingsDropdown(
            key: const ValueKey('equipment-location'),
            label: 'Training location',
            value: _location,
            fillColor: DSColors.bgElevated,
            choices: const {
              'GYM': 'Gym',
              'HOME': 'Home',
              'OUTDOORS': 'Outdoors',
              'MIX': 'A mix',
            },
            onChanged:
                _saving ? null : (value) => setState(() => _location = value),
          ),
          const SizedBox(height: 16),
          _tile(EquipmentCatalog.noEquipment, horizontal: true),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 2, children: [
            for (final group in EquipmentGroup.values)
              SettingsChoiceChip(
                key: ValueKey('equipment-group-${group.name}'),
                label: EquipmentCopy.tab(language, group),
                selected: group == _group,
                onTap: _saving ? null : () => setState(() => _group = group),
              ),
          ]),
          const SizedBox(height: 12),
          _equipmentGrid(items),
        ],
      ],
    );
  }
}

/// Equipment photos stay uncropped; selection uses the app's white and black.
class EquipmentSettingsTile extends StatelessWidget {
  final EquipmentItem item;
  final String title;
  final bool selected, horizontal;
  final VoidCallback? onTap;
  const EquipmentSettingsTile(
      {super.key,
      required this.item,
      required this.title,
      required this.selected,
      required this.horizontal,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? FitnessTheme.canvas : FitnessTheme.silver;
    final label = Row(children: [
      Expanded(
          child: Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500))),
      const SizedBox(width: 8),
      Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border:
                  Border.all(color: color.withValues(alpha: .6), width: .8)),
          child: selected
              ? Icon(CupertinoIcons.checkmark, size: 12, color: color)
              : null),
    ]);
    final photo = item.assetPath == null
        ? null
        : ColoredBox(
            color: FitnessTheme.canvas,
            child: Image.asset(item.assetPath!,
                fit: BoxFit.contain,
                cacheWidth: 480,
                excludeFromSemantics: true),
          );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : DSColors.bgElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: selected ? Colors.white : FitnessTheme.line, width: .7)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          overlayColor: WidgetStatePropertyAll(color.withValues(alpha: .04)),
          child: horizontal || photo == null
              ? Padding(
                  padding: EdgeInsets.all(photo == null ? 16 : 10),
                  child: Row(children: [
                    if (photo != null) ...[
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 88, height: 88, child: photo)),
                      const SizedBox(width: 14),
                    ],
                    Expanded(child: label),
                  ]))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      AspectRatio(aspectRatio: 1, child: photo),
                      Padding(padding: const EdgeInsets.all(12), child: label),
                    ]),
        ),
      ),
    );
  }
}
