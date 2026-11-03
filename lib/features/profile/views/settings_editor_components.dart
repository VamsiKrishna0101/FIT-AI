import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';

InputDecoration settingsFieldDecoration(BuildContext context, String label,
    {String? hint}) {
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: FitnessTheme.line, width: .7));
  return InputDecoration(
    labelText: fitnessText(context, label),
    hintText: hint == null ? null : fitnessText(context, hint),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(fontSize: 12, color: FitnessTheme.muted),
    floatingLabelStyle:
        const TextStyle(fontSize: 12, color: FitnessTheme.muted),
    filled: true,
    fillColor: const Color(0xFF2A2A2A),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
        borderSide:
            BorderSide(color: FitnessTheme.silver.withValues(alpha: .6))),
    errorMaxLines: 3,
  );
}

class SettingsEditorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsEditorSection(
      {super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
              header: true,
              child: FitnessText(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.3))),
          const SizedBox(height: 10),
          FitnessCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  children[i],
                ],
              ])),
        ]),
      );
}

class SettingsDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> choices;
  final ValueChanged<String>? onChanged;
  final Color? fillColor;
  const SettingsDropdown(
      {super.key,
      required this.label,
      required this.value,
      this.fillColor,
      required this.choices,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: choices.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: settingsFieldDecoration(context, label)
            .copyWith(fillColor: fillColor),
        borderRadius: BorderRadius.circular(14),
        dropdownColor: const Color(0xFF2A2A2A),
        menuMaxHeight: 340,
        itemHeight: null,
        icon: const Icon(CupertinoIcons.chevron_down,
            size: 12, color: FitnessTheme.muted),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontSize: 14, color: FitnessTheme.silver),
        selectedItemBuilder: (_) => [
          for (final choice in choices.values)
            FitnessText(choice, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        items: [
          for (final choice in choices.entries)
            DropdownMenuItem(
                value: choice.key,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: FitnessText(choice.value,
                        maxLines: 2, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: onChanged == null ? null : (value) => onChanged!(value!),
      );
}

class SettingsFieldPair extends StatelessWidget {
  final Widget first, second;
  const SettingsFieldPair(
      {super.key, required this.first, required this.second});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        if (bounds.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [first, const SizedBox(height: 14), second]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ]);
      });
}

class SettingsSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  const SettingsSaveButton(
      {super.key,
      this.buttonKey,
      required this.saving,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: FilledButton(
          key: buttonKey,
          onPressed: saving ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: FitnessTheme.silver,
            foregroundColor: FitnessTheme.canvas,
            disabledBackgroundColor: FitnessTheme.silver,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: saving
              ? const CupertinoActivityIndicator(color: FitnessTheme.canvas)
              : const FitnessText('Save changes',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
        ),
      );
}

/// Additional controls expand in place, keeping settings one screen deep.
class SettingsDisclosure extends StatelessWidget {
  final String title, summary;
  final List<Widget> children;
  const SettingsDisclosure(
      {super.key,
      required this.title,
      required this.summary,
      required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FitnessCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            maintainState: true,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            iconColor: FitnessTheme.muted,
            collapsedIconColor: FitnessTheme.muted,
            title: FitnessText(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FitnessText(summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, color: FitnessTheme.muted))),
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  children[i],
                ],
              ]),
            ],
          ),
        ),
      );
}

class SettingsChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const SettingsChoiceChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => FilterChip(
        label: FitnessText(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
        showCheckmark: false,
        backgroundColor: DSColors.bgElevated,
        selectedColor: Colors.white,
        disabledColor: const Color(0xFF292929),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: selected ? FitnessTheme.canvas : FitnessTheme.muted),
        side: BorderSide(
            color: selected
                ? FitnessTheme.silver.withValues(alpha: .5)
                : FitnessTheme.line,
            width: .7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      );
}
