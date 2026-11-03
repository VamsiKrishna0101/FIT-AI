import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/storage/secure_session_store.dart';
import '../../../core/localization/notification_copy.dart';

/// Device-local, user-started timers. This does not depend on Firebase or APNs.
class RestNotificationService extends ChangeNotifier
    with WidgetsBindingObserver {
  static final shared = RestNotificationService();
  static const notificationId = 4175;
  final FlutterLocalNotificationsPlugin _plugin;
  RestNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final opened = StreamController<Map<String, String>>.broadcast();
  Future<void>? _initializing;
  Future<void> _operations = Future.value();
  bool enabled = false;
  bool exactAllowed = true;
  bool _ready = false;
  String? _owner;
  Map<String, String>? _active;
  int _revision = 0;
  final _visibleTimers = <Object>{};
  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool get _timerVisible => _foreground && _visibleTimers.isNotEmpty;

  Future<void> setInAppTimerVisible(Object view, bool visible) {
    final changed =
        visible ? _visibleTimers.add(view) : _visibleTimers.remove(view);
    return changed ? _sync() : Future<void>.value();
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!supported) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) => _open(response.payload),
      );
      _ready = true;
      WidgetsBinding.instance.addObserver(this);
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _open(launch?.notificationResponse?.payload);
      }
      await refresh();
    } on PlatformException {
      _ready = false;
      _initializing = null;
    }
  }

  void _open(String? payload) {
    try {
      final data = Map<String, String>.from(jsonDecode(payload ?? '') as Map);
      final end = DateTime.tryParse(data['end'] ?? '');
      if (end == null ||
          DateTime.now().difference(end) > const Duration(minutes: 10)) {
        return;
      }
      opened.add(data);
    } catch (_) {/* Ignore an old or malformed local payload. */}
  }

  Future<void> refresh() async {
    if (!supported) return;
    _owner = await SecureSessionStore.shared.userId;
    final storage = await SharedPreferences.getInstance();
    enabled = _owner != null &&
        storage.getBool('setcraft_rest_alerts_$_owner') == true;
    exactAllowed = !Platform.isAndroid ||
        await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.canScheduleExactNotifications() ==
            true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    await initialize();
    if (!_ready) {
      throw StateError('Rest alerts are unavailable on this device.');
    }
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) throw StateError('Sign in to enable notifications.');
    if (value) {
      final allowed = Platform.isAndroid
          ? await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission()
          : await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: false, sound: true);
      if (allowed != true) {
        throw StateError(
            'Allow notifications in your phone settings, then enable them here.');
      }
    }
    if (owner != await SecureSessionStore.shared.userId) {
      throw StateError('Your account changed. Reopen notifications.');
    }
    final storage = await SharedPreferences.getInstance();
    await storage.setBool('setcraft_rest_alerts_$owner', value);
    await refresh();
    await _sync();
  }

  Future<void> requestPreciseTiming() async {
    await initialize();
    if (supported && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      await refresh();
      await _sync();
    }
  }

  Future<void> update(
      {required String date, DateTime? end, bool paused = false}) async {
    final revision = ++_revision;
    final owner = await SecureSessionStore.shared.userId;
    if (revision != _revision) return;
    _active =
        end != null && !paused && end.isAfter(DateTime.now()) && owner != null
            ? {
                'userId': owner,
                'date': date,
                'end': end.toUtc().toIso8601String(),
                'notificationId': 'rest:${end.millisecondsSinceEpoch}',
                'type': 'REST_FINISHED'
              }
            : null;
    await _sync();
  }

  Future<void> _sync() {
    final result = _operations.then((_) async {
      await initialize();
      if (!_ready) return;
      await _plugin.cancel(id: notificationId);
      final active = _active;
      final owner = await SecureSessionStore.shared.userId;
      if (_timerVisible || active == null || active['userId'] != owner) return;
      final storage = await SharedPreferences.getInstance();
      if (storage.getBool('setcraft_rest_alerts_$owner') != true) return;
      final end = DateTime.parse(active['end']!);
      if (!end.isAfter(DateTime.now())) return;
      final exact = !Platform.isAndroid ||
          await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ==
              true;
      if (!identical(active, _active) ||
          _timerVisible ||
          owner != await SecureSessionStore.shared.userId) {
        return;
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'setcraft_rest',
          'Rest timer',
          channelDescription:
              'Alerts for rest timers you start during a workout',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
          timeoutAfter: 600000,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          threadIdentifier: 'setcraft_rest',
        ),
      );
      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
            id: notificationId,
            title: notificationCopy('Rest finished'),
            body: notificationCopy('Your next set is ready.'),
            scheduledDate: tz.TZDateTime.from(end, tz.UTC),
            notificationDetails: details,
            androidScheduleMode: mode,
            payload: jsonEncode(active),
          );
      try {
        await schedule(exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle);
      } on PlatformException catch (error) {
        if (error.code != 'exact_alarms_not_permitted') rethrow;
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    });
    _operations =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> detach() async {
    _revision++;
    _active = null;
    await _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_sync().catchError((Object _) {}));
  }
}
