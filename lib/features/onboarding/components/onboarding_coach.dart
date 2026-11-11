import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mochi, the onboarding coach: shared reactions across every step.
///
/// Widget tests keep Mochi still so settled pumps never wait on its idle loop.
abstract final class OnboardingCoach {
  /// Increments whenever the user makes a choice; Mochi hops and reacts.
  static final reactions = ValueNotifier<int>(0);

  /// The name the user typed during onboarding, for Mochi's greeting.
  static final name = ValueNotifier<String>('');
  static bool _typedName = false, _greeted = false;

  static final bool liveMotion =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  /// Short replies Mochi rotates through when a choice is made.
  static const replies = [
    'Got it ✓',
    'Nice pick 👌',
    'Love that 💪',
    'Noted ✨',
  ];

  /// A choice was made: haptic tick, a happy hop and a quick reply.
  static void select() {
    HapticFeedback.selectionClick();
    reactions.value++;
  }

  static void typedName(String value) {
    _typedName = true;
    name.value = value.trim();
  }

  /// The name to greet once, right after the user typed it; null otherwise.
  static String? takeGreeting() {
    final value = name.value.split(RegExp(r'\s+')).first;
    if (!_typedName || _greeted || value.length < 2) return null;
    _greeted = true;
    return value;
  }
}
