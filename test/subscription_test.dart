import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
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
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/localization/membership_copy.dart';
import 'package:setcraft/features/subscription/subscription_gate.dart';
import 'package:setcraft/features/subscription/subscription_service.dart';
import 'package:setcraft/features/subscription/subscription_view.dart';

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
  final bool iPhone;
  PreviewMembership(
      {String state = 'available',
      bool trial = true,
      bool prices = true,
      this.iPhone = false}) {
    access = SubscriptionAccess(accessData(state));
    storeReady = prices;
    if (prices) {
      for (final interval in ['annual', 'monthly']) {
        offers[interval] = exampleOffer(interval, trial: trial);
      }
    }
  }
  @override
  bool get android => !iPhone;
  @override
  bool get ios => iPhone;
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
  int queries = 0;
  bool available = true, catalogFails = false;
  List<ProductDetails> catalog = [];
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    queries++;
    if (catalogFails) {
      throw StateError('Could not load Google Play prices. Please retry.');
    }
    return ProductDetailsResponse(
        productDetails: catalog,
        notFoundIDs: identifiers
            .where((id) => !catalog.any((p) => p.id == id))
            .toList());
  }

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
  bool billingReady = true;
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
            : {
                'data': {...accessData(state), 'billingReady': billingReady},
                'purchaseActive': verify && !reject
              }),
        verify && reject ? 503 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

class CatalogService extends SubscriptionService {
  CatalogService(StoreFixture store) : super(store: store);
  @override
  bool get android => true;
  @override
  bool get ios => false;
}

ProductDetails catalogProduct() =>
    GooglePlayProductDetails.fromProductDetails(const ProductDetailsWrapper(
        description: 'Fixture',
        name: 'Annual',
        title: 'Annual',
        productId: 'annual-product',
        productType: ProductType.subs,
        subscriptionOfferDetails: [
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'annual',
            offerId: null,
            offerTags: [],
            offerIdToken: 'base',
            pricingPhases: [
              PricingPhaseWrapper(
                  billingCycleCount: 0,
                  billingPeriod: 'P1Y',
                  formattedPrice: '€99.99',
                  priceAmountMicros: 99990000,
                  priceCurrencyCode: 'EUR',
                  recurrenceMode: RecurrenceMode.infiniteRecurring)
            ],
          )
        ])).single;

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

class IPhoneCheckoutService extends CheckoutService {
  IPhoneCheckoutService(super.store);
  @override
  bool get android => false;
  @override
  bool get ios => true;
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
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.remove_rounded), findsNothing);
    await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('membership-monthly'))),
        alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-monthly')));
    await tester.pumpAndSettle();
    expect(find.text('14 days free, then €12.99/month'), findsOneWidget);
    await tester.tap(find.text('Try for €0.00'));
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
    expect(find.text('Try for €0.00'), findsNothing);
    expect(find.text('Subscribe & continue'), findsOneWidget);
    expect(find.text('€99.99/year · auto-renewing'), findsNWidgets(2));
  });
  testWidgets('missing prices and network failure keep access locked',
      (tester) async {
    var continued = false;
    final service = PreviewMembership(prices: false)..fail = true;
    await tester.pumpWidget(app(SubscriptionView(
        service: service, onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Try for €0.00'), findsNothing);
    expect(find.text('Connection failed. Please retry.'), findsOneWidget);
    expect(continued, false);
  });
  testWidgets(
      'Paywall has the reference hierarchy without a brand or account header',
      (tester) async {
    await tester
        .pumpWidget(app(SubscriptionView(service: PreviewMembership())));
    await tester.pumpAndSettle();
    expect(find.text('SETCRAFT'), findsNothing);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Your first 14 days are free'), findsOneWidget);
    expect(find.text('Today:'), findsOneWidget);
    expect(find.text('Day 14:'), findsOneWidget);
    expect(find.text('Try for €0.00'), findsOneWidget);
    expect(find.text('This is included'), findsOneWidget);
    expect(find.text('We couldn’t load your plans.'), findsNothing);
  });
  testWidgets(
      'Missing billing setup has a clear availability state and never opens checkout',
      (tester) async {
    final service = PreviewMembership(prices: false)
      ..access = SubscriptionAccess(
          {...accessData('available'), 'billingReady': false})
      ..catalogIssue = SubscriptionCatalogIssue.setupPending;
    await tester.pumpWidget(app(SubscriptionView(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Membership opens soon'), findsOneWidget);
    expect(find.text('Check availability'), findsOneWidget);
    expect(find.text('We couldn’t load your plans.'), findsNothing);
    expect(find.text('Your first 14 days are free'), findsNothing);
    await tester.tap(find.text('Check availability'));
    await tester.pumpAndSettle();
    expect(service.selected, isNull);
  });
  testWidgets(
      'A delayed verified purchase continues once without another button tap',
      (tester) async {
    final service = PreviewMembership();
    var continued = 0;
    await tester.pumpWidget(
        app(SubscriptionView(service: service, onContinue: () => continued++)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try for €0.00'));
    await tester.pumpAndSettle();
    expect(continued, 0);
    service.verified('trial');
    await tester.pumpAndSettle();
    service.verified('trial');
    await tester.pumpAndSettle();
    expect(continued, 1);
  });
  testWidgets(
      'Store setup, unavailable store and missing products remain distinct',
      (tester) async {
    final adapter = VerificationFixture()..billingReady = false;
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture();
    final catalogue = CatalogService(store);
    await tester.runAsync(catalogue.initialize);
    expect(catalogue.catalogIssue, SubscriptionCatalogIssue.setupPending);
    expect(store.queries, 0);
    adapter.billingReady = true;
    store.available = false;
    await tester.runAsync(catalogue.initialize);
    expect(catalogue.catalogIssue, SubscriptionCatalogIssue.storeUnavailable);
    store.available = true;
    await tester.runAsync(catalogue.initialize);
    expect(catalogue.catalogIssue, SubscriptionCatalogIssue.productsMissing);
    expect(catalogue.plansAvailable, false);
    store.catalog = [catalogProduct()];
    await tester.runAsync(catalogue.initialize);
    expect(catalogue.catalogIssue, isNull);
    expect(catalogue.plansAvailable, true);
    catalogue.dispose();
    await store.stream.close();
  });
  testWidgets(
      'A temporary store failure keeps the last price and recovers on retry',
      (tester) async {
    final adapter = VerificationFixture();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture()..catalog = [catalogProduct()];
    final service = CatalogService(store);
    await tester.runAsync(service.initialize);
    expect(service.offers['annual']!.price, '€99.99');
    store.catalogFails = true;
    await tester.runAsync(service.initialize);
    expect(service.catalogIssue, SubscriptionCatalogIssue.connection);
    expect(service.offers['annual']!.price, '€99.99');
    expect(service.plansAvailable, false);
    store.catalogFails = false;
    await tester.runAsync(service.initialize);
    expect(service.catalogIssue, isNull);
    expect(service.plansAvailable, true);
    service.dispose();
    await store.stream.close();
  });
  testWidgets('Concurrent membership loads share one store request',
      (tester) async {
    final adapter = VerificationFixture();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture()..catalog = [catalogProduct()];
    final service = CatalogService(store);
    await tester.runAsync(() async {
      final first = service.initialize(), second = service.initialize();
      await Future.wait([first, second]);
    });
    expect(store.queries, 1);
    expect(adapter.paths.where((p) => p.endsWith('/status')).length, 1);
    service.dispose();
    await store.stream.close();
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
      expect(find.text('Try for €0.00').hitTestable(), findsOneWidget);
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
              .text(membershipTranslation(language, 'Try for {price}')!
                  .replaceAll(
                      '{price}',
                      NumberFormat.simpleCurrency(name: 'EUR', locale: language)
                          .format(0)))
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
    await tester.ensureVisible(find.text('This is included'));
    await tester.tap(find.text('This is included'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Workout logging & history'));
    await tester.pumpAndSettle();
    await capture('membership-feature-comparison');
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.remove_rounded), findsNWidgets(4));
    expect(find.text('Try for €0.00').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'iPhone checkout binds the Apple account and verifies through the iOS endpoint',
      (tester) async {
    final adapter = VerificationFixture();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final store = StoreFixture();
    final service = IPhoneCheckoutService(store);
    await tester.runAsync(service.initialize);
    await tester.runAsync(() => service.purchase('annual'));
    expect(store.requested?.applicationUserName, 'member');
    store.stream.add([
      PurchaseDetails(
          purchaseID: '12345678',
          productID: 'annual-product',
          verificationData: PurchaseVerificationData(
              localVerificationData: '',
              serverVerificationData: 'fixture-signed-storekit-transaction',
              source: 'app_store'),
          transactionDate: '2026-10-26',
          status: PurchaseStatus.purchased)
        ..pendingCompletePurchase = true
    ]);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    expect(adapter.paths, contains('/api/subscription/ios/verify'));
    expect(adapter.paths, isNot(contains('/api/subscription/android/verify')));
    expect(service.access!.hasAccess, true);
    expect(store.completions, 1);
    service.dispose();
    await store.stream.close();
  });

  testWidgets(
      'iPhone paywall uses App Store labels and closes back to the preview',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final capture = GlobalKey();
    final service = PreviewMembership(iPhone: true);
    await tester.pumpWidget(app(Builder(
        builder: (context) => Scaffold(
            body: Center(
                child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => RepaintBoundary(
                                key: capture,
                                child: SubscriptionView(service: service)))),
                    child: const Text('Plan preview')))))));
    await tester.tap(find.text('Plan preview'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel in App Store.'), findsOneWidget);
    expect(find.text('Cancel anytime in App Store.'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsNothing);
    expect(find.textContaining('Apple Pay'), findsNothing);
    expect(find.byKey(const ValueKey('membership-close')), findsOneWidget);
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/branding/setcraft-training-hero-v1.png'),
        capture.currentContext!));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/membership-iphone-example-offer.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    Navigator.of(tester.element(find.text('Sign out'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-close')));
    await tester.pumpAndSettle();
    expect(find.text('Plan preview'), findsOneWidget);
    expect(find.byType(SubscriptionView), findsNothing);
    expect(service.selected, isNull);
  });
}
