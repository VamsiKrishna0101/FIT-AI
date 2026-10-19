import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';

const progressMuted = DSColors.muted;
const progressSilver = DSColors.silver;
const progressBlue = Color(0xFF6AA9FF);
const progressCyan = Color(0xFF72D9ED);
const progressViolet = Color(0xFFB29AF7);
const progressAmber = Color(0xFFEBC487);

class ProgressSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  const ProgressSurface(
      {super.key,
      required this.child,
      this.accent,
      this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: Material(
          color: DSColors.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                  color: accent == null
                      ? DSColors.border
                      : Color.lerp(DSColors.border, accent, .16)!,
                  width: .7)),
          clipBehavior: Clip.antiAlias,
          child: Ink(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    accent == null
                        ? DSColors.bgCard
                        : Color.lerp(DSColors.bgCard, accent, .045)!,
                    DSColors.bgCard,
                  ])),
              child: Padding(padding: padding, child: child))));
}

class ProgressHeading extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String action;
  const ProgressHeading(this.title,
      {super.key, this.onTap, this.action = 'View all'});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 7),
      child: Row(children: [
        Expanded(
            child: Text(fitnessText(context, title),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5))),
        if (onTap != null)
          TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                  foregroundColor: progressMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(fitnessText(context, action),
                    style: const TextStyle(fontSize: 13)),
                const Icon(CupertinoIcons.chevron_right, size: 12)
              ])),
      ]));
}

/// A compact destination for metrics that do not have readings yet.
class ProgressSetupRow extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const ProgressSetupRow(
      {super.key,
      required this.title,
      required this.message,
      required this.icon,
      required this.onTap,
      this.color = progressCyan});

  @override
  Widget build(BuildContext context) => ProgressSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(fitnessText(context, title),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Text(fitnessText(context, message),
                          style: const TextStyle(
                              fontSize: 12, color: progressMuted, height: 1.4)),
                    ])),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.chevron_right,
                    color: progressMuted, size: 14),
              ]))));
}

class ProgressChoices extends StatelessWidget {
  final Map<String, String> choices;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color color;
  const ProgressChoices({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.color = progressSilver,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: choices.entries
              .map((entry) => Semantics(
                  selected: selected == entry.key,
                  button: true,
                  child: MotionPress(
                      child: InkWell(
                          onTap: () => onChanged(entry.key),
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 22, top: 12, bottom: 6),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(fitnessText(context, entry.value),
                                            style: TextStyle(
                                                color: selected == entry.key
                                                    ? progressSilver
                                                    : progressMuted,
                                                fontSize: 12,
                                                fontWeight:
                                                    selected == entry.key
                                                        ? FontWeight.w600
                                                        : FontWeight.w400)),
                                        const SizedBox(height: 10),
                                        AnimatedContainer(
                                            duration: DSMotion.duration(
                                                context, DSMotion.selection),
                                            curve: DSMotion.effects,
                                            width: 24,
                                            height: 2,
                                            decoration: BoxDecoration(
                                                color: selected == entry.key
                                                    ? color
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(1))),
                                      ])))))))
              .toList()));
}

class ProgressEmpty extends StatelessWidget {
  final String message;
  const ProgressEmpty(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Text(fitnessText(context, message),
          style: const TextStyle(
              color: progressMuted, fontSize: 13, height: 1.45)));
}

/// Consistent, readable supporting context across Progress detail pages.
class ProgressNote extends StatelessWidget {
  final String text;
  final Color color;
  const ProgressNote(this.text, {super.key, this.color = progressMuted});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(CupertinoIcons.info_circle, size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(fitnessText(context, text),
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: progressMuted))),
      ]));
}

class ProgressFactGrid extends StatelessWidget {
  final List<(String, String)> facts;
  final Color color;
  const ProgressFactGrid(
      {super.key, required this.facts, this.color = progressSilver});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        var columns = box.maxWidth < 340 ? 2 : 3;
        var minimumWidth = 100.0;
        for (final fact in facts) {
          final painter = TextPainter(
              text: TextSpan(
                  text: fact.$2,
                  style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.6)),
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: Directionality.of(context))
            ..layout();
          if (painter.width + 28 > minimumWidth) {
            minimumWidth = painter.width + 28;
          }
          painter.dispose();
        }
        while (columns > 1 &&
            (box.maxWidth - (columns - 1) * 10) / columns < minimumWidth) {
          columns--;
        }
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (var i = 0; i < facts.length; i++)
            Container(
                width: i == facts.length - 1 && facts.length % columns == 1
                    ? box.maxWidth
                    : (box.maxWidth - (columns - 1) * 10) / columns,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: DSColors.bgInset,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DSColors.border, width: .7)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(facts[i].$2,
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.6,
                              color: color)),
                      const SizedBox(height: 6),
                      Text(fitnessText(context, facts[i].$1),
                          style: const TextStyle(
                              fontSize: 13,
                              color: progressMuted,
                              height: 1.35)),
                    ])),
        ]);
      });
}

/// Wrapping selectors keep every metric discoverable, including long translations.
class ProgressMetricPicker extends StatelessWidget {
  final Map<String, String> choices;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color color;
  const ProgressMetricPicker(
      {super.key,
      required this.choices,
      required this.selected,
      required this.onChanged,
      this.color = progressCyan});
  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.entries.map((entry) {
        final active = entry.key == selected;
        return Semantics(
            selected: active,
            button: true,
            child: Material(
                color: active ? color.withValues(alpha: .14) : DSColors.bgCard,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: active
                            ? color.withValues(alpha: .5)
                            : DSColors.border)),
                child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(entry.key),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (active) ...[
                            Icon(Icons.check, color: color, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                              child: Text(fitnessText(context, entry.value),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: active ? color : progressSilver,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500))),
                        ])))));
      }).toList());
}

class ProgressExerciseRow extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  final Widget? trailing;
  const ProgressExerciseRow(
      {super.key, required this.exercise, required this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    final latest = exercise['latest'] as Map?;
    final load = progressNumber(latest?['weight']);
    final reps = progressNumber(latest?['reps']);
    return ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        title: Text(exercise['name'] as String? ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
                latest == null
                    ? fitnessText(context, 'No sets in this period')
                    : '${load != null && load > 0 ? '${progressValue(context, load, unit: 'kg')} × ' : ''}${progressValue(context, reps)} ${fitnessText(context, 'reps')}',
                style: const TextStyle(color: progressMuted, fontSize: 12))),
        trailing: trailing ??
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: progressMuted));
  }
}
