import 'package:flutter/material.dart';
import '../../../core/branding/setcraft_launch_screen.dart';
import '../../../core/health/health_sync_service.dart';
import 'health_connection_view.dart';

/// Offers setup once per account, after authentication. No automatic permission prompts.
class HealthSetupGate extends StatefulWidget {
  final Widget child;
  final HealthSyncService? service;
  final bool? initialOffer;
  const HealthSetupGate(
      {super.key, required this.child, this.service, this.initialOffer});
  @override
  State<HealthSetupGate> createState() => _HealthSetupGateState();
}

class _HealthSetupGateState extends State<HealthSetupGate> {
  bool? _offer;
  @override
  void initState() {
    super.initState();
    _offer = widget.initialOffer;
    if (_offer == null) _check();
  }

  Future<void> _check() async {
    bool offer = false;
    try {
      offer = await (widget.service ?? HealthSyncService.shared).needsSetup();
    } catch (_) {}
    if (mounted) setState(() => _offer = offer);
  }

  @override
  Widget build(BuildContext context) => _offer == null
      ? const SetcraftLaunchScreen()
      : _offer!
          ? HealthConnectionView(
              service: widget.service,
              onComplete: () => setState(() => _offer = false))
          : widget.child;
}
