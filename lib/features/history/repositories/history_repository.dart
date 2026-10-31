import 'dart:async';

import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';

// MARK: - Recovery history point (GET /api/history/recovery)
class RecoveryPoint {
  final DateTime date;
  final double? hrv;
  final String? hrvMethod;
  final int? restingHr;
  final int? recoveryScore;
  final double? sleepHours;

  const RecoveryPoint({
    required this.date,
    this.hrv,
    this.hrvMethod,
    this.restingHr,
    this.recoveryScore,
    this.sleepHours,
  });

  factory RecoveryPoint.fromJson(Map<String, dynamic> j) => RecoveryPoint(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        hrv: (j['hrv'] as num?)?.toDouble(),
        hrvMethod: j['hrvMethod'] as String?,
        restingHr: (j['restingHR'] as num?)?.toInt(),
        recoveryScore: (j['recoveryScore'] as num?)?.toInt(),
        sleepHours: (j['sleepHours'] as num?)?.toDouble(),
      );
}

// MARK: - History Repository (SWR, 15-minute TTL, user-scoped)
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository shared = HistoryRepository._();

  static const Duration _ttl = Duration(minutes: 15);
  final Map<String, List<RecoveryPoint>> _recoveryMem = {};
  final Map<String, DateTime> _recoveryUpdated = {};
  final Map<String, Future<List<RecoveryPoint>>> _inFlight = {};
  int _revision = 0;

  Future<void> invalidate() async {
    _revision++;
    _recoveryMem.clear();
    _recoveryUpdated.clear();
    _inFlight.clear();
    _nutritionMem.clear();
    _nutritionUpdated.clear();
    _nutritionInFlight.clear();
    await LocalCache.shared.removeByPrefix(
        '${CacheScope.userPrefix}${await CacheScope.userId()}_history_');
  }

  // A synchronous peek cannot verify the current account. Call getRecovery instead.
  List<RecoveryPoint>? peekRecovery({int days = 30}) => null;

  Future<List<RecoveryPoint>> getRecovery({
    int days = 30,
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return const <RecoveryPoint>[];
    final endDate = CacheScope.todayKey(date);
    final key =
        await CacheScope.userKey('history_recovery_v5_${days}_$endDate');

    if (!forceRefresh) {
      final mem = _recoveryMem[key];
      if (mem != null) {
        if (DateTime.now().difference(_recoveryUpdated[key]!) > _ttl) {
          unawaited(_fetchRecovery(days, key, owner, endDate));
        }
        return mem;
      }
      final entry = await LocalCache.shared.getEntry(key);
      if (entry != null && entry.$1 is List) {
        if (await CacheScope.userId() != owner) return const <RecoveryPoint>[];
        final list = _parse(entry.$1 as List);
        _recoveryMem[key] = list;
        _recoveryUpdated[key] = DateTime.now().subtract(entry.$2);
        if (entry.$2 > _ttl) {
          unawaited(_fetchRecovery(days, key, owner, endDate));
        }
        return list;
      }
    }
    return _fetchRecovery(days, key, owner, endDate);
  }

  Future<List<RecoveryPoint>> _fetchRecovery(
      int days, String key, String owner, String endDate) {
    final revision = _revision;
    return _inFlight[key] ??= () async {
      try {
        final res = await ApiClient.shared.get<Map<String, dynamic>>(
          Endpoints.recoveryHistory,
          queryParameters: {'days': days, 'date': endDate},
        );
        final raw = res.data?['data'];
        if (res.statusCode == 200 && raw is List) {
          if (await CacheScope.userId() != owner || revision != _revision) {
            return const <RecoveryPoint>[];
          }
          final list = _parse(raw);
          _recoveryMem[key] = list;
          _recoveryUpdated[key] = DateTime.now();
          await LocalCache.shared.saveEntry(key, raw);
          return list;
        }
      } catch (_) {
        // Offline: keep whatever we have.
      } finally {
        if (revision == _revision) _inFlight.remove(key);
      }
      return await CacheScope.userId() == owner
          ? _recoveryMem[key] ?? const <RecoveryPoint>[]
          : const <RecoveryPoint>[];
    }();
  }

  List<RecoveryPoint> _parse(List raw) => raw
      .whereType<Map<String, dynamic>>()
      .where((row) => DateTime.tryParse(row['date']?.toString() ?? '') != null)
      .map(RecoveryPoint.fromJson)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // ── Nutrition History ───────────────────────────────────────────────────────
  final Map<String, List<NutritionHistoryPoint>> _nutritionMem = {};
  final Map<String, Future<List<NutritionHistoryPoint>>> _nutritionInFlight =
      {};
  final Map<String, DateTime> _nutritionUpdated = {};

  List<NutritionHistoryPoint>? peekNutrition({int days = 7}) => null;

  Future<List<NutritionHistoryPoint>> getNutrition({
    int days = 7,
    bool forceRefresh = false,
  }) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') return const <NutritionHistoryPoint>[];
    final key = await CacheScope.userDayKey('history_nutrition_v3_$days');

    if (!forceRefresh) {
      final mem = _nutritionMem[key];
      if (mem != null) {
        if (DateTime.now().difference(_nutritionUpdated[key]!) > _ttl) {
          unawaited(_fetchNutrition(days, key, owner));
        }
        return mem;
      }
      final entry = await LocalCache.shared.getEntry(key);
      if (entry != null && entry.$1 is List) {
        if (await CacheScope.userId() != owner) {
          return const <NutritionHistoryPoint>[];
        }
        final list = _parseNutrition(entry.$1 as List);
        _nutritionMem[key] = list;
        _nutritionUpdated[key] = DateTime.now().subtract(entry.$2);
        if (entry.$2 > _ttl) unawaited(_fetchNutrition(days, key, owner));
        return list;
      }
    }
    return _fetchNutrition(days, key, owner);
  }

  Future<List<NutritionHistoryPoint>> _fetchNutrition(
      int days, String key, String owner) {
    final revision = _revision;
    return _nutritionInFlight[key] ??= () async {
      try {
        final res = await ApiClient.shared.get<Map<String, dynamic>>(
          Endpoints.nutritionHistory,
          queryParameters: {'days': days},
        );
        final raw = res.data?['data'];
        if (res.statusCode == 200 && raw is List) {
          if (await CacheScope.userId() != owner || revision != _revision) {
            return const <NutritionHistoryPoint>[];
          }
          final list = _parseNutrition(raw);
          _nutritionMem[key] = list;
          _nutritionUpdated[key] = DateTime.now();
          await LocalCache.shared.saveEntry(key, raw);
          return list;
        }
      } catch (_) {
        // Offline: preserve existing
      } finally {
        if (revision == _revision) _nutritionInFlight.remove(key);
      }
      return await CacheScope.userId() == owner
          ? _nutritionMem[key] ?? const <NutritionHistoryPoint>[]
          : const <NutritionHistoryPoint>[];
    }();
  }

  List<NutritionHistoryPoint> _parseNutrition(List raw) => raw
      .whereType<Map<String, dynamic>>()
      .where((row) => DateTime.tryParse(row['date']?.toString() ?? '') != null)
      .map(NutritionHistoryPoint.fromJson)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

// MARK: - Nutrition history point (GET /api/history/nutrition)
class NutritionHistoryPoint {
  final DateTime date;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionHistoryPoint({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionHistoryPoint.fromJson(Map<String, dynamic> j) =>
      NutritionHistoryPoint(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0.0,
      );
}
