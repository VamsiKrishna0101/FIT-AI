import 'package:flutter/material.dart';
import '../../../core/theme/ds_motion.dart';

/// Locks a single-choice answer through selection feedback and navigation.
mixin OnboardingAnswerFlow<T extends StatefulWidget> on State<T> {
  bool choosingAnswer = false;
  Future<void> chooseAnswer(
      VoidCallback select, Future<void> Function() advance) async {
    if (choosingAnswer) return;
    setState(() => choosingAnswer = true);
    try {
      select();
      await Future<void>.delayed(
          DSMotion.duration(context, DSMotion.selection));
      if (mounted) await advance();
    } finally {
      if (mounted) setState(() => choosingAnswer = false);
    }
  }
}
