import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final bool? centerTitle;

  const SettingsPage(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children,
      this.bottom,
      this.centerTitle});

  @override
  Widget build(BuildContext context) => FitnessTheme(
        child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
            centerTitle: centerTitle,
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
              child: MotionEntrance(
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
              ))),
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
  final double dividerIndent;
  const SettingsGroup(
      {super.key, this.title, required this.children, this.dividerIndent = 60});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 9),
                child: FitnessText(title!.toUpperCase(),
                    style: const TextStyle(
                        color: DSColors.textTertiary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700))),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: DSColors.bgElevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DSColors.border, width: .8),
            ),
            child: Column(children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Divider(
                      height: 1,
                      indent: dividerIndent,
                      endIndent: 16,
                      color: const Color(0x14FFFFFF)),
              ],
            ]),
          ),
          const SizedBox(height: 22),
        ],
      );
}

class SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailingWidget;
  final Color? iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsRow(
      {super.key,
      this.icon,
      required this.title,
      this.subtitle,
      this.value,
      this.trailingWidget,
      this.iconColor,
      this.iconBgColor,
      this.onTap,
      this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? (destructive ? FitnessTheme.coral : FitnessTheme.silver);
    final effectiveBgColor = iconBgColor != null
        ? iconBgColor!.withValues(alpha: .15)
        : Colors.white.withValues(alpha: .045);

    return Material(
      color: Colors.transparent,
      child: MotionPress(
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: effectiveBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: effectiveIconColor),
                ),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitnessText(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: destructive
                            ? FitnessTheme.coral
                            : DSColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      FitnessText(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FitnessTheme.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget!,
              ] else if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FitnessText(
                      value!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FitnessTheme.silver,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 10),
                const Icon(CupertinoIcons.chevron_right,
                    size: 13, color: DSColors.textTertiary),
              ],
            ]),
          ),
        ),
      ),
    );
  }
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
      animationStyle: DSMotion.dialogStyle(context),
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
