import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import 'liquid_water_visual.dart';

class NutritionSummaryCard extends StatelessWidget {
  final num calories,
      calorieTarget,
      protein,
      proteinTarget,
      carbs,
      carbTarget,
      fat,
      fatTarget;
  final double fiber;
  final VoidCallback? onTap, onAddMeal;
  const NutritionSummaryCard(
      {super.key,
      required this.calories,
      required this.calorieTarget,
      required this.protein,
      required this.proteinTarget,
      required this.carbs,
      required this.carbTarget,
      required this.fat,
      required this.fatTarget,
      this.fiber = 0,
      this.onTap,
      this.onAddMeal});
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final actual = calories.isFinite ? calories : 0;
    final goal =
        calorieTarget.isFinite && calorieTarget > 0 ? calorieTarget : 0;
    final progress = goal > 0 ? (actual / goal).clamp(0.0, 1.0) : 0.0;
    return Material(
        color: DSColors.bgCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DSColors.border, width: .7)),
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const FitnessText('Calories',
                                  style: TextStyle(
                                      color: DSColors.muted, fontSize: 11)),
                              const SizedBox(height: 5),
                              Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  spacing: 5,
                                  runSpacing: 2,
                                  children: [
                                    Text(number.format(actual.round()),
                                        style: const TextStyle(
                                            color: DSColors.silver,
                                            fontSize: 22,
                                            height: 1.15,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -.4)),
                                    const Padding(
                                        padding: EdgeInsets.only(bottom: 3),
                                        child: Text('kcal',
                                            style: TextStyle(
                                                color: DSColors.muted,
                                                fontSize: 10))),
                                  ]),
                              if (goal > 0)
                                Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        '/ ${number.format(goal.round())} kcal',
                                        style: const TextStyle(
                                            color: DSColors.muted,
                                            fontSize: 10))),
                            ])),
                        if (goal > 0)
                          Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox.expand(
                                            child: CircularProgressIndicator(
                                                value: progress,
                                                strokeWidth: 3,
                                                strokeCap: StrokeCap.round,
                                                color: DSColors.silver,
                                                backgroundColor:
                                                    const Color(0xFF3C3C3C))),
                                        Padding(
                                            padding: const EdgeInsets.all(7),
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                    '${(progress * 100).round()}%',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500)))),
                                      ]))),
                        if (onAddMeal != null)
                          Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                  tooltip: fitnessText(context, 'Add meal'),
                                  onPressed: onAddMeal,
                                  style: IconButton.styleFrom(
                                      foregroundColor: DSColors.silver,
                                      backgroundColor: const Color(0xFF2C2C2C)),
                                  icon:
                                      const Icon(Icons.add_rounded, size: 18))),
                      ]),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: DSColors.border),
                      const SizedBox(height: 10),
                      LayoutBuilder(builder: (context, bounds) {
                        final items = [
                          ('Protein', protein, proteinTarget),
                          ('Carbs', carbs, carbTarget),
                          ('Fat', fat, fatTarget)
                        ];
                        final scale = MediaQuery.textScalerOf(context);
                        final columnWidth = (bounds.maxWidth - 24) / 3;
                        final labelStyle = DefaultTextStyle.of(context)
                            .style
                            .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2);
                        final valueStyle = labelStyle.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                            height: 1.3);
                        double width(String text, TextStyle style) {
                          final painter = TextPainter(
                              text: TextSpan(text: text, style: style),
                              textScaler: scale,
                              textDirection: Directionality.of(context),
                              maxLines: 1)
                            ..layout();
                          final measured = painter.width;
                          painter.dispose();
                          return measured;
                        }

                        final horizontal = scale.scale(14) > 20 ||
                            items.any((item) {
                              final consumed = number.format(item.$2.round());
                              final target = item.$3 > 0
                                  ? ' / ${number.format(item.$3.round())}'
                                  : '';
                              return width(fitnessText(context, item.$1),
                                              labelStyle) +
                                          2 >
                                      columnWidth ||
                                  width('$consumed$target g', valueStyle) + 2 >
                                      columnWidth;
                            });
                        Widget macro(int i) => _Macro(
                            key: ValueKey(items[i].$1),
                            label: items[i].$1,
                            consumed: items[i].$2,
                            target: items[i].$3,
                            horizontal: horizontal);
                        return horizontal
                            ? Column(children: [
                                macro(0),
                                const SizedBox(height: 10),
                                macro(1),
                                const SizedBox(height: 10),
                                macro(2),
                              ])
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(child: macro(0)),
                                    const SizedBox(width: 12),
                                    Expanded(child: macro(1)),
                                    const SizedBox(width: 12),
                                    Expanded(child: macro(2)),
                                  ]);
                      }),
                      if (fiber > 0)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                '${fitnessText(context, 'Fibre')} · ${NumberFormat('0.#', locale).format(fiber)} g',
                                style: const TextStyle(
                                    color: DSColors.muted, fontSize: 10))),
                    ]))));
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final num consumed, target;
  final bool horizontal;
  const _Macro(
      {super.key,
      required this.label,
      required this.consumed,
      required this.target,
      required this.horizontal});
  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag());
    final value = consumed.isFinite ? consumed : 0;
    final goal = target.isFinite && target > 0 ? target : 0;
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final color = switch (label) {
      'Protein' => const Color(0xFFA7C1DB),
      'Carbs' => const Color(0xFFD6C4A8),
      _ => const Color(0xFFBDB4D4),
    };
    final detail = goal > 0
        ? '${number.format(value.round())} / ${number.format(goal.round())} g'
        : '${number.format(value.round())} g';
    final capsule = ExcludeSemantics(
        child: LiquidWaterVisual(
            fraction: progress,
            size: const Size(32, 46),
            reactToTilt: false,
            perspective: false,
            phaseOffset: switch (label) {
              'Protein' => .7,
              'Carbs' => 2.9,
              _ => 5.1,
            },
            tint: color));
    final large = horizontal;
    final words = Column(
        crossAxisAlignment:
            large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FitnessText(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(detail,
              textAlign: large ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                  color: DSColors.muted, fontSize: 10, height: 1.3)),
        ]);
    return Semantics(
        label: '${fitnessText(context, label)}: $detail',
        excludeSemantics: true,
        child: large
            ? Row(children: [
                capsule,
                const SizedBox(width: 16),
                Expanded(child: words)
              ])
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [capsule, const SizedBox(height: 6), words]));
  }
}
