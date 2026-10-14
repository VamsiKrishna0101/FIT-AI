import 'package:flutter/widgets.dart';
import '../../features/health/views/health_setup_gate.dart';
import '../../features/today/views/today_view.dart';
import '../../features/subscription/subscription_gate.dart';

/// Setup is an onboarding offer, never a returning-login requirement.
Widget authenticatedHome({bool newlyRegistered = false}) => newlyRegistered
    ? const HealthSetupGate(child: SubscriptionGate(child: TodayView()))
    : const SubscriptionGate(child: TodayView());
