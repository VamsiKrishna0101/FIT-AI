import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import 'liquid_water_visual.dart';

String waterLitres(BuildContext context, int ml) =>
    '${NumberFormat('0.##', Localizations.localeOf(context).toLanguageTag()).format(ml / 1000)} L';

class WaterIntakeCard extends StatelessWidget {
  final int? consumedMl, targetMl;
  final VoidCallback? onTap;
  const WaterIntakeCard(
      {super.key, this.consumedMl, this.targetMl, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: DSColors.bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DSColors.border, width: .7)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: FitnessText('Water',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -.3))),
                      if (onTap != null)
                        const Icon(CupertinoIcons.chevron_right,
                            size: 13, color: DSColors.muted)
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                              consumedMl == null
                                  ? '—'
                                  : waterLitres(context, consumedMl!),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -.6)),
                          if (targetMl != null && targetMl! > 0)
                            Text('/ ${waterLitres(context, targetMl!)}',
                                style: const TextStyle(
                                    color: DSColors.muted, fontSize: 12)),
                        ]),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                        builder: (_, bounds) => ExcludeSemantics(
                            child: LiquidWaterVisual(
                                fraction: targetMl != null && targetMl! > 0
                                    ? (consumedMl ?? 0) / targetMl!
                                    : 0,
                                size: Size(bounds.maxWidth, 84)))),
                  ]))));
}
