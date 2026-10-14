import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../models/equipment_models.dart';

class EquipmentProfile {
  final List<String> ids;
  final bool needsExactSelection;
  const EquipmentProfile(this.ids, {this.needsExactSelection = false});
}

class EquipmentRepository {
  String? _owner;
  Future<EquipmentProfile> load() async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') throw StateError('Sign in to edit equipment.');
    final data = await UserDataCache.shared.load('profile', 'onboarding', () async {
      final response = await ApiClient.shared.get<Map<String, dynamic>>('/api/onboarding');
      return Map<String, dynamic>.from(response.data?['data'] as Map);
    });
    if (await CacheScope.userId() != owner) {
      throw StateError('Your session changed. Reopen equipment.');
    }
    _owner = owner;
    final profile = data;
    final ids = EquipmentCatalog.normalizeIds(
        (profile['equipmentIds'] as List? ?? []).whereType<String>());
    return EquipmentProfile(ids, needsExactSelection: ids.isEmpty);
  }

  Future<void> save(Iterable<String> selectedIds) async {
    if (_owner == null || await CacheScope.userId() != _owner) {
      throw StateError('Your session changed. Reopen equipment.');
    }
    final ids = EquipmentCatalog.normalizeIds(selectedIds);
    if (ids.isEmpty) throw StateError('Choose at least one option.');
    await ApiClient.shared.patch('/api/onboarding', data: {
      'equipmentIds': ids,
      'equipment': EquipmentCatalog.backendCategories(ids),
    });
    if (await CacheScope.userId() != _owner) {
      throw StateError('Your session changed. Reopen equipment.');
    }
    await UserDataCache.shared.invalidate('profile');
    await UserDataCache.shared.invalidate('training_map');
  }
}
