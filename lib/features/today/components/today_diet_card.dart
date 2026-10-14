import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/home_models.dart';
import '../../../core/theme/ds_colors.dart';
import '../../nutrition/views/today_diet_view.dart';

// MARK: - Whoop 4.0 Metabolic Fueling & Nutrition Card
class TodayDietCard extends StatelessWidget {
  final HomeNutrition nutrition;

  const TodayDietCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final cal = nutrition.calories;
    final targetCal = cal.target > 0 ? cal.target : 2400;
    final consumedCal = cal.consumed;
    final remainingCal = (targetCal - consumedCal).clamp(0, targetCal);
    final percent = (consumedCal / targetCal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const TodayDietView()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DSColors.whoopCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DSColors.whoopCardBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DSColors.whoopRecoveryGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FitnessText(
                      'METABOLIC FUELING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DSColors.whoopRecoveryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          DSColors.whoopRecoveryGreen.withValues(alpha: 0.35),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '$remainingCal KCAL LEFT',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: DSColors.whoopRecoveryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Calorie Counter ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$consumedCal',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ $targetCal KCAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Progress Bar ────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(DSColors.whoopRecoveryGreen),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Macros Breakdown ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DSColors.whoopSubCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  _macroTile(
                    label: 'PROTEIN',
                    current: nutrition.protein.consumed,
                    target: nutrition.protein.target,
                    unit: 'g',
                    color: DSColors.whoopRecoveryGreen,
                  ),
                  _divider(),
                  _macroTile(
                    label: 'CARBS',
                    current: nutrition.carbs.consumed,
                    target: nutrition.carbs.target,
                    unit: 'g',
                    color: DSColors.whoopStrainCyan,
                  ),
                  _divider(),
                  _macroTile(
                    label: 'FATS',
                    current: nutrition.fat.consumed,
                    target: nutrition.fat.target,
                    unit: 'g',
                    color: const Color(0xFFFF9500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroTile({
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final t = target > 0 ? target : 1;
    final pct = (current / t).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
              Text(
                '$current$unit',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 0.6,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
