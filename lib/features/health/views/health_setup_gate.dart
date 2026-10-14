import '../../../core/theme/ds_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/health/health_sync_service.dart';
import 'health_connection_view.dart';

/// Offers setup once per account, after authentication. No automatic permission prompts.
class HealthSetupGate extends StatefulWidget {
  final Widget child;
  final HealthSyncService? service;
  const HealthSetupGate({super.key, required this.child, this.service});
  @override
  State<HealthSetupGate> createState() => _HealthSetupGateState();
}

class _HealthSetupGateState extends State<HealthSetupGate> {
  bool? _offer;
  @override
  void initState() {
    super.initState();
    _check();
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
      ? const Scaffold(
          backgroundColor: DSColors.bg,
          body: Center(child: CircularProgressIndicator(color: Colors.white54)))
      : _offer!
          ? HealthConnectionView(
              service: widget.service,
              onComplete: () => setState(() => _offer = false))
          : widget.child;
}
