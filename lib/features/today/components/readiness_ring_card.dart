import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/home_models.dart';
import '../../../core/components/liquid_glass_box.dart';
import '../../../core/theme/ds_colors.dart';
import '../../history/repositories/history_repository.dart';
import '../views/biometrics_detail_view.dart';

// MARK: - Silver Liquid Glass Recovery Card + Previous 7-Day Trend
class ReadinessRingCard extends StatefulWidget {
  final HomeReadiness? readiness;

  const ReadinessRingCard({
    super.key,
    required this.readiness,
  });

  @override
  State<ReadinessRingCard> createState() => _ReadinessRingCardState();
}

class _ReadinessRingCardState extends State<ReadinessRingCard> {
  List<RecoveryPoint> _history = const [];

  @override
  void initState() {
    super.initState();
    _history = HistoryRepository.shared.peekRecovery() ?? const [];
    HistoryRepository.shared.getRecovery().then((list) {
      if (mounted) setState(() => _history = list);
    });
  }

  @override
  void didUpdateWidget(covariant ReadinessRingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New readiness (pull-to-refresh / health sync) → refresh the trend too.
    if (oldWidget.readiness?.score != widget.readiness?.score) {
      HistoryRepository.shared.getRecovery(forceRefresh: true).then((list) {
        if (mounted) setState(() => _history = list);
      });
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double? _avg(Iterable<num?> values) {
    final v = values.whereType<num>().toList();
    if (v.isEmpty) return null;
    return v.fold<double>(0, (a, b) => a + b) / v.length;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.readiness;
    final hasScore = r != null && r.score > 0;
    final score = !hasScore
        ? 0.0
        : (r.score <= 10 ? r.score * 10 : r.score).toDouble().clamp(0.0, 100.0);

    final String statusLabel = !hasScore
        ? 'NO DATA YET'
        : score >= 67
            ? 'PRIME RECOVERY'
            : (score >= 34 ? 'MODERATE' : 'REST NEEDED');

    final Color stateColor = !hasScore
        ? Colors.white.withValues(alpha: 0.35)
        : score >= 67
            ? DSColors.whoopRecoveryGreen
            : (score >= 34
                ? DSColors.whoopRecoveryAmber
                : DSColors.whoopRecoveryRed);

    final headline = !hasScore
        ? 'Sync Health or log a check-in to see recovery.'
        : score >= 67
            ? 'Optimal window for heavy overload.'
            : (score >= 34
                ? 'Target moderate volume today.'
                : 'Prioritize nervous system recovery.');
    final aiNote = r?.aiTarget.trim() ?? '';

    final sourceLabel = r?.source == 'health_connect'
        ? 'HEALTH CONNECT'
        : (r?.source == 'healthkit' ? 'APPLE HEALTH' : 'BIOMETRIC');

    // ── Previous 7 days (excluding today) for baseline arrows & trend ──────
    final now = DateTime.now();
    final past = _history.where((p) => !_sameDay(p.date, now)).toList();
    final last7 = past.length > 7 ? past.sublist(past.length - 7) : past;
    final baseHrv = _avg(last7.map((p) => p.hrv));
    final baseRhr = _avg(last7.map((p) => p.restingHr));

    final hrv = r?.hrvMs ?? 0;
    final rhr = r?.restingHrBpm ?? 0;
    final sleepMin = r?.sleepMinutes ?? 0;

    IconData? hrvArrowFor(num current, double? base) {
      if (current <= 0) return null;
      if (base != null && (current - base).abs() >= 1) {
        return current >= base
            ? CupertinoIcons.arrow_up_right
            : CupertinoIcons.arrow_down_right;
      }
      return CupertinoIcons.arrow_up_right;
    }

    IconData? rhrArrowFor(num current, double? base) {
      if (current <= 0) return null;
      if (base != null && (current - base).abs() >= 1) {
        return current <= base
            ? CupertinoIcons.arrow_down_right
            : CupertinoIcons.arrow_up_right;
      }
      return CupertinoIcons.arrow_down_right;
    }

    final sleepBars = last7
        .map((p) => p.sleepHours)
        .whereType<double>()
        .map((h) => (h / 9.0).clamp(0.0, 1.0))
        .toList();

    return LiquidGlassBox(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => BiometricsDetailView(readiness: r),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor,
                  boxShadow: [
                    BoxShadow(
                      color: stateColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$sourceLabel RECOVERY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LiquidGlassPill(
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Silver Dial + Coach Insight ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score / 100.0),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => CustomPaint(
                        size: const Size(118, 118),
                        painter: _SilverDialPainter(percent: value),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasScore ? '${score.toInt()}%' : '—',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.0,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'RECOVERY',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.48),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                    if (aiNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        aiNote,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Telemetry Strip ───────────────────────────────────────────
          LiquidGlassPill(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _TelemetryTile(
                    label: 'HRV',
                    value: hrv > 0 ? '$hrv ms' : '—',
                    trailing: _arrow(hrvArrowFor(hrv, baseHrv)),
                  ),
                  _divider(),
                  _TelemetryTile(
                    label: 'RESTING HR',
                    value: rhr > 0 ? '$rhr bpm' : '—',
                    trailing: _arrow(rhrArrowFor(rhr, baseRhr)),
                  ),
                  _divider(),
                  _TelemetryTile(
                    label: 'SLEEP',
                    value: sleepMin > 0
                        ? '${sleepMin ~/ 60}h ${(sleepMin % 60).toString().padLeft(2, '0')}m'
                        : '—',
                    valueColor: const Color(0xFF8B7BFF),
                    trailing: sleepMin > 0
                        ? LiquidSparklineBars(
                            values: sleepBars.length >= 3
                                ? (sleepBars.length > 5
                                    ? sleepBars.sublist(sleepBars.length - 5)
                                    : sleepBars)
                                : const [0.35, 0.65, 0.45, 0.85, 0.70],
                            width: 16,
                            height: 12,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Previous 7-Day Recovery Trend ─────────────────────────────
          _SevenDayTrend(
            history: _history,
            todayScore: hasScore ? score : null,
          ),
        ],
      ),
    );
  }

  Widget? _arrow(IconData? icon) => icon == null
      ? null
      : Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75));

  Widget _divider() => Container(
        width: 0.7,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withValues(alpha: 0.10),
      );
}

class _TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;

  const _TelemetryTile({
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: valueColor ?? Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// MARK: - 7-Day Recovery Bars (previous 6 days + today)
class _SevenDayTrend extends StatelessWidget {
  final List<RecoveryPoint> history;
  final double? todayScore;

  const _SevenDayTrend({required this.history, required this.todayScore});

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Map recovery by calendar day.
    final byDay = <DateTime, double>{};
    for (final p in history) {
      if (p.recoveryScore == null) continue;
      byDay[DateTime(p.date.year, p.date.month, p.date.day)] =
          p.recoveryScore!.toDouble();
    }
    if (todayScore != null) byDay[today] = todayScore!;

    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = days.map((d) => byDay[d]).toList();
    final known = values.whereType<double>().toList();
    final avg =
        known.isEmpty ? null : known.reduce((a, b) => a + b) / known.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'LAST 7 DAYS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
            const Spacer(),
            Text(
              avg == null ? 'NO TREND YET' : 'AVG ${avg.round()}%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.8),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _TrendBar(
                    value: values[i],
                    letter: _letters[days[i].weekday - 1],
                    isToday: i == 6,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  final double? value;
  final String letter;
  final bool isToday;

  const _TrendBar({
    required this.value,
    required this.letter,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    const maxBar = 52.0;
    final v = value;
    final h = v == null ? 4.0 : math.max(6.0, (v / 100.0) * maxBar);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          v == null ? '' : '${v.round()}',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color:
                isToday ? Colors.white : Colors.white.withValues(alpha: 0.45),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: h),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, barH, __) => Container(
            width: 14,
            height: barH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: v == null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isToday
                          ? const [Color(0xFFFFFFFF), Color(0xFFB9C2C9)]
                          : [
                              Colors.white.withValues(alpha: 0.42),
                              Colors.white.withValues(alpha: 0.14),
                            ],
                    ),
              color: v == null ? Colors.white.withValues(alpha: 0.08) : null,
              boxShadow: isToday && v != null
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.22),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isToday ? 'TODAY' : letter,
          style: TextStyle(
            fontSize: isToday ? 8.5 : 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: isToday ? 0.6 : 0.2,
            color:
                isToday ? Colors.white : Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

// MARK: - Silver Specular Dial
class _SilverDialPainter extends CustomPainter {
  final double percent;

  _SilverDialPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.0;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (percent <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * percent;

    // Soft glow under the arc
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(-math.pi / 2),
          colors: [Color(0xFFAEB8C0), Color(0xFFFFFFFF), Color(0xFFD9DFE3)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_SilverDialPainter old) => old.percent != percent;
}
