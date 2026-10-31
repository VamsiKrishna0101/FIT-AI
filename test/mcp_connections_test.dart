import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/profile/repositories/mcp_repository.dart';
import 'package:setcraft/features/profile/views/mcp_connections_view.dart';
import 'helpers/fake_mcp_repository.dart';

Widget app(Widget child, {double scale = 1}) => RepaintBoundary(
    key: const ValueKey('mcp-preview'),
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: true, textScaler: TextScaler.linear(scale)),
            child: child!),
        home: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final copied = <String>[];
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() {
    copied.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(McpClipboard.channel, (call) async {
      if (call.method == 'copyToken') {
        copied.add((call.arguments as Map)['value'] as String);
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(McpClipboard.channel, null));
  Future<void> size(WidgetTester t, {double width = 393}) async {
    t.view.physicalSize = Size(width, 852);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets(
      'Create defaults to read-only training; optional permissions remain off',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository();
    await t.pumpWidget(app(ClaudeConnectionView(repository: repo)));
    await t.pumpAndSettle();
    await t.tap(find.text('Create access token'));
    await t.pumpAndSettle();
    final switches =
        t.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(switches.map((s) => s.value), [true, true, true, false, false]);
    await t.ensureVisible(find.text('7 days'));
    await t.tap(find.text('7 days'));
    await t.pumpAndSettle();
    await t.tap(find.text('Generate token'));
    await t.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.days, 7);
    expect(repo.granted, ['training:read', 'plans:read', 'workouts:read']);
    expect(find.text('Ready to connect'), findsOneWidget);
    expect(find.textContaining('fixture-only-not-a-real-token'), findsNothing);
    await t.tap(find.text('Copy token'));
    await t.pumpAndSettle();
    expect(copied.single, 'sc_mcp_fixture-only-not-a-real-token');
    expect(find.text('Token copied'), findsOneWidget);
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.text('Not used yet'), findsOneWidget);
    expect(find.textContaining('fixture-only-not-a-real-token'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'Token generation blocks duplicate taps until the response arrives',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository()..pending = Completer<McpIssuedToken>();
    await t.pumpWidget(
        app(CreateMcpTokenView(repository: repo, owner: repo.owner)));
    await t.pumpAndSettle();
    await t.tap(find.text('Generate token'));
    await t.pump();
    expect(repo.creates, 1);
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    repo.pending!.complete(repo.issue());
    await t.pumpAndSettle();
    expect(repo.creates, 1);
    expect(find.text('Ready to connect'), findsOneWidget);
  });
  testWidgets(
      'Reveal masks on background and copying refuses a changed account',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository();
    final issued = repo.issue();
    await t
        .pumpWidget(app(McpTokenCreatedView(repository: repo, issued: issued)));
    await t.pumpAndSettle();
    await t.tap(find.text('Show token'));
    await t.pumpAndSettle();
    expect(find.text(issued.secret), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(find.text(issued.secret), findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    repo.owner = 'other-owner';
    await t.tap(find.text('Copy token'));
    await t.pumpAndSettle();
    expect(copied, isEmpty);
    expect(find.textContaining('Could not copy this token.'), findsOneWidget);
  });
  testWidgets('Revocation requires confirmation and removes access metadata',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository();
    repo.tokens.add(repo.issue().token);
    await t.pumpWidget(app(ClaudeConnectionView(repository: repo)));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Revoke'));
    await t.tap(find.text('Revoke'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(repo.revocations, 0);
    await t.tap(find.text('Revoke'));
    await t.pumpAndSettle();
    await t.tap(find.text('Revoke').last);
    await t.pumpAndSettle();
    expect(repo.revocations, 1);
    expect(find.text('Ready when you are'), findsOneWidget);
  });
  testWidgets(
      'Unconfigured server disables generation without claiming a connection',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository()..configured = false;
    await t.pumpWidget(app(ClaudeConnectionView(repository: repo)));
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.text('Connected'), findsNothing);
    expect(repo.creates, 0);
  });
  testWidgets('Narrow screens, large text and replacement controls fit',
      (t) async {
    await size(t, width: 320);
    final repo = FakeMcpRepository();
    repo.tokens.add(repo.issue().token);
    for (final screen in [
      ClaudeConnectionView(repository: repo),
      CreateMcpTokenView(
          repository: repo, owner: repo.owner, replace: repo.tokens.single),
      McpTokenCreatedView(repository: repo, issued: repo.issue())
    ]) {
      await t.pumpWidget(app(screen, scale: 1.8));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });
  testWidgets('Capture the token manager using fixture metadata only',
      (t) async {
    await size(t);
    final repo = FakeMcpRepository();
    repo.tokens.add(repo.issue().token);
    await t.pumpWidget(app(ClaudeConnectionView(repository: repo)));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('mcp-preview')));
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/mcp-token-manager-preview.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(t.takeException(), isNull);
  });
}
