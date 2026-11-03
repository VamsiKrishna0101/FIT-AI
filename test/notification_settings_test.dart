import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/notifications/repositories/notifications_repository.dart';
import 'package:setcraft/features/notifications/services/notification_service.dart';
import 'package:setcraft/features/notifications/services/rest_notification_service.dart';
import 'package:setcraft/features/notifications/views/notification_settings_view.dart';

class FakeNotifications extends NotificationsRepository {
  bool fail = false;
  int tests = 0;
  Map<String, dynamic> values = {
    'enabled': false,
    'deliveryReady': true,
    'workouts': true,
    'plans': true,
    'checkIns': false,
    'summaries': false,
    'meals': false,
    'billing': true,
    'pausedUntil': null,
    'nextWorkoutReminder': {'date': '2026-11-03', 'time': '18:00'},
    'workoutTime': '18:00',
    'checkInTime': '09:00',
    'summaryTime': '18:00',
    'mealTime': '12:30',
    'mealType': 'LUNCH',
    'quietStart': '22:00',
    'quietEnd': '08:00',
  };

  @override
  Future<Map<String, dynamic>> preferences() async => Map.from(values);

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> changes,
      {String? ownerToken}) async {
    if (fail) throw StateError('Could not save. Please try again.');
    values.addAll(changes);
    return Map.from(values);
  }

  @override
  Future<void> test(String installation) async {
    tests++;
  }
}

class FakePush extends NotificationService {
  final FakeNotifications data;
  FakePush(this.data) {
    configured = true;
    allowed = true;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<Map<String, dynamic>> enable() => data.save({'enabled': true});

  @override
  Future<Map<String, dynamic>> disable() => data.save({'enabled': false});

  @override
  Future<String> installationId() async => 'test-installation';
}

class FakeRest extends RestNotificationService {
  @override
  bool get supported => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

final remoteSwitch = find.descendant(
  of: find.byKey(const ValueKey('remote-notifications')),
  matching: find.byType(CupertinoSwitch),
);
const preview = ValueKey('notification-preview');
Widget app(FakeNotifications data, FakePush service, {double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                    key: preview,
                    child: NotificationSettingsView(
                        repository: data,
                        service: service,
                        restService: FakeRest())),
              )),
    );

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  testWidgets('No permission prompt or automatic opt-in when settings opens',
      (tester) async {
    final data = FakeNotifications();
    final push = FakePush(data);
    await tester.pumpWidget(app(data, push));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(remoteSwitch).value, false);
    expect(data.values['checkIns'], false);
    expect(data.values['meals'], false);
    await tester.tap(remoteSwitch);
    await tester.pumpAndSettle();
    expect(data.values['enabled'], true);
    await tester.tap(remoteSwitch);
    await tester.pumpAndSettle();
    expect(data.values['enabled'], false);
  });

  testWidgets('Failed enable keeps switch off and shows an actionable error',
      (tester) async {
    final data = FakeNotifications()..fail = true;
    await tester.pumpWidget(app(data, FakePush(data)));
    await tester.pumpAndSettle();
    await tester.tap(remoteSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(remoteSwitch).value, false);
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
  });

  testWidgets(
      'Category opens a detail screen and saves only its requested change',
      (tester) async {
    final data = FakeNotifications();
    await tester.pumpWidget(app(data, FakePush(data)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    await tester.tap(find.byType(CupertinoSwitch).last);
    await tester.pumpAndSettle();
    expect(data.values['workouts'], false);
    expect(data.values['plans'], true);
    expect(data.values['enabled'], false);
  });

  testWidgets(
      'Large text fits and the test notification targets this installation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = FakeNotifications()..values['enabled'] = true;
    await tester.pumpWidget(app(data, FakePush(data), scale: 1.5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Send test notification'), 300);
    await tester.ensureVisible(find.text('Send test notification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();
    expect(data.tests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Render notification settings preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = FakeNotifications()..values['enabled'] = true;
    await tester.pumpWidget(app(data, FakePush(data)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(preview));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/notifications.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });

  testWidgets('Rest alerts can be enabled independently of remote reminders',
      (tester) async {
    final data = FakeNotifications();
    await tester.pumpWidget(app(data, FakePush(data)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Rest timer alerts'), 250);
    final toggle = find.descendant(
        of: find.byKey(const ValueKey('rest-notifications')),
        matching: find.byType(CupertinoSwitch));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(toggle).value, true);
    expect(data.values['enabled'], false);
  });

  testWidgets('Pause and resume preserve category choices and billing',
      (tester) async {
    final data = FakeNotifications()..values['enabled'] = true;
    await tester.pumpWidget(app(data, FakePush(data)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pause reminders'), 250);
    await tester.ensureVisible(find.text('Pause reminders'));
    await tester.tap(find.text('Pause reminders'));
    await tester.pumpAndSettle();
    expect(
        DateTime.parse(data.values['pausedUntil'] as String)
            .isAfter(DateTime.now()),
        true);
    expect(data.values['billing'], true);
    expect(data.values['workouts'], true);
    await tester.ensureVisible(find.text('Resume reminders'));
    await tester.tap(find.text('Resume reminders'));
    await tester.pumpAndSettle();
    expect(data.values['pausedUntil'], null);
  });
}
