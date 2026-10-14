import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/navigation/authenticated_home.dart';
import 'package:fitai_mobile/features/health/views/health_setup_gate.dart';
import 'package:fitai_mobile/features/today/views/today_view.dart';
import 'package:fitai_mobile/features/subscription/subscription_gate.dart';

void main() {
  test('Returning login and restored sessions open Home without a setup gate',
      () {
    expect(authenticatedHome(), isA<SubscriptionGate>());
    expect((authenticatedHome() as SubscriptionGate).child, isA<TodayView>());
    expect(authenticatedHome(), isNot(isA<HealthSetupGate>()));
  });
  test('New account retains optional health onboarding', () {
    expect(authenticatedHome(newlyRegistered: true), isA<HealthSetupGate>());
  });
}
