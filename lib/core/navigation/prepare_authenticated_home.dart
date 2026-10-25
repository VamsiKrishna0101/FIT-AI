import 'package:flutter/widgets.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/health/views/health_setup_gate.dart';
import '../../features/onboarding/data/discovery_repository.dart';
import '../../features/onboarding/data/starter_plan_repository.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/onboarding/views/starter_plan_view.dart';
import '../../features/subscription/subscription_gate.dart';
import '../../features/subscription/subscription_service.dart';
import '../../features/today/views/today_view.dart';
import '../health/health_sync_service.dart';
import '../storage/secure_session_store.dart';

/// Complete account routing while the existing sign-in button is loading.
/// Cold launch still uses authenticatedHome and its continuous launch screen.
Future<Widget> prepareAuthenticatedHome({
  bool newlyRegistered = false,
  AuthRepository? auth,
  StarterPlanRepository? starter,
  SubscriptionService? membership,
  DiscoveryRepository discovery = const DiscoveryRepository(),
  HealthSyncService? health,
  Widget home = const TodayView(),
}) async {
  final owner = await SecureSessionStore.shared.userId;
  Future<void> ensureOwner() async {
    final token = await SecureSessionStore.shared.accessToken;
    if (owner == null ||
        token == null ||
        token.isEmpty ||
        await SecureSessionStore.shared.userId != owner) {
      throw const AuthFlowException(
          'Your session changed. Please sign in again.');
    }
  }

  await ensureOwner();
  final hasProfile = await (auth ?? AuthRepository()).hasProfile();
  await ensureOwner();
  if (!hasProfile) return const OnboardingView();

  final plans = starter ?? StarterPlanRepository();
  final service = membership ?? SubscriptionService.shared;
  Map<String, dynamic>? starterData;
  late SubscriptionPreparation subscription;
  Future<void> loadStarter() async {
    try {
      starterData = await plans.current();
    } catch (_) {
      /* Membership still controls access when preview status is offline. */
    }
  }

  // Independent requests share one visible loading state, not successive pages.
  await Future.wait([
    loadStarter(),
    service.prepareAccountEntry().then((value) => subscription = value),
  ]);
  await ensureOwner();

  DiscoveryPreparation? survey;
  if (StarterEntryPreparation.shouldOffer(starterData)) {
    survey = await discovery.prepareAccountEntry();
    if (survey.owner != owner) {
      throw const AuthFlowException(
          'Your session changed. Please sign in again.');
    }
  }
  bool offerHealth = false;
  if (newlyRegistered) {
    try {
      offerHealth = await (health ?? HealthSyncService.shared).needsSetup();
    } catch (_) {/* Optional health setup does not block account entry. */}
  }
  await ensureOwner();
  if (!subscription.isCurrent || subscription.owner != owner) {
    throw const AuthFlowException('Your session changed. Please try again.');
  }
  return StarterOnboardingGate(
    repository: plans,
    discoveryRepository: discovery,
    preparation: StarterEntryPreparation(starterData, discovery: survey),
    child: SubscriptionGate(
        service: service,
        preparation: subscription,
        child: newlyRegistered
            ? HealthSetupGate(
                service: health, initialOffer: offerHealth, child: home)
            : home),
  );
}
