import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/localization/membership_copy.dart';
import 'package:setcraft/features/auth/views/auth_view.dart';
import 'package:setcraft/features/auth/data/social_sign_in.dart';

class PendingSocial extends SocialSignIn {
  final result = Completer<String?>();
  int attempts = 0;
  @override
  bool available(SocialProvider provider) => true;
  @override
  Future<String?> authenticate(SocialProvider provider) {
    attempts++;
    return result.future;
  }
}

class UnconfiguredSocial extends SocialSignIn {
  @override
  bool available(SocialProvider provider) => false;
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
  });
  Widget app({bool signIn = true, double scale = 1, SocialSignIn? social}) =>
      MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale)),
              child: child!),
          home: RepaintBoundary(
              key: const ValueKey('auth-preview'),
              child: AuthView(initialSignIn: signIn, socialSignIn: social)));
  testWidgets('unconfigured providers are honest and do not initialize SDKs',
      (tester) async {
    await tester.pumpWidget(app(social: UnconfiguredSocial()));
    await tester.pumpAndSettle();
    final buttons =
        tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttons.length, 2);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
        find.byType(Image), findsOneWidget); // Only Google's small brand mark
    expect(
        tester
            .widget<ColoredBox>(find.byKey(const ValueKey('auth-background')))
            .color,
        Colors.black);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets('ordinary Android builds enable Google without build defines',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final google = find.descendant(
        of: find.byKey(const ValueKey('auth-google')),
        matching: find.byType(OutlinedButton));
    expect(tester.widget<OutlinedButton>(google).onPressed, isNotNull);
    expect(find.text('Coming soon'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  test(
      'Google remains unavailable on iOS until its native client is configured',
      () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(SocialSignIn().available(SocialProvider.google), isFalse);
  });
  testWidgets(
      'provider cancellation restores controls without creating a session',
      (tester) async {
    final social = PendingSocial();
    await tester.pumpWidget(app(social: social));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('auth-apple')));
    await tester.tap(find.byKey(const ValueKey('auth-apple')));
    await tester.pump();
    expect(social.attempts, 1);
    expect(
        tester
            .widgetList<OutlinedButton>(find.byType(OutlinedButton))
            .every((button) => button.onPressed == null),
        isTrue);
    social.result.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(AuthView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        tester
            .widgetList<OutlinedButton>(find.byType(OutlinedButton))
            .every((button) => button.onPressed != null),
        isTrue);
  });
  test(
      'membership translations cover all app language families and preserve billing placeholders',
      () {
    for (final phrase in membershipCopy.entries) {
      expect(phrase.value.length, membershipCopyLocales.length,
          reason: phrase.key);
      final placeholders =
          RegExp(r'\{[^}]+\}').allMatches(phrase.key).map((m) => m[0]!).toSet();
      for (final translation in phrase.value) {
        expect(translation.trim(), isNotEmpty);
        expect(
            RegExp(r'\{[^}]+\}')
                .allMatches(translation)
                .map((m) => m[0]!)
                .toSet(),
            placeholders,
            reason: phrase.key);
      }
    }
  });
  testWidgets('email password validation and password visibility remain usable',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'test@example.invalid');
    await tester.enterText(find.byType(TextField).last, 'short');
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    final toggle = find.byTooltip('Show password');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        false);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });
  testWidgets('sign in fits narrow phone with large text and a keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(scale: 1.8));
    await tester.pumpAndSettle();
    final background =
        tester.getRect(find.byKey(const ValueKey('auth-background')));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('auth-email')), 150,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('auth-email'))),
        alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-email')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('auth-email')))
            .focusNode!
            .hasFocus,
        true);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byKey(const ValueKey('auth-background'))),
        background);
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
  });
  testWidgets('capture new sign-in and account creation screens',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.runAsync(() => precacheImage(
        const ResizeImage(AssetImage('assets/branding/google_g_logo.png'),
            width: 63),
        tester.element(find.byType(AuthView))));
    await tester.pumpAndSettle();
    Future<void> save(String name) => tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('auth-preview')))
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/previews').createSync(recursive: true);
          File('build/previews/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
    await save('signin-redesigned');
    await save('signin-email');
    await tester.ensureVisible(find.textContaining('New to Setcraft?'));
    await tester.tap(find.textContaining('New to Setcraft?'));
    await tester.pumpAndSettle();
    await save('signup-redesigned');
    expect(tester.takeException(), isNull);
  });
}
