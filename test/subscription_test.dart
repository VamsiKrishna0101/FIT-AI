import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/localization/membership_copy.dart';
import 'package:fitai_mobile/features/subscription/subscription_gate.dart';
import 'package:fitai_mobile/features/subscription/subscription_service.dart';
import 'package:fitai_mobile/features/subscription/subscription_view.dart';

Map<String, dynamic> accessData(String state) => {
      'state': state,
      'billingReady': true,
      'trialSource': 'store',
      'serverTime': '2026-10-24T12:00:00Z',
      'trialEndsAt': state == 'trial' ? '2026-11-07T12:00:00Z' : null,
      'paidUntil': state == 'active' ? '2026-11-24T12:00:00Z' : null,
      'accountId': 'billing-account',
      'appleAccountId': 'member',
      'products': {'annual': 'annual-product', 'monthly': 'monthly-product'},
      'basePlans': {'annual': 'annual', 'monthly': 'monthly'},
    };
MembershipOffer exampleOffer(String interval, {bool trial = true}) {
  final annual = interval == 'annual';
  final product = ProductDetails(
      id: '$interval-product',
      title: interval,
      description: 'Test store fixture',
      price: annual ? '€99.99' : '€12.99',
      rawPrice: annual ? 99.99 : 12.99,
      currencyCode: 'EUR');
  return MembershipOffer(
      product: product,
      price: product.price,
      amount: product.rawPrice,
      trialDays: trial ? 14 : 0);
}

class PreviewMembership extends SubscriptionService {
  String? selected;
  bool fail = false;
  PreviewMembership(
      {String state = 'available', bool trial = true, bool prices = true}) {
    access = SubscriptionAccess(accessData(state));
    storeReady = prices;
    if (prices) {
      for (final interval in ['annual', 'monthly']) {
        offers[interval] = exampleOffer(interval, trial: trial);
      }
    }
  }
  @override
  bool get android => true;
  @override
  Future<void> initialize() async {
    if (fail) throw StateError('Connection failed. Please retry.');
  }

  @override
  Future<void> refresh() async {
    if (fail) throw StateError('Connection failed. Please retry.');
  }

  @override
  Future<void> purchase(String interval) async {
    selected = interval;
  }

  void verified(String state) {
    access = SubscriptionAccess(accessData(state));
    notifyListeners();
  }
}

class StoreFixture extends Fake implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  PurchaseParam? requested;
  int completions = 0;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    requested = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completions++;
  }
}

class VerificationFixture implements HttpClientAdapter {
  final paths = <String>[];
  bool reject = false;
  String state = 'available';
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add(options.path);
    final verify = options.path.endsWith('/verify');
    if (verify && !reject) state = 'trial';
    return ResponseBody.fromString(
        jsonEncode(verify && reject
            ? {'error': 'Verification unavailable'}
            : {'data': accessData(state), 'purchaseActive': verify && !reject}),
        verify && reject ? 503 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

class CheckoutService extends SubscriptionService {
  CheckoutService(StoreFixture store) : super(store: store);
  bool offerChanged = false;
  @override
  bool get android => true;
  @override
  Future<void> loadProducts() async {
    storeReady = true;
    for (final interval in ['annual', 'monthly']) {
      offers[interval] = exampleOffer(interval, trial: !offerChanged);
    }
  }
}

PurchaseDetails purchaseEvent(PurchaseStatus status) => PurchaseDetails(
    purchaseID: 'transaction',
    productID: 'annual-product',
    transactionDate: '2026-10-24',
    verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'opaque-store-token',
        source: 'google_play'),
    status: status)
  ..pendingCompletePurchase = status == PurchaseStatus.purchased;

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'test-session', 'fitai_user_id': 'member'});
  });
  Widget app(Widget child,
          {double scale = 1, Locale locale = const Locale('en', 'GB')}) =>
      MaterialApp(
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('de'),
            Locale('fr'),
            Locale('sv'),
            Locale('no'),
            Locale('da'),
            Locale('nl'),
            Locale('es'),
            Locale('it')
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale)),
              child: child!),
          home: child);
  test('malformed and expired access cannot unlock the app', () {
    expect(SubscriptionAccess(accessData('trial')).hasAccess, true);
    expect(
        SubscriptionAccess(
                {...accessData('trial'), 'serverTime': '2026-11-08T12:00:00Z'})
            .hasAccess,
        false);
    expect(SubscriptionAccess({'state': 'active', 'hasAccess': true}).hasAccess,
        false);
    expect(
        SubscriptionAccess({...accessData('trial'), 'trialEndsAt': 'bad'})
            .hasAccess,
        false);
  });
  test('free phase uses actual paid renewal price and exact 14-day eligibility',
      () {
    GooglePlayProductDetails product({String period = 'P2W'}) =>
        GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
            description: 'Fixture',
            name: 'Annual',
            title: 'Annual',
            productId: 'annual-product',
            productType: ProductType.subs,
            subscriptionOfferDetails: [
              SubscriptionOfferDetailsWrapper(
                  basePlanId: 'annual',
                  offerId: 'new-member',
                  offerTags: const [],
                  offerIdToken: 'trial-offer',
                  pricingPhases: [
                    PricingPhaseWrapper(
                        billingCycleCount: 1,
                        billingPeriod: period,
                        formattedPrice: 'Free',
                        priceAmountMicros: 0,
                        priceCurrencyCode: 'EUR',
                        recurrenceMode: RecurrenceMode.finiteRecurring),
                    const PricingPhaseWrapper(
                        billingCycleCount: 0,
                        billingPeriod: 'P1Y',
                        formattedPrice: '€99.99',
                        priceAmountMicros: 99990000,
                        priceCurrencyCode: 'EUR',
                        recurrenceMode: RecurrenceMode.infiniteRecurring)
                  ])
            ])).single;
    final offer =
        SubscriptionService.googleOffer(product(), 'annual', allowTrial: true)!;
    expect(offer.price, '€99.99');
    expect(offer.amount, 99.99);
    expect(offer.trialDays, 14);
    expect(
        SubscriptionService.googleOffer(product(), 'wrong', allowTrial: true),
        isNull);
    expect(
        SubscriptionService.googleOffer(product(), 'annual', allowTrial: false),
        isNull);
    expect(
        SubscriptionService.googleOffer(product(period: 'P1W'), 'annual',
            allowTrial: true),
        isNull);
    expect(
        SubscriptionService.googleOffer(product(), 'annual',
            allowTrial: true, expectedPeriod: 'P1M'),
        isNull);
  });
  testWidgets('price is visible, annual and monthly update the same checkout',
      (tester) async {
    final service = PreviewMembership();
    await tester.pumpWidget(app(SubscriptionView(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('14 days free, then €99.99/year'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(12));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(12));
    await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('membership-monthly'))),
        alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-monthly')));
    await tester.pumpAndSettle();
    expect(find.text('14 days free, then €12.99/month'), findsOneWidget);
    await tester.tap(find.text('Start my 14-day free trial'));
    await tester.pumpAndSettle();
    expect(service.selected, 'monthly');
    expect(service.access!.hasAccess, false);
    expect(find.text('No payment details. No automatic charge.'), findsNothing);
  });
  testWidgets('ineligible store offer never promises a free trial',
      (tester) async {
    await tester.pumpWidget(app(SubscriptionView(
        service: PreviewMembership(state: 'expired', trial: false))));
    await tester.pumpAndSettle();
    expect(find.text('Start my 14-day free trial'), findsNothing);
    expect(find.text('Subscribe & continue'), findsOneWidget);
    expect(find.text('€99.99/year · auto-renewing'), findsOneWidget);
  });
  testWidgets('missing prices and network failure keep access locked',
      (tester) async {
    var continued = false;
    final service = PreviewMembership(prices: false)..fail = true;
    await tester.pumpWidget(app(SubscriptionView(
        service: service, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    expect(find.text('Retry loading plans'), findsOneWidget);
    expect(find.text('Start my 14-day free trial'), findsNothing);
    expect(find.text('Connection failed. Please retry.'), findsOneWidget);
    expect(continued, false);
  });
  testWidgets(
      'root gate has no dashboard bypass and responds to verified expiry',
      (tester) async {
    final service = PreviewMembership();
    await tester.pumpWidget(app(SubscriptionGate(
        service: service, child: const Text('PRIVATE DASHBOARD'))));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE DASHBOARD'), findsNothing);
    expect(find.text('Not now'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE DASHBOARD'), findsNothing);
    service.verified('trial');
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE DASHBOARD'), findsOneWidget);
    service.verified('expired');
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE DASHBOARD'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets(
      'canceled pending and unverified purchases stay locked; verified receipt unlocks',
      (tester) async {
    final adapter = VerificationFixture();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture();
    final checkout = CheckoutService(store);
    await tester.runAsync(checkout.initialize);
    await tester.runAsync(() => checkout.purchase('annual'));
    expect(store.requested?.applicationUserName, 'billing-account');
    expect(checkout.access!.hasAccess, false);
    store.stream.add([purchaseEvent(PurchaseStatus.pending)]);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(checkout.access!.hasAccess, false);
    store.stream.add([purchaseEvent(PurchaseStatus.canceled)]);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(checkout.awaitingConfirmation, false);
    expect(adapter.paths.where((path) => path.endsWith('/verify')), isEmpty);
    adapter.reject = true;
    store.stream.add([purchaseEvent(PurchaseStatus.purchased)]);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    expect(checkout.access!.hasAccess, false);
    expect(store.completions, 0);
    adapter.reject = false;
    store.stream.add([purchaseEvent(PurchaseStatus.purchased)]);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    expect(checkout.access!.hasAccess, true);
    expect(store.completions, 1);
    expect(adapter.paths.contains('/api/subscription/start-trial'), false);
    checkout.dispose();
    await store.stream.close();
  });
  testWidgets('an offer change requires review before any checkout opens',
      (tester) async {
    final adapter = VerificationFixture();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture();
    final service = CheckoutService(store);
    await tester.runAsync(service.initialize);
    service.offerChanged = true;
    await tester.runAsync(() => service.purchase('annual'));
    expect(store.requested, isNull);
    expect(service.error, contains('Review the updated price'));
    expect(service.access!.hasAccess, false);
    service.dispose();
    await store.stream.close();
  });
  testWidgets('expiry also locks a detail route until access is restored',
      (tester) async {
    final navigation = GlobalKey<NavigatorState>();
    final service = PreviewMembership(state: 'trial');
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigation,
        home: SubscriptionGate(
            service: service,
            child: const Scaffold(body: Text('ACCOUNT HOME')))));
    await tester.pumpAndSettle();
    unawaited(navigation.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('OPEN DETAIL')))));
    await tester.pumpAndSettle();
    service.verified('expired');
    ApiClient.subscriptionRequired.value++;
    await tester.pumpAndSettle();
    expect(find.text('OPEN DETAIL'), findsNothing);
    expect(find.byType(SubscriptionView), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('OPEN DETAIL'), findsNothing);
    service.verified('trial');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to my plan'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN DETAIL'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  for (final scale in [1.0, 1.8]) {
    testWidgets('membership fits 320px phone at $scale text scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          app(SubscriptionView(service: PreviewMembership()), scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Start my 14-day free trial').hitTestable(),
          findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final language in ['de', 'nl', 'it']) {
    testWidgets('localized membership fits narrow large-text $language',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(
          SubscriptionView(service: PreviewMembership()),
          scale: 1.6,
          locale: Locale(language)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find
              .text(membershipTranslation(
                  language, 'Start my 14-day free trial')!)
              .hitTestable(),
          findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('capture membership with example store prices', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('membership-preview');
    await tester.pumpWidget(app(RepaintBoundary(
        key: key, child: SubscriptionView(service: PreviewMembership()))));
    await tester.pumpAndSettle();
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/branding/setcraft-training-hero-v1.png'),
        tester.element(find.byKey(key))));
    await tester.pumpAndSettle();
    Future<void> capture(String name) => tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(key))
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/previews').createSync(recursive: true);
          File('build/previews/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
    await capture('membership-example-offer');
    await tester.drag(find.byType(ListView), const Offset(0, -620));
    await tester.pumpAndSettle();
    await capture('membership-trial-timeline');
    await Scrollable.ensureVisible(
        tester.element(find.text('See what’s included.')),
        alignment: 0);
    await tester.pumpAndSettle();
    await capture('membership-feature-comparison');
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(12));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(12));
    expect(find.text('Sets, reps & weight guidance'), findsOneWidget);
    await Scrollable.ensureVisible(
        tester.element(find.text('Personal records & exercise progress')),
        alignment: 0);
    await tester.pumpAndSettle();
    await capture('membership-feature-comparison-more');
    await Scrollable.ensureVisible(
        tester.element(find.text('Progress photos & comparisons')),
        alignment: .6);
    await tester.pumpAndSettle();
    expect(
        find.text('Start my 14-day free trial').hitTestable(), findsOneWidget);
    await capture('membership-feature-comparison-body');
    expect(tester.takeException(), isNull);
  });
}
