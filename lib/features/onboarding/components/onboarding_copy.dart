import 'package:flutter/widgets.dart';
import '../../../core/localization/fitness_copy.dart';

/// Keep onboarding labels light without changing translated copy elsewhere.
String onboardingText(BuildContext context, String text) =>
    fitnessText(context, text).replaceAll(RegExp(r'\.(?=\s|$)'), '');
