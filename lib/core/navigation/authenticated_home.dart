import 'package:flutter/widgets.dart';
import '../../features/health/views/health_setup_gate.dart';
import '../../features/today/views/today_view.dart';
import '../../features/subscription/subscription_gate.dart';
import '../../features/onboarding/views/starter_plan_view.dart';
import 'profile_setup_gate.dart';

/// Returning members skip optional health setup, but still need a saved profile.
Widget authenticatedHome({bool newlyRegistered = false}) => ProfileSetupGate(
    child: StarterOnboardingGate(
        child: newlyRegistered
            ? const SubscriptionGate(child: HealthSetupGate(child: TodayView()))
            : const SubscriptionGate(child: TodayView())));
