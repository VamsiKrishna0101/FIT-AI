import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/branding/setcraft_launch_screen.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/core/navigation/prepare_authenticated_home.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/auth/views/auth_view.dart';
import 'package:setcraft/features/auth/data/auth_repository.dart';
import 'package:setcraft/models/auth_models.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/views/onboarding_view.dart';
import 'package:setcraft/features/onboarding/views/discovery_onboarding_gate.dart';
import 'package:setcraft/features/subscription/subscription_service.dart';
import 'package:setcraft/features/subscription/subscription_view.dart';

class EntryAdapter implements HttpClientAdapter {
  final paths = <String>[];
  String state = 'active';
  int profileStatus = 200, membershipStatus = 200;
  bool eligible = false;
  Completer<void>? pendingMembership;
  final membershipStarted = Completer<void>();
  @override
  Future<ResponseBody> fetch(RequestOptions request, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    paths.add(request.path);
    Object body;
    int status = 200;
    switch (request.path) {
      case '/api/auth/login':
        body = {
          'user': {'id': 'entry-owner', 'email': 'entry@example.test'},
          'tokens': {
            'accessToken': 'synthetic-token',
            'refreshToken': 'synthetic-refresh'
          }
        };
      case '/api/onboarding':
        status = profileStatus;
        body = {'data': {}};
      case '/api/plans/starter':
        body = {
          'data': {'eligible': eligible, 'hasAccess': state == 'active'}
        };
      case '/api/onboarding/discovery':
        body = {
          'data': {'completed': false}
        };
      case '/api/subscription/status':
        if (!membershipStarted.isCompleted) membershipStarted.complete();
        await pendingMembership?.future;
        status = membershipStatus;
        final now = DateTime.now().toUtc();
        body = status == 200
            ? {
                'data': {
                  'state': state,
                  'billingReady': false,
                  'products': {},
                  'serverTime': now.toIso8601String(),
                  'paidUntil':
                      now.add(const Duration(hours: 1)).toIso8601String(),
                }
              }
            : {'error': 'Could not verify membership — try again'};
      default:
        throw StateError('Unexpected fixture request ${request.path}');
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class EntryMembership extends SubscriptionService {
  int initializations = 0;
  @override
  bool get android => false;
  @override
  bool get ios => false;
  @override
  Future<void> initialize() {
    initializations++;
    return super.initialize();
  }
}

class EntryAuth extends AuthRepository {
  int signIns = 0;
  @override
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    signIns++;
    return AuthResponse(
        accessToken: 'synthetic-token',
        refreshToken: 'synthetic-refresh',
        user: UserProfile(id: 'entry-owner', email: email));
  }
}

class EntryRegistration extends EntryAuth {
  int sent = 0, registered = 0;
  @override
  Future<void> sendOtp(String email) async {
    sent++;
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {}
  @override
  Future<AuthResponse> registerVerifiedEmail(
      {required String email,
      required String password,
      required OnboardingDraft draft}) async {
    registered++;
    return AuthResponse(
        accessToken: 'synthetic-token',
        refreshToken: 'synthetic-refresh',
        user: UserProfile(id: 'entry-owner', email: email));
  }
}

String entryToken(String owner) =>
    '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.'
    '${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.synthetic-signature';

const destination = Scaffold(body: Text('VERIFIED ACCOUNT HOME'));

void main() {
  late EntryAdapter adapter;
  late EntryMembership membership;
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('fitai/sleep_estimate'), (_) async => null);
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('fitai/sleep_estimate'), null);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': entryToken('entry-owner'),
      'fitai_user_id': 'entry-owner'
    });
    adapter = EntryAdapter();
    membership = EntryMembership();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() {
      ApiClient.shared.client.httpClientAdapter = original;
      membership.dispose();
    });
  });

  testWidgets(
      'sign-in stays visible until all checks finish, without a splash frame',
      (tester) async {
    final pendingDestination = Completer<Widget>();
    final auth = EntryAuth();
    bool preparing = false;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: AuthView(
            initialSignIn: true,
            repository: auth,
            prepareHome: (_) {
              preparing = true;
              return pendingDestination.future;
            })));
    await tester.enterText(
        find.byKey(const ValueKey('auth-email')), 'entry@example.test');
    await tester.enterText(find.byType(TextField).last, 'synthetic-password');
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.tap(find.byType(LiquidChromeButton));
    for (int frame = 0; frame < 10 && !preparing; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(preparing, true);
    await tester.pump();
    expect(find.text('Signing in'), findsOneWidget);
    expect(find.byType(AuthView), findsOneWidget);
    expect(find.byType(SetcraftLaunchScreen), findsNothing);
    expect(find.text('VERIFIED ACCOUNT HOME'), findsNothing);
    expect(auth.signIns, 1);
    pendingDestination.complete(destination);
    for (int frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SetcraftLaunchScreen), findsNothing);
    }
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED ACCOUNT HOME'), findsOneWidget);
    expect(auth.signIns, 1,
        reason: 'Retry resumes account checks without another login');
    await tester.pumpWidget(const SizedBox());
  });

  for (final expiredSession in [false, true]) {
    testWidgets(
        'created account retries without duplicate OTP/registration (expired session: $expiredSession)',
        (tester) async {
      final auth = EntryRegistration();
      int attempts = 0;
      final entryKinds = <bool>[];
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: AuthView(
              repository: auth,
              prepareHome: (newAccount) async {
                entryKinds.add(newAccount);
                if (++attempts == 1) {
                  if (expiredSession) {
                    final request =
                        RequestOptions(path: '/api/subscription/status');
                    throw DioException(
                        requestOptions: request,
                        response: Response(
                            requestOptions: request,
                            statusCode: 401,
                            data: {
                              'error': 'Could not open account — try again'
                            }));
                  }
                  throw const AuthFlowException(
                      'Could not open account — try again');
                }
                return destination;
              })));
      await tester.enterText(
          find.byKey(const ValueKey('auth-email')), 'entry@example.test');
      await tester.enterText(
          find.byKey(const ValueKey('auth-password')), 'synthetic-password');
      await tester.ensureVisible(find.byType(LiquidChromeButton));
      await tester.tap(find.byType(LiquidChromeButton));
      await tester.pumpAndSettle();
      final code = find.descendant(
          of: find.byType(OtpCodeField), matching: find.byType(TextField));
      await tester.enterText(code, '123456');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Verify and continue'));
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();
      expect(find.text('Could not open account — try again'), findsOneWidget);
      expect(auth.registered, 1);
      await tester.ensureVisible(find.byType(LiquidChromeButton));
      await tester.tap(find.byType(LiquidChromeButton));
      await tester.pumpAndSettle();
      expect(find.text('VERIFIED ACCOUNT HOME'), findsOneWidget);
      expect(auth.sent, 1);
      expect(auth.registered, 1);
      expect(auth.signIns, expiredSession ? 1 : 0);
      expect(entryKinds, [true, true]);
      expect(find.byType(SetcraftLaunchScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'expired membership opens paywall directly and remains protected on refresh',
      (tester) async {
    adapter.state = 'expired';
    final prepared = (await tester.runAsync(() =>
        prepareAuthenticatedHome(membership: membership, home: destination)))!;
    await tester
        .pumpWidget(MaterialApp(theme: ThemeData.dark(), home: prepared));
    expect(find.byType(SetcraftLaunchScreen), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(find.text('VERIFIED ACCOUNT HOME'), findsNothing);
    expect(membership.initializations, 1);
    expect(adapter.paths.where((p) => p == '/api/onboarding').length, 1);
    expect(adapter.paths.where((p) => p == '/api/plans/starter').length, 1);
    expect(
        adapter.paths.where((p) => p == '/api/subscription/status').length, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('prepared access still locks immediately after verified expiry',
      (tester) async {
    final prepared = (await tester.runAsync(() =>
        prepareAuthenticatedHome(membership: membership, home: destination)))!;
    await tester
        .pumpWidget(MaterialApp(theme: ThemeData.dark(), home: prepared));
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED ACCOUNT HOME'), findsOneWidget);
    adapter.state = 'expired';
    await tester.runAsync(membership.refresh);
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED ACCOUNT HOME'), findsNothing);
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(find.byType(SetcraftLaunchScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'missing profile returns setup before making membership or plan requests',
      () async {
    adapter.profileStatus = 404;
    expect(await prepareAuthenticatedHome(membership: membership),
        isA<OnboardingView>());
    expect(adapter.paths, ['/api/onboarding']);
  });

  test('failed membership check cannot produce a destination', () async {
    adapter.membershipStatus = 503;
    await expectLater(prepareAuthenticatedHome(membership: membership),
        throwsA(isA<DioException>()));
  });

  test('account switch during preparation cannot open the prior account',
      () async {
    adapter.pendingMembership = Completer<void>();
    final attempt = prepareAuthenticatedHome(membership: membership);
    final assertion = expectLater(attempt, throwsA(anything));
    await adapter.membershipStarted.future.timeout(const Duration(seconds: 3));
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': entryToken('other-owner'),
      'fitai_user_id': 'other-owner',
    });
    adapter.pendingMembership!.complete();
    await assertion;
  });

  testWidgets('survey is prepared before entry without another splash',
      (tester) async {
    adapter.eligible = true;
    final prepared = (await tester.runAsync(() =>
        prepareAuthenticatedHome(membership: membership, home: destination)))!;
    await tester
        .pumpWidget(MaterialApp(theme: ThemeData.dark(), home: prepared));
    expect(find.byType(SetcraftLaunchScreen), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryOnboardingGate), findsOneWidget);
    expect(
        find.text('Where did you first hear about Setcraft?'), findsOneWidget);
    expect(
        adapter.paths.where((p) => p == '/api/onboarding/discovery').length, 1);
    expect(find.text('VERIFIED ACCOUNT HOME'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed preparation stays on sign-in and can be retried',
      (tester) async {
    final auth = EntryAuth();
    int attempts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: AuthView(
            initialSignIn: true,
            repository: auth,
            prepareHome: (_) async {
              if (++attempts == 1) {
                throw const AuthFlowException(
                    'Could not open account — try again');
              }
              return destination;
            })));
    await tester.enterText(
        find.byKey(const ValueKey('auth-email')), 'entry@example.test');
    await tester.enterText(find.byType(TextField).last, 'synthetic-password');
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.byType(AuthView), findsOneWidget);
    expect(find.text('Could not open account — try again'), findsOneWidget);
    expect(find.byType(SetcraftLaunchScreen), findsNothing);
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED ACCOUNT HOME'), findsOneWidget);
    expect(auth.signIns, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'editing credentials after a failed check requires authentication again',
      (tester) async {
    final auth = EntryAuth();
    int attempts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: AuthView(
            initialSignIn: true,
            repository: auth,
            prepareHome: (_) async {
              if (++attempts == 1) {
                throw const AuthFlowException(
                    'Could not open account — try again');
              }
              return destination;
            })));
    await tester.enterText(
        find.byKey(const ValueKey('auth-email')), 'entry@example.test');
    await tester.enterText(
        find.byKey(const ValueKey('auth-password')), 'synthetic-password');
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('auth-password')),
        'changed-synthetic-password');
    await tester.ensureVisible(find.byType(LiquidChromeButton));
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(find.text('VERIFIED ACCOUNT HOME'), findsOneWidget);
    expect(auth.signIns, 2);
    await tester.pumpWidget(const SizedBox());
  });

  test('prepared membership is invalidated when credentials change', () async {
    final prepared = await membership.prepareAccountEntry();
    expect(prepared.isCurrent, true);
    await SecureSessionStore.shared.saveUserId('entry-owner');
    expect(prepared.isCurrent, false);
  });
}
