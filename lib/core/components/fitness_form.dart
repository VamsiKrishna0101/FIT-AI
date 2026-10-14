import 'motion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../localization/fitness_text.dart';
import '../theme/fitness_theme.dart';

class FitnessInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final String? unit;
  const FitnessInput(
      {super.key,
      required this.label,
      required this.controller,
      this.numeric = false,
      this.unit});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        decoration: InputDecoration(
            label: FitnessText(label),
            suffixText: unit,
            labelStyle:
                const TextStyle(color: FitnessTheme.muted, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: FitnessTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none)),
      );
}

class FitnessSubmit extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const FitnessSubmit(
      {super.key, required this.label, this.busy = false, this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 50,
      child: MotionPress(
          enabled: !busy && onPressed != null,
          child: FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                  backgroundColor: FitnessTheme.silver,
                  foregroundColor: FitnessTheme.canvas,
                  disabledBackgroundColor: const Color(0xFF363636),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: busy
                  ? const CupertinoActivityIndicator(color: Colors.white70)
                  : FitnessText(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)))));
}

double? inputNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}
