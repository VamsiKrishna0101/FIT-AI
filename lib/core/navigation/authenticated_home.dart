import 'package:flutter/widgets.dart';
import '../../features/health/views/health_setup_gate.dart';
import '../../features/today/views/today_view.dart';

/// Setup is an onboarding offer, never a returning-login requirement.
Widget authenticatedHome({bool newlyRegistered = false}) => newlyRegistered
    ? const HealthSetupGate(child: TodayView())
    : const TodayView();
