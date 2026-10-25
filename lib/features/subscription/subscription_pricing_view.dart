import 'package:flutter/material.dart';
import 'subscription_service.dart';
import 'subscription_view.dart';

/// Pricing and checkout now share one page; there is no draft-price detour.
class SubscriptionPricingView extends StatelessWidget {
  final SubscriptionService service;
  final VoidCallback? onContinue;
  const SubscriptionPricingView(
      {super.key, required this.service, this.onContinue});
  @override
  Widget build(BuildContext context) =>
      SubscriptionView(service: service, onContinue: onContinue);
}
