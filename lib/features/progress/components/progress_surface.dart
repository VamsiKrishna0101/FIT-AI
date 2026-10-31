import 'dart:ui' as ui;
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';

const progressMuted = DSColors.muted;
const progressSilver = DSColors.silver;
// Each area of Progress owns one hue, so a glance tells you what a chart is
// about. Values and text stay neutral; colour belongs to the data marks.
const progressTraining = DSColors.accent;
const progressStrength = DSColors.ice;
const progressMuscle = DSColors.pulse;
const progressBody = DSColors.gold;
const progressNutrition = DSColors.coral;
const progressRecovery = DSColors.sage;
// Direction of change and personal records.
const progressUp = Color(0xFF4ADE80);
const progressDown = Color(0xFFFF6B6B);
const progressRecord = DSColors.gold;
// The original token names map onto those hues, so every detail screen and
// metric picker picks up the palette without changing its call sites.
const progressBlue = progressStrength;
const progressCyan = Color(0xFF5EE6D0);
const progressViolet = progressMuscle;
const progressAmber = progressBody;
const progressCard = DSColors.bgCard;

String progressTitle(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

Color progressMuscleColor(String id) => progressMuscle;

/// The shared Progress card: a graphite gradient lifted off the black canvas
/// by a soft shadow and a specular top edge. An [accent] adds a faint glow of
/// that area's hue from the top corner.
class ProgressSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double radius;
  const ProgressSurface(
      {super.key,
      required this.child,
      this.accent,
      this.radius = 22,
      this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    final shape = BorderRadius.circular(radius);
    return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: shape, boxShadow: const [
              BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ]),
            child: Material(
                type: MaterialType.transparency,
                shape: RoundedRectangleBorder(
                    borderRadius: shape,
                    side: BorderSide(
                        color:
                            highContrast ? DSColors.borderHi : DSColors.border,
                        width: highContrast ? 1 : .7)),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                    decoration: BoxDecoration(
                        color: highContrast ? progressCard : null,
                        gradient: highContrast
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1E1F22), Color(0xFF141416)])),
                    child: CustomPaint(
                        painter: highContrast
                            ? null
                            : _SurfaceSheen(accent: accent, radius: radius),
                        child: Padding(padding: padding, child: child))))));
  }
}

class _SurfaceSheen extends CustomPainter {
  const _SurfaceSheen({required this.accent, required this.radius});
  final Color? accent;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    if (accent case final accent?) {
      canvas.drawRect(
          bounds,
          Paint()
            ..shader = RadialGradient(
                center: const Alignment(-.85, -1.15),
                radius: 1.05,
                colors: [
                  accent.withValues(alpha: .16),
                  accent.withValues(alpha: 0)
                ]).createShader(bounds));
    }
    if (size.width <= radius * 1.2) return;
    // A hairline of light along the top edge reads as a polished bevel.
    final edge = Rect.fromLTWH(radius * .6, 0, size.width - radius * 1.2, 1);
    canvas.drawRect(
        edge,
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .11),
            Colors.white.withValues(alpha: 0),
          ]).createShader(edge));
  }

  @override
  bool shouldRepaint(_SurfaceSheen oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.radius != radius;
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
    return DecoratedBox(
        decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: .28), width: .7)),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600))),
            ])));
  }
}

class ProgressHeading extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String action;
  final bool stacked;
  const ProgressHeading(this.title,
      {super.key, this.onTap, this.action = 'View all', this.stacked = false});
  @override
  Widget build(BuildContext context) {
    final heading = Text(fitnessText(context, title),
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -.5));
    final button = TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
            foregroundColor: progressMuted,
            padding: EdgeInsets.symmetric(horizontal: stacked ? 0 : 8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
              child: Text(fitnessText(context, action),
                  style: const TextStyle(fontSize: 13))),
          const Icon(CupertinoIcons.chevron_right, size: 12)
        ]));
    return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: stacked && onTap != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, button])
            : Row(children: [
                Expanded(child: heading),
                if (onTap != null) button
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

/// Placeholder cards shaped like the content that is loading. They fade in
/// once rather than pulsing forever, so a slow request never keeps frames
/// scheduled.
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
                      child: SizedBox(
                          height: heights[i] - 32,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Bone(width: 90, height: 12),
                                const SizedBox(height: 14),
                                const _Bone(width: 140, height: 28),
                                const Spacer(),
                                const _Bone(height: 44),
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
