import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../models/home_models.dart';
import '../../body_scan/models/body_assessment_models.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../../body_scan/views/body_entry_view.dart';
import '../../nutrition/views/hydration_view.dart';
import '../../nutrition/repositories/nutrition_repository.dart';
import '../../progress/components/progress_photos.dart';
import '../../wellness/models/sleep_edit_window.dart';
import '../../wellness/views/daily_check_in_sheet.dart';
import '../repositories/today_repository.dart';

class UpdateStatsView extends StatefulWidget {
  final DateTime date;
  final HomeData? initial;
  final DateTime Function()? clock;
  const UpdateStatsView(
      {super.key, required this.date, this.initial, this.clock});
  @override
  State<UpdateStatsView> createState() => _UpdateStatsViewState();
}

class _UpdateStatsViewState extends State<UpdateStatsView> {
  HomeData? _home;
  BodyOverview? _body;
  bool _failed = false, _busy = false, _loading = true;
  int _request = 0;
  bool _homeChanged = false;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  String get _date => CacheScope.todayKey(widget.date);
  bool get _today => DateUtils.isSameDay(widget.date, _now);
  bool get _future =>
      DateUtils.dateOnly(widget.date).isAfter(DateUtils.dateOnly(_now));
  bool get _preview => AppDataMode.shared.preview;
  String copy(String text) => fitnessText(context, text);

  @override
  void initState() {
    super.initState();
    if (widget.initial?.calendarDate == _date) _home = widget.initial;
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _languageChanged() {
    _request++;
    setState(() {
      _home = null;
      _body = null;
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    final owner = await CacheScope.userId();
    var failed = false;
    // Keep these independent: a measurement outage must not hide saved sleep.
    final results = await Future.wait<Object?>([
      (!refresh && _home != null
              ? Future<HomeData?>.value(_home)
              : TodayRepository.shared
                  .loadDate(widget.date, forceRefresh: refresh))
          .catchError((Object _) {
        failed = true;
        return null;
      }),
      BodyAssessmentRepository.shared
          .load()
          .then<BodyOverview?>((value) => value)
          .catchError((Object _) {
        failed = true;
        return null;
      }),
    ]);
    final currentOwner = await CacheScope.userId();
    if (!mounted || request != _request || owner != currentOwner) {
      return;
    }
    setState(() {
      _home = results[0] as HomeData? ?? _home;
      _body = results[1] as BodyOverview? ?? _body;
      _failed = failed ||
          results[0] == null ||
          TodayRepository.shared.refreshFailedFor(widget.date);
      _loading = false;
    });
  }

  Future<void> _open(Widget Function() page) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result =
          await Navigator.of(context).push(AppPageRoute<Object?>(page: page()));
      if (mounted) {
        final current = TodayRepository.shared.current;
        if (current?.calendarDate == _date) _home = current;
        final refresh = result != null || _homeChanged;
        _homeChanged = false;
        await _load(refresh: refresh);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _measurements() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final owner = await CacheScope.userId();
      final overview = await BodyAssessmentRepository.shared.load();
      final currentOwner = await CacheScope.userId();
      if (!mounted || owner != currentOwner) return;
      final records = overview.records
          .where((entry) =>
              entry.recordedDate == _date &&
              entry.status == 'SAVED' &&
              !entry.synthetic)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final saved = await Navigator.of(context).push(AppPageRoute<bool>(
          page: BodyEntryView(
              initialDate: widget.date, existing: records.firstOrNull)));
      if (mounted && saved == true) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: DSColors.bgRaised,
            content: Text(
                copy('Could not load your measurements. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _logWater(int ml) async {
    final saved = await NutritionRepository.shared.logWater(ml);
    if (saved) _homeChanged = true;
    return saved;
  }

  String get _weightLabel {
    final records = _body?.records
            .where((e) =>
                e.status == 'SAVED' &&
                !e.synthetic &&
                e.recordedDate.compareTo(_date) <= 0 &&
                e.metrics['weightKg'] != null &&
                !e.metrics['weightKg']!.isPhotoEstimate)
            .toList() ??
        [];
    records.sort((a, b) => b.recordedDate.compareTo(a.recordedDate));
    if (records.isEmpty) return '';
    final entry = records.first;
    final value = entry.metrics['weightKg']!.display('kg');
    if (entry.recordedDate == _date) return value;
    final date =
        DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
            .format(DateTime.parse(entry.recordedDate));
    return '$value · $date';
  }

  @override
  Widget build(BuildContext context) {
    final sleep = (_home?.sleepLog?['sleepMinutes'] as num?)?.toInt();
    final water = _home?.nutrition.water.consumed;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FitnessTheme(
        child: Scaffold(
            backgroundColor: DSColors.bg,
            appBar: AppBar(
                foregroundColor: DSColors.silver,
                title: Text(copy('Update your stats'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w500))),
            body: SafeArea(
                top: false,
                child: RefreshIndicator(
                    color: DSColors.silver,
                    onRefresh: () => _load(refresh: true),
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Text(DateFormat.MMMEd(locale).format(widget.date),
                              key: const ValueKey('update-stats-date'),
                              style: const TextStyle(
                                  color: DSColors.muted, fontSize: 12)),
                          const SizedBox(height: 18),
                          if (_preview || _future)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                    copy(_preview
                                        ? 'Preview · read only'
                                        : 'Future date · read only'),
                                    style: const TextStyle(
                                        color: DSColors.muted, fontSize: 12))),
                          Material(
                              color: DSColors.bgElevated,
                              clipBehavior: Clip.antiAlias,
                              borderRadius: BorderRadius.circular(18),
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border:
                                          Border.all(color: DSColors.border)),
                                  child: Column(children: [
                                    _StatsRow(
                                        id: 'sleep',
                                        title: copy('Sleep & recovery'),
                                        value: sleep == null
                                            ? null
                                            : fitnessText(context,
                                                '{hours}h {minutes}m', values: {
                                                'hours':
                                                    NumberFormat.decimalPattern(
                                                            locale)
                                                        .format(sleep ~/ 60),
                                                'minutes':
                                                    NumberFormat.decimalPattern(
                                                            locale)
                                                        .format(sleep % 60)
                                              }),
                                        hint: !canEditSleepDate(widget.date, _now)
                                            ? copy(_future
                                                ? futureSleepReadOnly
                                                : pastSleepReadOnly)
                                            : '',
                                        onTap: !_preview &&
                                                !_busy &&
                                                !_loading &&
                                                _home != null &&
                                                canEditSleepDate(
                                                    widget.date, _now)
                                            ? () => _open(() =>
                                                DailyCheckInSheet(
                                                    date: widget.date,
                                                    entry: _home?.sleepLog,
                                                    clock: widget.clock,
                                                    syncedSleepMinutes: _home
                                                                ?.healthMetrics
                                                                ?.date ==
                                                            _date
                                                        ? _home?.healthMetrics
                                                            ?.sleepMinutes
                                                            ?.round()
                                                        : null,
                                                    fullScreen: true))
                                            : null),
                                    const _RowDivider(),
                                    _StatsRow(
                                        id: 'measurements',
                                        title: copy('Body measurements'),
                                        value: _weightLabel.isEmpty
                                            ? null
                                            : _weightLabel,
                                        onTap: !_preview && !_future && !_busy
                                            ? _measurements
                                            : null),
                                    const _RowDivider(),
                                    _StatsRow(
                                        id: 'water',
                                        title: copy('Water intake'),
                                        value: water == null
                                            ? null
                                            : '${NumberFormat.decimalPattern(locale).format(water)} ml',
                                        hint: !_today
                                            ? copy(
                                                'Water entries can be added for today.')
                                            : '',
                                        onTap: !_preview && _today && !_busy
                                            ? () => _open(() => HydrationView(
                                                date: widget.date,
                                                logWater: _logWater,
                                                initialConsumedMl: _home
                                                    ?.nutrition.water.consumed,
                                                initialTargetMl: _home
                                                    ?.nutrition.water.target,
                                                clock: widget.clock))
                                            : null),
                                    const _RowDivider(),
                                    _StatsRow(
                                        id: 'photos',
                                        title: copy('Progress photos'),
                                        onTap: !_preview && !_busy
                                            ? () => _open(() =>
                                                const ProgressPhotoGallery())
                                            : null),
                                  ]))),
                          if (_loading || _busy)
                            const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator(
                                    color: DSColors.silver,
                                    backgroundColor: DSColors.border,
                                    minHeight: 2)),
                          if (_failed)
                            Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                    onPressed: () => _load(refresh: true),
                                    child: Text(
                                        copy('Could not refresh · Retry'),
                                        style: const TextStyle(
                                            color: DSColors.muted,
                                            fontSize: 12)))),
                        ])))));
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: .5, color: DSColors.border));
}

class _StatsRow extends StatelessWidget {
  final String id, title, hint;
  final String? value;
  final VoidCallback? onTap;
  const _StatsRow(
      {required this.id,
      required this.title,
      this.value,
      this.hint = '',
      this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
      message: hint,
      child: InkWell(
          key: ValueKey('update-stats-$id'),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      if (value != null) ...[
                        const SizedBox(height: 5),
                        Text(value!,
                            style: const TextStyle(
                                color: DSColors.muted, fontSize: 12))
                      ],
                    ])),
                const SizedBox(width: 12),
                if (onTap != null)
                  const Icon(CupertinoIcons.chevron_right,
                      size: 12, color: DSColors.muted)
                else if (hint.isNotEmpty)
                  Text(fitnessText(context, 'Read only'),
                      style:
                          const TextStyle(color: DSColors.muted, fontSize: 11)),
              ]))));
}
