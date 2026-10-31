import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../localization/fitness_text.dart';
import '../theme/ds_colors.dart';

enum SessionOverviewStatus {
  notStarted('Not started', Color(0xFFDCEAFF), Color(0xFF24476B),
      CupertinoIcons.circle),
  inProgress('In progress', Color(0xFFF6E4BC), Color(0xFF6E4A13),
      CupertinoIcons.play_fill),
  completed('Completed', Color(0xFFCDEBDD), Color(0xFF245B44),
      CupertinoIcons.check_mark),
  restDay('Rest day', Color(0xFFE2DCF1), Color(0xFF5C497C),
      CupertinoIcons.moon_fill),
  unavailable(
      'Training', Color(0xFF2B2B2B), DSColors.silver, CupertinoIcons.calendar);

  const SessionOverviewStatus(
      this.label, this.background, this.foreground, this.icon);

  final String label;
  final Color background, foreground;
  final IconData icon;
}

/// One visual hierarchy for the session shown in Today and in Train.
class SessionOverviewCard extends StatelessWidget {
  const SessionOverviewCard({
    super.key,
    required this.status,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.onTap,
    this.metrics = const [],
    this.caption,
    this.trailing,
    this.options,
    this.primary = true,
    this.busy = false,
    this.titleFirst = false,
  });

  final SessionOverviewStatus status;
  final String title, actionLabel;
  final List<String> metrics;
  final Widget? caption, options;
  final String? trailing;
  final VoidCallback? onAction, onTap;
  final bool primary, busy, titleFirst;

  Widget _title() => Text(title,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 23,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: -.65));

  Widget _status() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: status.background, borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.icon, size: 11, color: status.foreground),
        const SizedBox(width: 4),
        Flexible(
            child: FitnessText(status.label,
                style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: status.foreground,
                    fontWeight: FontWeight.w600))),
      ]));

  Widget _compactHeader(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        if (MediaQuery.textScalerOf(context).scale(23) > 32 ||
            bounds.maxWidth < 240) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _title(),
                const SizedBox(height: 8),
                Align(
                    alignment: AlignmentDirectional.centerEnd, child: _status())
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _title()),
          const SizedBox(width: 12),
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: bounds.maxWidth * .42),
              child: _status()),
        ]);
      });

  @override
  Widget build(BuildContext context) => Material(
        color: DSColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DSColors.border, width: .7)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (titleFirst)
                    _compactHeader(context)
                  else ...[
                    Row(children: [
                      Expanded(
                          child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _status(),
                      )),
                      const SizedBox(width: 8),
                      if (trailing != null)
                        Flexible(
                          fit: FlexFit.tight,
                          child: Text(trailing!,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 11, color: DSColors.muted)),
                        ),
                      if (options != null) options!,
                    ]),
                    const SizedBox(height: 15),
                    _title(),
                  ],
                  if (metrics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(builder: (context, bounds) {
                      Widget metric(String value) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: const Color(0xFF292929),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(value,
                                style: const TextStyle(
                                    color: DSColors.silver,
                                    fontSize: 12,
                                    height: 1.35)),
                          );
                      return MediaQuery.textScalerOf(context).scale(12) > 18
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  for (var i = 0; i < metrics.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 8),
                                    metric(metrics[i]),
                                  ],
                                ])
                          : IntrinsicHeight(
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                  for (var i = 0; i < metrics.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(child: metric(metrics[i])),
                                  ],
                                ]));
                    }),
                  ],
                  if (caption != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: caption!),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : onAction,
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            primary ? DSColors.silver : const Color(0xFF303030),
                        foregroundColor:
                            primary ? DSColors.bg : DSColors.silver,
                        disabledBackgroundColor:
                            busy ? DSColors.silver : DSColors.bgRaised,
                        disabledForegroundColor:
                            busy ? DSColors.bg : DSColors.muted,
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: busy
                        ? const CupertinoActivityIndicator(color: DSColors.bg)
                        : Text(actionLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )),
      );
}
