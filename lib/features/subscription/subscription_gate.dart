import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/branding/setcraft_launch_screen.dart';
import '../../core/network/api_client.dart';
import '../../core/navigation/onboarding_page_route.dart';
import 'subscription_service.dart';
import 'subscription_view.dart';

/// Dashboard access requires a current, server-confirmed entitlement.
class SubscriptionGate extends StatefulWidget {
  final Widget child;
  final SubscriptionService? service;
  final SubscriptionPreparation? preparation;
  const SubscriptionGate(
      {super.key, required this.child, this.service, this.preparation});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate>
    with WidgetsBindingObserver {
  late final service = widget.service ?? SubscriptionService.shared;
  bool _loaded = false;
  bool _refreshing = false;
  bool _presenting = false;
  bool _hadAccess = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiClient.subscriptionRequired.addListener(_required);
    final preparation = widget.preparation;
    if (preparation != null &&
        identical(preparation.service, service) &&
        preparation.isCurrent) {
      _loaded = true;
      _hadAccess = service.access?.hasAccess == true;
    } else {
      _initialize();
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _initialize() async {
    try {
      await service.initialize();
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = null;
          _hadAccess = service.access?.hasAccess == true;
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
    if (_refreshing) return;
    _refreshing = true;
    try {
      await service.refresh();
      if (mounted) setState(() => _error = null);
    } catch (failure) {
      if (mounted) {
        setState(() => _error = SubscriptionService.message(failure));
      }
    } finally {
      _refreshing = false;
      if (mounted) _protectOpenRoute();
    }
  }

  Future<void> _protectOpenRoute({bool requiredByApi = false}) async {
    if (!mounted || _presenting) return;
    if (service.access?.hasAccess == true) {
      _hadAccess = true;
      return;
    }
    // The root rebuild already protects Today. Cover any detail route that
    // was opened before access expired, without discarding saved work.
    if ((!_hadAccess && !requiredByApi) ||
        ModalRoute.of(context)?.isCurrent != false) {
      return;
    }
    _presenting = true;
    try {
      await Navigator.of(context).push(AppPageRoute<void>(
          page: SubscriptionView(
              service: service,
              blocking: true,
              onContinue: () {
                if (mounted && service.access?.hasAccess == true) {
                  setState(() => _error = null);
                  Navigator.of(context).pop();
                }
              })));
    } finally {
      _presenting = false;
    }
  }

  void _required() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _refresh();
        if (mounted) _protectOpenRoute(requiredByApi: true);
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
          return const SetcraftLaunchScreen();
        }
        if (_error != null || service.access?.hasAccess != true) {
          return SubscriptionView(
              service: service,
              preparation: widget.preparation,
              blocking: true,
              onContinue: () {
                if (service.access?.hasAccess == true) {
                  setState(() => _error = null);
                }
              });
        }
        return widget.child;
      });
}
