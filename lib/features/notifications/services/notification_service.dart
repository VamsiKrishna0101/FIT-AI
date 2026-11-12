import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/secure_session_store.dart';
import '../repositories/notifications_repository.dart';
import 'rest_notification_service.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../onboarding/components/coach_mascot.dart';

@pragma('vm:entry-point')
Future<void> fitaiNotificationBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
  // FCM displays the background alert; do not display a second notification.
}

class NotificationService extends ChangeNotifier with WidgetsBindingObserver {
  static final shared = NotificationService();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final repository = NotificationsRepository();
  final _opened = StreamController<Map<String, String>>.broadcast();
  final _seen = <String>{};
  Map<String, String>? _pending;
  Timer? _heartbeat;
  Future<void>? _initializing;
  Future<void> _operations = Future.value();
  bool configured = false;
  bool allowed = false;
  bool _foreground = true;

  Stream<Map<String, String>> get opened => _opened.stream;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    RestNotificationService.shared.opened.stream
        .listen((data) => unawaited(_openData(data)));
    try {
      await RestNotificationService.shared.initialize();
    } catch (_) {/* Remote push remains independent. */}
    try {
      await Firebase.initializeApp();
      configured = true;
      WidgetsBinding.instance.addObserver(this);
      FirebaseMessaging.onBackgroundMessage(fitaiNotificationBackground);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
              alert: false, badge: false, sound: false);
      FirebaseMessaging.onMessage
          .listen((message) => unawaited(_receive(message)));
      FirebaseMessaging.onMessageOpenedApp
          .listen((message) => unawaited(_open(message)));
      FirebaseMessaging.instance.onTokenRefresh
          .listen((_) => unawaited(refresh()));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) await _open(initial);
      _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) {
        if (_foreground) unawaited(refresh());
      });
    } catch (_) {
      configured = false;
    }
    notifyListeners();
  }

  Future<String> installationId() async {
    final storage = await SharedPreferences.getInstance();
    var id = storage.getString('fitai_notification_installation');
    if (id == null) {
      final random = Random.secure();
      id = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      await storage.setString('fitai_notification_installation', id);
    }
    return id;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _operations.then((_) => action());
    _operations =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> refresh() => _serialized(() async {
        await initialize();
        if (!configured ||
            await SecureSessionStore.shared.accessToken == null) {
          return;
        }
        try {
          final settings =
              await FirebaseMessaging.instance.getNotificationSettings();
          allowed = _authorized(settings);
          final preferences = await repository.preferences();
          if (!allowed || preferences['enabled'] != true) {
            await repository.remove(await installationId());
            await FirebaseMessaging.instance.setAutoInitEnabled(false);
          } else {
            await _register();
          }
          notifyListeners();
        } catch (_) {
          // Offline refresh keeps the last confirmed preference and never asks permission.
        }
      });

  bool _authorized(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  Future<Map<String, dynamic>> enable() => _serialized(() async {
        final ownerToken = await SecureSessionStore.shared.accessToken;
        if (ownerToken == null) {
          throw StateError('Sign in to enable notifications.');
        }
        await initialize();
        if (!configured) {
          throw StateError('Firebase is not configured for this build.');
        }
        final preferences = await repository.preferences();
        if (preferences['deliveryReady'] != true) {
          throw StateError('Push delivery is not ready on the server.');
        }
        final permission = await FirebaseMessaging.instance.requestPermission();
        allowed = _authorized(permission);
        notifyListeners();
        if (!allowed) {
          throw StateError(
              'Allow notifications in your phone settings, then enable them here.');
        }

        if (!SecureSessionStore.shared.sameOwner(
            ownerToken, await SecureSessionStore.shared.accessToken)) {
          throw StateError('Your account changed. Reopen notifications.');
        }
        await _register();
        final zone = await FlutterTimezone.getLocalTimezone();
        return repository.save({'enabled': true, 'timezone': zone.identifier},
            ownerToken: ownerToken);
      });

  Future<void> _register() async {
    final ownerToken = await SecureSessionStore.shared.accessToken;
    final owner = await SecureSessionStore.shared.userId;
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken;
      for (var attempt = 0; attempt < 10 && apnsToken == null; attempt++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }
      if (apnsToken == null) {
        throw StateError('Could not register notifications. Please try again.');
      }
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || owner != await SecureSessionStore.shared.userId) {
      throw StateError('Could not register notifications. Please try again.');
    }
    await repository.register({
      'installationId': await installationId(),
      'token': token,
      'platform':
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      'foreground': _foreground,
    }, ownerToken: ownerToken);
    final zone = await FlutterTimezone.getLocalTimezone();
    final preferences = await repository.preferences();
    if (preferences['timezone'] != zone.identifier) {
      await repository
          .save({'timezone': zone.identifier}, ownerToken: ownerToken);
    }
  }

  Future<Map<String, dynamic>> disable() => _serialized(() async {
        final preferences = await repository.save({'enabled': false});
        await _detach();
        return preferences;
      });

  Future<void> detach() => _serialized(() async {
        try {
          await RestNotificationService.shared.detach();
        } on MissingPluginException {
          // Older native builds may lack local alerts. Still remove the push
          // registration for the account before its credentials are cleared.
        } on PlatformException {
          // A local notification error must not block remote push cleanup.
        }
        await _detach();
      });

  Future<void> _detach() async {
    _pending = null;
    messengerKey.currentState?.hideCurrentSnackBar();
    try {
      await repository.remove(await installationId());
    } catch (_) {}
    if (configured) {
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }
  }

  Future<bool> _belongsToAccount(RemoteMessage message) async =>
      await SecureSessionStore.shared.accessToken != null &&
      message.data['userId'] == await SecureSessionStore.shared.userId;

  Future<void> _receive(RemoteMessage message) async {
    if (!await _belongsToAccount(message)) return;
    final title = message.notification?.title;
    if (title == null) return;
    messengerKey.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      backgroundColor: const Color(0xFFE0E3E5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: NotificationBannerContent(
          title: title,
          body: message.notification?.body,
          type: message.data['type']?.toString()),
      action: SnackBarAction(
          label: fitnessText(messengerKey.currentContext!, 'Open'),
          textColor: const Color(0xFF181A1C),
          onPressed: () => unawaited(_open(message))),
    ));
  }

  Future<void> _open(RemoteMessage message) => _openData(
      message.data.map((key, value) => MapEntry(key, value.toString())));

  Future<void> _openData(Map<String, String> data) async {
    final owner = await SecureSessionStore.shared.userId;
    if (await SecureSessionStore.shared.accessToken != null &&
        data['userId'] != owner) {
      return;
    }
    final id = data['notificationId'];
    if (id == null || !_seen.add(id)) return;
    if (_seen.length > 100) _seen.remove(_seen.first);
    _pending = data;
    if (!id.startsWith('rest:') && data['userId'] == owner) {
      unawaited(repository.opened(id).catchError((Object _) {}));
    }
    _opened.add(_pending!);
  }

  Map<String, String>? takePending() {
    final value = _pending;
    _pending = null;
    return value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(refresh());
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _opened.close();
    super.dispose();
  }
}

/// In-app banner for a push received while Setcraft is open.
/// Mochi, the AI coach, delivers every coaching alert; billing notices stay plain.
class NotificationBannerContent extends StatelessWidget {
  static const _billingTypes = {'TRIAL_ENDING', 'TRIAL_EXPIRED'};
  final String title;
  final String? body;
  final String? type;
  const NotificationBannerContent(
      {super.key, required this.title, this.body, this.type});

  @override
  Widget build(BuildContext context) {
    final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF181A1C), fontWeight: FontWeight.w500)),
          if (body != null)
            Text(body!,
                style: const TextStyle(color: Color(0xFF44484C), fontSize: 12)),
        ]);
    if (_billingTypes.contains(type)) return text;
    return Row(children: [
      const ExcludeSemantics(
          child: CoachMascot(
              key: ValueKey('notification-mochi'),
              size: 36,
              mood: CoachMood.cheer)),
      const SizedBox(width: 12),
      Expanded(child: text),
    ]);
  }
}
