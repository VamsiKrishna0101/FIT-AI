import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';

const progressMuted = Color(0xFFA0A0A5);
const progressSilver = Color(0xFFE4E4E4);
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
          color: const Color(0xFF1D1E20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0x0DFFFFFF))),
          clipBehavior: Clip.antiAlias,
          child: Ink(
              decoration: BoxDecoration(
                  gradient: accent == null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                              Color.lerp(
                                  const Color(0xFF1D1E20), accent, .055)!,
                              const Color(0xFF1D1E20)
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
                    style: const TextStyle(fontSize: 12)),
                const Icon(CupertinoIcons.chevron_right, size: 12)
              ])),
      ]));
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
                  child: InkWell(
                      onTap: () => onChanged(entry.key),
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 22, top: 12, bottom: 6),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fitnessText(context, entry.value),
                                        style: TextStyle(
                                            color: selected == entry.key
                                                ? progressSilver
                                                : progressMuted,
                                            fontSize: 12,
                                            fontWeight: selected == entry.key
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                    const SizedBox(height: 10),
                                    Container(
                                        width: 24,
                                        height: 2,
                                        decoration: BoxDecoration(
                                            color: selected == entry.key
                                                ? color
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(1))),
                                  ]))))))
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
