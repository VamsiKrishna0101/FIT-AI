import '../../../core/theme/ds_colors.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/home_models.dart';
import '../../../core/components/bioluminescent_trend_card.dart';
import '../../../core/components/biometric_range_slider.dart';
import '../../../core/components/luminous_orbital_ring.dart';
import '../../../core/health/health_models.dart';
import '../../../core/health/health_sync_service.dart';
import '../../history/repositories/history_repository.dart';
import '../repositories/today_repository.dart';

// MARK: - Whoop 5.0 Inspired Full Health Span & Recovery View
// Every number on this screen comes from the backend (today's readiness +
// /api/history/recovery). Nothing is invented: missing data is hidden.
class BiometricsDetailView extends StatefulWidget {
  final HomeReadiness? readiness;

  const BiometricsDetailView({
    super.key,
    required this.readiness,
  });

  @override
  State<BiometricsDetailView> createState() => _BiometricsDetailViewState();
}

class _BiometricsDetailViewState extends State<BiometricsDetailView> {
  List<RecoveryPoint> _history = const [];
  StreamSubscription<HealthConnectionState>? _healthSub;
  HealthConnectionState _healthState = HealthConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _history = HistoryRepository.shared.peekRecovery() ?? const [];
    HistoryRepository.shared.getRecovery().then((list) {
      if (mounted) setState(() => _history = list);
    });

    _healthState = HealthSyncService.shared.currentState;
    _healthSub = HealthSyncService.shared.stateStream.listen((s) {
      if (mounted) setState(() => _healthState = s);
    });
    HealthSyncService.shared.initialize();
  }

  @override
  void dispose() {
    _healthSub?.cancel();
    super.dispose();
  }

  Future<void> _connectHealth() async {
    HapticFeedback.mediumImpact();
    final ok = await HealthSyncService.shared.requestPermissions();
    if (ok && mounted) {
      _syncHealth();
    }
  }

  Future<void> _syncHealth() async {
    HapticFeedback.lightImpact();
    final res = await HealthSyncService.shared.syncToday();
    if (res.success && mounted) {
      HapticFeedback.mediumImpact();
      TodayRepository.shared.fetchFresh(forceRefresh: true);
      final list =
          await HistoryRepository.shared.getRecovery(forceRefresh: true);
      if (mounted) setState(() => _history = list);
    }
  }

  // 7-day baseline excluding today.
  double? _avg(Iterable<num?> values) {
    final v = values.whereType<num>().toList();
    if (v.isEmpty) return null;
    return v.fold<double>(0, (a, b) => a + b) / v.length;
  }

  String _delta(num current, double? baseline, String unit, {int digits = 0}) {
    if (baseline == null || current <= 0) return 'TODAY';
    final d = current - baseline;
    final sign = d >= 0 ? '+' : '−';
    return '$sign${d.abs().toStringAsFixed(digits)}$unit vs 7D';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.readiness;
    final hasScore = r != null && r.score > 0;
    final score = !hasScore
        ? 0.0
        : (r.score <= 10 ? r.score * 10 : r.score).toDouble().clamp(0.0, 100.0);

    final rhr = r?.restingHrBpm ?? 0;
    final hrv = r?.hrvMs ?? 0;
    final sleepMin = r?.sleepMinutes ?? 0;
    final sleepEff = r?.sleepEfficiency ?? 0;
    final activeCals = r?.activeCalories ?? 0;
    final steps = r?.steps ?? 0;

    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;
    final past = _history.where((p) => !isToday(p.date)).toList();
    final last7 = past.length > 7 ? past.sublist(past.length - 7) : past;

    final baseScore = _avg(last7.map((p) => p.recoveryScore));
    final baseHrv = _avg(last7.map((p) => p.hrv));
    final baseRhr = _avg(last7.map((p) => p.restingHr));
    final baseSleep = _avg(last7.map((p) => p.sleepHours));

    final trend = _history.where((p) => p.recoveryScore != null).toList();
    final trend7 = trend.length > 7 ? trend.sublist(trend.length - 7) : trend;
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    final primaryGlow = !hasScore
        ? const Color(0xFF8E8E93)
        : score >= 80
            ? const Color(0xFFE5A93C) // Whoop signature gold
            : (score >= 60 ? const Color(0xFF30D158) : const Color(0xFFFF453A));

    final vsBaseline = (hasScore && baseScore != null && baseScore > 0)
        ? '${score >= baseScore ? '+' : '−'}${((score - baseScore).abs() / baseScore * 100).toStringAsFixed(1)}%'
        : '—';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back,
              color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const FitnessText(
          'HEALTH TELEMETRY',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.info_circle,
                color: Colors.white70, size: 20),
            onPressed: () => _showBiometricInfoSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Health Provider Connection & Live Sync Banner ───────────
              _HealthSyncBanner(
                state: _healthState,
                lastSyncTime: HealthSyncService.shared.lastSyncTime,
                onSync: _syncHealth,
                onConnect: _connectHealth,
              ),

              const SizedBox(height: 14),

              // ── 1. Hero Ring ─────────────────────────────────────────────
              LuminousOrbitalRing(
                score: score,
                label: hasScore ? r.label.toUpperCase() : 'NO DATA',
                leftMetric: vsBaseline,
                leftLabel: 'VS BASELINE',
                primaryGlow: primaryGlow,
              ),

              const SizedBox(height: 18),

              // ── 2. Metric range sliders ──────────────────────────────────
              if (rhr > 0)
                BiometricRangeSlider(
                  icon: CupertinoIcons.heart_fill,
                  label: 'RESTING HEART RATE',
                  value: rhr.toDouble(),
                  valueDisplay: '$rhr',
                  unit: 'bpm',
                  min: 30,
                  max: 100,
                  minLabel: '30 bpm',
                  maxLabel: '100 bpm',
                  impactTag: _delta(rhr, baseRhr, ' bpm'),
                  impactColor: baseRhr != null && rhr <= baseRhr
                      ? const Color(0xFF30D158)
                      : const Color(0xFFFF9F0A),
                  gradientColors: const [
                    Color(0xFF30D158),
                    Color(0xFFFFD60A),
                    Color(0xFFFF453A),
                  ],
                ),

              if (hrv > 0)
                BiometricRangeSlider(
                  icon: CupertinoIcons.waveform_path_ecg,
                  label: 'HEART RATE VARIABILITY',
                  value: hrv.toDouble(),
                  valueDisplay: '$hrv',
                  unit: 'ms',
                  min: 10,
                  max: 150,
                  minLabel: '10 ms',
                  maxLabel: '150 ms',
                  impactTag: _delta(hrv, baseHrv, ' ms'),
                  impactColor: baseHrv != null && hrv >= baseHrv
                      ? const Color(0xFF30D158)
                      : const Color(0xFFFF9F0A),
                  gradientColors: const [
                    Color(0xFFFF453A),
                    Color(0xFFFFD60A),
                    Color(0xFF30D158),
                  ],
                ),

              if (sleepMin > 0)
                BiometricRangeSlider(
                  icon: CupertinoIcons.moon_fill,
                  label: 'SLEEP DURATION',
                  value: (sleepMin / 60.0),
                  valueDisplay:
                      '${sleepMin ~/ 60}h ${(sleepMin % 60).toString().padLeft(2, '0')}m',
                  unit: '',
                  min: 3,
                  max: 11,
                  minLabel: '3h',
                  maxLabel: '11h',
                  impactTag: sleepEff > 0
                      ? '$sleepEff% EFF'
                      : _delta(sleepMin / 60.0, baseSleep, 'h', digits: 1),
                  impactColor: const Color(0xFFBF5AF2),
                  gradientColors: const [
                    Color(0xFFFF453A),
                    Color(0xFFFFD60A),
                    Color(0xFFBF5AF2),
                  ],
                ),

              if (activeCals > 0)
                BiometricRangeSlider(
                  icon: CupertinoIcons.flame_fill,
                  label: 'ACTIVE ENERGY',
                  value: activeCals.toDouble(),
                  valueDisplay: '$activeCals',
                  unit: 'kcal',
                  min: 0,
                  max: 1200,
                  minLabel: '0 kcal',
                  maxLabel: '1,200 kcal',
                  impactTag: steps > 0 ? '$steps STEPS' : 'TODAY',
                  impactColor: const Color(0xFFFF9F0A),
                  gradientColors: const [
                    Color(0xFF00E5FF),
                    Color(0xFFFFD60A),
                    Color(0xFFFF453A),
                  ],
                  showDivider: false,
                ),

              if (rhr == 0 && hrv == 0 && sleepMin == 0 && activeCals == 0)
                _EmptyBiometrics(
                  onConnect: _connectHealth,
                  state: _healthState,
                ),

              const SizedBox(height: 20),

              // ── 3. Real recovery trend ───────────────────────────────────
              if (trend7.length >= 2)
                BioluminescentTrendCard(
                  dataPoints:
                      trend7.map((p) => p.recoveryScore!.toDouble()).toList(),
                  baseline: baseScore ??
                      _avg(trend7.map((p) => p.recoveryScore)) ??
                      0,
                  title: 'Trend View',
                  metricName: 'RECOVERY · LAST ${trend7.length} DAYS',
                  unit: '%',
                  trajectoryColor: primaryGlow,
                  xLabels: trend7
                      .map((p) => isToday(p.date)
                          ? 'TODAY'
                          : dayNames[p.date.weekday - 1])
                      .toList(),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricInfoSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DSColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const FitnessText(
              'Biometric Intelligence & Recovery',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            FitnessText(
              'Your FitAI Recovery score aggregates Resting Heart Rate (RHR), Heart Rate Variability (HRV), and Sleep Quality to compute your autonomic nervous system readiness. A higher score signifies optimal readiness for high-strain training.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Health Provider Live Sync Banner
class _HealthSyncBanner extends StatelessWidget {
  final HealthConnectionState state;
  final DateTime? lastSyncTime;
  final VoidCallback onSync;
  final VoidCallback onConnect;

  const _HealthSyncBanner({
    required this.state,
    required this.lastSyncTime,
    required this.onSync,
    required this.onConnect,
  });

  String _formatLastSync() {
    if (lastSyncTime == null) return 'Ready to sync';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Synced just now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
    return 'Synced ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final providerTitle = isAndroid ? 'Google Health Connect' : 'Apple Health';
    final isSyncing = state == HealthConnectionState.syncing;
    final isConnected = state.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF00FF87).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF00FF87).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isConnected
                    ? const Color(0xFF00FF87).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            child: Icon(
              isAndroid
                  ? CupertinoIcons.shield_lefthalf_fill
                  : CupertinoIcons.heart_fill,
              size: 16,
              color: isConnected
                  ? const Color(0xFF00FF87)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      providerTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? const Color(0xFF00FF87)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isSyncing
                      ? 'Syncing latest biometric telemetry...'
                      : _formatLastSync(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSyncing ? null : (isConnected ? onSync : onConnect),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFF00FF87).withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isConnected
                      ? const Color(0xFF00FF87).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 0.6,
                ),
              ),
              child: isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CupertinoActivityIndicator(
                        radius: 6,
                        color: Color(0xFF00FF87),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected
                              ? CupertinoIcons.arrow_2_circlepath
                              : CupertinoIcons.link,
                          size: 11,
                          color: isConnected
                              ? const Color(0xFF00FF87)
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'SYNC' : 'CONNECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: isConnected
                                ? const Color(0xFF00FF87)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Interactive Empty State
class _EmptyBiometrics extends StatelessWidget {
  final VoidCallback onConnect;
  final HealthConnectionState state;

  const _EmptyBiometrics({
    required this.onConnect,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final providerName =
        isAndroid ? 'Google Health Connect' : 'Apple HealthKit';
    final buttonText = state == HealthConnectionState.needsInstall
        ? 'Install Health Connect from Play Store'
        : 'Connect $providerName';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.waveform_path_ecg,
            size: 40,
            color: const Color(0xFF00FF87).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 14),
          const FitnessText(
            'Biometric Telemetry Disconnected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect $providerName to unlock precision autonomic nervous system telemetry, daily Whoop recovery scores, and sleep architecture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00FF87)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAndroid
                        ? CupertinoIcons.shield_lefthalf_fill
                        : CupertinoIcons.heart_fill,
                    size: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
