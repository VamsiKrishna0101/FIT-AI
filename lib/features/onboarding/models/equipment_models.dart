import 'package:flutter/material.dart';

enum EquipmentGroup { weights, machines, bodyweight }

class EquipmentItem {
  final String id, backendCategory;
  final EquipmentGroup group;
  final String? assetName;
  final IconData fallbackIcon;
  final bool isAdditionalMachine;
  const EquipmentItem(this.id, this.group, this.backendCategory, this.assetName,
      {this.fallbackIcon = Icons.fitness_center_rounded,
      this.isAdditionalMachine = false});
  String? get assetPath =>
      assetName == null ? null : 'assets/onboarding_images/$assetName.webp';
}

class EquipmentCatalog {
  static const mainItems = <EquipmentItem>[
    EquipmentItem('dumbbells', EquipmentGroup.weights, 'DUMBBELLS', 'dumbell'),
    EquipmentItem('barbell', EquipmentGroup.weights, 'BARBELLS', 'barbell'),
    EquipmentItem('squat_rack', EquipmentGroup.weights, 'OTHER', 'sqaut_rack'),
    EquipmentItem('adjustable_bench', EquipmentGroup.weights, 'BENCH',
        'Adjustable_Weight_Bench'),
    EquipmentItem(
        'kettlebells', EquipmentGroup.weights, 'OTHER', 'Kettlebells'),
    EquipmentItem('cable_station', EquipmentGroup.machines, 'CABLE',
        'Cable_Crossover_Machine'),
    EquipmentItem(
        'smith_machine', EquipmentGroup.machines, 'MACHINES', 'Smith_Machine'),
    EquipmentItem(
        'leg_press', EquipmentGroup.machines, 'MACHINES', 'Leg_Press_Machine'),
    EquipmentItem('resistance_bands', EquipmentGroup.bodyweight, 'OTHER',
        'ResistanceBand'),
    EquipmentItem(
        'pullup_bar', EquipmentGroup.bodyweight, 'OTHER', 'Pull_Up_Rig'),
    EquipmentItem('dip_bars', EquipmentGroup.bodyweight, 'OTHER', 'Dip_Bars'),
  ];
  static const additionalMachines = <EquipmentItem>[
    EquipmentItem(
        'hack_squat', EquipmentGroup.machines, 'MACHINES', 'Hack_Squat_Machine',
        isAdditionalMachine: true),
    EquipmentItem('chest_press', EquipmentGroup.machines, 'MACHINES',
        'Chest_Press_Machine',
        isAdditionalMachine: true),
    EquipmentItem('shoulder_press', EquipmentGroup.machines, 'MACHINES',
        'Shoulder_Press_Machine',
        isAdditionalMachine: true),
    EquipmentItem('leg_extension', EquipmentGroup.machines, 'MACHINES',
        'Leg_Extension_Machine',
        isAdditionalMachine: true),
    // Shared illustrations; selecting one does not select its paired movement.
    EquipmentItem('leg_curl', EquipmentGroup.machines, 'MACHINES',
        'Leg_Extension_Machine',
        isAdditionalMachine: true),
    EquipmentItem('lat_pulldown', EquipmentGroup.machines, 'MACHINES',
        'Lat_Pulldown_Machine',
        isAdditionalMachine: true),
    EquipmentItem(
        'seated_row', EquipmentGroup.machines, 'MACHINES', 'Seated_Row_Machine',
        isAdditionalMachine: true),
    EquipmentItem(
        'pec_deck', EquipmentGroup.machines, 'MACHINES', 'Pec_Deck_Machine',
        isAdditionalMachine: true),
    EquipmentItem(
        'rear_delt', EquipmentGroup.machines, 'MACHINES', 'Pec_Deck_Machine',
        isAdditionalMachine: true),
    EquipmentItem('assisted_pullup_dip', EquipmentGroup.machines, 'MACHINES',
        'Assisted_Pull_Up_Dip_Machine',
        isAdditionalMachine: true),
  ];
  static const noEquipment = EquipmentItem(
      'bodyweight_only', EquipmentGroup.bodyweight, 'OTHER', null,
      fallbackIcon: Icons.accessibility_new_rounded);
  static const legacyIds = <String, List<String>>{
    'barbell_rack': ['barbell', 'squat_rack'],
    'pullup_dip_station': ['pullup_bar', 'dip_bars'],
    'leg_extension_curl': ['leg_extension', 'leg_curl'],
    'lat_pulldown_row': ['lat_pulldown', 'seated_row'],
    'pec_deck_rear_delt': ['pec_deck', 'rear_delt'],
  };
  static final byId = <String, EquipmentItem>{
    for (final item in [noEquipment, ...mainItems, ...additionalMachines])
      item.id: item,
  };
  static List<String> normalizeIds(Iterable<String> ids) {
    final result = <String>{};
    for (final id in ids) {
      result.addAll((legacyIds[id] ?? [id]).where(byId.containsKey));
    }
    if (result.length > 1) result.remove('bodyweight_only');
    return result.toList()..sort();
  }

  static List<String> backendCategories(Iterable<String> ids) =>
      {for (final id in normalizeIds(ids)) byId[id]!.backendCategory}.toList()
        ..sort();
}
