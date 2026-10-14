import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/navigation/onboarding_page_route.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/ds_colors.dart';
import 'subscription_service.dart';
import 'subscription_view.dart';

/// Offers the trial once; expired users retain access to saved records/settings.
class SubscriptionGate extends StatefulWidget {
  final Widget child;
  const SubscriptionGate({super.key, required this.child});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate>
    with WidgetsBindingObserver {
  final service = SubscriptionService.shared;
  bool _loaded = false;
  bool _dismissed = false;
  bool _presenting = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiClient.subscriptionRequired.addListener(_required);
    _initialize();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _initialize() async {
    try {
      await service.initialize();
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = SubscriptionService.message(error);
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      await service.refresh();
      if (mounted) setState(() => _error = null);
    } catch (_) {
      /* Keep records readable; the backend still enforces access. */
    }
  }

  void _required() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          _presenting ||
          (!_dismissed && service.access?.hasAccess != true)) {
        return;
      }
      _presenting = true;
      try {
        await Navigator.push(
            context, AppPageRoute<void>(page: const SubscriptionView()));
      } finally {
        _presenting = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    ApiClient.subscriptionRequired.removeListener(_required);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (!_loaded) {
          return const Scaffold(
              backgroundColor: DSColors.bg,
              body: Center(
                  child: CircularProgressIndicator(color: Colors.white54)));
        }
        if (!_dismissed &&
            (_error != null || service.access?.hasAccess != true)) {
          return SubscriptionView(
              onContinue: () => setState(() => _dismissed = true));
        }
        return widget.child;
      });
}

class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: SubscriptionService.shared,
        builder: (context, _) {
          final access = SubscriptionService.shared.access;
          if (access == null || access.state == 'active' && access.hasAccess) {
            return const SizedBox.shrink();
          }
          final trial = access.state == 'trial' && access.hasAccess;
          final label = trial
              ? fitnessText(context, '{days} days left in your trial',
                  values: {'days': access.daysRemaining})
              : fitnessText(
                  context,
                  access.trialAvailable
                      ? 'Start your 14-day trial'
                      : 'Your trial has ended');
          return SafeArea(
              bottom: false,
              child: Material(
                color: DSColors.bg,
                child: InkWell(
                  onTap: () => Navigator.push(context,
                      AppPageRoute<void>(page: const SubscriptionView())),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome_outlined,
                            size: 16, color: DSColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: DSColors.textSecondary))),
                        const FitnessText('View',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 16),
                      ])),
                ),
              ));
        },
      );
}
