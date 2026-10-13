import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;

  const SettingsPage(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children,
      this.bottom});

  @override
  Widget build(BuildContext context) => FitnessTheme(
        child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            title: FitnessText(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(CupertinoIcons.chevron_left, size: 22),
            ),
          ),
          body: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (subtitle.isNotEmpty) ...[
                    FitnessText(subtitle,
                        style: const TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 14,
                            height: 1.5)),
                    const SizedBox(height: 20),
                  ],
                  ...children,
                ],
              )),
          bottomNavigationBar: bottom == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: bottom!),
        ),
      );
}

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const SettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 9),
                child: FitnessText(title!,
                    style: const TextStyle(
                        color: FitnessTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF191A1C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .055), width: .7),
            ),
            child: Column(children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: FitnessTheme.line),
              ],
            ]),
          ),
          const SizedBox(height: 22),
        ],
      );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsRow(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.value,
      this.onTap,
      this.destructive = false});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon,
                      size: 18,
                      color: destructive
                          ? FitnessTheme.coral
                          : FitnessTheme.silver)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: destructive
                                ? FitnessTheme.coral
                                : FitnessTheme.silver)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      FitnessText(subtitle!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: FitnessTheme.muted,
                              height: 1.4)),
                    ],
                  ])),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                    child: FitnessText(value!,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 12, color: FitnessTheme.muted))),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 10),
                const Icon(CupertinoIcons.chevron_right,
                    size: 13, color: FitnessTheme.muted),
              ],
            ]),
          ),
        ),
      );
}

class SettingsNotice extends StatelessWidget {
  final String text;
  final bool error;
  const SettingsNotice(this.text, {super.key, this.error = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FitnessText(text,
            style: TextStyle(
                color: error ? FitnessTheme.coral : FitnessTheme.muted,
                fontSize: 13,
                height: 1.5)),
      );
}

Future<bool> confirmSettingsAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitnessTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: FitnessText(title),
        content: FitnessText(message,
            style: const TextStyle(color: FitnessTheme.muted, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const FitnessText('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: FitnessText(action,
                  style: TextStyle(
                      color: destructive
                          ? FitnessTheme.coral
                          : FitnessTheme.silver))),
        ],
      ),
    ) ??
    false;
