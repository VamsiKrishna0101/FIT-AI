import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../models/home_models.dart';
import '../../../core/components/liquid_glass_box.dart';
import '../../../core/theme/ds_colors.dart';

enum _DayState { done, missed, rest, today, upcoming }

// MARK: - This Week Status (Silver Liquid Glass)
// ✓ completed · ✕ skipped / missed · – rest day · ◉ today · ○ upcoming
class WeeklyStreakStrip extends StatelessWidget {
  final List<WeekDay> weeklyStreak;
  final int streakDays;

  const WeeklyStreakStrip({
    super.key,
    required this.weeklyStreak,
    this.streakDays = 0,
  });

  static bool _isDone(String s) => s == 'COMPLETED' || s == 'DONE';

  List<_DayState> _resolveStates(List<WeekDay> days) {
    final todayIdx = days.indexWhere((d) => d.isToday);
    return List.generate(days.length, (i) {
      final s = days[i].status.toUpperCase();
      if (_isDone(s)) return _DayState.done;
      if (s == 'REST_DAY') return _DayState.rest;
      if (s == 'SKIPPED') return _DayState.missed;
      if (days[i].isToday) return _DayState.today;
      // A past training day that was never finished counts as missed.
      final isPast = todayIdx >= 0 && i < todayIdx;
      if (isPast && s != 'UNAVAILABLE') return _DayState.missed;
      return _DayState.upcoming;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = weeklyStreak.isNotEmpty ? weeklyStreak : _fallbackDays();
    final states = _resolveStates(days);
    final done = states.where((s) => s == _DayState.done).length;
    final missed = states.where((s) => s == _DayState.missed).length;
    final planned = states.where((s) => s != _DayState.rest).length;

    return LiquidGlassBox(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              FitnessText(
                'THIS WEEK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const Spacer(),
              LiquidGlassPill(
                borderRadius: 14,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  '$done / $planned DONE',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayColumn(day: days[i], state: states[i]),
                ),
            ],
          ),
          if (missed > 0) ...[
            const SizedBox(height: 12),
            Text(
              missed == 1
                  ? '1 session missed this week — today is a fresh start.'
                  : '$missed sessions missed this week — today is a fresh start.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<WeekDay> _fallbackDays() {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final monday = now.subtract(Duration(days: todayIndex));
    return List.generate(7, (i) {
      return WeekDay(
        day: labels[i],
        dateNum: monday.add(Duration(days: i)).day,
        status: 'UNAVAILABLE',
        isToday: i == todayIndex,
      );
    });
  }
}

class _DayColumn extends StatelessWidget {
  final WeekDay day;
  final _DayState state;

  const _DayColumn({required this.day, required this.state});

  @override
  Widget build(BuildContext context) {
    final isToday = state == _DayState.today || day.isToday;
    final label = day.day.isNotEmpty ? day.day[0].toUpperCase() : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.4,
            color:
                isToday ? Colors.white : Colors.white.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 8),
        _StatusOrb(state: state, isToday: isToday),
        const SizedBox(height: 6),
        Text(
          day.dateNum?.toString() ?? '',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isToday
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.30),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StatusOrb extends StatelessWidget {
  final _DayState state;
  final bool isToday;

  const _StatusOrb({required this.state, required this.isToday});

  @override
  Widget build(BuildContext context) {
    const size = 30.0;

    switch (state) {
      case _DayState.done:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2F5F7), Color(0xFFB9C2C9)],
            ),
            border:
                isToday ? Border.all(color: Colors.white, width: 1.4) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.checkmark_alt,
            size: 16,
            color: Colors.black,
          ),
        );

      case _DayState.missed:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DSColors.whoopRecoveryRed.withValues(alpha: 0.12),
            border: Border.all(
              color: DSColors.whoopRecoveryRed.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: const Icon(
            CupertinoIcons.xmark,
            size: 12,
            color: Color(0xFFFF6B61),
          ),
        );

      case _DayState.rest:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Icon(
            CupertinoIcons.moon_fill,
            size: 11,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        );

      case _DayState.today:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DSColors.glassControlGradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        );

      case _DayState.upcoming:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        );
    }
  }
}
