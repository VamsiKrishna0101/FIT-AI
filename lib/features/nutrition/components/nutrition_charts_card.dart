import '../../../core/components/motion.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../history/repositories/history_repository.dart';

// MARK: - Macro Colors (Apple Fitness & WHOOP Palette)
class MacroColors {
  static const Color protein = Color(0xFF00E5FF); // Electric Cyan
  static const Color carbs = Color(0xFFFFD60A); // Sun Gold
  static const Color fat = Color(0xFFFF375F); // Rose Coral
  static const Color energy = Color(0xFFFF9F0A); // Amber Flame
}

// MARK: - WHOOP & Apple Health Multi-Segment Macro Distribution Card
class MacroDistributionCard extends StatelessWidget {
  final double proteinGrams;
  final double proteinTarget;
  final double carbsGrams;
  final double carbsTarget;
  final double fatGrams;
  final double fatTarget;
  final double totalCalories;
  final double targetCalories;

  const MacroDistributionCard({
    super.key,
    required this.proteinGrams,
    required this.proteinTarget,
    required this.carbsGrams,
    required this.carbsTarget,
    required this.fatGrams,
    required this.fatTarget,
    required this.totalCalories,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    // Macro caloric calculations (Protein 4kcal/g, Carbs 4kcal/g, Fat 9kcal/g)
    final proteinCal = proteinGrams * 4.0;
    final carbsCal = carbsGrams * 4.0;
    final fatCal = fatGrams * 9.0;
    final totalMacroCal = math.max(1.0, proteinCal + carbsCal + fatCal);

    final pRatio = proteinCal / totalMacroCal;
    final cRatio = carbsCal / totalMacroCal;
    final fRatio = fatCal / totalMacroCal;

    final calRemaining = math.max(0.0, targetCalories - totalCalories);
    final calProgress = targetCalories > 0
        ? (totalCalories / targetCalories).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101216),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Calories & Energy Target ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FitnessText(
                      'DAILY ENERGY INTAKE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF8E929C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalCalories.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          targetCalories > 0
                              ? '/ ${targetCalories.toInt()} kcal'
                              : 'kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    if (targetCalories > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: MotionValue(
                            value: calProgress,
                            builder: (context, animatedValue) =>
                                LinearProgressIndicator(
                                  value: animatedValue,
                                  minHeight: 3,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00E5FF),
                                  ),
                                )),
                      ),
                    ],
                  ],
                ),
              ),
              // Calorie Remaining Pill Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (calRemaining > 0
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFF9F0A))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (calRemaining > 0
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFFF9F0A))
                        .withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      targetCalories > 0
                          ? '${calRemaining.toInt()} KCAL'
                          : 'SET TARGET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: calRemaining > 0
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFFF9F0A),
                      ),
                    ),
                    Text(
                      targetCalories > 0 ? 'REMAINING' : 'IN SETTINGS',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Multi-Segment Macro Proportion Bar (WHOOP Style) ─────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: totalCalories <= 0
                  ? Container(
                      color: Colors.white.withValues(alpha: 0.08),
                    )
                  : Row(
                      children: [
                        if (pRatio > 0.02)
                          Flexible(
                            flex: (pRatio * 1000).toInt(),
                            child: Container(
                              color: MacroColors.protein,
                              margin: const EdgeInsets.only(right: 2),
                            ),
                          ),
                        if (cRatio > 0.02)
                          Flexible(
                            flex: (cRatio * 1000).toInt(),
                            child: Container(
                              color: MacroColors.carbs,
                              margin: const EdgeInsets.only(right: 2),
                            ),
                          ),
                        if (fRatio > 0.02)
                          Flexible(
                            flex: (fRatio * 1000).toInt(),
                            child: Container(
                              color: MacroColors.fat,
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Three Macro Detail Metric Cards ──────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMacroPill(
                  label: 'PROTEIN',
                  grams: proteinGrams,
                  target: proteinTarget,
                  percent: (pRatio * 100).toInt(),
                  color: MacroColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'CARBS',
                  grams: carbsGrams,
                  target: carbsTarget,
                  percent: (cRatio * 100).toInt(),
                  color: MacroColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'FATS',
                  grams: fatGrams,
                  target: fatTarget,
                  percent: (fRatio * 100).toInt(),
                  color: MacroColors.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required double grams,
    required double target,
    required int percent,
    required Color color,
  }) {
    final progress = target > 0 ? (grams / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${grams.toInt()}g',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (target > 0) ...[
                const SizedBox(width: 2),
                Text(
                  '/${target.toInt()}g',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: MotionValue(
                value: progress,
                builder: (context, animatedValue) => LinearProgressIndicator(
                      value: animatedValue,
                      minHeight: 3.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    )),
          ),
        ],
      ),
    );
  }
}

// MARK: - WHOOP 7-Day Caloric Intake Bar Chart
class CalorieWeeklyBarChart extends StatelessWidget {
  final List<NutritionHistoryPoint> points;
  final double targetCalories;

  const CalorieWeeklyBarChart({
    super.key,
    required this.points,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxCal = math.max(
      targetCalories > 0 ? targetCalories * 1.25 : 2500.0,
      points.fold<double>(0.0, (m, p) => math.max(m, p.calories.toDouble())),
    );

    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101216),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitnessText(
                    '7-DAY INTAKE TREND',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xFF8E929C),
                    ),
                  ),
                  SizedBox(height: 2),
                  FitnessText(
                    'Caloric Consistency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (targetCalories > 0)
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 2,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Target ${targetCalories.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Bar Chart Canvas ─────────────────────────────────────────
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(points.length, (index) {
                final pt = points[index];
                final isToday = pt.date.year == now.year &&
                    pt.date.month == now.month &&
                    pt.date.day == now.day;

                final barHeightRatio = (pt.calories / maxCal).clamp(0.04, 1.0);
                final dayLetter = dayLetters[(pt.date.weekday - 1) % 7];

                // Bar color logic: cyan if near target, amber if high/low
                final isNearTarget = targetCalories > 0 &&
                    (pt.calories - targetCalories).abs() <=
                        targetCalories * 0.15;
                final barColor = isToday
                    ? const Color(0xFF00E5FF)
                    : isNearTarget
                        ? const Color(0xFF30D158)
                        : const Color(0xFF2C3038);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip-style mini calorie figure
                        if (pt.calories > 0)
                          Text(
                            '${(pt.calories / 1000).toStringAsFixed(1)}k',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          )
                        else
                          const SizedBox(height: 11),
                        const SizedBox(height: 4),
                        // Bar Column
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: MotionValue(
                                value: barHeightRatio,
                                builder: (context, animatedValue) =>
                                    FractionallySizedBox(
                                      heightFactor: animatedValue,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          gradient: isToday
                                              ? const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF00E5FF),
                                                    Color(0xFF0091EA),
                                                  ],
                                                )
                                              : null,
                                        ),
                                      ),
                                    )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day Label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: Text(
                            isToday ? 'TDY' : dayLetter,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
