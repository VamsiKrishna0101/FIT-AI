import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';
import '../models/body_scan_models.dart';

class BodyScanRepository {
  static final BodyScanRepository shared = BodyScanRepository._();
  BodyScanRepository._();

  BodyScanModel? _cachedScan;
  HeatmapComparisonModel? _cachedComparison;
  String? _activeUserId;

  BodyScanModel? get currentScan => _cachedScan;
  HeatmapComparisonModel? get currentComparison => _cachedComparison;

  Future<void> initialize() async {
    final userId = await CacheScope.userId();
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _cachedScan = null;
      _cachedComparison = null;
    }

    try {
      final scanJson = await LocalCache.shared
          .getJson(await CacheScope.userKey('latest_body_scan'));
      _cachedScan = scanJson == null ? null : BodyScanModel.fromJson(scanJson);
      final comparisonJson = await LocalCache.shared
          .getJson(await CacheScope.userKey('heatmap_comparison'));
      _cachedComparison = comparisonJson == null
          ? null
          : HeatmapComparisonModel.fromJson(comparisonJson);
    } catch (_) {
      // Invalid cached payloads are discarded; an empty cache is not a scan.
      _cachedScan = null;
      _cachedComparison = null;
    }
  }

  Future<BodyScanModel?> fetchLatestScan({bool forceRefresh = false}) async {
    final userId = await CacheScope.userId();
    final key = await CacheScope.userKey('latest_body_scan');
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>(Endpoints.bodyScanLatest);
    if (response.statusCode != 200) {
      throw StateError(
          'Could not load the latest body scan (HTTP ${response.statusCode}).');
    }

    final raw = response.data;
    if (raw == null || raw.isEmpty) {
      if (await CacheScope.userId() != userId) return null;
      _activeUserId = userId;
      _cachedScan = null;
      _cachedComparison = null;
      await LocalCache.shared.remove(key);
      await LocalCache.shared
          .remove(await CacheScope.userKey('heatmap_comparison'));
      return null;
    }

    final fresh = BodyScanModel.fromJson(raw);
    if (!fresh.hasScan) return null;
    if (await CacheScope.userId() != userId) return null;
    _activeUserId = userId;
    _cachedScan = fresh;
    await LocalCache.shared.saveJson(key, raw);
    return fresh;
  }

  Future<HeatmapComparisonModel?> fetchComparison(
      {bool forceRefresh = false}) async {
    final userId = await CacheScope.userId();
    final key = await CacheScope.userKey('heatmap_comparison');
    final response = await ApiClient.shared
        .get<Map<String, dynamic>>(Endpoints.heatmapCompare);
    if (response.statusCode != 200) {
      throw StateError(
          'Could not load scan comparison (HTTP ${response.statusCode}).');
    }

    final raw = response.data;
    if (raw == null || raw.isEmpty) {
      if (await CacheScope.userId() != userId) return null;
      _cachedComparison = null;
      await LocalCache.shared.remove(key);
      return null;
    }
    final fresh = HeatmapComparisonModel.fromJson(raw);
    if (fresh.scan1Id.isEmpty || fresh.scan2Id.isEmpty) {
      if (await CacheScope.userId() != userId) return null;
      _cachedComparison = null;
      await LocalCache.shared.remove(key);
      return null;
    }
    if (await CacheScope.userId() != userId) return null;
    _activeUserId = userId;
    _cachedComparison = fresh;
    await LocalCache.shared.saveJson(key, raw);
    return fresh;
  }
}
