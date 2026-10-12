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
  List<RecoveryPoint> _recovery = const [];
  StreamSubscription<HomeData>? _subscription;
  StreamSubscription<TrainingDay>? _trainingUpdates;
  StreamSubscription<HealthSnapshotPayload>? _healthUpdates;
  bool _loading = true;
  bool _loadFailed = false;
  TrainingMapData? _trainingMap;
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
        final before = _homeData?.todayWorkout;
        setState(() {
          _homeData = data;
          _weekDays = data.weeklyStreak;
          _loadFailed = false;
          _loading = false;
        });
        if (widget.isActive &&
            (before?.status != data.todayWorkout?.status ||
                before?.userWorkoutId != data.todayWorkout?.userWorkoutId)) {
          unawaited(_loadTrainingPreview());
        }
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
        unawaited(_loadHome(refresh: true));
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
      unawaited(_loadHome(refresh: true));
    }
  }

  Future<void> _loadTrainingPreview() async {
    if (!widget.isActive) return;
    final request = ++_mapRequest;
    final date = _selectedDate;
    try {
      final owner = await CacheScope.userId();
      if (!mounted || owner == 'anonymous') return;
      final map = await BodyAssessmentRepository.shared
          .trainingMap(date: date, daily: true);
      if (mounted &&
          request == _mapRequest &&
          DateUtils.isSameDay(date, _selectedDate) &&
          owner == await CacheScope.userId() &&
          map.date == CacheScope.todayKey(date)) {
        setState(() => _trainingMap = map);
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
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    HomeData? fresh;
    try {
      fresh =
          await TodayRepository.shared.loadDate(date, forceRefresh: refresh);
    } catch (_) {
      // A failed request or cache read must leave loading and offer a retry.
    }
    if (!mounted ||
        request != _request ||
        owner != await CacheScope.userId() ||
        locale != LanguageManager.shared.currentLanguage.code) {
      return;
    }
    setState(() {
      _homeData = fresh;
      if (fresh != null) _weekDays = fresh.weeklyStreak;
      _loading = false;
      _loadFailed = fresh == null;
    });
    unawaited(_loadTrainingPreview());
    final recovery = await HistoryRepository.shared
        .getRecovery(days: 14, forceRefresh: refresh);
    if (mounted && request == _request && owner == await CacheScope.userId()) {
      setState(() => _recovery = recovery);
    }
  }

  void _selectDate(DateTime date) {
    if (DateUtils.isSameDay(date, _selectedDate) && !_loadFailed) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _trainingMap = null;
      _recovery = const [];
      _loading = true;
    });
    _mapRequest++;
    unawaited(_loadHome(refresh: true));
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _subscription?.cancel();
    _trainingUpdates?.cancel();
    _healthUpdates?.cancel();
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
            recovery: _recovery,
            trainingMap: _trainingMap,
            loading: _loading,
            loadFailed: _loadFailed,
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
                    await Navigator.of(context).push<bool>(MaterialPageRoute(
                        builder: (_) =>
                            SleepEntryView(initialDate: _selectedDate)));
                    if (mounted) {
                      await _loadHome(refresh: true);
                    }
                  },
          ),
        ),
      );
}
