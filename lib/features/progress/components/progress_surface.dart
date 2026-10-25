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
// Match the rest of Setcraft: shared backgrounds, neutral values, chart accents only.
const progressCard = DSColors.bgCard;

String progressTitle(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

Color progressMuscleColor(String id) => progressCyan;

class ProgressSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  const ProgressSurface(
      {super.key,
      required this.child,
      this.accent,
      this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: Material(
          color: progressCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: DSColors.border, width: .7)),
          clipBehavior: Clip.antiAlias,
          child: Ink(
              decoration: const BoxDecoration(color: progressCard),
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
      padding: const EdgeInsets.only(top: 24, bottom: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(fitnessText(context, text),
          style: const TextStyle(
              fontSize: 12, height: 1.5, color: progressMuted)));
}

class ProgressFactGrid extends StatelessWidget {
  final List<(String, String)> facts;
  final Color color;
  const ProgressFactGrid(
      {super.key, required this.facts, this.color = progressSilver});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (facts.isEmpty) return const SizedBox.shrink();
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = (box.maxWidth / (scale > 1.7 ? 150 : 100))
            .floor()
            .clamp(1, facts.length.clamp(1, 3));
        final width = (box.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(spacing: 14, runSpacing: 16, children: [
          for (final fact in facts)
            SizedBox(
                width: width,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fitnessText(context, fact.$1),
                          style: const TextStyle(
                              fontSize: 11, color: progressMuted, height: 1.3)),
                      const SizedBox(height: 7),
                      ProgressValueText(fact.$2, color: progressSilver),
                    ])),
        ]);
      });
}

/// Units stay visually subordinate and can wrap independently at larger text sizes.
class ProgressValueText extends StatelessWidget {
  final String value;
  final Color color;
  final double size;
  const ProgressValueText(this.value,
      {super.key, this.color = progressSilver, this.size = 23});
  @override
  Widget build(BuildContext context) {
    final split =
        RegExp(r'^(.+?)\s(kg·reps|kcal|kg|cm|g|L|h|ms|bpm|sets|reps|/100)$')
            .firstMatch(value);
    return Text.rich(
        TextSpan(children: [
          TextSpan(text: split?.group(1) ?? value),
          if (split != null)
            TextSpan(
                text: ' ${split.group(2)}',
                style: TextStyle(
                    fontSize: size * .52,
                    color: progressMuted,
                    letterSpacing: 0)),
        ]),
        style: TextStyle(
            fontSize: size,
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: -.65,
            color: color));
  }
}

/// One scrolling row keeps chart controls compact without clipping translations.
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
  Widget build(BuildContext context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: choices.entries.map((entry) {
        final active = entry.key == selected;
        return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
                selected: active,
                button: true,
                child: Material(
                    color: active ? DSColors.bgRaised : progressCard,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(entry.key),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 11),
                                child: Text(fitnessText(context, entry.value),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: active
                                            ? progressSilver
                                            : progressMuted,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w500))))))));
      }).toList()));
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
        title: Text(progressTitle(exercise['name'] as String? ?? ''),
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
