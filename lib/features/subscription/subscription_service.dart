import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_session_store.dart';

class SubscriptionAccess {
  final Map<String, dynamic> data;
  final Stopwatch _elapsed = Stopwatch()..start();

  SubscriptionAccess(this.data);

  String get state => data['state'] as String;
  bool get trialAvailable => state == 'available';
  bool get billingReady => data['billingReady'] == true;
  DateTime? get trialEnd => DateTime.tryParse(data['trialEndsAt'] ?? '');
  DateTime? get paidEnd => DateTime.tryParse(data['paidUntil'] ?? '');
  DateTime get now => DateTime.parse(data['serverTime']).add(_elapsed.elapsed);
  bool get hasAccess =>
      (state == 'trial' && trialEnd!.isAfter(now)) ||
      (state == 'active' && paidEnd!.isAfter(now));
  int get daysRemaining => trialEnd == null
      ? 0
      : (trialEnd!.difference(now).inSeconds / 86400).ceil().clamp(0, 14);
}

/// Access always comes from the server. Store prices come from Google Play.
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
  String? error;
  String? _owner;
  bool busy = false;
  bool storeReady = false;
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  Future<void> _purchaseQueue = Future.value();

  bool get android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (android && _purchases == null) {
      _purchases = store.purchaseStream.listen((purchases) {
        _purchaseQueue = _purchaseQueue
            .then((_) => _verify(purchases))
            .catchError((Object failure) {
          error = message(failure);
          busy = false;
          notifyListeners();
        });
      }, onError: (Object failure) {
        error = message(failure);
        busy = false;
        notifyListeners();
      });
    }
    await refresh();
    if (android) {
      try {
        await loadProducts();
      } catch (_) {
        // A store outage does not invalidate server-confirmed trial access.
        products.clear();
        storeReady = false;
        notifyListeners();
      }
      if (storeReady && access?.billingReady == true) await restore();
    }
  }

  Future<void> refresh() async {
    final owner = await SecureSessionStore.shared.userId;
    if (_owner != owner) {
      access = null;
      products.clear();
      error = null;
      _owner = owner;
    }
    if (owner == null) return;

    final response =
        await api.get<Map<String, dynamic>>('/api/subscription/status');
    if (owner != await SecureSessionStore.shared.userId) return;
    access =
        SubscriptionAccess(Map<String, dynamic>.from(response.data!['data']));
    notifyListeners();
  }

  Future<Map<String, dynamic>> loadPricing() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) throw StateError('Sign in to see pricing.');
    final response =
        await api.get<Map<String, dynamic>>('/api/subscription/pricing');
    if (owner != await SecureSessionStore.shared.userId) {
      throw StateError('Your session changed. Please try again.');
    }
    return Map<String, dynamic>.from(response.data!['data']);
  }

  Future<void> startTrial() => _run(() async {
        final owner = await SecureSessionStore.shared.userId;
        final response = await api
            .post<Map<String, dynamic>>('/api/subscription/start-trial');
        if (owner != await SecureSessionStore.shared.userId) return;
        access = SubscriptionAccess(
            Map<String, dynamic>.from(response.data!['data']));
      });

  bool get plansAvailable =>
      android &&
      access?.billingReady == true &&
      storeReady &&
      products.isNotEmpty;

  Future<void> loadProducts() async {
    if (!android || access == null || !access!.billingReady) {
      products.clear();
      storeReady = false;
      return;
    }
    products.clear();
    storeReady = false;
    storeReady = await store.isAvailable();
    if (!storeReady) {
      notifyListeners();
      return;
    }

    final ids = Map<String, dynamic>.from(access!.data['products']);
    final plans = Map<String, dynamic>.from(access!.data['basePlans']);
    final response =
        await store.queryProductDetails(ids.values.cast<String>().toSet());
    if (response.error != null) {
      throw StateError('Could not load Google Play prices. Please retry.');
    }

    for (final interval in ['monthly', 'annual']) {
      for (final product
          in response.productDetails.whereType<GooglePlayProductDetails>()) {
        final index = product.subscriptionIndex;
        final offers = product.productDetails.subscriptionOfferDetails;
        if (product.id != ids[interval] || index == null || offers == null) {
          continue;
        }
        final offer = offers[index];
        // App-managed trial is separate: use the regular base plan, without a second store trial.
        if (offer.basePlanId == plans[interval] && offer.offerId == null) {
          products[interval] = product;
          break;
        }
      }
    }
    notifyListeners();
  }

  int? get annualSavings {
    final month = products['monthly'];
    final year = products['annual'];
    if (month == null ||
        year == null ||
        month.rawPrice <= 0 ||
        month.currencyCode != year.currencyCode) {
      return null;
    }
    final savings = ((1 - year.rawPrice / (month.rawPrice * 12)) * 100).round();
    return savings > 0 ? savings : null;
  }

  Future<void> purchase(String interval) async {
    if (busy) return;
    await _run(() async {
      await refresh();
      if (access!.state == 'active') {
        throw StateError('You already have an active subscription.');
      }
      if (!android || !access!.billingReady) {
        throw StateError('Google Play billing is not ready yet.');
      }
      await loadProducts(); // Do not launch billing with stale store details.
      final product = products[interval];
      if (product == null) {
        throw StateError('This plan is not available in Google Play yet.');
      }
      final opened = await store.buyNonConsumable(
          purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: access!.data['accountId'] as String,
      ));
      if (!opened) throw StateError('Could not open Google Play checkout.');
    });
  }

  Future<void> restore() => _run(() async {
        if (!android || !await store.isAvailable()) {
          throw StateError('Google Play is unavailable on this device.');
        }
        await store.restorePurchases();
      });

  Future<void> _verify(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        error =
            'Payment is pending. Access unlocks after Google Play confirms it.';
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        error = purchase.status == PurchaseStatus.canceled
            ? null
            : 'Google Play could not complete this purchase.';
        notifyListeners();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      final owner = await SecureSessionStore.shared.userId;
      if (owner == null) continue;
      final ids = access?.data['products'];
      if (ids is! Map || !ids.values.contains(purchase.productID)) continue;

      final response = await api.post<Map<String, dynamic>>(
          '/api/subscription/android/verify',
          data: {
            'purchaseToken': purchase.verificationData.serverVerificationData,
          });
      if (owner != await SecureSessionStore.shared.userId) continue;
      access =
          SubscriptionAccess(Map<String, dynamic>.from(response.data!['data']));
      error = null;
      if (response.data!['purchaseActive'] == true &&
          purchase.pendingCompletePurchase) {
        await store.completePurchase(purchase);
      }
      notifyListeners();
    }
  }

  Future<void> manage() => _run(() async {
        final uri =
            Uri.https('play.google.com', '/store/account/subscriptions');
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw StateError(
              'Open Google Play → Payments & subscriptions → Subscriptions.');
        }
      });

  Future<void> openLegal(String key) => _run(() async {
        final value = access?.data[key];
        if (value is! String ||
            !await launchUrl(Uri.parse(value),
                mode: LaunchMode.externalApplication)) {
          throw StateError('This document is not available yet.');
        }
      });

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
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
    return 'Could not refresh your subscription. Please retry.';
  }

  @override
  void dispose() {
    _purchases?.cancel();
    super.dispose();
  }
}
