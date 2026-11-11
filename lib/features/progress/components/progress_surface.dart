import 'dart:ui' as ui;
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import '../../onboarding/components/coach_mascot.dart';

const progressMuted = DSColors.muted;
const progressSilver = DSColors.silver;
// FitAI Design System tokens — 100% harmonized with Today & Train tabs
const progressTraining = DSColors.accent; // FitAI Mint Sage (#67D7B0)
const progressStrength = DSColors.ice; // FitAI Ice (#5AC8FA)
const progressMuscle = DSColors.violet; // FitAI Violet (#A28BFA)
const progressBody = DSColors.gold; // FitAI Gold (#FFB84D)
const progressNutrition = DSColors.coral; // FitAI Coral (#ED927F)
const progressRecovery = DSColors.accent; // FitAI Accent
// Direction of change and personal records.
const progressUp = DSColors.accent;
const progressDown = DSColors.coral;
const progressRecord = DSColors.gold;
// Backward compatibility token aliases
const progressBlue = progressStrength;
const progressCyan = DSColors.ice;
const progressViolet = progressMuscle;
const progressAmber = progressBody;
const progressCard = DSColors.bgCard;

String progressTitle(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

Color progressMuscleColor(String id) => progressMuscle;

/// The shared Progress card: Solid obsidian card matching the Today tab
/// (_TodaySurface), with pure black OLED background, 18px radius, and clean hairline border.
class ProgressSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double radius;
  final bool hero;
  final VoidCallback? onTap;

  const ProgressSurface({
    super.key,
    required this.child,
    this.accent,
    this.radius = 18,
    this.hero = false,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hero ? DSColors.borderHi : DSColors.border;

    final surface = Material(
      color: DSColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: .7),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return MotionPress(enabled: onTap != null, child: surface);
  }
}

/// A change badge tinted by direction, with an arrow so the meaning never
/// relies on colour alone.
class ProgressChangeChip extends StatelessWidget {
  final num change;
  final String label;
  const ProgressChangeChip(
      {super.key, required this.change, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = change > 0
        ? progressUp
        : change < 0
            ? progressDown
            : progressMuted;
    final icon = change > 0
        ? CupertinoIcons.arrow_up_right
        : change < 0
            ? CupertinoIcons.arrow_down_right
            : CupertinoIcons.minus;
    return Container(
        decoration: BoxDecoration(
            color: DSColors.bgRaised,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: .3), width: .7)),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 10.5, color: color),
              const SizedBox(width: 5),
              Flexible(
                  child: Text(label,
                      style: const TextStyle(
                          color: DSColors.silver,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.1))),
            ])));
  }
}

class ProgressHeading extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String action;
  final bool stacked;
  final double topPadding;
  const ProgressHeading(this.title,
      {super.key,
      this.onTap,
      this.action = 'View all',
      this.stacked = false,
      this.topPadding = 24});
  @override
  Widget build(BuildContext context) {
    final heading = Text(fitnessText(context, title),
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: -.3,
            color: Colors.white));
    final button = onTap == null
        ? null
        : MotionPress(
            child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                    foregroundColor: DSColors.silver,
                    padding: EdgeInsets.symmetric(horizontal: stacked ? 0 : 8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                      child: Text(fitnessText(context, action),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: DSColors.muted))),
                  const SizedBox(width: 3),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 11, color: DSColors.muted)
                ])));
    return Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: 8),
        child: stacked && onTap != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 4), button!])
            : Row(children: [
                Expanded(child: heading),
                if (button != null) button
              ]));
  }
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
          ])));
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

/// Placeholder cards shaped like the content that is loading.
class ProgressSkeleton extends StatelessWidget {
  final List<double> heights;
  const ProgressSkeleton({super.key, this.heights = const [200, 190, 150]});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: DSMotion.duration(context, DSMotion.reveal),
          curve: DSMotion.effects,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: Column(children: [
            for (var i = 0; i < heights.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              ProgressSurface(
                  padding: const EdgeInsets.all(16),
                  child: heights[i] < 100
                      ? const Row(
                          children: [
                            _Bone(width: 24, height: 24),
                            SizedBox(width: 12),
                            Expanded(child: _Bone(height: 16)),
                          ],
                        )
                      : SizedBox(
                          height: heights[i] - 32,
                          child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Bone(width: 90, height: 12),
                                SizedBox(height: 12),
                                _Bone(width: 140, height: 22),
                                Spacer(),
                                _Bone(height: 36),
                              ]))),
            ],
          ])));
}

class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  const _Bone({this.width, required this.height});
  @override
  Widget build(BuildContext context) => Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2.5),
          gradient: const LinearGradient(colors: [
            Color(0x14FFFFFF),
            Color(0x0AFFFFFF),
          ])));
}

class ProgressEmpty extends StatelessWidget {
  final String message;

  /// Whole-list empty states show Mochi; small chart cards keep the icon.
  final bool coach;
  const ProgressEmpty(this.message, {super.key, this.coach = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
      child: Row(children: [
        if (coach)
          const CoachMascot(size: 44)
        else
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DSColors.border, width: .7),
            ),
            child: const Icon(CupertinoIcons.chart_bar,
                size: 15, color: DSColors.muted),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(fitnessText(context, message),
              style: const TextStyle(
                  color: DSColors.muted, fontSize: 12.5, height: 1.4)),
        ),
      ]));
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
            // Equal-width digits keep values aligned and steady as they change.
            fontFeatures: const [ui.FontFeature.tabularFigures()],
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
      physics: const BouncingScrollPhysics(),
      child: Row(
          children: choices.entries.map((entry) {
        final active = entry.key == selected;
        return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
                selected: active,
                button: true,
                child: MotionPress(
                    child: Container(
                        decoration: BoxDecoration(
                            color: active ? DSColors.bgRaised : DSColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: active
                                    ? DSColors.borderHi
                                    : DSColors.border,
                                width: .7)),
                        child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (!active) {
                                    HapticFeedback.selectionClick();
                                    onChanged(entry.key);
                                  }
                                },
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minHeight: 40),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        child: Text(
                                            fitnessText(context, entry.value),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: active
                                                    ? DSColors.silver
                                                    : DSColors.muted,
                                                fontWeight: active
                                                    ? FontWeight.w600
                                                    : FontWeight.w500))))))))));
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
