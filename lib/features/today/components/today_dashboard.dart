import '../../../core/components/motion.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/localization/fitai_copy.dart';
import '../../../models/home_models.dart';
import '../../history/repositories/history_repository.dart';
import 'readiness_score_ring.dart';
import 'readiness_signals.dart';
import '../views/readiness_detail_view.dart';
import '../models/session_guidance.dart';
import '../models/readiness_availability.dart';
import '../../body_scan/models/training_map_models.dart';
import 'today_training_preview.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/components/profile_avatar.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../wellness/views/sleep_preferences_view.dart';

const _surface = DSColors.bgCard;
const _muted = DSColors.muted;
const _silver = DSColors.silver;
const _blue = Color(0xFF0A84FF);
const _line = DSColors.border;

/// Today-specific surfaces and layout. Other dashboard tabs keep their styling.
class TodayDashboard extends StatelessWidget {
  final HomeData? data;
  final List<RecoveryPoint> recovery;
  final TrainingMapData? trainingMap;
  final ScrollController? scrollController;
  final bool loading;
  final bool loadFailed;
  final bool refreshFailed;
  final DateTime? now;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final List<WeekDay>? weekDays;
  final Future<void> Function() onRefresh;
  final VoidCallback onProfile;
  final VoidCallback onSession;
  final VoidCallback onTrain;
  final VoidCallback onNutrition;
  final VoidCallback onBody;
  final VoidCallback? onSleep;

  const TodayDashboard({
    super.key,
    required this.data,
    this.recovery = const [],
    this.trainingMap,
    this.scrollController,
    this.loading = false,
    this.loadFailed = false,
    this.refreshFailed = false,
    this.now,
    this.selectedDate,
    this.onDateSelected,
    this.weekDays,
    this.onSleep,
    required this.onRefresh,
    required this.onProfile,
    required this.onSession,
    required this.onTrain,
    required this.onNutrition,
    required this.onBody,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family =
        theme.platform == TargetPlatform.iOS ? 'CupertinoSystemText' : 'Inter';
    return Theme(
      data: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: family),
          colorScheme:
              theme.colorScheme.copyWith(primary: _silver, secondary: _silver)),
      child: DefaultTextStyle.merge(
          style: TextStyle(fontFamily: family),
          child: Builder(builder: _buildContent)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final copy = FitAiCopy.of(context);
    final date = selectedDate ?? now ?? DateTime.now();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('d MMM', locale).format(date);
    final historical = !DateUtils.isSameDay(date, now ?? DateTime.now());
    final metrics = data?.healthMetrics;
    final health = metrics != null &&
            metrics.date == DateFormat('yyyy-MM-dd').format(date) &&
            !RegExp('sample|preview|demo', caseSensitive: false)
                .hasMatch(metrics.source)
        ? metrics
        : null;
    final reading = data?.readiness;
    final r = reading != null &&
            !RegExp('sample|preview|demo', caseSensitive: false)
                .hasMatch(reading.source) &&
            (selectedDate == null ||
                reading.date == DateFormat('yyyy-MM-dd').format(date))
        ? reading
        : null;
    final days = weekDays ?? data?.weeklyStreak ?? const <WeekDay>[];
    final noWearable = data?.wearableUsage == 'NONE';
    final needsCheckIn = noWearable &&
        data?.sleepLog != null &&
        (data?.sleepLog?['rested'] == null ||
            data?.sleepLog?['energy'] == null ||
            data?.sleepLog?['soreness'] == null);
    void openReadiness() {
      if (noWearable && r == null && onSleep != null) {
        onSleep!();
        return;
      }
      _showReadiness(context, r, copy,
          date: date,
          onSleep: onSleep,
          health: health,
          sleepLog: data?.sleepLog,
          noWearable: noWearable);
    }

    final history = recovery
        .where((p) =>
            !DateUtils.dateOnly(p.date).isAfter(DateUtils.dateOnly(date)) &&
            (p.recoveryScore != null ||
                p.hrv != null ||
                p.sleepHours != null ||
                p.restingHr != null))
        .toList();
    // The latest dated reading can still be charted while history is loading.
    final readingDate = r?.date == null ? null : DateTime.tryParse(r!.date!);
    if (r != null &&
        readingDate != null &&
        !history.any((p) => DateUtils.isSameDay(p.date, readingDate))) {
      history.add(RecoveryPoint(
          date: readingDate,
          recoveryScore:
              ['check_in_estimate', 'mixed_estimate'].contains(r.source)
                  ? null
                  : _readinessScore(r),
          hrv: r.hrvMs > 0 ? r.hrvMs.toDouble() : null,
          hrvMethod: health?.hrvMethod ??
              (r.source == 'health_connect'
                  ? 'RMSSD'
                  : r.source == 'healthkit'
                      ? 'SDNN'
                      : null),
          restingHr: r.restingHrBpm > 0 ? r.restingHrBpm : null,
          sleepHours: r.sleepMinutes > 0 ? r.sleepMinutes / 60 : null));
    }
    return Column(children: [
      Padding(
        key: const ValueKey('today-fixed-header'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: _Header(
            name: data?.user.name ?? '',
            date: date,
            clock: now ?? DateTime.now(),
            locale: locale,
            copy: copy,
            onProfile: onProfile),
      ),
      Expanded(
          child: RefreshIndicator(
        color: _silver,
        backgroundColor: _surface,
        onRefresh: onRefresh,
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, LiquidSilverBottomBar.scrollBottomInset(context)),
              sliver: SliverList.list(children: [
                if (loadFailed) ...[
                  _TodaySurface(
                      child: Row(children: [
                    const Icon(CupertinoIcons.wifi_slash,
                        color: _muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(copy.text('loadFailedBody'),
                            style:
                                const TextStyle(color: _muted, fontSize: 13))),
                    TextButton(
                        onPressed: onRefresh,
                        child: Text(copy.text('retry'),
                            style: const TextStyle(color: _silver))),
                  ])),
                  const SizedBox(height: 24),
                ],
                if (refreshFailed && !loadFailed) ...[
                  _TodaySurface(
                      key: const ValueKey('today-refresh-warning'),
                      child: Row(children: [
                        const Icon(CupertinoIcons.wifi_slash,
                            size: 18, color: _muted),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: FitnessText(
                                'Could not refresh. Showing saved data.',
                                style: TextStyle(color: _muted, fontSize: 12))),
                        TextButton(
                            onPressed: onRefresh,
                            child: Text(copy.text('retry'))),
                      ])),
                  const SizedBox(height: 16),
                ],
                if (days.isNotEmpty) ...[
                  _Section(
                      title: copy.text('weekProgress'),
                      trailing: !loading && (data?.user.streakDays ?? 0) > 0
                          ? '${data!.user.streakDays} ${copy.text(data!.user.streakDays == 1 ? 'todayDay' : 'days')}'
                          : null),
                  const SizedBox(height: 12),
                  _WeekCard(
                      days: days,
                      today: date,
                      locale: locale,
                      copy: copy,
                      onDateSelected: onDateSelected),
                  SizedBox(height: history.isNotEmpty ? 12 : 24),
                ],
                if (loading)
                  _TodaySurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(copy.text('todayLoading'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                            color: _silver,
                            backgroundColor: _line,
                            minHeight: 2),
                      ]))
                else if (!loadFailed) ...[
                  if (history.isNotEmpty) ...[
                    _RecoveryChart(
                        key: ValueKey(
                            'recovery-${DateFormat('yyyy-MM-dd').format(date)}'),
                        history: history,
                        today: date,
                        locale: locale,
                        copy: copy),
                    const SizedBox(height: 24),
                  ],
                  _Section(title: copy.text('readiness'), onTap: openReadiness),
                  const SizedBox(height: 12),
                  _ReadinessCard(
                      readiness: r,
                      health: health,
                      sleepLog: data?.sleepLog,
                      noWearable: noWearable,
                      copy: copy,
                      today: date,
                      onTap: openReadiness),
                  if (health != null &&
                      (health.steps != null ||
                          health.activeCalories != null ||
                          health.sleepMinutes != null)) ...[
                    const SizedBox(height: 12),
                    _DailyMetrics(
                        metrics: health, copy: copy, onTap: openReadiness),
                  ],
                  if (onSleep != null) ...[
                    const SizedBox(height: 12),
                    _TodaySurface(
                        onTap: onSleep,
                        child: Row(children: [
                          const Icon(CupertinoIcons.moon_stars,
                              color: Color(0xFFA28BFA), size: 22),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                FitnessText(
                                    needsCheckIn
                                        ? 'Complete check-in'
                                        : data?.sleepLog != null ||
                                                (health?.sleepMinutes ?? 0) > 0
                                            ? 'Sleep logged'
                                            : 'Log sleep',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                FitnessText(
                                    needsCheckIn
                                        ? 'Sleep saved · add how you feel'
                                        : data?.sleepLog != null
                                            ? (data?.sleepLog?['source'] ==
                                                    'phone_estimate_confirmed'
                                                ? 'Phone estimate · confirmed'
                                                : 'Self-reported')
                                            : (health?.sleepMinutes ?? 0) > 0
                                                ? 'Synced from your health app'
                                                : 'No device needed',
                                    style: const TextStyle(
                                        color: _muted, fontSize: 12)),
                              ])),
                          if ((data?.sleepLog?['sleepMinutes'] ??
                                  health?.sleepMinutes)
                              case final num minutes)
                            Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                    '${minutes ~/ 60} h ${minutes.toInt() % 60} m',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16))),
                          Icon(
                              data?.sleepLog != null ||
                                      (health?.sleepMinutes ?? 0) > 0
                                  ? CupertinoIcons.pencil
                                  : CupertinoIcons.add,
                              color: _silver,
                              size: 18),
                        ])),
                  ],
                  const SizedBox(height: 24),
                  _Section(
                      title: historical
                          ? '${copy.text('training')} · $dateLabel'
                          : copy.text('todaySessionHeading'),
                      onTap: onSession),
                  const SizedBox(height: 12),
                  _SessionCard(
                      workout: data?.todayWorkout,
                      copy: copy,
                      onSession: onSession,
                      onTrain: onTrain),
                  const SizedBox(height: 24),
                  _Section(
                      title: copy.text('nutrition'),
                      trailing: '$dateLabel · ${copy.text('viewAll')}',
                      onTap: onNutrition),
                  const SizedBox(height: 12),
                  _NutritionCard(
                      nutrition: data?.nutrition,
                      copy: copy,
                      onTap: onNutrition),
                  const SizedBox(height: 24),
                  _Section(
                      title: copy.text(trainingMap == null
                          ? 'bodyScan'
                          : 'todayMusclesHeading'),
                      trailing: dateLabel,
                      onTap: onBody),
                  const SizedBox(height: 12),
                  _TodaySurface(
                      onTap: onBody,
                      child: Row(children: [
                        TodayTrainingPreview(data: trainingMap),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  copy.text(trainingMap == null
                                      ? 'todayBodyTitle'
                                      : 'todayTrainingMapTitle'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                  copy.text(trainingMap == null
                                      ? 'todayBodySubtitle'
                                      : trainingMap!.regions
                                              .any((r) => r.completedSets > 0)
                                          ? 'todayLoggedMuscles'
                                          : 'todayNoLoggedMuscles'),
                                  style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      height: 1.4)),
                            ])),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right,
                            color: _muted, size: 13),
                      ])),
                ],
              ]),
            )
          ],
        ),
      )),
    ]);
  }
}

class _Header extends StatelessWidget {
  final String name;
  final DateTime date;
  final DateTime clock;
  final String locale;
  final FitAiCopy copy;
  final VoidCallback onProfile;
  const _Header(
      {required this.name,
      required this.date,
      required this.clock,
      required this.locale,
      required this.copy,
      required this.onProfile});
  @override
  Widget build(BuildContext context) {
    final names =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final greeting = copy.text(clock.hour < 12
        ? 'goodMorning'
        : clock.hour < 18
            ? 'goodAfternoon'
            : 'goodEvening');
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting${names.isEmpty ? '' : ', ${names.first}'}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -.2)),
        const SizedBox(height: 5),
        Text(DateFormat('EEEE, d MMM', locale).format(date),
            style: const TextStyle(
                color: _muted, fontSize: 12, letterSpacing: -.1)),
      ])),
      const SizedBox(width: 12),
      ProfileAvatar(name: name, label: 'Settings', onTap: onProfile),
    ]);
  }
}

class _TodaySurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool hero;
  const _TodaySurface(
      {required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16),
      this.hero = false,
      super.key});

  @override
  State<_TodaySurface> createState() => _TodaySurfaceState();
}

class _TodaySurfaceState extends State<_TodaySurface> {
  bool _pressed = false;

  void _press(bool pressed) {
    if (MediaQuery.disableAnimationsOf(context) || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final surface = Material(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: DSColors.bgCard,
                border: Border.all(
                    color: widget.hero ? DSColors.borderHi : DSColors.border,
                    width: .7)),
            child: InkWell(
                onTap: widget.onTap,
                onTapDown: widget.onTap == null ? null : (_) => _press(true),
                onTapUp: widget.onTap == null ? null : (_) => _press(false),
                onTapCancel: widget.onTap == null ? null : () => _press(false),
                child: Padding(padding: widget.padding, child: widget.child))));

    if (widget.onTap == null || MediaQuery.disableAnimationsOf(context)) {
      return surface;
    }
    return AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: DSMotion.duration(context, DSMotion.press),
        curve: Curves.easeOutCubic,
        child: surface);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  const _Section({required this.title, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
      header: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(children: [
              Flexible(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.3))),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: _muted)
              ],
              const Spacer(),
              if (trailing != null)
                Flexible(
                    child: Text(trailing!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: _muted, fontSize: 11))),
            ])),
      ));
}

int _readinessScore(HomeReadiness r) =>
    (r.score <= 10 ? r.score * 10 : r.score).clamp(0, 100).round();

class _ReadinessCard extends StatelessWidget {
  final HomeReadiness? readiness;
  final HomeHealthMetrics? health;
  final Map<String, dynamic>? sleepLog;
  final bool noWearable;
  final FitAiCopy copy;
  final DateTime today;
  final VoidCallback? onTap;

  const _ReadinessCard(
      {required this.readiness,
      this.health,
      this.sleepLog,
      this.noWearable = false,
      required this.copy,
      required this.today,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final reading = readiness;
    final score = reading == null ? null : _readinessScore(reading);
    final availability = ReadinessAvailability.fromMetrics(health,
        sleepLog: sleepLog, noWearable: noWearable);
    final checkIn =
        reading == null ? noWearable : reading.source == 'check_in_estimate';

    final heading = score == null
        ? checkIn
            ? 'How are you feeling?'
            : 'Add your readings'
        : score >= 67
            ? 'Ready today'
            : readinessHeadline(score);
    final basis =
        reading == null ? availability.title : readinessBasis(reading);

    return _TodaySurface(
      key: const ValueKey('today-readiness-card'),
      hero: true,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, bounds) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
          final title = FitnessText(heading,
              key: const ValueKey('today-readiness-heading'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.3));
          final metadata =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(basis,
                style:
                    const TextStyle(color: _muted, fontSize: 11, height: 1.3)),
            const SizedBox(height: 6),
            Text(DateFormat.MMMd(copy.localeCode).format(today),
                key: const ValueKey('today-readiness-date'),
                style: const TextStyle(color: _muted, fontSize: 12)),
          ]);
          final ring = ReadinessScoreRing(
              key: const ValueKey('today-readiness-ring'),
              score: score,
              color: _silver,
              size: 92,
              minimal: true);
          return largeText
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: metadata),
                    const SizedBox(width: 12),
                    ring
                  ]),
                  const SizedBox(height: 8),
                  title,
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        metadata,
                        const SizedBox(height: 12),
                        title,
                      ])),
                  const SizedBox(width: 12),
                  ring,
                ]);
        }),
        const SizedBox(height: 10),
        FitnessText(
            score == null ? availability.description : readinessMeaning(score),
            style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.4)),
        const SizedBox(height: 16),
        const Divider(height: 1, color: _line),
        const SizedBox(height: 14),
        ReadinessSignals(
            readiness: reading,
            sleepLog: sleepLog,
            checkIn: checkIn,
            compact: true),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _Metric({required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4)),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.5)),
          if (unit.isNotEmpty)
            TextSpan(
                text: ' $unit',
                style: const TextStyle(color: _muted, fontSize: 11)),
        ])),
      ]);
}

class _DailyMetrics extends StatelessWidget {
  final HomeHealthMetrics metrics;
  final FitAiCopy copy;
  final VoidCallback? onTap;
  const _DailyMetrics({required this.metrics, required this.copy, this.onTap});
  @override
  Widget build(BuildContext context) {
    final r = metrics;
    final sleep = r.sleepMinutes?.round();
    final movement = r.steps != null || r.activeCalories != null;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (sleep != null)
        Expanded(
            child: _TodaySurface(
                onTap: onTap,
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CupertinoIcons.moon, color: _silver, size: 19),
                      const SizedBox(height: 8),
                      _Metric(
                          label: copy.text('todaySleep'),
                          value: '${sleep ~/ 60}',
                          unit: 'h ${sleep % 60} m'),
                      const SizedBox(height: 8),
                      Text(copy.text('todayLastNight'),
                          style: const TextStyle(color: _muted, fontSize: 10)),
                    ]))),
      if (sleep != null && movement) const SizedBox(width: 12),
      if (movement)
        Expanded(
            child: _TodaySurface(
                onTap: onTap,
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CupertinoIcons.flame,
                          color: _silver, size: 19),
                      const SizedBox(height: 8),
                      _Metric(
                          label: copy.text(r.steps != null
                              ? 'todaySteps'
                              : 'todayActiveEnergy'),
                          value: NumberFormat.decimalPattern(copy.localeCode)
                              .format(r.steps ?? r.activeCalories!),
                          unit: r.steps != null ? '' : 'kcal'),
                      const SizedBox(height: 8),
                      Text(
                          r.steps != null && r.activeCalories != null
                              ? '${r.activeCalories!.round()} ${copy.text('todayActiveKcal')}'
                              : copy.text('todayMovement'),
                          style: const TextStyle(color: _muted, fontSize: 10)),
                    ]))),
    ]);
  }
}

class _SessionCard extends StatelessWidget {
  final HomeTodayWorkout? workout;
  final FitAiCopy copy;
  final VoidCallback onSession;
  final VoidCallback onTrain;
  const _SessionCard(
      {required this.workout,
      required this.copy,
      required this.onSession,
      required this.onTrain});
  @override
  Widget build(BuildContext context) {
    final w = workout;
    final complete = w?.status == 'COMPLETED';
    final rest = w == null || w.status == 'REST_DAY';
    final guidance = SessionGuidance.fromNote(w?.aiNote,
        fallback: copy.text('todayAdaptiveEffort'));
    final actionLabel = copy.text(rest
        ? 'openPlan'
        : complete
            ? 'todayReviewSession'
            : w.status == 'IN_PROGRESS'
                ? 'todayContinueSession'
                : 'startSession');
    return _TodaySurface(
        onTap: rest ? onTrain : onSession,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(
                    copy.text(rest
                        ? 'training'
                        : complete
                            ? 'completed'
                            : w.status == 'IN_PROGRESS'
                                ? 'todayInProgress'
                                : 'todayPlanned'),
                    style: const TextStyle(color: _muted, fontSize: 11))),
            if (!rest && w.durationMinutes > 0)
              Text('${w.durationMinutes} ${copy.text('minutes')}',
                  style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 3,
                height: 17,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                    color: _silver, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      rest
                          ? copy.text('todayNoSession')
                          : w.sessionTitle ?? w.workoutTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.25)),
                  const SizedBox(height: 5),
                  Wrap(
                      spacing: 12,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                            rest
                                ? copy.text('noWorkout')
                                : '${w.exerciseCount} ${copy.text('exercises')}',
                            style: const TextStyle(
                                color: _muted, fontSize: 12, height: 1.4)),
                        if (!rest && guidance.effort != null)
                          Container(
                              key: const ValueKey('today-effort-pill'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0x20FFFFFF),
                                      width: .5)),
                              child: Text(
                                  '${copy.text('todayTargetEffort')} · ${NumberFormat('0.#', copy.localeCode).format(guidance.effort)} / 10',
                                  style: const TextStyle(
                                      color: _silver,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500))),
                      ]),
                ])),
          ]),
          if (!rest && guidance.summary.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(guidance.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: _muted, fontSize: 12, height: 1.45)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: _line),
          CupertinoButton(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              onPressed: rest ? onTrain : onSession,
              child: Row(children: [
                Icon(
                    rest
                        ? CupertinoIcons.calendar
                        : complete
                            ? CupertinoIcons.check_mark_circled
                            : CupertinoIcons.play_circle,
                    size: 21,
                    color: _blue),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(actionLabel,
                        style: TextStyle(
                            fontFamily: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontFamily,
                            color: _blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500))),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: _muted),
              ])),
        ]));
  }
}

class _NutritionCard extends StatelessWidget {
  final HomeNutrition? nutrition;
  final FitAiCopy copy;
  final VoidCallback onTap;
  const _NutritionCard(
      {required this.nutrition, required this.copy, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    if (n == null) {
      return _TodaySurface(
          onTap: onTap,
          child: Text(copy.text('todayNutritionEmpty'),
              style: const TextStyle(color: _muted, fontSize: 13)));
    }
    return _TodaySurface(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CaloriesHeader(calories: n.calories, copy: copy),
          const SizedBox(height: 16),
          _Macro(
              label: copy.text('protein'),
              target: n.protein,
              color: const Color(0xFF8BAAFF)),
          const SizedBox(height: 16),
          _Macro(
              label: copy.text('carbohydrates'),
              target: n.carbs,
              color: const Color(0xFFB3A1DF)),
          const SizedBox(height: 16),
          _Macro(
              label: copy.text('fat'),
              target: n.fat,
              color: const Color(0xFFE1C47E)),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(CupertinoIcons.drop, color: Color(0xFFB0B0B0), size: 18),
            const SizedBox(width: 9),
            Expanded(
                child: Text(copy.text('water'),
                    style: const TextStyle(color: Colors.white, fontSize: 12))),
            Flexible(
                child: Text(
                    '${(n.water.consumed / 1000).toStringAsFixed(2)}${n.water.target > 0 ? ' / ${(n.water.target / 1000).toStringAsFixed(1)}' : ''} L',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: Color(0xFFB7B7B7), fontSize: 12))),
          ]),
          if (n.water.target > 0) ...[
            const SizedBox(height: 11),
            _Progress(
                value: n.water.progress,
                color: const Color(0xFFB0B0B0),
                height: 4)
          ],
        ]));
  }
}

class _CaloriesHeader extends StatelessWidget {
  final MacroTarget calories;
  final FitAiCopy copy;
  const _CaloriesHeader({required this.calories, required this.copy});
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final stack = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final summary =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(copy.text('calories'),
              style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
              NumberFormat.decimalPattern(copy.localeCode)
                  .format(calories.consumed),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.5)),
          const SizedBox(height: 3),
          Text(calories.target > 0 ? '/ ${calories.target} kcal' : 'kcal',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ]);
        final donut = Semantics(
            label:
                '${copy.text('calories')}: ${calories.consumed} / ${calories.target} kcal',
            excludeSemantics: true,
            child: SizedBox(
                width: 66,
                height: 66,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                      child: CircularProgressIndicator(
                          value: calories.progress,
                          strokeWidth: 3.5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: const Color(0xFF383838),
                          valueColor: const AlwaysStoppedAnimation(_silver))),
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${(calories.progress * 100).round()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(copy.text('todayOfGoal'),
                                style: const TextStyle(
                                    color: _muted, fontSize: 9)),
                          ]))),
                ])));
        if (calories.target <= 0) return summary;
        if (stack) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 12), donut]);
        }
        return Row(children: [
          Expanded(child: summary),
          const SizedBox(width: 14),
          donut
        ]);
      });
}

class _Macro extends StatelessWidget {
  final String label;
  final MacroTarget target;
  final Color color;
  const _Macro(
      {required this.label, required this.target, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: Color(0xFFC4C4C4), fontSize: 12))),
          Text(
              '${target.consumed}${target.target > 0 ? ' / ${target.target}' : ''} g',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
        if (target.target > 0) ...[
          const SizedBox(height: 8),
          _Progress(value: target.progress, color: color, height: 3)
        ],
      ]);
}

class _Progress extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const _Progress(
      {required this.value, required this.color, required this.height});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: height,
          backgroundColor: const Color(0xFF363636),
          valueColor: AlwaysStoppedAnimation(color)));
}

class _WeekCard extends StatelessWidget {
  final ValueChanged<DateTime>? onDateSelected;
  final List<WeekDay> days;
  final DateTime today;
  final String locale;
  final FitAiCopy copy;
  const _WeekCard(
      {required this.days,
      required this.today,
      required this.locale,
      required this.copy,
      this.onDateSelected});
  @override
  Widget build(BuildContext context) {
    final monday =
        DateUtils.dateOnly(today).subtract(Duration(days: today.weekday - 1));
    return _TodaySurface(
        key: const ValueKey('today-weekly-rhythm'),
        child: Row(
            children: days.take(7).toList().asMap().entries.map((entry) {
          final day = entry.value;
          final date = monday.add(Duration(days: entry.key));
          final complete = day.status == 'COMPLETED';
          final rest = day.status == 'REST_DAY';
          final selected = DateUtils.isSameDay(date, today);
          return Expanded(
              child: Semantics(
                  label:
                      '${DateFormat('EEEE', locale).format(date)}: ${day.status}',
                  button: true,
                  selected: selected,
                  onTap: onDateSelected == null
                      ? null
                      : () => onDateSelected!(date),
                  excludeSemantics: true,
                  child: InkResponse(
                      key: ValueKey(
                          'today-week-day-${DateFormat('yyyy-MM-dd').format(date)}'),
                      onTap: onDateSelected == null
                          ? null
                          : () => onDateSelected!(date),
                      radius: 26,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('EEEEE', locale).format(date),
                                    style: TextStyle(
                                        color: selected ? Colors.white : _muted,
                                        fontSize: 11)),
                                const SizedBox(height: 10),
                                Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: complete
                                            ? _silver
                                            : const Color(0xFF2D2D2D),
                                        border: selected
                                            ? Border.all(
                                                color: _silver, width: 1)
                                            : null),
                                    child: complete
                                        ? const Icon(CupertinoIcons.check_mark,
                                            color: Color(0xFF242424), size: 14)
                                        : rest
                                            ? const Icon(CupertinoIcons.moon,
                                                color: _muted, size: 12)
                                            : Text('${date.day}',
                                                style: TextStyle(
                                                    color: selected
                                                        ? Colors.white
                                                        : _muted,
                                                    fontSize: 11))),
                              ])))));
        }).toList()));
  }
}

class _RecoveryChart extends StatefulWidget {
  final List<RecoveryPoint> history;
  final DateTime today;
  final String locale;
  final FitAiCopy copy;
  const _RecoveryChart(
      {super.key,
      required this.history,
      required this.today,
      required this.locale,
      required this.copy});
  @override
  State<_RecoveryChart> createState() => _RecoveryChartState();
}

class _RecoveryChartState extends State<_RecoveryChart> {
  int _selected = 0, _sample = 6;

  void _selectMetric(int index) {
    if (_selected == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  void _selectDay(int index) {
    if (_sample == index) return;
    HapticFeedback.selectionClick();
    setState(() => _sample = index);
  }

  String? get _hrvMethod => widget.history
      .where((p) => p.hrv != null && p.hrvMethod != null)
      .lastOrNull
      ?.hrvMethod;
  double? _value(RecoveryPoint p) => switch (_selected) {
        0 => p.recoveryScore?.toDouble(),
        1 => p.hrvMethod == _hrvMethod ? p.hrv : null,
        2 => p.sleepHours,
        _ => p.restingHr?.toDouble(),
      };
  String _display(double value) => switch (_selected) {
        0 => '${value.round()} / 100',
        1 => '${value.round()} ms',
        2 => '${(value * 60).round() ~/ 60} h ${(value * 60).round() % 60} m',
        _ => '${value.round()} bpm',
      };
  String? _comparison(List<double?> values) {
    final today = values[6];
    final previous = values.take(6).whereType<double>().toList();
    if (_sample != 6 || today == null || previous.length < 3) return null;
    final difference =
        today - previous.reduce((a, b) => a + b) / previous.length;
    final rounded = (difference.abs() * (_selected == 2 ? 60 : 1)).round();
    if (rounded == 0) return widget.copy.text('todayAtAverage');
    final unit =
        switch (_selected) { 0 => 'pts', 1 => 'ms', 2 => 'min', _ => 'bpm' };
    return widget.copy
        .text(difference > 0 ? 'todayAboveAverage' : 'todayBelowAverage')
        .replaceAll('{value}', '$rounded $unit');
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
        7,
        (i) =>
            DateUtils.dateOnly(widget.today).subtract(Duration(days: 6 - i)));
    final values = dates.map((date) {
      final point = widget.history
          .where((p) => DateUtils.isSameDay(date, p.date))
          .firstOrNull;
      return point == null ? null : _value(point);
    }).toList();
    final comparison = _comparison(values);
    final hasValues = values.any((value) => value != null);
    final duration = DSMotion.duration(context, DSMotion.selection);
    final labels = ['recovery', 'hrv', 'todaySleep', 'todayRhr'];
    return _TodaySurface(
        key: const ValueKey('today-chart-card'),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(
                    '${widget.copy.text('todaySevenDays')} · ${DateFormat('d MMM', widget.locale).format(dates[_sample])}',
                    style: const TextStyle(color: _muted, fontSize: 11))),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
                    values[_sample] == null ? '—' : _display(values[_sample]!),
                    key: const ValueKey('today-chart-value'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 5),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: List.generate(
                      4,
                      (index) => Semantics(
                          button: true,
                          selected: _selected == index,
                          child: TextButton(
                              onPressed: () => _selectMetric(index),
                              style: TextButton.styleFrom(
                                  foregroundColor: _selected == index
                                      ? Colors.white
                                      : _muted,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  minimumSize: const Size(44, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: Text(widget.copy.text(labels[index]),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500))))))),
          const SizedBox(height: 6),
          AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !hasValues
                  ? const Padding(
                      key: ValueKey('today-chart-empty'),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Icon(CupertinoIcons.chart_bar, size: 18, color: _muted),
                        SizedBox(width: 10),
                        Expanded(
                            child: FitnessText('Your trend builds as you log.',
                                style: TextStyle(
                                    color: _muted, fontSize: 12, height: 1.4))),
                      ]))
                  : SizedBox(
                      height: 65,
                      child: Stack(children: [
                        Positioned.fill(
                            bottom: 19,
                            child: RepaintBoundary(
                                child: MotionProgress(
                                    dataKey:
                                        '$_selected:${dates.first.toIso8601String()}:${values.join('|')}',
                                    builder: (context, progress) => CustomPaint(
                                        painter: _TrendPainter(
                                            progress: progress,
                                            values: values,
                                            selectedIndex: _sample,
                                            color: _selected == 1
                                                ? const Color(0xFFB3A1DF)
                                                : _selected == 2
                                                    ? const Color(0xFFE1C47E)
                                                    : const Color(0xFF8BAAFF),
                                            bars: _selected == 0 ||
                                                _selected == 2,
                                            fixedMax: _selected == 0
                                                ? 100
                                                : _selected == 2
                                                    ? 12
                                                    : null))))),
                        Row(
                            children: List.generate(
                                7,
                                (i) => Expanded(
                                    child: Semantics(
                                        button: true,
                                        selected: i == _sample,
                                        label:
                                            '${DateFormat('EEE d MMM', widget.locale).format(dates[i])}: ${values[i] == null ? widget.copy.text('todayMissing') : _display(values[i]!)}',
                                        excludeSemantics: true,
                                        child: GestureDetector(
                                            key: ValueKey('today-chart-day-$i'),
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _selectDay(i),
                                            child: Column(children: [
                                              const Expanded(
                                                  child: SizedBox.expand()),
                                              Text(
                                                  DateFormat('EEEEE',
                                                          widget.locale)
                                                      .format(dates[i]),
                                                  style: TextStyle(
                                                      color: i == _sample
                                                          ? Colors.white
                                                          : _muted,
                                                      fontSize: 10,
                                                      fontWeight: i == 6
                                                          ? FontWeight.w600
                                                          : FontWeight.w400)),
                                              const SizedBox(height: 2),
                                            ])))))),
                      ]))),
          if (comparison != null) ...[
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(comparison,
                    key: const ValueKey('today-chart-comparison'),
                    style: const TextStyle(
                        color: _muted, fontSize: 11, height: 1.3))),
          ],
        ]));
  }
}

class _TrendPainter extends CustomPainter {
  final List<double?> values;
  final Color color;
  final bool bars;
  final int selectedIndex;
  final double? fixedMax;
  final double progress;
  const _TrendPainter(
      {required this.values,
      required this.bars,
      required this.selectedIndex,
      required this.color,
      this.progress = 1,
      this.fixedMax});
  @override
  void paint(Canvas canvas, Size size) {
    final samples = values.whereType<double>().toList();
    final low = bars || samples.isEmpty
        ? 0.0
        : samples.reduce((a, b) => a < b ? a : b) - 5;
    final high = fixedMax ??
        (samples.isEmpty ? 1.0 : samples.reduce((a, b) => a > b ? a : b) + 5);
    final paint = Paint()
      ..color = _silver
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final cell = size.width / 7;
    Offset? previous;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final x = cell * (i + .5);
      if (value == null) {
        canvas.drawLine(
            Offset(x - 3, size.height - 2),
            Offset(x + 3, size.height - 2),
            Paint()
              ..color = const Color(0xFF444444)
              ..strokeWidth = 1.5);
        previous = null;
        continue;
      }
      final fraction = ((value - low) / (high - low)).clamp(0.0, 1.0);
      final point =
          Offset(x, size.height - 4 - fraction * progress * (size.height - 9));
      paint.color = color.withValues(
          alpha: i == selectedIndex
              ? 1
              : i == 6
                  ? .8
                  : .4);
      if (i == selectedIndex) {
        canvas.drawLine(
            Offset(x, 1),
            Offset(x, size.height),
            Paint()
              ..color = Colors.white.withValues(alpha: .07)
              ..strokeWidth = 1);
      }
      if (bars) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTRB(x - 7, point.dy, x + 7, size.height - 1),
                const Radius.circular(3)),
            paint);
      } else {
        if (previous != null) canvas.drawLine(previous, point, paint);
        canvas.drawCircle(point, i == selectedIndex ? 3.5 : 2, paint);
        previous = point;
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.progress != progress ||
      old.selectedIndex != selectedIndex ||
      old.color != color ||
      old.bars != bars ||
      old.fixedMax != fixedMax ||
      !_sameValues(old.values, values);
  bool _sameValues(List<double?> a, List<double?> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((same) => same);
}

void _showReadiness(BuildContext context, HomeReadiness? r, FitAiCopy copy,
    {DateTime? date,
    VoidCallback? onSleep,
    HomeHealthMetrics? health,
    Map<String, dynamic>? sleepLog,
    bool noWearable = false}) {
  if (r == null) {
    final availability = ReadinessAvailability.fromMetrics(health,
        sleepLog: sleepLog, noWearable: noWearable);
    showModalBottomSheet<void>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.text('readiness'),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 8),
                  if (date != null)
                    Text(DateFormat('EEE, d MMM', copy.localeCode).format(date),
                        style: const TextStyle(color: _muted, fontSize: 13)),
                  const SizedBox(height: 24),
                  FitnessText(availability.title,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 10),
                  FitnessText(availability.description,
                      style: const TextStyle(
                          color: _muted, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 12),
                  _ReadinessInputRow(
                      label: availability.enteredSleep
                          ? 'Entered sleep'
                          : 'Synced sleep',
                      available: availability.sleep),
                  if (noWearable) ...[
                    _ReadinessInputRow(
                        label: 'Rest', available: sleepLog?['rested'] != null),
                    _ReadinessInputRow(
                        label: 'Energy',
                        available: sleepLog?['energy'] != null),
                    _ReadinessInputRow(
                        label: 'Soreness',
                        available: sleepLog?['soreness'] != null),
                  ] else ...[
                    _ReadinessInputRow(
                        label: 'Synced heart readings',
                        available: availability.heart),
                    if (!availability.heart)
                      TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.of(context).push(AppPageRoute<void>(
                                page: const SleepPreferencesView()));
                          },
                          child: const FitnessText('Sleep preferences')),
                  ],
                  if (health != null) ...[
                    const SizedBox(height: 24),
                    const FitnessText('Recorded readings',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 24, runSpacing: 18, children: [
                      if (health.steps != null)
                        _Metric(
                            label: copy.text('todaySteps'),
                            value: NumberFormat.decimalPattern(copy.localeCode)
                                .format(health.steps),
                            unit: ''),
                      if (health.activeCalories != null)
                        _Metric(
                            label: copy.text('todayActiveEnergy'),
                            value: '${health.activeCalories!.round()}',
                            unit: 'kcal'),
                      if (health.sleepMinutes != null)
                        _Metric(
                            label: copy.text('todaySleep'),
                            value: '${health.sleepMinutes!.round() ~/ 60}',
                            unit: 'h ${health.sleepMinutes!.round() % 60} m'),
                      if (health.hrv != null)
                        _Metric(
                            label: copy.text('hrv'),
                            value: '${health.hrv!.round()}',
                            unit: 'ms'),
                      if (health.restingHR != null)
                        _Metric(
                            label: copy.text('restingHeartRate'),
                            value: '${health.restingHR!.round()}',
                            unit: 'bpm'),
                    ]),
                  ],
                  if (onSleep != null) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          onSleep();
                        },
                        icon: const Icon(CupertinoIcons.moon_stars),
                        label: FitnessText(
                            noWearable && availability.missingAnswers.isNotEmpty
                                ? 'Complete check-in'
                                : sleepLog == null
                                    ? 'Log sleep'
                                    : 'Edit sleep')),
                  ],
                ]),
          )),
    );
    return;
  }
  final route = AppPageRoute<bool>(
      page: ReadinessDetailView(
    readiness: r,
    sleepLog: sleepLog,
    onEdit: onSleep == null ? null : () => Navigator.of(context).pop(true),
  ));
  Navigator.of(context).push(route).then((edit) async {
    await route.completed;
    if (edit == true && context.mounted) onSleep?.call();
  });
}

class _ReadinessInputRow extends StatelessWidget {
  final String label;
  final bool available;
  const _ReadinessInputRow({required this.label, required this.available});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(
            available
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.minus_circle,
            size: 18,
            color: available ? _silver : _muted),
        const SizedBox(width: 10),
        Expanded(
            child: FitnessText(label,
                style: const TextStyle(color: _muted, fontSize: 13))),
        const SizedBox(width: 12),
        FitnessText(available ? 'Recorded' : 'Missing',
            style: const TextStyle(color: _silver, fontSize: 12))
      ]));
}
