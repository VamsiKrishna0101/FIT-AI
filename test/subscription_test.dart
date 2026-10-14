import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:fitai_mobile/features/subscription/subscription_service.dart';
import 'package:fitai_mobile/features/subscription/subscription_view.dart';

Map<String, dynamic> accessData(String state) => {
      'state': state,
      'hasAccess': state == 'trial' || state == 'active',
      'billingReady': true,
      'serverTime': '2026-10-14T12:00:00Z',
      'trialEndsAt': state == 'available' ? null : '2026-10-28T12:00:00Z',
      'paidUntil': state == 'active' ? '2026-11-14T12:00:00Z' : null,
      'accountId': 'account',
    };

class TestSubscription extends SubscriptionService {
  TestSubscription({super.store});
  int trials = 0;
  String? refreshError;
  bool storeFails = false;
  String? selected;
  @override
  bool get android => true;
  @override
  Future<void> refresh() async {
    if (refreshError != null) throw StateError(refreshError!);
  }

  @override
  Future<void> loadProducts() async {
    storeReady = products.isNotEmpty && !storeFails;
    if (storeFails) {
      products.clear();
      throw StateError('Could not load Google Play prices. Please retry.');
    }
  }

  @override
  Future<void> startTrial() async {
    trials++;
    access = SubscriptionAccess(accessData('trial'));
    notifyListeners();
  }

  @override
  Future<void> purchase(String interval) async {
    selected = interval;
  }
}

class QuietPlayStore extends Fake implements InAppPurchase {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
}

class UnconfiguredAndroidSubscription extends SubscriptionService {
  @override
  bool get android => true;
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(rootBundle
          .load('packages/cupertino_icons/assets/CupertinoIcons.ttf'));
    await icons.load();
  });
  TestSubscription service(String state) =>
      TestSubscription()..access = SubscriptionAccess(accessData(state));

  Widget screen(TestSubscription service,
          {VoidCallback? onContinue, double scale = 1}) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
            data: MediaQueryData(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: SubscriptionView(service: service, onContinue: onContinue)),
      );

  test(
      'server time determines access; expired/canceled local state cannot grant it',
      () {
    final trial = SubscriptionAccess(accessData('trial'));
    expect(trial.hasAccess, true);
    expect(trial.daysRemaining, 14);
    expect(SubscriptionAccess(accessData('expired')).hasAccess, false);
    expect(
        SubscriptionAccess(
                {...accessData('trial'), 'serverTime': '2026-10-29T12:00:00Z'})
            .hasAccess,
        false);
  });

  testWidgets(
      'card-free trial starts only after a tap and continues after server confirmation',
      (tester) async {
    final model = service('available');
    var continued = false;
    await tester.pumpWidget(screen(model, onContinue: () => continued = true));
    await tester.pumpAndSettle();
    expect(model.trials, 0);
    expect(
        find.text(
            '14 days of full access. No card required. No automatic charge.'),
        findsOneWidget);
    await tester.tap(find.text('Start my 14 days'));
    await tester.pumpAndSettle();
    expect(model.trials, 1);
    expect(continued, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired account cannot subscribe with missing live store prices',
      (tester) async {
    final model = service('expired');
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe now'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
    expect(find.text('View saved records'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('We couldn’t load plans'), 250);
    expect(model.selected, isNull);
    expect(find.text('Start my 14 days'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'plan selection uses live localized prices and real annual savings',
      (tester) async {
    final model = service('expired');
    for (final interval in ['monthly', 'annual']) {
      model.products[interval] = ProductDetails(
          id: interval,
          title: interval,
          description: '',
          price: interval == 'monthly' ? '€12.99' : '€99.99',
          rawPrice: interval == 'monthly' ? 12.99 : 99.99,
          currencyCode: 'EUR');
    }
    expect(model.annualSavings, 36);
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Monthly'), 350);
    await tester.ensureVisible(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('€12.99'), findsOneWidget);
    await tester.tap(find.text('Subscribe now'));
    expect(model.selected, 'monthly');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'trial layout supports narrow screens and larger text with reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(screen(service('available'), scale: 1.8));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Restore purchases'), 300);
    expect(tester.takeException(), isNull);
  });

  test('unconfigured Play billing does not prevent trial access', () async {
    final model = UnconfiguredAndroidSubscription()
      ..access = SubscriptionAccess(
          {...accessData('available'), 'billingReady': false});
    await model.loadProducts();
    expect(model.products, isEmpty);
    expect(model.storeReady, false);
    expect(model.access!.trialAvailable, true);
    model.dispose();
  });

  testWidgets(
      'missing subscription status offers retry without claiming an active trial',
      (tester) async {
    final model = TestSubscription()
      ..refreshError = 'Membership is temporarily unavailable.';
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    expect(find.text('Membership is temporarily unavailable.'), findsOneWidget);
    expect(find.text('Continue your trial'), findsNothing);
    expect(model.trials, 0);
    model.refreshError = null;
    model.access = SubscriptionAccess(accessData('available'));
    await tester.tap(find.text('Retry').last);
    await tester.pumpAndSettle();
    expect(find.text('Start my 14 days'), findsOneWidget);
    expect(model.trials, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unconfigured plans open a compact message and keep trial continuation',
      (tester) async {
    final model = service('trial')
      ..access =
          SubscriptionAccess({...accessData('trial'), 'billingReady': false});
    var continued = false;
    await tester.pumpWidget(screen(model, onContinue: () => continued = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View subscription plans'));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions are coming soon'), findsOneWidget);
    expect(
        find.text(
            'Your trial is still active. Keep exploring all your features.'),
        findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    expect(find.text('Subscribe now'), findsNothing);
    await tester.tap(find.text('Continue your trial').last);
    await tester.pumpAndSettle();
    expect(continued, true);
    expect(model.trials, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Play price error does not become a trial status error',
      (tester) async {
    final model = service('trial')..storeFails = true;
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    expect(find.text('Could not refresh your subscription. Please retry.'),
        findsNothing);
    await tester.tap(find.text('View subscription plans'));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t load plans'), findsOneWidget);
    expect(find.text('Continue your trial'), findsWidgets);
    expect(find.text('Subscribe now'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'only returned Play plans are offered and monthly-only checkout remains usable',
      (tester) async {
    final model = service('expired');
    model.products['monthly'] = ProductDetails(
        id: 'monthly',
        title: 'Monthly',
        description: '',
        price: '£10.99',
        rawPrice: 10.99,
        currencyCode: 'GBP');
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Monthly'), 250);
    expect(find.text('Annual'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
    await tester.tap(find.text('Subscribe now'));
    expect(model.selected, 'monthly');
    expect(tester.takeException(), isNull);
  });

  test('a store outage during startup preserves confirmed trial access',
      () async {
    final model = TestSubscription(store: QuietPlayStore())
      ..access = SubscriptionAccess(accessData('trial'))
      ..storeFails = true;
    await model.initialize();
    expect(model.access!.hasAccess, true);
    expect(model.plansAvailable, false);
    model.dispose();
  });

  testWidgets('trial preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: screen(service('available'))));
    await tester.pumpAndSettle();
    if (Platform.environment['FITAI_SUBSCRIPTION_PREVIEW'] == '1') {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/subscription-trial-preview.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });
}
