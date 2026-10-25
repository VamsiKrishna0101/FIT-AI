import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_session_store.dart';

class SubscriptionAccess {
  final Map<String, dynamic> data;
  final Stopwatch _elapsed = Stopwatch()..start();
  SubscriptionAccess(this.data);
  String get state => data['state'] as String? ?? 'unavailable';
  bool get trialAvailable => state == 'available';
  bool get billingReady => data['billingReady'] == true;
  DateTime? get trialEnd => DateTime.tryParse('${data['trialEndsAt'] ?? ''}');
  DateTime? get paidEnd => DateTime.tryParse('${data['paidUntil'] ?? ''}');
  DateTime? get _serverTime => DateTime.tryParse('${data['serverTime'] ?? ''}');
  DateTime get now => (_serverTime ?? DateTime.now()).add(_elapsed.elapsed);
  bool get hasAccess =>
      _serverTime != null &&
      ((state == 'trial' && trialEnd?.isAfter(now) == true) ||
          (state == 'active' && paidEnd?.isAfter(now) == true));
  bool get legacyTrial => state == 'trial' && data['trialSource'] != 'store';
  int get daysRemaining => trialEnd == null
      ? 0
      : (trialEnd!.difference(now).inSeconds / 86400).ceil().clamp(0, 14);
}

/// A free first pricing phase must never replace the renewal price.
@immutable
class MembershipOffer {
  final ProductDetails product;
  final String price;
  final double amount;
  final int trialDays;
  const MembershipOffer(
      {required this.product,
      required this.price,
      required this.amount,
      this.trialDays = 0});
  bool get hasTrial => trialDays == 14;
  String get currencyCode => product.currencyCode;
}

/// Reuses a completed check for this transition, only within the same session.
/// The gate still evaluates expiry and keeps its normal refresh protection.
class SubscriptionPreparation {
  final SubscriptionService service;
  final String owner;
  final SubscriptionAccess snapshot;
  final int sessionRevision;
  const SubscriptionPreparation._(
      this.service, this.owner, this.snapshot, this.sessionRevision);
  bool get isCurrent =>
      SecureSessionStore.shared.revision == sessionRevision &&
      service._owner == owner &&
      identical(service.access, snapshot);
}

class SubscriptionService extends ChangeNotifier {
  static final shared = SubscriptionService();
  final ApiClient api;
  final InAppPurchase? _store;
  InAppPurchase get store => _store ?? InAppPurchase.instance;
  SubscriptionService({ApiClient? api, InAppPurchase? store})
      : api = api ?? ApiClient.shared,
        _store = store;
  SubscriptionAccess? access;
  final products = <String, ProductDetails>{};
  final offers = <String, MembershipOffer>{};
  String? error, notice, _owner;
  bool busy = false, storeReady = false, awaitingConfirmation = false;
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  Future<void> _purchaseQueue = Future.value();
  bool get android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String get storeName => ios ? 'App Store' : 'Google Play';
  bool get plansAvailable =>
      (android || ios) &&
      access?.billingReady == true &&
      storeReady &&
      offers.isNotEmpty;

  void _listen() {
    if ((!android && !ios) || _purchases != null) return;
    _purchases = store.purchaseStream.listen((purchases) {
      _purchaseQueue = _purchaseQueue
          .then((_) => _verify(purchases))
          .catchError((Object failure) {
        error = message(failure);
        awaitingConfirmation = false;
        notifyListeners();
      });
    }, onError: (Object failure) {
      error = message(failure);
      awaitingConfirmation = false;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _listen();
    await refresh();
    try {
      await loadProducts();
    } catch (_) {
      products.clear();
      offers.clear();
      storeReady = false;
      notifyListeners();
    }
  }

  Future<SubscriptionPreparation> prepareAccountEntry() async {
    await initialize();
    final owner = await SecureSessionStore.shared.userId;
    final snapshot = access;
    if (owner == null || _owner != owner || snapshot == null) {
      throw StateError('Your session changed. Please sign in again.');
    }
    return SubscriptionPreparation._(
        this, owner, snapshot, SecureSessionStore.shared.revision);
  }

  Future<void> refresh() async {
    final owner = await SecureSessionStore.shared.userId;
    if (_owner != owner) {
      access = null;
      products.clear();
      offers.clear();
      error = null;
      notice = null;
      awaitingConfirmation = false;
      _owner = owner;
    }
    if (owner == null) {
      notifyListeners();
      return;
    }
    final response = await api.get<Map<String, dynamic>>(
        '/api/subscription/status',
        queryParameters: {'platform': ios ? 'ios' : 'android'});
    if (owner != await SecureSessionStore.shared.userId) return;
    access =
        SubscriptionAccess(Map<String, dynamic>.from(response.data!['data']));
    notifyListeners();
  }

  // Compatibility for older callers; new trials always use native checkout.
  Future<void> startTrial() => purchase('annual');
  Future<Map<String, dynamic>> loadPricing() async {
    final response =
        await api.get<Map<String, dynamic>>('/api/subscription/pricing');
    return Map<String, dynamic>.from(response.data!['data']);
  }

  Future<void> loadProducts() async {
    _listen();
    final owner = _owner, snapshot = access;
    products.clear();
    offers.clear();
    storeReady = false;
    if ((!android && !ios) || snapshot?.billingReady != true) {
      notifyListeners();
      return;
    }
    storeReady = await store.isAvailable();
    if (!storeReady) {
      notifyListeners();
      return;
    }
    final ids = Map<String, dynamic>.from(snapshot!.data['products'] as Map);
    final plans =
        Map<String, dynamic>.from(snapshot.data['basePlans'] as Map? ?? {});
    final response =
        await store.queryProductDetails(ids.values.cast<String>().toSet());
    if (response.error != null) {
      throw StateError('Could not load $storeName prices. Please retry.');
    }
    final loaded = <String, MembershipOffer>{};
    if (android) {
      for (final interval in ['monthly', 'annual']) {
        for (final product
            in response.productDetails.whereType<GooglePlayProductDetails>()) {
          if (product.id != ids[interval]) continue;
          final offer = googleOffer(product, plans[interval] as String?,
              allowTrial: snapshot.trialAvailable,
              expectedPeriod: interval == 'annual' ? 'P1Y' : 'P1M');
          if (offer != null && (loaded[interval] == null || offer.hasTrial)) {
            loaded[interval] = offer;
          }
        }
      }
    } else {
      // StoreKit 2 provides eligibility; native product metadata provides the
      // exact introductory duration. Neither comes from a hardcoded offer.
      final metadata = await SKRequestMaker()
          .startProductRequest(ids.values.cast<String>().toList());
      for (final interval in ['monthly', 'annual']) {
        final product = response.productDetails
            .where((p) => p.id == ids[interval])
            .firstOrNull;
        if (product == null || product.rawPrice <= 0) continue;
        final native = metadata.products
            .where((p) => p.productIdentifier == product.id)
            .firstOrNull;
        final term = native?.subscriptionPeriod;
        if (term == null ||
            term.numberOfUnits != 1 ||
            term.unit !=
                (interval == 'annual'
                    ? SKSubscriptionPeriodUnit.year
                    : SKSubscriptionPeriodUnit.month)) {
          continue;
        }
        final intro = native?.introductoryPrice;
        final days = intro == null
            ? 0
            : switch (intro.subscriptionPeriod.unit) {
                SKSubscriptionPeriodUnit.day =>
                  intro.subscriptionPeriod.numberOfUnits *
                      intro.numberOfPeriods,
                SKSubscriptionPeriodUnit.week =>
                  intro.subscriptionPeriod.numberOfUnits *
                      intro.numberOfPeriods *
                      7,
                _ => 0,
              };
        final eligible = days == 14 &&
            intro?.paymentMode == SKProductDiscountPaymentMode.freeTrail &&
            double.tryParse(intro?.price ?? '') == 0 &&
            await SK2Product.isIntroductoryOfferEligible(product.id);
        loaded[interval] = MembershipOffer(
            product: product,
            price: product.price,
            amount: product.rawPrice,
            trialDays: eligible ? 14 : 0);
      }
    }
    if (owner != _owner || owner != await SecureSessionStore.shared.userId) {
      return;
    }
    offers.addAll(loaded);
    products.addAll(loaded.map((key, value) => MapEntry(key, value.product)));
    notifyListeners();
  }

  @visibleForTesting
  static MembershipOffer? googleOffer(
      GooglePlayProductDetails product, String? basePlan,
      {required bool allowTrial, String? expectedPeriod}) {
    final index = product.subscriptionIndex;
    final details = product.productDetails.subscriptionOfferDetails;
    if (index == null || details == null || index >= details.length) {
      return null;
    }
    final offer = details[index], phases = details[index].pricingPhases;
    if (offer.basePlanId != basePlan || phases.isEmpty) return null;
    final renewal = phases.last;
    if (renewal.priceAmountMicros <= 0 ||
        renewal.recurrenceMode != RecurrenceMode.infiniteRecurring ||
        renewal.priceCurrencyCode != product.currencyCode ||
        (expectedPeriod != null && renewal.billingPeriod != expectedPeriod)) {
      return null;
    }
    final trial = allowTrial &&
        phases.length == 2 &&
        phases.first.priceAmountMicros == 0 &&
        phases.first.billingCycleCount == 1 &&
        ['P2W', 'P14D'].contains(phases.first.billingPeriod);
    if (!trial && (offer.offerId != null || phases.length != 1)) return null;
    return MembershipOffer(
        product: product,
        price: renewal.formattedPrice,
        amount: renewal.priceAmountMicros / 1000000,
        trialDays: trial ? 14 : 0);
  }

  int? get annualSavings {
    final month = offers['monthly'], year = offers['annual'];
    if (month == null ||
        year == null ||
        month.amount <= 0 ||
        month.currencyCode != year.currencyCode) {
      return null;
    }
    final savings = ((1 - year.amount / (month.amount * 12)) * 100).round();
    return savings > 0 ? savings : null;
  }

  Future<void> purchase(String interval) async {
    if (busy || awaitingConfirmation) return;
    await _run(() async {
      _listen();
      await refresh();
      if (access?.hasAccess == true) return;
      if ((!android && !ios) || access?.billingReady != true) {
        throw StateError(
            'Subscriptions are currently unavailable. Please try again later.');
      }
      // Never silently change a displayed free offer to an immediate payment.
      final displayed = offers[interval];
      await loadProducts();
      final selected = offers[interval];
      if (selected == null) {
        throw StateError('This plan is unavailable. Please retry.');
      }
      if (displayed == null ||
          displayed.price != selected.price ||
          displayed.trialDays != selected.trialDays ||
          displayed.currencyCode != selected.currencyCode) {
        throw StateError(
            'Your store offer has changed. Review the updated price and try again.');
      }
      awaitingConfirmation = true;
      final opened = await store.buyNonConsumable(
          purchaseParam: PurchaseParam(
              productDetails: selected.product,
              applicationUserName: (ios
                  ? access!.data['appleAccountId']
                  : access!.data['accountId']) as String));
      if (!opened) {
        awaitingConfirmation = false;
        throw StateError('Could not open $storeName checkout.');
      }
    });
    if (error != null) awaitingConfirmation = false;
  }

  Future<void> restore() => _run(() async {
        _listen();
        if ((!android && !ios) || !await store.isAvailable()) {
          throw StateError('Restore purchases is available in the mobile app.');
        }
        await store.restorePurchases();
        await refresh();
        notice =
            'Restoring purchases. Your membership will update after verification.';
      });
  Future<void> _verify(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        awaitingConfirmation = true;
        notice =
            'Waiting for $storeName confirmation. You can safely return later.';
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        awaitingConfirmation = false;
        notice = null;
        error = purchase.status == PurchaseStatus.canceled
            ? null
            : '$storeName could not complete this purchase. Please try again.';
        notifyListeners();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      final owner = await SecureSessionStore.shared.userId;
      if (owner == null) continue;
      if (access == null) await refresh();
      final ids = access?.data['products'];
      if (ids is! Map || !ids.values.contains(purchase.productID)) continue;
      try {
        final response = await api.post<Map<String, dynamic>>(
            '/api/subscription/${ios ? 'ios' : 'android'}/verify',
            data: ios
                ? {
                    'transactionId': purchase.purchaseID,
                    'signedTransaction':
                        purchase.verificationData.serverVerificationData
                  }
                : {
                    'purchaseToken':
                        purchase.verificationData.serverVerificationData
                  });
        if (owner != await SecureSessionStore.shared.userId) continue;
        access = SubscriptionAccess(
            Map<String, dynamic>.from(response.data!['data']));
        error = null;
        notice = null;
        awaitingConfirmation = false;
        if ((response.data!['purchaseActive'] == true || ios) &&
            purchase.pendingCompletePurchase) {
          await store.completePurchase(purchase);
        }
      } catch (failure) {
        error = message(failure);
        awaitingConfirmation = false;
      }
      notifyListeners();
    }
  }

  Future<void> manage() => _run(() async {
        final uri = ios
            ? Uri.parse('https://apps.apple.com/account/subscriptions')
            : Uri.https('play.google.com', '/store/account/subscriptions');
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw StateError('Open $storeName and manage your subscriptions.');
        }
      });
  Future<void> openLegal(String key) => _run(() async {
        final value = access?.data[key];
        final uri = value is String ? Uri.tryParse(value) : null;
        if (uri == null ||
            uri.scheme != 'https' ||
            !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw StateError(
              'This document is unavailable. Please try again later.');
        }
      });
  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      await action();
    } catch (failure) {
      error = message(failure);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static String message(Object failure) {
    if (failure is DioException && failure.response?.data is Map) {
      final text = failure.response!.data['error'];
      if (text is String) return text;
    }
    if (failure is StateError) return failure.message.toString();
    return 'Could not refresh your membership. Please retry.';
  }

  @override
  void dispose() {
    _purchases?.cancel();
    super.dispose();
  }
}
