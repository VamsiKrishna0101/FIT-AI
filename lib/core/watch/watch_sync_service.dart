import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_models.dart';

class WatchSyncService extends ChangeNotifier {
  WatchSyncService._() {
    _initChannel();
    _loadPreferences();
  }
  static final WatchSyncService shared = WatchSyncService._();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String get statusLabel {
    if (!isSupported) return 'Unavailable';
    if (!_isPaired) return 'Not paired';
    if (!_isAppInstalled) return 'Install watch app';
    return _isReachable ? 'Available' : 'Offline';
  }

  static const MethodChannel _channel = MethodChannel('setcraft/watch');

  final _actionController = StreamController<WatchIncomingAction>.broadcast();
  Stream<WatchIncomingAction> get actions => _actionController.stream;

  WatchWorkoutSnapshot? _latestSnapshot;
  WatchWorkoutSnapshot? get latestSnapshot => _latestSnapshot;

  WatchRestPayload? _latestRest;
  WatchRestPayload? get latestRest => _latestRest;

  final ValueNotifier<WatchBiometrics?> biometricsNotifier =
      ValueNotifier<WatchBiometrics?>(null);

  bool _isPaired = false;
  bool _isAppInstalled = false;
  bool _isReachable = false;
  bool get isPaired => _isPaired;
  bool get isAppInstalled => _isAppInstalled;
  bool get isReachable => _isReachable;

  bool _autoLaunchWatch = true;
  bool _hapticRestAlerts = true;
  bool _opticalHrEnabled = true;
  bool get autoLaunchWatch => _autoLaunchWatch;
  bool get hapticRestAlerts => _hapticRestAlerts;
  bool get opticalHrEnabled => _opticalHrEnabled;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoLaunchWatch = prefs.getBool('watch_auto_launch') ?? true;
      _hapticRestAlerts = prefs.getBool('watch_haptic_rest') ?? true;
      _opticalHrEnabled = prefs.getBool('watch_optical_hr') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setAutoLaunchWatch(bool value) async {
    _autoLaunchWatch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watch_auto_launch', value);
  }

  Future<void> setHapticRestAlerts(bool value) async {
    _hapticRestAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watch_haptic_rest', value);
    await _resendSettings();
  }

  Future<void> setOpticalHrEnabled(bool value) async {
    _opticalHrEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watch_optical_hr', value);
    await _resendSettings();
  }

  /// Watch settings travel with the workout snapshot, so a change made while a
  /// workout is open reaches the watch right away.
  Future<void> _resendSettings() async {
    final snapshot = _latestSnapshot;
    if (snapshot != null) await syncWorkoutState(snapshot);
  }

  @visibleForTesting
  Map<String, dynamic> watchPayload(WatchWorkoutSnapshot snapshot) => {
        ...snapshot.toJson(),
        'hapticRestAlerts': _hapticRestAlerts,
        'heartRateEnabled': _opticalHrEnabled,
      };

  void _initChannel() {
    if (isSupported) {
      _channel.setMethodCallHandler(_handleNativeCall);
      checkWatchState();
    }
  }

  Future<Map<String, dynamic>> checkWatchState() async {
    if (isSupported) {
      try {
        final res =
            await _channel.invokeMapMethod<String, dynamic>('checkWatchState');
        if (res != null) {
          _isPaired = res['isPaired'] == true;
          _isAppInstalled = res['isAppInstalled'] == true;
          _isReachable = res['isReachable'] == true;
          notifyListeners();
          return res;
        }
      } catch (_) {}
    }
    if (_isReachable) {
      _isReachable = false;
      notifyListeners();
    }
    return {
      'isPaired': _isPaired,
      'isAppInstalled': _isAppInstalled,
      'isReachable': _isReachable,
    };
  }

  /// Sends wake/launch signal to Apple Watch via HealthKit
  Future<bool> startWatchApp({bool manual = false}) async {
    if (!_autoLaunchWatch && !manual) return false;
    if (isSupported) {
      try {
        final success = await _channel.invokeMethod<bool>('startWatchApp');
        return success == true;
      } catch (e) {
        debugPrint('[WatchSyncService] startWatchApp failed: $e');
      }
    }
    return false;
  }

  /// Deep links to iOS Apple Watch app if installation is needed
  Future<bool> openWatchSettings() async {
    if (isSupported) {
      try {
        final success = await _channel.invokeMethod<bool>('openWatchSettings');
        return success == true;
      } catch (e) {
        debugPrint('[WatchSyncService] openWatchSettings failed: $e');
      }
    }
    return false;
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    try {
      final args = call.arguments is Map
          ? Map<String, dynamic>.from(call.arguments as Map)
          : <String, dynamic>{};
      switch (call.method) {
        case 'onLogSet':
          final action = WatchLogSetAction(
            itemId: (args['itemId'] ?? '').toString(),
            setNumber: (args['setNumber'] as num?)?.toInt() ?? 1,
            weight: (args['weight'] as num?)?.toDouble() ?? 0.0,
            reps: (args['reps'] as num?)?.toInt() ?? 0,
          );
          _actionController.add(action);
          break;

        case 'onSelectExercise':
          final action = WatchSelectExerciseAction(
            itemId: (args['itemId'] ?? '').toString(),
          );
          _actionController.add(action);
          break;

        case 'onSkipExercise':
          final action = WatchSkipExerciseAction(
            itemId: (args['itemId'] ?? '').toString(),
          );
          _actionController.add(action);
          break;

        case 'onRestControl':
          final action = WatchRestControlAction(
            operation: (args['operation'] ?? 'SKIP').toString(),
          );
          _actionController.add(action);
          break;

        case 'onBiometricUpdate':
          final bio = WatchBiometrics.fromJson(args);
          biometricsNotifier.value = bio;
          _actionController.add(WatchBiometricUpdateAction(biometrics: bio));
          break;

        case 'onFinishWorkout':
          _actionController.add(const WatchFinishWorkoutAction());
          break;
      }
    } catch (e) {
      debugPrint('[WatchSyncService] Error handling watch call: $e');
    }
    return null;
  }

  /// Sends the full workout state to Apple Watch
  Future<void> syncWorkoutState(WatchWorkoutSnapshot snapshot) async {
    _latestSnapshot = snapshot;
    notifyListeners();

    if (isSupported) {
      try {
        await _channel.invokeMethod(
            'updateWorkoutState', watchPayload(snapshot));
      } catch (e) {
        debugPrint('[WatchSyncService] Failed to send state to watch: $e');
      }
    }
  }

  /// Sends updated rest timer state to Apple Watch
  Future<void> syncRestState(WatchRestPayload? rest) async {
    _latestRest = rest;
    notifyListeners();

    if (isSupported) {
      try {
        await _channel.invokeMethod('updateRestState', rest?.toJson());
      } catch (e) {
        debugPrint('[WatchSyncService] Failed to send rest to watch: $e');
      }
    }
  }

  /// Dispatches an action as if it came from the physical Apple Watch.
  /// Used by the Virtual Watch Debug sheet and automated tests.
  void dispatchVirtualAction(WatchIncomingAction action) {
    if (action is WatchBiometricUpdateAction) {
      biometricsNotifier.value = action.biometrics;
    }
    _actionController.add(action);
  }

  /// Clears active session state on workout finish
  void clearSession() {
    _latestSnapshot = null;
    _latestRest = null;
    biometricsNotifier.value = null;
    notifyListeners();

    if (isSupported) {
      _channel.invokeMethod('clearSession').catchError((_) {});
    }
  }
}
