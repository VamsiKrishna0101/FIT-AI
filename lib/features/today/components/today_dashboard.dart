import '../../../core/components/session_overview_card.dart';
import 'package:flutter/foundation.dart';
import '../../../core/components/motion.dart';
import '../../../core/components/content_transition.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/localization/setcraft_copy.dart';
import '../../../models/home_models.dart';
import '../../history/repositories/history_repository.dart';
import 'readiness_summary.dart';
import '../views/readiness_detail_view.dart';
import '../models/session_guidance.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/components/profile_avatar.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../wellness/models/sleep_edit_window.dart';
import 'weekly_rhythm_calendar.dart';
import '../../nutrition/components/nutrition_summary_card.dart';
import '../../nutrition/components/water_intake_card.dart';

const _surface = DSColors.bgCard;
const _muted = DSColors.muted;
const _silver = DSColors.silver;
const _line = DSColors.border;

/// Today-specific surfaces and layout. Other dashboard tabs keep their styling.
class TodayDashboard extends StatelessWidget {
  final HomeData? data;
  final List<RecoveryPoint> recovery;
  final ValueListenable<List<RecoveryPoint>>? recoveryUpdates;
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
  final VoidCallback? onAddMeal;
  final VoidCallback? onWater;
  final VoidCallback? onSleep;

  const TodayDashboard({
    super.key,
    required this.data,
    this.recovery = const [],
    this.recoveryUpdates,
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
    this.onAddMeal,
    this.onWater,
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
    final copy = SetcraftCopy.of(context);
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
            reading.score.isFinite &&
            reading.source == 'check_in_estimate' &&
            !RegExp('sample|preview|demo', caseSensitive: false)
                .hasMatch(reading.source) &&
            (selectedDate == null ||
                reading.date == DateFormat('yyyy-MM-dd').format(date))
        ? reading
        : null;
    final days = weekDays ?? data?.weeklyStreak ?? const <WeekDay>[];
    final rhythmDays = days.isEmpty && onDateSelected != null
        ? List.generate(7, (_) => const WeekDay(day: '', status: 'UNAVAILABLE'))
        : days;
    final actualToday = now ?? DateTime.now();
    final editSleep = canEditSleepDate(date, actualToday) ? onSleep : null;
    final previousWeek =
        sleepWeekStart(date).isBefore(sleepWeekStart(actualToday));
    void openReadiness() {
      _showReadiness(context, r, copy,
          date: date,
          onSleep: editSleep,
          health: health,
          sleepLog: data?.sleepLog,
          readOnly: previousWeek);
    }

    Widget buildRecovery(List<RecoveryPoint> points) {
      final history = points
          .where((p) =>
              !DateUtils.dateOnly(p.date).isAfter(DateUtils.dateOnly(date)) &&
              p.sleepHours != null)
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _RecoveryChart(
            key: ValueKey('recovery-${DateFormat('yyyy-MM-dd').format(date)}'),
            history: history,
            today: date,
            locale: locale,
            copy: copy),
      );
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
                if (rhythmDays.isNotEmpty) ...[
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Semantics(
                              header: true,
                              child: Text(copy.text('weekProgress'),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -.3))),
                          if (!loading &&
                              !previousWeek &&
                              (data?.user.streakDays ?? 0) > 0) ...[
                            const SizedBox(height: 5),
                            Text(
                                '${data!.user.streakDays} ${copy.text(data!.user.streakDays == 1 ? 'todayDay' : 'days')}',
                                style: const TextStyle(
                                    fontSize: 11, height: 1.4, color: _muted)),
                          ],
                        ])),
                    const SizedBox(width: 12),
                    WeeklyRhythmCalendarButton(
                        selectedDate: date,
                        today: actualToday,
                        onSelected: onDateSelected),
                  ]),
                  const SizedBox(height: 12),
                  _WeekCard(
                      days: rhythmDays,
                      today: date,
                      locale: locale,
                      copy: copy,
                      onDateSelected: onDateSelected),
                  const SizedBox(height: 24),
                ],
                ContentTransition(
                    child: Column(
                        key: ValueKey(
                            'today-content-${DateFormat('yyyy-MM-dd').format(date)}-${loading ? 'loading' : loadFailed ? 'error' : 'ready'}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                        _Section(
                            key: const ValueKey('today-section-readiness'),
                            title: copy.text('recovery'),
                            onTap: openReadiness),
                        const SizedBox(height: 12),
                        _TodaySurface(
                            key: const ValueKey('today-readiness-card'),
                            hero: true,
                            onTap: openReadiness,
                            child: ReadinessSummary(
                                readiness: r,
                                sleepLog: data?.sleepLog,
                                health: health,
                                now: actualToday,
                                date: date,
                                readOnly: previousWeek)),
                        const SizedBox(height: 24),
                        _Section(
                            title: historical
                                ? '${copy.text('training')} · $dateLabel'
                                : copy.text('todaySessionHeading'),
                            onTap: onSession),
                        const SizedBox(height: 12),
                        _SessionCard(
                            key: const ValueKey('today-session-card'),
                            workout: data?.todayWorkout,
                            copy: copy,
                            onSession: onSession,
                            onTrain: onTrain),
                        const SizedBox(height: 24),
                        ValueListenableBuilder<List<RecoveryPoint>>(
                            valueListenable: recoveryUpdates ??
                                AlwaysStoppedAnimation(recovery),
                            builder: (context, points, _) =>
                                ContentResize(child: buildRecovery(points))),
                        _Section(
                            key: const ValueKey('today-section-nutrition'),
                            title: copy.text('nutrition'),
                            onTap: onNutrition),
                        const SizedBox(height: 12),
                        _NutritionCard(
                            nutrition: data?.nutrition,
                            onAddMeal: onAddMeal,
                            copy: copy,
                            onTap: onNutrition),
                        const SizedBox(height: 16),
                        WaterIntakeCard(
                            consumedMl: data?.nutrition.water.consumed,
                            targetMl: data?.nutrition.water.target,
                            onTap: onWater),
                      ],
                    ])),
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
  final SetcraftCopy copy;
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

class _TodaySurface extends StatelessWidget {
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
                    color: hero ? DSColors.borderHi : DSColors.border,
                    width: .7)),
            child: InkWell(
                onTap: onTap, child: Padding(padding: padding, child: child))));

    return MotionPress(enabled: onTap != null, child: surface);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _Section({super.key, required this.title, this.onTap});
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
            ])),
      ));
}

int _readinessScore(HomeReadiness r) =>
    (r.score <= 10 ? r.score * 10 : r.score).clamp(0, 100).round();

class _SessionCard extends StatelessWidget {
  final HomeTodayWorkout? workout;
  final SetcraftCopy copy;
  final VoidCallback onSession, onTrain;
  const _SessionCard(
      {super.key,
      required this.workout,
      required this.copy,
      required this.onSession,
      required this.onTrain});
  @override
  Widget build(BuildContext context) {
    final w = workout;
    final complete = w?.status == 'COMPLETED';
    final rest = w == null || w.status == 'REST_DAY';
    final progress = w?.status == 'IN_PROGRESS';
    final guidance = SessionGuidance.fromNote(w?.aiNote,
        fallback: copy.text('todayAdaptiveEffort'));
    final actionLabel = copy.text(rest
        ? 'openPlan'
        : complete
            ? 'todayReviewSession'
            : progress
                ? 'todayContinueSession'
                : 'startSession');
    return SessionOverviewCard(
      titleFirst: true,
      status: w == null
          ? SessionOverviewStatus.unavailable
          : complete
              ? SessionOverviewStatus.completed
              : rest
                  ? SessionOverviewStatus.restDay
                  : progress
                      ? SessionOverviewStatus.inProgress
                      : SessionOverviewStatus.notStarted,
      title:
          rest ? copy.text('todayNoSession') : w.sessionTitle ?? w.workoutTitle,
      metrics: [
        if (!rest && w.durationMinutes > 0)
          '${w.durationMinutes} ${copy.text('minutes')}',
        if (!rest && w.exerciseCount > 0)
          '${w.exerciseCount} ${copy.text('exercises')}',
      ],
      caption: !rest && guidance.effort != null
          ? Text(
              '${copy.text('todayTargetEffort')} · ${NumberFormat('0.#', copy.localeCode).format(guidance.effort)} / 10',
              key: const ValueKey('today-effort-pill'),
              style: const TextStyle(color: _muted, fontSize: 11))
          : null,
      actionLabel: actionLabel,
      onAction: rest ? onTrain : onSession,
      onTap: rest ? onTrain : onSession,
      primary: !rest,
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final VoidCallback? onAddMeal;
  final HomeNutrition? nutrition;
  final SetcraftCopy copy;
  final VoidCallback onTap;
  const _NutritionCard(
      {required this.nutrition,
      required this.copy,
      required this.onTap,
      this.onAddMeal});
  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    if (n == null) {
      return _TodaySurface(
          onTap: onTap,
          child: Text(copy.text('todayNutritionEmpty'),
              style: const TextStyle(color: _muted, fontSize: 13)));
    }
    return NutritionSummaryCard(
        calories: n.calories.consumed,
        calorieTarget: n.calories.target,
        protein: n.protein.consumed,
        proteinTarget: n.protein.target,
        carbs: n.carbs.consumed,
        carbTarget: n.carbs.target,
        fat: n.fat.consumed,
        fatTarget: n.fat.target,
        onAddMeal: onAddMeal,
        onTap: onTap);
  }
}

class _WeekCard extends StatelessWidget {
  final ValueChanged<DateTime>? onDateSelected;
  final List<WeekDay> days;
  final DateTime today;
  final String locale;
  final SetcraftCopy copy;
  const _WeekCard(
      {required this.days,
      required this.today,
      required this.locale,
      required this.copy,
      this.onDateSelected});
  @override
  Widget build(BuildContext context) {
    final monday =
        DateTime(today.year, today.month, today.day - today.weekday + 1);
    return _TodaySurface(
        key: const ValueKey('today-weekly-rhythm'),
        child: Row(
            children: days.take(7).toList().asMap().entries.map((entry) {
          final day = entry.value;
          final date =
              DateTime(monday.year, monday.month, monday.day + entry.key);
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
  final SetcraftCopy copy;
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
  static const _dayCount = 6;
  static const _barHeight = 44.0;
  int _sample = _dayCount - 1;

  void _selectDay(int index) {
    if (_sample == index) return;
    HapticFeedback.selectionClick();
    setState(() => _sample = index);
  }

  String _display(double value) =>
      '${(value * 60).round() ~/ 60} h ${(value * 60).round() % 60} m';

  Widget _day(int index, DateTime date, double? hours, double scale,
      Duration duration) {
    final latest = index == _dayCount - 1;
    final selected = index == _sample;
    final color = latest ? const Color(0xFFF2F2F2) : const Color(0xFF797979);
    return Expanded(
        child: Semantics(
            button: true,
            selected: selected,
            label:
                '${DateFormat('EEE d MMM', widget.locale).format(date)}: ${hours == null ? widget.copy.text('todayMissing') : _display(hours)}',
            excludeSemantics: true,
            child: InkWell(
                key: ValueKey('today-chart-day-$index'),
                onTap: () => _selectDay(index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(children: [
                      SizedBox(
                          height: _barHeight,
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: hours == null
                                  ? Container(
                                      key: ValueKey(
                                          'today-sleep-missing-$index'),
                                      width: 12,
                                      height: 2,
                                      color: latest ? color : _muted)
                                  : FractionallySizedBox(
                                      widthFactor: .62,
                                      child: AnimatedContainer(
                                          key: ValueKey(
                                              'today-sleep-bar-$index'),
                                          duration: duration,
                                          curve: DSMotion.effects,
                                          height: (hours / scale * _barHeight)
                                              .clamp(1.0, _barHeight),
                                          decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: selected && !latest
                                                  ? Border.all(color: _silver)
                                                  : null))))),
                      const SizedBox(height: 8),
                      Text(DateFormat('EEEEE', widget.locale).format(date),
                          maxLines: 1,
                          style: TextStyle(
                              color: latest || selected ? _silver : _muted,
                              fontSize: 10,
                              height: 1.3)),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                          duration: duration,
                          padding: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: selected
                                          ? _silver
                                          : Colors.transparent))),
                          child: Text('${date.day}',
                              maxLines: 1,
                              style: TextStyle(
                                  color: latest || selected
                                      ? Colors.white
                                      : _muted,
                                  fontSize: 11,
                                  height: 1.3,
                                  fontWeight: latest
                                      ? FontWeight.w600
                                      : FontWeight.w400))),
                    ])))));
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
        _dayCount,
        (i) => DateTime(widget.today.year, widget.today.month,
            widget.today.day - (_dayCount - 1) + i));
    final values = dates.map((date) {
      final point = widget.history
          .where((p) => DateUtils.isSameDay(date, p.date))
          .firstOrNull;
      final hours = point?.sleepHours;
      return hours != null && hours.isFinite && hours >= 0 && hours <= 24
          ? hours
          : null;
    }).toList();
    final hasValues = values.any((value) => value != null);
    final scale = values
        .whereType<double>()
        .fold(8.0, (highest, hours) => hours > highest ? hours : highest)
        .ceilToDouble();
    final duration = DSMotion.duration(context, DSMotion.selection);
    final value = Text(
        values[_sample] == null ? '—' : _display(values[_sample]!),
        key: const ValueKey('today-chart-value'),
        style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.2,
            letterSpacing: -.5,
            fontWeight: FontWeight.w600));
    final dateLabel = Text(
        DateFormat('EEE, d MMM', widget.locale).format(dates[_sample]),
        key: const ValueKey('today-chart-date'),
        style: const TextStyle(color: _muted, fontSize: 11, height: 1.4));
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 16;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
          header: true,
          child: const FitnessText('Recorded sleep',
              key: ValueKey('today-recorded-sleep-heading'),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.3))),
      const SizedBox(height: 5),
      const FitnessText('Last 6 days',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.4)),
      const SizedBox(height: 12),
      _TodaySurface(
          key: const ValueKey('today-chart-card'),
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (largeText)
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [value, const SizedBox(height: 5), dateLabel])
            else
              Row(children: [
                Expanded(flex: 3, child: value),
                const SizedBox(width: 12),
                Flexible(
                    flex: 2,
                    child: Align(
                        alignment: Alignment.centerRight, child: dateLabel)),
              ]),
            const SizedBox(height: 14),
            if (!hasValues)
              const Padding(
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
            else
              Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_dayCount,
                      (i) => _day(i, dates[i], values[i], scale, duration))),
          ])),
    ]);
  }
}

void _showReadiness(BuildContext context, HomeReadiness? r, SetcraftCopy copy,
    {DateTime? date,
    VoidCallback? onSleep,
    HomeHealthMetrics? health,
    Map<String, dynamic>? sleepLog,
    bool readOnly = false}) {
  var editRequested = false;
  final route = AppPageRoute<bool>(
      page: ReadinessDetailView(
    readiness: r,
    health: health,
    sleepLog: sleepLog,
    date: date,
    readOnly: readOnly,
    onEdit: onSleep == null
        ? null
        : () {
            if (editRequested) return;
            editRequested = true;
            Navigator.of(context).pop(true);
          },
  ));
  Navigator.of(context).push(route).then((edit) async {
    await route.completed;
    if (edit == true && context.mounted) onSleep?.call();
  });
}
