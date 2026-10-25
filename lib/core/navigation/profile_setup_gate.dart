import 'package:flutter/material.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../branding/setcraft_launch_screen.dart';
import '../cache/cache_scope.dart';
import '../localization/fitness_text.dart';

/// Sign-in can outlive the profile after a data reset. Check the server before
/// opening personalized features, including the adult-only photo review.
class ProfileSetupGate extends StatefulWidget {
  final Widget child;
  final Future<bool> Function()? checkProfile;
  final Widget? setup;
  const ProfileSetupGate(
      {super.key, required this.child, this.checkProfile, this.setup});

  @override
  State<ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends State<ProfileSetupGate> {
  bool? _hasProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final owner = await CacheScope.userId();
    try {
      final exists =
          await (widget.checkProfile ?? AuthRepository().hasProfile)();
      if (mounted && await CacheScope.userId() == owner && mounted) {
        setState(() => _hasProfile = exists);
      }
    } catch (error) {
      if (mounted && await CacheScope.userId() == owner && mounted) {
        setState(() => _error = AuthRepository.messageFor(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
          body: SafeArea(
              child: Center(
                  child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FitnessText('Could not load your profile'),
          const SizedBox(height: 12),
          FitnessText(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const FitnessText('Try again')),
        ]),
      ))));
    }
    return switch (_hasProfile) {
      true => widget.child,
      false => widget.setup ?? const OnboardingView(),
      null => const SetcraftLaunchScreen(),
    };
  }
}
