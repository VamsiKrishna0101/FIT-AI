import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:fitai_mobile/features/subscription/subscription_service.dart';
import 'package:fitai_mobile/features/subscription/subscription_view.dart';
import 'package:fitai_mobile/features/subscription/trial_access_hero.dart';
import 'package:fitai_mobile/features/subscription/subscription_pricing_view.dart';

Map<String, dynamic> accessData(String state) => {
      'state': state,
      'hasAccess': state == 'trial' || state == 'active',
      'billingReady': true,
      'serverTime': '2026-10-14T12:00:00Z',
      'trialEndsAt': state == 'available' ? null : '2026-10-28T12:00:00Z',
      'paidUntil': state == 'active' ? '2026-11-14T12:00:00Z' : null,
      'accountId': 'account',
    };

Map<String, dynamic> pricingData(String code) {
  final config = jsonDecode(
          File('../backend/data/subscription_prices.json').readAsStringSync())
      as Map;
  return {
    'source': 'planned',
    'trialDays': 14,
    'countryCode': code,
    'countries': [
      for (final entry in (config['countries'] as Map).entries)
        {'code': entry.key, ...Map<String, dynamic>.from(entry.value as Map)}
    ]
  };
}

class TestSubscription extends SubscriptionService {
  TestSubscription({super.store});
  int trials = 0;
  String? refreshError;
  bool storeFails = false;
  String? selected;
  String countryCode = 'GB';
  bool pricingFails = false;
  @override
  Future<Map<String, dynamic>> loadPricing() async {
    if (pricingFails) throw StateError('Pricing failed');
    return pricingData(countryCode);
  }

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
        find.text('No payment details. No automatic charge.'), findsOneWidget);
    await tester.tap(find.text('Start my 14-day trial'));
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
    expect(find.text('Start my 14-day trial'), findsNothing);
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
    expect(find.text('Start my 14-day trial'), findsOneWidget);
    expect(model.trials, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planned country prices keep trial continuation available',
      (tester) async {
    final model = service('trial')
      ..access =
          SubscriptionAccess({...accessData('trial'), 'billingReady': false});
    var continued = false;
    await tester.pumpWidget(screen(model, onContinue: () => continued = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View subscription plans'));
    await tester.pumpAndSettle();
    expect(find.text('Planned prices'), findsOneWidget);
    expect(find.byType(SubscriptionPricingView), findsOneWidget);
    expect(find.text('£84.99'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
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
    expect(find.text('Planned prices'), findsOneWidget);
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
  testWidgets(
      'trial hero shows full access without starting a trial on refresh',
      (tester) async {
    final model = service('available');
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    expect(find.byType(TrialAccessHero), findsOneWidget);
    expect(find.byKey(const ValueKey('trial-card-animation')), findsNothing);
    expect(model.trials, 0);
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(model.trials, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Not now starts no trial', (tester) async {
    final model = service('available');
    var continued = 0;
    await tester.pumpWidget(screen(model, onContinue: () => continued++));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Not now'));
    await tester.tap(find.text('Not now'));
    expect(continued, 1);
    expect(model.trials, 0);
  });
  testWidgets('active trial keeps its confirmed end date after refresh',
      (tester) async {
    final model = service('trial');
    final access = model.access;
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    expect(find.byType(TrialAccessHero), findsOneWidget);
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(model.access, same(access));
    expect(model.trials, 0);
    expect(find.text('14 days left in your trial'), findsOneWidget);
  });
  testWidgets('paid and expired accounts do not show the trial introduction',
      (tester) async {
    for (final state in ['active', 'expired']) {
      await tester.pumpWidget(screen(service(state)));
      await tester.pumpAndSettle();
      expect(find.byType(TrialAccessHero), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('See pricing opens a separate page without starting the trial',
      (tester) async {
    final model = service('available');
    await tester.pumpWidget(screen(model));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See pricing'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionPricingView), findsOneWidget);
    expect(model.trials, 0);
    expect(find.text('£84.99'), findsOneWidget);
    expect(find.text('£10.99'), findsOneWidget);
    expect(find.text('Save 36%'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('pricing-monthly')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pricing-monthly')));
    await tester.pumpAndSettle();
    expect(model.selected, isNull);
    expect(model.trials, 0);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1100));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('United Kingdom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('United Kingdom'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pricing-country-DK')));
    await tester.pumpAndSettle();
    expect(find.text('Denmark'), findsOneWidget);
    expect(find.textContaining('749'), findsWidgets);
    expect(find.text('Save 37%'), findsOneWidget);
    expect(find.text('Subscribe now'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pricing uses live store amounts and never mixes preview prices with checkout',
      (tester) async {
    final model = service('expired');
    for (final interval in ['monthly', 'annual']) {
      model.products[interval] = ProductDetails(
          id: interval,
          title: interval,
          description: '',
          price: interval == 'monthly' ? '€14.99' : '€79.99',
          rawPrice: interval == 'monthly' ? 14.99 : 79.99,
          currencyCode: 'EUR');
    }
    model.storeReady = true;
    await tester
        .pumpWidget(MaterialApp(home: SubscriptionPricingView(service: model)));
    await tester.pumpAndSettle();
    expect(find.text('Google Play pricing'), findsOneWidget);
    expect(find.text('€79.99'), findsOneWidget);
    expect(find.text('£84.99'), findsNothing);
    expect(find.text('Save 56%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pricing-monthly')));
    await tester.tap(find.text('Subscribe now'));
    expect(model.selected, 'monthly');
    model.selected = null;
    await tester.ensureVisible(find.text('Compare countries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare countries'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pricing-country-DK')));
    await tester.pumpAndSettle();
    expect(find.text('Planned prices'), findsOneWidget);
    expect(find.text('Subscribe now'), findsNothing);
    expect(model.selected, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pricing fits small screens, preserves unknown countries and supports retry',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = service('available')
      ..countryCode = 'ZZ'
      ..pricingFails = true;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                textScaler: TextScaler.linear(1.8), disableAnimations: true),
            child: SubscriptionPricingView(service: model))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Could not load pricing. Please try again.'), 250);
    expect(
        find.text('Could not load pricing. Please try again.'), findsOneWidget);
    model.pricingFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a country'), findsOneWidget);
    expect(find.text('£84.99'), findsNothing);
    await tester.ensureVisible(find.text('Choose a country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a country'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pricing-country-SE')), 250,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('pricing-country-SE')));
    await tester.pumpAndSettle();
    expect(find.text('Sweden'), findsOneWidget);
    expect(find.text('Save 33%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'country prices use European number formats and support enlarged translated text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final country in ['DE', 'DK', 'CH']) {
      final locale =
          country == 'DK' ? const Locale('da', 'DK') : Locale('de', country);
      final model = service('available')..countryCode = country;
      await tester.pumpWidget(MaterialApp(
          locale: locale,
          supportedLocales: const [
            Locale('de', 'DE'),
            Locale('de', 'CH'),
            Locale('da', 'DK')
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
              data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.6), disableAnimations: true),
              child: SubscriptionPricingView(
                  key: ValueKey(country), service: model))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('pricing-annual')), 250);
      expect(
          find.textContaining(country == 'DK'
              ? '749'
              : country == 'CH'
                  ? '99.90'
                  : '99,99'),
          findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('pricing preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: key,
            child: SubscriptionPricingView(service: service('available')))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File('build/previews/subscription-pricing.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
