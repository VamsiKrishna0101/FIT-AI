import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/cache_scope.dart';
import '../network/api_client.dart';
import '../network/endpoints.dart';
import '../storage/local_cache.dart';
import '../storage/secure_session_store.dart';
import '../../features/today/repositories/today_repository.dart';
import '../../features/history/repositories/history_repository.dart';
import '../../features/progress/repositories/progress_repository.dart';
import 'health_models.dart';
import 'health_normalizer.dart';

class HealthSyncService extends ChangeNotifier {
  HealthSyncService._()
      : _health = Health(),
        _provider = null,
        _now = DateTime.now,
        _energyTotal = null,
        _stepTotal = _platformSteps;
  @visibleForTesting
  HealthSyncService.forTesting(
      {required Health health,
      required HealthProviderType provider,
      DateTime Function()? now,
      Future<double?> Function(DateTime, DateTime)? energyTotal,
      Future<int?> Function(DateTime, DateTime)? stepTotal})
      : _health = health,
        _provider = provider,
        _now = now ?? DateTime.now,
        _energyTotal = energyTotal,
        _stepTotal = stepTotal ??
            ((start, end) => health.getTotalStepsInInterval(start, end));
  static final shared = HealthSyncService._();
  final Health _health;
  final HealthProviderType? _provider;
  final DateTime Function() _now;
  final Future<double?> Function(DateTime, DateTime)? _energyTotal;
  final Future<int?> Function(DateTime, DateTime) _stepTotal;
  static Future<int?> _platformSteps(DateTime start, DateTime end) async {
    final value = await const MethodChannel('fitai/health_ui')
        .invokeMethod<num>('stepTotal', {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch
    });
    return value?.toInt();
  }

  final _normalizer = const HealthNormalizer();
  final _stateController = StreamController<HealthConnectionState>.broadcast();
  final updates = StreamController<HealthSnapshotPayload>.broadcast();
  Stream<HealthConnectionState> get stateStream => _stateController.stream;
  HealthConnectionState _state = HealthConnectionState.disconnected;
  HealthConnectionState get currentState => _state;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? _owner;
  bool _enabled = false, _body = false;
  bool get enabled => _enabled;
  bool get bodyEnabled => _body;
  HealthSnapshotPayload? lastSnapshot;
  final _flights = <String, Future<HealthSyncResult>>{};
  final _history = <String, Future<void>>{};
  Set<HealthDataType> readableTypes = {};
  HealthProviderType get currentProvider =>
      _provider ??
      (kIsWeb
          ? HealthProviderType.manual
          : Platform.isAndroid
              ? HealthProviderType.googleHealthConnect
              : Platform.isIOS
                  ? HealthProviderType.appleHealthKit
                  : HealthProviderType.manual);
  String _key(String owner, String field) => 'fitai_health_v2_${owner}_$field';
  bool get _android =>
      currentProvider == HealthProviderType.googleHealthConnect;

  List<HealthDataType> types({bool includeBody = false}) => [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.RESTING_HEART_RATE,
        _android
            ? HealthDataType.HEART_RATE_VARIABILITY_RMSSD
            : HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
        if (_android) HealthDataType.SLEEP_SESSION,
        if (!_android) HealthDataType.SLEEP_IN_BED,
        if (includeBody) ...[
          HealthDataType.WEIGHT,
          HealthDataType.BODY_FAT_PERCENTAGE
        ],
      ].where(_health.isDataTypeAvailable).toList();

  Future<bool> needsSetup() async {
    if (currentProvider == HealthProviderType.manual) return false;
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return false;
    final prefs = await SharedPreferences.getInstance();
    // Repair an older/incomplete local marker without changing sharing choices.
    // A previous sync timestamp is account-scoped, never a reason to enable
    // permissions or opt this account back into syncing after disconnection.
    if (prefs.getBool(_key(owner, 'enabled')) == true ||
        prefs.containsKey(_key(owner, 'last_sync'))) {
      await prefs.setBool(_key(owner, 'decided'), true);
      return false;
    }
    return !(prefs.getBool(_key(owner, 'decided')) ?? false);
  }

  Future<void> _checkOwner(String owner, String? token) async {
    if (await SecureSessionStore.shared.userId != owner ||
        !SecureSessionStore.shared
            .sameOwner(token, await SecureSessionStore.shared.accessToken)) {
      throw StateError('Account changed');
    }
  }

  void _update(HealthConnectionState state) {
    _state = state;
    _stateController.add(state);
    notifyListeners();
  }

  Future<void> initialize() async {
    final owner = await SecureSessionStore.shared.userId;
    if (_owner != owner) {
      _owner = owner;
      _enabled = false;
      _lastSyncTime = null;
      lastSnapshot = null;
      readableTypes = {};
      _body = false;
    }
    if (owner == null || currentProvider == HealthProviderType.manual) {
      _update(HealthConnectionState.unsupported);
      return;
    }
    final token = await SecureSessionStore.shared.accessToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_key(owner, 'enabled')) ?? false;
      final body = prefs.getBool(_key(owner, 'body')) ?? false;
      await _health.configure();
      await _checkOwner(owner, token);
      _enabled = enabled;
      _body = body;
      final millis = prefs.getInt(_key(owner, 'last_sync'));
      _lastSyncTime =
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
      if (_android) {
        final status = await _health.getHealthConnectSdkStatus();
        await _checkOwner(owner, token);
        if (status ==
            HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          _update(HealthConnectionState.needsInstall);
          return;
        }
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          _update(HealthConnectionState.unsupported);
          return;
        }
      }
      readableTypes = await _readable(types(includeBody: body));
      await _checkOwner(owner, token);
      _update(enabled && readableTypes.isNotEmpty
          ? HealthConnectionState.connected
          : HealthConnectionState.disconnected);
    } catch (_) {
      if (_owner == owner && await SecureSessionStore.shared.userId == owner) {
        _update(HealthConnectionState.error);
      }
    }
  }

  Future<Set<HealthDataType>> _readable(List<HealthDataType> candidates) async {
    // HealthKit cannot disclose read denials. Attempt supported reads after setup.
    if (!_android) return candidates.toSet();
    final granted = <HealthDataType>{};
    for (final type in candidates) {
      try {
        if (await _health
                .hasPermissions([type], permissions: [HealthDataAccess.READ]) ==
            true) {
          granted.add(type);
        }
      } catch (_) {/* A denied type does not block other types. */}
    }
    return granted;
  }

  Future<bool> requestPermissions({bool includeBody = false}) async {
    await initialize();
    if (_state == HealthConnectionState.needsInstall) {
      await installHealthConnect();
      return false;
    }
    if (_state == HealthConnectionState.unsupported) return false;
    final owner = await SecureSessionStore.shared.userId;
    final token = await SecureSessionStore.shared.accessToken;
    if (owner == null) return false;
    _update(HealthConnectionState.authorizing);
    try {
      final selected = types(includeBody: includeBody);
      final existing = await _readable(selected);
      final completed = _android && existing.length == selected.length ||
          await _health.requestAuthorization(selected,
              permissions: List.filled(selected.length, HealthDataAccess.READ));
      await _checkOwner(owner, token);
      final granted = await _readable(selected);
      await _checkOwner(owner, token);
      if ((_android && granted.isEmpty) || (!_android && !completed)) {
        _update(HealthConnectionState.disconnected);
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await _checkOwner(owner, token);
      await prefs.setBool(_key(owner, 'enabled'), true);
      await prefs.setBool(_key(owner, 'body'), includeBody);
      await prefs.setBool(_key(owner, 'decided'), true);
      await prefs.setBool(_key(owner, 'history_done'), false);
      await _checkOwner(owner, token);
      _enabled = true;
      _body = includeBody;
      readableTypes = granted;
      _update(HealthConnectionState.connected);
      return true;
    } catch (_) {
      if (await SecureSessionStore.shared.userId == owner) {
        _update(HealthConnectionState.error);
      }
      return false;
    }
  }

  Future<void> skipSetup() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(owner, 'decided'), true);
    await prefs.setBool(_key(owner, 'enabled'), false);
    _enabled = false;
    _update(HealthConnectionState.disconnected);
  }

  Future<void> disconnect() async {
    await skipSetup();
    if (_android) {
      try {
        await _health.revokePermissions();
      } catch (_) {}
    }
  }

  Future<void> installHealthConnect() => _health.installHealthConnect();

  Future<HealthSyncResult> syncToday({DateTime? date}) async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) {
      return const HealthSyncResult(
          success: false, message: 'Sign in to sync health data.');
    }
    final target = date ?? _now();
    final key = '$owner:${CacheScope.todayKey(target)}';
    if (_flights[key] != null) return _flights[key]!;
    final future = _sync(owner, target);
    _flights[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_flights[key], future)) _flights.remove(key);
    }
  }

  Future<HealthSyncResult> _sync(String owner, DateTime date) async {
    final token = await SecureSessionStore.shared.accessToken;
    try {
      await initialize();
      await _checkOwner(owner, token);
      if (!_enabled || readableTypes.isEmpty) {
        return const HealthSyncResult(
            success: false,
            message: 'Connect health and choose the data you want to share.');
      }
      _update(HealthConnectionState.syncing);
      final start = DateTime(date.year, date.month, date.day);
      final midnightEnd = DateTime(date.year, date.month, date.day + 1);
      final end = midnightEnd.isAfter(_now()) ? _now() : midnightEnd;
      if (!end.isAfter(start)) throw StateError('No readings for a future day');
      final raw = <HealthDataPoint>[];
      int successfulReads = 0;
      final permitted = Set<HealthDataType>.of(readableTypes);
      for (final type in permitted.where((t) =>
          t != HealthDataType.STEPS &&
          t != HealthDataType.ACTIVE_ENERGY_BURNED)) {
        try {
          raw.addAll(await _health.getHealthDataFromTypes(
              types: [type],
              startTime: HealthNormalizer.sleepTypes.contains(type)
                  ? DateTime(date.year, date.month, date.day - 1, 12)
                  : start,
              endTime: end).timeout(const Duration(seconds: 15)));
          successfulReads++;
        } catch (_) {
          /* Read other permitted categories if this one is unavailable. */
        }
        await _checkOwner(owner, token);
        if (!((await SharedPreferences.getInstance())
                .getBool(_key(owner, 'enabled')) ??
            false)) {
          throw StateError('Sync stopped');
        }
      }
      int? steps;
      if (permitted.contains(HealthDataType.STEPS)) {
        try {
          final total =
              await _stepTotal(start, end).timeout(const Duration(seconds: 15));
          steps = total;
          successfulReads++;
        } catch (_) {}
      }
      double? energy;
      if (permitted.contains(HealthDataType.ACTIVE_ENERGY_BURNED)) {
        try {
          energy = await (_energyTotal != null
                  ? _energyTotal!(start, end)
                  : const MethodChannel('fitai/health_ui').invokeMethod<num>(
                      'activeEnergyTotal', {
                      'start': start.millisecondsSinceEpoch,
                      'end': end.millisecondsSinceEpoch
                    }).then((v) => v?.toDouble()))
              .timeout(const Duration(seconds: 15));
          successfulReads++;
        } catch (_) {/* Unavailable totals remain empty. */}
      }
      if (successfulReads == 0) throw StateError('Could not read health data');
      await _checkOwner(owner, token);
      if (!((await SharedPreferences.getInstance())
              .getBool(_key(owner, 'enabled')) ??
          false)) {
        throw StateError('Sync stopped');
      }
      final payload = _normalizer.normalize(
          targetDate: date,
          provider: currentProvider,
          dataPoints: raw,
          aggregatedSteps: steps,
          aggregatedActiveCalories: energy,
          energyAggregated: true,
          readAt: end);
      final json = payload.toJson();
      final hasReadings = payload.metricMetadata.isNotEmpty ||
          payload.externalWorkouts.isNotEmpty;
      double? score;
      String? note;
      if (hasReadings) {
        final response = await ApiClient.shared.client
            .post<Map<String, dynamic>>(Endpoints.syncHealth,
                data: json,
                options: Options(extra: {'sessionOwnerToken': token}));
        await _checkOwner(owner, token);
        final data = response.data?['data'] as Map?;
        score = (data?['recoveryScore'] as num?)?.toDouble();
        note = data?['aiNote'] as String?;
        await LocalCache.shared
            .saveJson('fitai_u_${owner}_health_v2_${payload.date}', json);
        await HistoryRepository.shared.invalidate();
        await ProgressRepository.shared.invalidate();
        unawaited(TodayRepository.shared
            .fetchFresh(forceRefresh: true)
            .catchError((_) => null));
      }
      await _checkOwner(owner, token);
      if (CacheScope.todayKey(date) == CacheScope.todayKey(_now())) {
        lastSnapshot = payload;
        _lastSyncTime = _now();
        await (await SharedPreferences.getInstance()).setInt(
            _key(owner, 'last_sync'), _lastSyncTime!.millisecondsSinceEpoch);
      }
      await _checkOwner(owner, token);
      if (!((await SharedPreferences.getInstance())
              .getBool(_key(owner, 'enabled')) ??
          false)) {
        throw StateError('Sync stopped');
      }
      updates.add(payload);
      _update(HealthConnectionState.synced);
      return HealthSyncResult(
          success: true,
          message: hasReadings
              ? 'Available readings synced.'
              : 'No readable records yet. Check your health app and data sources.',
          snapshot: payload,
          recoveryScore: score,
          aiNote: note);
    } catch (_) {
      if (await SecureSessionStore.shared.userId == owner) {
        _update(HealthConnectionState.error);
      }
      return const HealthSyncResult(
          success: false,
          message:
              'Could not sync. Your saved readings are preserved. Try again.');
    }
  }

  Future<void> syncRecentDays() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return;
    if (_history[owner] != null) return _history[owner]!;
    final future = () async {
      final prefs = await SharedPreferences.getInstance();
      bool complete = true;
      final today = _now();
      for (int i = 1; i <= 6; i++) {
        if (await SecureSessionStore.shared.userId != owner ||
            !(prefs.getBool(_key(owner, 'enabled')) ?? false)) {
          return;
        }
        final result = await syncToday(
            date: DateTime(today.year, today.month, today.day - i));
        if (!result.success) complete = false;
      }
      if (complete && await SecureSessionStore.shared.userId == owner) {
        await prefs.setBool(_key(owner, 'history_done'), true);
      }
    }();
    _history[owner] = future;
    try {
      await future;
    } finally {
      _history.remove(owner);
    }
  }

  Future<void> syncIfEnabled() async {
    if (currentProvider == HealthProviderType.manual) return;
    await initialize();
    if (!_enabled || readableTypes.isEmpty) return;
    if (_lastSyncTime != null &&
        CacheScope.todayKey(_lastSyncTime!) == CacheScope.todayKey(_now()) &&
        _now().difference(_lastSyncTime!) < const Duration(minutes: 5)) {
      return;
    }
    final result = await syncToday();
    final owner = await SecureSessionStore.shared.userId;
    if (result.success &&
        owner != null &&
        !((await SharedPreferences.getInstance())
                .getBool(_key(owner, 'history_done')) ??
            false)) {
      await syncRecentDays();
    }
  }

  Future<List<Map<String, dynamic>>> loadSavedReadings() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return [];
    final token = await SecureSessionStore.shared.accessToken;
    final date = CacheScope.todayKey(_now());
    final response = await ApiClient.shared.client.get<Map<String, dynamic>>(
        '/api/healthkit/snapshot',
        queryParameters: {'date': date},
        options: Options(extra: {'sessionOwnerToken': token}));
    await _checkOwner(owner, token);
    final snapshot = response.data?['data'];
    if (snapshot is Map && snapshot['date'] == date) {
      lastSnapshot =
          HealthSnapshotPayload.fromJson(Map<String, dynamic>.from(snapshot));
      notifyListeners();
    }
    final workouts = await ApiClient.shared.client.get<Map<String, dynamic>>(
        '/api/healthkit/workouts',
        queryParameters: {'date': date},
        options: Options(extra: {'sessionOwnerToken': token}));
    await _checkOwner(owner, token);
    return (workouts.data?['data'] as List? ?? [])
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  void dispose() {
    _stateController.close();
    updates.close();
    super.dispose();
  }
}
