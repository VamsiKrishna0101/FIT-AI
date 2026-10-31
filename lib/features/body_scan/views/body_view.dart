import '../models/body_map_models.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../train/views/exercise_detail_screen.dart';
import '../../train/repositories/workout_repository.dart';
import 'widgets/body_muscle_map_card.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/localization/language_manager.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/components/motion.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/health/health_models.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/repositories/weekly_plan_repository.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_entry_view.dart';
import 'body_record_view.dart';
import 'body_measurements_view.dart';
import 'body_history_view.dart';
import '../models/body_measurement_baseline.dart';
import 'widgets/body_measurement_dashboard.dart';

class BodyView extends StatefulWidget {
  final VoidCallback onTrain;
  final bool isActive;
  final BodyAssessmentRepository? repository;
  final WeeklyPlanRepository? planRepository;
  const BodyView(
      {super.key,
      required this.onTrain,
      this.isActive = true,
      this.repository,
      this.planRepository});
  @override
  State<BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends State<BodyView> with WidgetsBindingObserver {
  BodyAssessmentRepository get _repository =>
      widget.repository ?? BodyAssessmentRepository.shared;
  final _overview = ValueNotifier<BodyOverview?>(null);
  BodyOverview? get _data => _overview.value;
  String? _owner, _error;
  int _request = 0;
  bool _loading = true;
  BodyMapData? _mapData;
  bool _mapLoading = true;
  DateTime _week = bodyMapWeek(DateTime.now());
  BodyDateSelection _selection = BodyDateSelection.thisWeek(DateTime.now());
  bool _trained = true;
  bool _openingExercise = false;
  String? _mapError;
  String _mapScope = '', _mapLanguage = '', _mapDay = '', _mapDataset = '';
  String? _shownMapKey;
  int _mapRevision = 0;
  final _maps = <String, ({BodyMapData data, DateTime saved})>{};
  final _mapRequests = <String, Future<BodyMapData>>{};
  StreamSubscription<String>? _trainingChanges;
  StreamSubscription<HealthSnapshotPayload>? _healthUpdates;
  double? get _profileWeight => (_data?.profile?['weight'] as num?)?.toDouble();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    LanguageManager.shared.addListener(_languageChanged);
    _trainingChanges = ProgressRepository.shared.updates.stream.listen((event) {
      if (event != 'invalidated') return;
      _clearMaps();
      if (mounted && widget.isActive) unawaited(_load());
    });
    _healthUpdates = HealthSyncService.shared.updates.stream.listen((_) async {
      await _repository.invalidate();
      if (mounted && widget.isActive) await _load(refresh: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthUpdates?.cancel();
    _trainingChanges?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    _overview.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BodyView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) unawaited(_load(refresh: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      unawaited(_load(refresh: true));
    }
  }

  void _clearMaps() {
    _mapRevision++;
    _maps.clear();
    _mapRequests.clear();
  }

  void _languageChanged() {
    _clearMaps();
    if (mounted && widget.isActive) unawaited(_load());
  }

  String _mapKey(bool trained) {
    final query = <String, String>{
      'date': CacheScope.todayKey(trained ? _selection.end : _week),
      if (trained) ..._selection.query.map((k, v) => MapEntry(k, v.toString())),
    };
    return '$_mapScope:${Uri(queryParameters: query).query}';
  }

  bool get _mapScopeMatches =>
      _owner == (AppDataMode.shared.owner ?? 'anonymous') &&
      _mapLanguage == LanguageManager.shared.currentLanguage.code &&
      _mapDay == CacheScope.todayKey() &&
      _mapDataset == AppDataMode.shared.dataset;
  BodyMapData? _peekMap(bool trained) =>
      _mapScopeMatches ? _maps[_mapKey(trained)]?.data : null;
  bool get _sameCurrentWeek =>
      _week == bodyMapWeek(DateTime.now()) &&
      _selection.mode == BodyDateMode.range &&
      _selection.start == _week &&
      _selection.end == DateUtils.dateOnly(DateTime.now());

  Future<BodyMapData> _getMap(bool trained) {
    final key = _mapKey(trained);
    final cached = _maps[key];
    if (cached != null &&
        DateTime.now().difference(cached.saved) < const Duration(minutes: 2)) {
      return Future.value(cached.data);
    }
    final pending = _mapRequests[key];
    if (pending != null) return pending;
    final date = trained ? _selection.end : _week;
    final selection = trained ? _selection : null;
    final revision = _mapRevision, owner = _owner, scope = _mapScope;
    final alias = _sameCurrentWeek ? _mapKey(!trained) : null;
    late Future<BodyMapData> request;
    request = () async {
      try {
        final map = await _repository.bodyMap(date: date, selection: selection);
        if (mounted &&
            revision == _mapRevision &&
            scope == _mapScope &&
            owner == await CacheScope.userId() &&
            _mapScopeMatches) {
          if (_maps.length >= 24) _maps.remove(_maps.keys.first);
          final entry = (data: map, saved: DateTime.now());
          _maps[key] = entry;
          if (alias != null) _maps[alias] = entry;
        }
        return map;
      } finally {
        if (identical(_mapRequests[key], request)) _mapRequests.remove(key);
      }
    }();
    _mapRequests[key] = request;
    return request;
  }

  Future<void> _load({bool refresh = false, bool overview = true}) async {
    if (!widget.isActive) return;
    final request = ++_request, owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    if (owner == 'anonymous' && widget.repository == null) {
      _clearMaps();
      setState(() {
        _overview.value = null;
        _mapData = null;
        _mapError = null;
        _loading = false;
        _mapLoading = false;
        _error = 'Sign in to see your measurements.';
      });
      return;
    }
    if (refresh) {
      _clearMaps();
      await _repository.invalidateMaps();
    }
    final language = LanguageManager.shared.currentLanguage.code;
    final day = CacheScope.todayKey();
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    final scope =
        await CacheScope.userKey('body_maps_${language}_${day}_$offset');
    final scopeOwner = await CacheScope.userId();
    if (!mounted || request != _request || owner != scopeOwner) {
      return;
    }
    setState(() {
      if (owner != _owner) {
        _overview.value = null;
        _mapData = null;
        _shownMapKey = null;
        _week = bodyMapWeek(DateTime.now());
        _selection = BodyDateSelection.thisWeek(DateTime.now());
        _trained = true;
      }
      if (scope != _mapScope) {
        if (_mapDataset != AppDataMode.shared.dataset) _overview.value = null;
        _clearMaps();
        _mapData = null;
        _shownMapKey = null;
      }
      _owner = owner;
      _mapScope = scope;
      _mapLanguage = language;
      _mapDay = day;
      _mapDataset = AppDataMode.shared.dataset;
      final key = _mapKey(_trained), cached = _maps[key];
      _mapData = cached?.data ?? (_shownMapKey == key ? _mapData : null);
      _loading = _overview.value == null;
      _mapLoading = _mapData == null;
      _error = null;
      _mapError = null;
    });
    final key = _mapKey(_trained);
    BodyOverview? data = _data;
    BodyMapData? map;
    String? bodyError, mapError;
    await Future.wait([
      if (overview || data == null)
        _repository.load().then<void>((value) => data = value,
            onError: (Object error) =>
                bodyError = BodyAssessmentRepository.message(error)),
      _getMap(_trained).then<void>((value) => map = value,
          onError: (Object error) =>
              mapError = BodyAssessmentRepository.message(error)),
    ]);
    final currentOwner = await CacheScope.userId();
    if (!mounted ||
        request != _request ||
        currentOwner != owner ||
        !_mapScopeMatches) {
      return;
    }
    setState(() {
      if (data != null) _overview.value = data;
      if (map != null) {
        _mapData = map;
        _shownMapKey = key;
      }
      _mapError = mapError;
      _mapLoading = false;
      _error = bodyError;
      _loading = false;
    });
    if (map != null) {
      unawaited(_getMap(!_trained)
          .then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    }
  }

  void _changeWeek(DateTime week) {
    if (_week == week) return;
    setState(() {
      _week = week;
      _mapData = _peekMap(_trained);
      _shownMapKey = _mapData == null ? null : _mapKey(_trained);
      _mapLoading = _mapData == null;
      _mapError = null;
    });
    unawaited(_load(overview: false));
  }

  void _changeSelection(BodyDateSelection selection) {
    setState(() {
      _selection = selection;
      _mapData = null;
      _mapError = null;
    });
    unawaited(_load());
  }

  void _changeMode(bool trained) {
    setState(() {
      _trained = trained;
      _mapData = null;
      _mapError = null;
    });
    unawaited(_load());
  }

  Future<void> _openExercise(String id) async {
    if (_openingExercise) return;
    _openingExercise = true;
    final owner = _owner;
    try {
      final exercise = await WorkoutRepository.shared.getExerciseDetail(id);
      final currentOwner = await CacheScope.userId();
      if (!mounted || owner != currentOwner) return;
      if (exercise == null) throw StateError('Could not open this exercise.');
      final route =
          AppPageRoute<void>(page: ExerciseDetailView(exercise: exercise));
      await Navigator.of(context).push(route);
      await route.completed;
      if (mounted) await _load(refresh: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText('Could not open this exercise.')));
      }
    } finally {
      _openingExercise = false;
    }
  }

  Future<void> _preparePlan() async {
    if (_data == null) await _load();
    if (!mounted || _data == null) return;
    if (!BodyMeasurementBaseline(_data!).isComplete) {
      _update();
      return;
    }
    final route = AppPageRoute<void>(
        page: WeeklyPlanView(repository: widget.planRepository));
    await Navigator.of(context).push(route);
    await route.completed;
    if (mounted) await _load();
  }

  Future<void> _route(Widget page) async {
    final route = AppPageRoute<bool>(page: page);
    final changed = await Navigator.of(context).push(route);
    await route.completed;
    if (mounted && changed == true) await _load(refresh: true);
  }

  Future<void> _openRecord(BodyAssessment entry) =>
      _route(BodyRecordView(entry: entry));

  void _update() => _route(BodyEntryView(
      repository: _repository,
      profileWeight: _profileWeight,
      baseline: _data == null ? null : BodyMeasurementBaseline(_data!),
      requireBaseline:
          _data != null && !BodyMeasurementBaseline(_data!).isComplete));

  Widget _details(Widget Function(BodyOverview data) page) =>
      ValueListenableBuilder<BodyOverview?>(
        valueListenable: _overview,
        builder: (context, data, _) => data == null
            ? Scaffold(
                appBar: AppBar(title: const FitnessText('Body')),
                body: const Center(
                    child: FitnessText('Refresh Body to load your readings.')))
            : page(data),
      );

  void _measurements() => Navigator.of(context).push(AppPageRoute<void>(
        page: _details((data) => BodyMeasurementsView(
            overview: data, onAdd: _update, onRecord: _openRecord)),
      ));

  void _history() => Navigator.of(context).push(AppPageRoute<void>(
        page: BodyHistoryView(repository: _repository, onRecord: _openRecord),
      ));

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        backgroundColor: FitnessTheme.canvas,
        body: SafeArea(
            bottom: false,
            child: Column(children: [
              const Padding(
                key: ValueKey('body-fixed-header'),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: FitnessText('Body',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.7))),
                    ]),
              ),
              Expanded(
                  child: RefreshIndicator(
                color: FitnessTheme.silver,
                onRefresh: () async {
                  await _repository.invalidate();
                  await _load(refresh: true);
                },
                child: ListView(
                  key: const ValueKey('body-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(16, 8, 16,
                      LiquidSilverBottomBar.scrollBottomInset(context)),
                  children: [
                    if (_error != null && !_loading)
                      FitnessCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            FitnessText(_error!,
                                style: const TextStyle(
                                    fontSize: 13, color: FitnessTheme.muted)),
                            TextButton(
                                onPressed: _load,
                                child: const FitnessText('Retry')),
                          ])),
                    BodyMuscleMapCard(
                        key: ValueKey('body-map-$_owner'),
                        data: _mapData,
                        female: _data?.female ?? (_mapData?.gender == 'FEMALE'),
                        loading: _mapLoading,
                        week: _week,
                        onWeekChanged: _changeWeek,
                        onExercise: _openExercise,
                        selection: _selection,
                        onSelectionChanged: _changeSelection,
                        onModeChanged: _changeMode,
                        onPreparePlan: _preparePlan,
                        canCreatePlan: _data != null &&
                            BodyMeasurementBaseline(_data!).isComplete,
                        error: _mapError,
                        onRetry: _load,
                        onTrain: widget.onTrain),
                    const SizedBox(height: 22),
                    if (_data != null)
                      MotionEntrance(
                          child: BodyMeasurementDashboard(
                        key: ValueKey(_owner),
                        overview: _data!,
                        onUpdate: _update,
                        onMeasurements: _measurements,
                        onHistory: _history,
                      )),
                  ],
                ),
              )),
            ])),
      ));
}
