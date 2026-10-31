import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/components/fitness_form.dart';

InputDecoration nutritionEntryDecoration({String? unit}) => InputDecoration(
    suffixIcon: unit == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(unit,
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)))),
    suffixIconConstraints: const BoxConstraints(minWidth: 32),
    filled: true,
    fillColor: const Color(0xFF0D0D0D),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FitnessTheme.line, width: .7)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FitnessTheme.line, width: .7)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FitnessTheme.silver, width: .7)));

class NutritionEntryField extends StatelessWidget {
  const NutritionEntryField(
      {super.key,
      required this.label,
      required this.controller,
      this.numeric = false,
      this.enabled = true,
      this.unit,
      this.onChanged});
  final String label;
  final TextEditingController controller;
  final bool numeric, enabled;
  final String? unit;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => NutritionEntryLabel(
      label: label,
      child: Semantics(
          label: fitnessText(context, label),
          child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 15, color: FitnessTheme.silver),
              decoration: nutritionEntryDecoration(unit: unit))));
}

class NutritionEntryLabel extends StatelessWidget {
  const NutritionEntryLabel(
      {super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FitnessText(label,
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 8),
        child,
      ]);
}

class NutritionEntryGrid extends StatelessWidget {
  const NutritionEntryGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final twoColumns = box.maxWidth >= 300 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final width = twoColumns ? (box.maxWidth - 12) / 2 : box.maxWidth;
        return Wrap(spacing: 12, runSpacing: 16, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}

class NutritionEntryFooter extends StatelessWidget {
  const NutritionEntryFooter(
      {super.key,
      required this.label,
      required this.busy,
      required this.onPressed,
      this.error});
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final String? error;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                      liveRegion: true,
                      child: FitnessText(error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: FitnessTheme.coral)))),
            FitnessSubmit(label: label, busy: busy, onPressed: onPressed),
          ])));
}
