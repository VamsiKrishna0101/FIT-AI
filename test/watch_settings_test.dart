import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/watch/views/apple_watch_settings_view.dart';
import 'package:setcraft/core/watch/watch_sync_service.dart';
import 'package:setcraft/features/profile/repositories/settings_repository.dart';
import 'package:setcraft/features/profile/views/profile_view.dart';

class _Profile extends SettingsRepository {
  @override
  Future<Map<String, dynamic>> profile() async => {'name': 'Test member'};
}

Widget _app(Widget page, {double scale = 1}) => RepaintBoundary(
      key: const ValueKey('watch-preview'),
      child: MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: page,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('setcraft/watch');
  var state = <String, bool>{};
  var nativeFails = false;
  final calls = <String>[];

  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'CupertinoSystemText': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    state = {'isPaired': false, 'isAppInstalled': false, 'isReachable': false};
    calls.clear();
    nativeFails = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'checkWatchState' && nativeFails) {
        throw PlatformException(code: 'unavailable');
      }
      return call.method == 'checkWatchState' ? state : true;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Android hides Apple Watch and uses Health Connect',
      (tester) async {
    await tester.pumpWidget(_app(ProfileView(repository: _Profile())));
    await tester.pumpAndSettle();
    expect(find.text('Apple Watch'), findsNothing);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('MCP'), findsOneWidget);
    expect(find.text('Sleep preferences'), findsNothing);
    expect(find.text('Health & sleep'), findsNothing);
    expect(find.text('Ready'), findsNothing);
    await tester.pumpWidget(_app(const AppleWatchSettingsView()));
    await tester.pumpAndSettle();
    expect(find.text('Apple Watch is available on iPhone.'), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final (paired, installed, reachable, label) in [
    (false, false, false, 'Not paired'),
    (true, false, false, 'Install watch app'),
    (true, true, false, 'Offline'),
    (true, true, true, 'Available'),
  ]) {
    testWidgets('iPhone watch status uses native state: $label',
        (tester) async {
      state = {
        'isPaired': paired,
        'isAppInstalled': installed,
        'isReachable': reachable
      };
      await WatchSyncService.shared.checkWatchState();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(ProfileView(repository: _Profile()), scale: 1.8));
      await tester.pumpAndSettle();
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(find.text('Apple Health'), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(find.text('Ready'), findsNothing);
      await tester.pumpWidget(_app(const AppleWatchSettingsView()));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      final controls =
          tester.widgetList<CupertinoSwitch>(find.byType(CupertinoSwitch));
      expect(controls.length, 3);
      expect(
          controls.every((control) =>
              (control.onChanged != null) == (paired && installed)),
          isTrue);
      expect(find.byIcon(Icons.watch_outlined), findsNothing);
      expect(find.byIcon(CupertinoIcons.heart), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets('Watch preferences save and the page fits enlarged text',
      (tester) async {
    state = {'isPaired': true, 'isAppInstalled': true, 'isReachable': true};
    await WatchSyncService.shared.checkWatchState();
    await WatchSyncService.shared.setHapticRestAlerts(true);
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const AppleWatchSettingsView(), scale: 1.8));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rest alerts'));
    await tester.tap(find.byType(CupertinoSwitch).at(1));
    await tester.pumpAndSettle();
    expect(WatchSyncService.shared.hapticRestAlerts, isFalse);
    expect((await SharedPreferences.getInstance()).getBool('watch_haptic_rest'),
        isFalse);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Failed refresh stops claiming the watch is available',
      (tester) async {
    state = {'isPaired': true, 'isAppInstalled': true, 'isReachable': true};
    await tester.pumpWidget(_app(const AppleWatchSettingsView()));
    await tester.pumpAndSettle();
    expect(find.text('Available'), findsOneWidget);
    nativeFails = true;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Available'), findsNothing);
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Manual watch launch still works when auto-launch is off',
      (tester) async {
    state = {'isPaired': true, 'isAppInstalled': true, 'isReachable': true};
    await WatchSyncService.shared.setAutoLaunchWatch(false);
    calls.clear();
    expect(await WatchSyncService.shared.startWatchApp(), isFalse);
    expect(calls, isEmpty);
    await tester.pumpWidget(_app(const AppleWatchSettingsView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open on watch'));
    await tester.pumpAndSettle();
    expect(calls, contains('startWatchApp'));
    expect(tester.takeException(), isNull);
    await WatchSyncService.shared.setAutoLaunchWatch(true);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Capture compact watch settings with supported device state',
      (tester) async {
    state = {'isPaired': true, 'isAppInstalled': true, 'isReachable': true};
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const AppleWatchSettingsView()));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('watch-preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/watch-settings-compact.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
