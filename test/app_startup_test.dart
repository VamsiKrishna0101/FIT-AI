import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitai_mobile/core/branding/app_startup.dart';
import 'package:fitai_mobile/core/branding/setcraft_brand.dart';
import 'package:fitai_mobile/features/onboarding/data/starter_plan_repository.dart';
import 'package:fitai_mobile/features/onboarding/views/starter_plan_view.dart';

class _PendingStarterRepository extends StarterPlanRepository {
  final response = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> current() => response.future;
}

void main() {
  testWidgets('complete mark persists across session and account setup checks',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': 'test-session',
      'fitai_user_id': 'startup-user'
    });
    final session = Completer<Widget>();
    final repository = _PendingStarterRepository();
    await tester.pumpWidget(
        MaterialApp(home: AppStartup(initialize: () => session.future)));
    final centre = tester.getCenter(find.byType(SetcraftMark));
    session.complete(StarterOnboardingGate(
        repository: repository,
        child: const Scaffold(body: Text('Account home'))));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SetcraftMark), findsOneWidget);
    expect(tester.getCenter(find.byType(SetcraftMark)), centre);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Account home'), findsNothing);
    repository.response.complete({'eligible': false, 'hasAccess': true});
    await tester.pumpAndSettle();
    expect(find.text('Account home'), findsOneWidget);
    expect(find.byType(SetcraftMark), findsNothing);
  });

  testWidgets(
      'recovery mark stays at the full viewport centre with unequal insets',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final home = Completer<Widget>();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(top: 47, bottom: 20),
          viewPadding: EdgeInsets.only(top: 47, bottom: 20)),
      child: AppStartup(initialize: () => home.future),
    )));
    expect(tester.getCenter(find.byType(SetcraftMark)), const Offset(195, 422));
  });

  testWidgets(
      'paints branding during initialization and opens home immediately',
      (tester) async {
    final home = Completer<Widget>();
    var calls = 0;
    var ready = 0;
    await tester.pumpWidget(MaterialApp(
      home: AppStartup(
          initialize: () {
            calls++;
            return home.future;
          },
          onReady: () => ready++),
    ));
    expect(find.byType(SetcraftLockup), findsOneWidget);
    expect(ready, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1);
    expect(find.byType(SetcraftLockup), findsOneWidget);
    home.complete(const Scaffold(body: Text('Ready home')));
    // No minimum display time or repeating animation holds up the ready home.
    // Flush the completed future, then render its scheduled frame.
    await tester.pump();
    await tester.pump();
    expect(find.text('Ready home'), findsOneWidget);
    expect(find.byType(SetcraftLockup), findsNothing);
    expect(ready, 1);
  });

  testWidgets(
      'failed initialization offers retry and only signals ready on success',
      (tester) async {
    var attempts = 0;
    var ready = 0;
    await tester.pumpWidget(MaterialApp(
      home: AppStartup(
          initialize: () async {
            if (++attempts == 1) throw StateError('Device storage unavailable');
            return const Scaffold(body: Text('Recovered home'));
          },
          onReady: () => ready++),
    ));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(ready, 0);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('Recovered home'), findsOneWidget);
    expect(attempts, 2);
    expect(ready, 1);
  });

  testWidgets(
      'finishing after disposal does not navigate or initialize services',
      (tester) async {
    final home = Completer<Widget>();
    var ready = 0;
    await tester.pumpWidget(MaterialApp(
      home: AppStartup(initialize: () => home.future, onReady: () => ready++),
    ));
    await tester.pumpWidget(const SizedBox());
    home.complete(const Text('Stale home'));
    await tester.pump();
    expect(ready, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures the real opening screen at phone size', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    final home = Completer<Widget>();
    const key = ValueKey('startup-capture');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
      ),
      home: RepaintBoundary(
        key: key,
        child: AppStartup(initialize: () => home.future),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/branding').createSync(recursive: true);
      File('build/branding/setcraft-splash-preview.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
