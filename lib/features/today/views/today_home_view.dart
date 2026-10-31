import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/language_manager.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/ds_colors.dart';
import '../../history/repositories/history_repository.dart';
import '../../../models/home_models.dart';
import '../../nutrition/views/nutrition_view.dart';
import '../../nutrition/views/food_library_view.dart';
import '../../nutrition/views/hydration_view.dart';
import '../../train/views/train_view.dart';
import '../components/today_dashboard.dart';
import '../repositories/today_repository.dart';
import '../../wellness/views/daily_check_in_sheet.dart';
import '../models/daily_check_in_prompt.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/health/health_models.dart';
import '../../wellness/models/sleep_edit_window.dart';
import '../../wellness/models/check_in_state.dart';
import '../../../core/localization/fitness_text.dart';

class TodayHomeView extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenProfile;
  final bool isActive;
  final DateTime Function()? clock;

  const TodayHomeView({
    super.key,
    required this.onSelectTab,
    required this.onOpenProfile,
    this.isActive = true,
    this.clock,
  });

  @override
  State<TodayHomeView> createState() => _TodayHomeViewState();
}

class _TodayHomeViewState extends State<TodayHomeView>
    with WidgetsBindingObserver {
  HomeData? _homeData;
  final _recovery = ValueNotifier<List<RecoveryPoint>>(const []);
  StreamSubscription<HomeData>? _subscription;
  StreamSubscription<HealthSnapshotPayload>? _healthUpdates;
  bool _loading = true;
  bool _loadFailed = false;
  bool _refreshFailed = false;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  late DateTime _selectedDate;
  List<WeekDay> _weekDays = const [];
  int _request = 0;
  String _locale = '';
  bool _checkingPrompt = false, _checkInOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateUtils.dateOnly(_now);
    _locale = LanguageManager.shared.currentLanguage.code;
    LanguageManager.shared.addListener(_languageChanged);
    _homeData = TodayRepository.shared.current;
    _weekDays = _homeData?.weeklyStreak ?? const [];
    _loading = _homeData == null;
    _subscription = TodayRepository.shared.homeStream.listen((data) {
      if (mounted && data.calendarDate == CacheScope.todayKey(_selectedDate)) {
        if (identical(data, _homeData) && !_loading && !_loadFailed) return;
        setState(() {
          _homeData = data;
          _weekDays = data.weeklyStreak;
          _loadFailed = false;
          _refreshFailed =
              TodayRepository.shared.refreshFailedFor(_selectedDate);
          _loading = false;
        });
        _schedulePrompt();
      }
    });
    unawaited(_loadHome());
    _healthUpdates = HealthSyncService.shared.updates.stream.listen((snapshot) {
      if (mounted &&
          widget.isActive &&
          snapshot.date == CacheScope.todayKey(_selectedDate)) {
        // The sync service already refreshes Home and invalidates history.
        unawaited(_loadHome());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      unawaited(_loadHome());
    }
  }

  bool get _canPrompt {
    final date = CacheScope.todayKey(_selectedDate);
    final data = _homeData;
    return mounted &&
        widget.isActive &&
        !_loading &&
        !_loadFailed &&
        !_refreshFailed &&
        !_checkInOpen &&
        !AppDataMode.shared.preview &&
        DateUtils.isSameDay(_selectedDate, _now) &&
        data?.calendarDate == date &&
        ModalRoute.of(context)?.isCurrent == true &&
        data?.sleepLog?['sleepMinutes'] is! num &&
        !(data?.healthMetrics?.date == date &&
            (data?.healthMetrics?.sleepMinutes ?? 0) > 0) &&
        !(data?.readiness?.date == date &&
            (data?.readiness?.sleepMinutes ?? 0) > 0);
  }

  void _schedulePrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybePrompt());
    });
  }

  Future<void> _maybePrompt() async {
    if (_checkingPrompt || !_canPrompt) return;
    _checkingPrompt = true;
    try {
      final date = _selectedDate;
      final owner = await CacheScope.userId();
      if (!_canPrompt || owner == 'anonymous') return;
      if (!await DailyCheckInPrompt.claim(owner, date)) return;
      if (_canPrompt &&
          owner == await CacheScope.userId() &&
          DateUtils.isSameDay(date, _selectedDate)) {
        await _openCheckIn();
      }
    } catch (_) {
      // A preference failure must not interrupt Today or repeatedly prompt.
    } finally {
      _checkingPrompt = false;
    }
  }

  Future<void> _openCheckIn() async {
    if (_checkInOpen ||
        AppDataMode.shared.preview ||
        !canEditSleepDate(_selectedDate, _now)) {
      return;
    }
    final date = _selectedDate;
    _checkInOpen = true;
    try {
      final entry = await showDailyCheckInSheet(context,
          date: date,
          clock: widget.clock,
          entry: _homeData?.sleepLog,
          syncedSleepMinutes:
              _homeData?.healthMetrics?.date == CacheScope.todayKey(date)
                  ? _homeData?.healthMetrics?.sleepMinutes?.round()
                  : null);
      if (!mounted) return;
      if (entry != null &&
          entry['date'] == CacheScope.todayKey(_selectedDate) &&
          _homeData != null) {
        setState(() => _homeData = HomeData.fromJson({
              ..._homeData!.toJson(),
              'sleepLog': entry,
              if (entry.containsKey('readiness'))
                'readiness': entry['readiness'],
              if (entry.containsKey('wearableUsage'))
                'wearableUsage': entry['wearableUsage']
            }));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              backgroundColor: DSColors.bgRaised,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              content: FitnessText(savedCheckInLabel(entry),
                  style: const TextStyle(color: Colors.white))));
        await _loadHome(refresh: true);
      }
    } finally {
      _checkInOpen = false;
    }
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) return;
    _locale = locale;
    setState(() {
      _homeData = null;
      _loading = true;
    });
    unawaited(_loadHome(refresh: true));
  }

  @override
  void didUpdateWidget(covariant TodayHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_loadHome());
    }
  }

  Future<void> _loadHome({bool refresh = false}) async {
    final request = ++_request;
    final date = _selectedDate;
    final locale = LanguageManager.shared.currentLanguage.code;
    final owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    final needsLoading = _homeData?.calendarDate != CacheScope.todayKey(date);
    if (_loading != needsLoading || _loadFailed) {
      setState(() {
        _loading = needsLoading;
        _loadFailed = false;
      });
    }

    // Recovery history loads independently of the main cards.
    final recovery = _loadRecovery(request, owner, locale, refresh, date);
    HomeData? fresh;
    try {
      fresh =
          await TodayRepository.shared.loadDate(date, forceRefresh: refresh);
    } catch (_) {
      // A failed request or cache read must leave loading and offer a retry.
    }
    final currentOwner = await CacheScope.userId();
    if (!mounted ||
        request != _request ||
        owner != currentOwner ||
        locale != LanguageManager.shared.currentLanguage.code) {
      return;
    }
    final refreshFailed = TodayRepository.shared.refreshFailedFor(date);
    if (!identical(fresh, _homeData) ||
        _loading ||
        _loadFailed ||
        _refreshFailed != refreshFailed) {
      setState(() {
        if (fresh != null ||
            _homeData?.calendarDate != CacheScope.todayKey(date)) {
          _homeData = fresh;
        }
        if (fresh != null) _weekDays = fresh.weeklyStreak;
        _loading = false;
        _loadFailed = _homeData == null;
        _refreshFailed = refreshFailed;
      });
    }
    _schedulePrompt();
    await recovery;
  }

  Future<void> _loadRecovery(int request, String owner, String locale,
      bool refresh, DateTime date) async {
    try {
      final recovery = await HistoryRepository.shared
          .getRecovery(days: 14, date: date, forceRefresh: refresh);
      final currentOwner = await CacheScope.userId();
      if (mounted &&
          request == _request &&
          locale == LanguageManager.shared.currentLanguage.code &&
          owner == currentOwner) {
        _recovery.value = recovery;
      }
    } catch (_) {
      // A missing history response must not hide today's saved readings.
    }
  }

  void _selectDate(DateTime date) {
    if (DateUtils.isSameDay(date, _selectedDate) && !_loadFailed) return;
    final retry = _loadFailed;
    setState(() {
      if (!DateUtils.isSameDay(
          sleepWeekStart(date), sleepWeekStart(_selectedDate))) {
        _weekDays = const [];
      }
      _selectedDate = DateUtils.dateOnly(date);
      _loading = true;
    });
    unawaited(_loadHome(refresh: retry));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LanguageManager.shared.removeListener(_languageChanged);
    _subscription?.cancel();
    _healthUpdates?.cancel();
    _recovery.dispose();
    super.dispose();
  }

  void _open(Widget page) => Navigator.of(context).push(
        AppPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DSColors.dashboardBg,
        body: SafeArea(
          bottom: false,
          child: TodayDashboard(
            now: _now,
            selectedDate: _selectedDate,
            onDateSelected: _selectDate,
            weekDays: _weekDays,
            data: _homeData,
            recoveryUpdates: _recovery,
            loading: _loading,
            loadFailed: _loadFailed,
            refreshFailed: _refreshFailed,
            onRefresh: () => _loadHome(refresh: true),
            onProfile: widget.onOpenProfile,
            onSession: () => _open(TrainView(
                standalone: true,
                initialDate: CacheScope.todayKey(_selectedDate))),
            onTrain: () => DateUtils.isSameDay(_selectedDate, _now)
                ? widget.onSelectTab(1)
                : _open(TrainView(
                    standalone: true,
                    initialDate: CacheScope.todayKey(_selectedDate))),
            onNutrition: () => _open(NutritionView(date: _selectedDate)),
            onWater: () => _open(HydrationView(
                date: _selectedDate,
                initialConsumedMl: _homeData?.nutrition.water.consumed,
                initialTargetMl: _homeData?.nutrition.water.target)),
            onAddMeal: DateUtils.isSameDay(_selectedDate, _now)
                ? () => _open(FoodLibraryView(onMealAdded: () {
                      if (mounted) unawaited(_loadHome(refresh: true));
                    }))
                : null,
            onSleep:
                canEditSleepDate(_selectedDate, _now) ? _openCheckIn : null,
          ),
        ),
      );
}
