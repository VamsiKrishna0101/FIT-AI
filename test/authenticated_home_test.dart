import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/navigation/authenticated_home.dart';
import 'package:fitai_mobile/features/health/views/health_setup_gate.dart';
import 'package:fitai_mobile/features/today/views/today_view.dart';
import 'package:fitai_mobile/features/subscription/subscription_gate.dart';
import 'package:fitai_mobile/core/navigation/profile_setup_gate.dart';
import 'package:fitai_mobile/features/onboarding/views/starter_plan_view.dart';

void main() {
  test('Returning sessions verify a profile and skip optional health setup',
      () {
    final gate = authenticatedHome() as ProfileSetupGate;
    final starter = gate.child as StarterOnboardingGate;
    expect(starter.child, isA<SubscriptionGate>());
    expect((starter.child as SubscriptionGate).child, isA<TodayView>());
  });
  test('New account retains optional health onboarding', () {
    final gate = authenticatedHome(newlyRegistered: true) as ProfileSetupGate;
    final membership =
        (gate.child as StarterOnboardingGate).child as SubscriptionGate;
    expect(membership.child, isA<HealthSetupGate>());
  });
}
