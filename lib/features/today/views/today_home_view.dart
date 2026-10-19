import 'dart:async';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/language_manager.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/ds_colors.dart';
import '../../history/repositories/history_repository.dart';
import '../../../models/home_models.dart';
import '../../nutrition/views/nutrition_view.dart';
import '../../train/views/train_view.dart';
import '../../train/repositories/training_repository.dart';
import '../../train/models/training_session.dart';
import '../components/today_dashboard.dart';
import '../repositories/today_repository.dart';
import '../../body_scan/models/training_map_models.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../../wellness/views/sleep_entry_view.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/health/health_models.dart';

class TodayHomeView extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenProfile;
  final bool isActive;

  const TodayHomeView({
    super.key,
    required this.onSelectTab,
    required this.onOpenProfile,
    this.isActive = true,
  });

  @override
  State<TodayHomeView> createState() => _TodayHomeViewState();
}

class _TodayHomeViewState extends State<TodayHomeView> {
  HomeData? _homeData;
  final _recovery = ValueNotifier<List<RecoveryPoint>>(const []);
  StreamSubscription<HomeData>? _subscription;
  StreamSubscription<TrainingDay>? _trainingUpdates;
  StreamSubscription<HealthSnapshotPayload>? _healthUpdates;
  bool _loading = true;
  bool _loadFailed = false;
  bool _refreshFailed = false;
  final _trainingMap = ValueNotifier<TrainingMapData?>(null);
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<WeekDay> _weekDays = const [];
  int _request = 0, _mapRequest = 0;
  String _locale = '';

  @override
  void initState() {
    super.initState();
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
      }
    });
    _trainingUpdates = TrainingRepository.shared.changes.stream.listen((day) {
      if (mounted &&
          widget.isActive &&
          day.date == CacheScope.todayKey(_selectedDate)) {
        unawaited(_loadTrainingPreview());
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

  Future<void> _loadTrainingPreview() async {
    final request = ++_mapRequest;
    final date = _selectedDate;
    final locale = LanguageManager.shared.currentLanguage.code;
    try {
      final owner = await CacheScope.userId();
      if (!mounted || owner == 'anonymous') return;
      final map = await BodyAssessmentRepository.shared
          .trainingMap(date: date, daily: true);
      final currentOwner = await CacheScope.userId();
      if (mounted &&
          request == _mapRequest &&
          DateUtils.isSameDay(date, _selectedDate) &&
          locale == LanguageManager.shared.currentLanguage.code &&
          owner == currentOwner &&
          map.date == CacheScope.todayKey(date)) {
        _trainingMap.value = map;
      }
    } catch (_) {
      // Optional preview: retain the Body shortcut when unavailable.
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

    // These sections are independent. Neither blocks the main cards.
    final recovery = _loadRecovery(request, owner, locale, refresh);
    final preview = _loadTrainingPreview();
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
    await Future.wait([recovery, preview]);
  }

  Future<void> _loadRecovery(
      int request, String owner, String locale, bool refresh) async {
    try {
      final recovery = await HistoryRepository.shared
          .getRecovery(days: 14, forceRefresh: refresh);
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
      _selectedDate = DateUtils.dateOnly(date);
      _trainingMap.value = null;
      _loading = true;
    });
    _mapRequest++;
    unawaited(_loadHome(refresh: retry));
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _subscription?.cancel();
    _trainingUpdates?.cancel();
    _healthUpdates?.cancel();
    _recovery.dispose();
    _trainingMap.dispose();
    super.dispose();
  }

  void _open(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DSColors.dashboardBg,
        body: SafeArea(
          bottom: false,
          child: TodayDashboard(
            selectedDate: _selectedDate,
            onDateSelected: _selectDate,
            weekDays: _weekDays,
            data: _homeData,
            recoveryUpdates: _recovery,
            trainingUpdates: _trainingMap,
            loading: _loading,
            loadFailed: _loadFailed,
            refreshFailed: _refreshFailed,
            onRefresh: () => _loadHome(refresh: true),
            onProfile: widget.onOpenProfile,
            onSession: () => _open(TrainView(
                standalone: true,
                initialDate: CacheScope.todayKey(_selectedDate))),
            onTrain: () => DateUtils.isSameDay(_selectedDate, DateTime.now())
                ? widget.onSelectTab(1)
                : _open(TrainView(
                    standalone: true,
                    initialDate: CacheScope.todayKey(_selectedDate))),
            onNutrition: () => _open(NutritionView(date: _selectedDate)),
            onBody: () => widget.onSelectTab(2),
            onSleep: _selectedDate.isAfter(DateUtils.dateOnly(DateTime.now()))
                ? null
                : () async {
                    final entry = await Navigator.of(context)
                        .push<Map<String, dynamic>>(MaterialPageRoute(
                            builder: (_) =>
                                SleepEntryView(initialDate: _selectedDate)));
                    if (mounted) {
                      if (entry != null &&
                          entry['date'] == CacheScope.todayKey(_selectedDate) &&
                          _homeData != null) {
                        setState(() => _homeData = HomeData.fromJson({
                              ..._homeData!.toJson(),
                              'sleepLog': entry,
                              if (entry.containsKey('readiness'))
                                'readiness': entry['readiness'],
                              if (entry.containsKey('wearableUsage'))
                                'wearableUsage': entry['wearableUsage'],
                            }));
                      }
                      await _loadHome(refresh: true);
                    }
                  },
          ),
        ),
      );
}
