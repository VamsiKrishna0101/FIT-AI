import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/animated_tab_stack.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/health/health_models.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../profile/views/profile_view.dart';
import '../../planner/repositories/weekly_plan_repository.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_entry_view.dart';
import 'body_photo_review_view.dart';
import 'body_record_view.dart';
import 'body_focus_result_view.dart';
import 'body_training_view.dart';
import 'body_comparison_view.dart';
import 'widgets/body_physique_home.dart';
import 'widgets/body_controls.dart';
import 'body_measurements_view.dart';
import 'body_history_view.dart';

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
  int _section = 0;
  StreamSubscription<HealthSnapshotPayload>? _healthUpdates;
  double? get _profileWeight => (_data?.profile?['weight'] as num?)?.toDouble();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _healthUpdates = HealthSyncService.shared.updates.stream.listen((_) {
      if (mounted && widget.isActive) unawaited(_load());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthUpdates?.cancel();
    _overview.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BodyView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (!widget.isActive) return;
    final request = ++_request, owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    if (owner == 'anonymous' && widget.repository == null) {
      setState(() {
        _overview.value = null;
        _loading = false;
        _error = 'Sign in to see your body assessments.';
      });
      return;
    }
    setState(() {
      if (owner != _owner) _overview.value = null;
      _owner = owner;
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.load();
      final currentOwner = await CacheScope.userId();
      if (!mounted || request != _request || currentOwner != owner) return;
      setState(() {
        _overview.value = data;
        _loading = false;
      });
    } catch (error) {
      if (mounted &&
          request == _request &&
          await CacheScope.userId() == owner) {
        setState(() {
          _loading = false;
          _error = BodyAssessmentRepository.message(error);
        });
      }
    }
  }

  Future<void> _route(Widget page) async {
    final route = AppPageRoute<bool>(page: page);
    final changed = await Navigator.of(context).push(route);
    await route.completed;
    if (mounted && changed == true) await _load();
  }

  List<BodyAssessment> _baselines(BodyAssessment entry) =>
      (_data?.records ?? []).where((r) => r.isEarlierThan(entry)).toList();
  void _compare(BodyAssessment entry) {
    final earlier = _baselines(entry);
    if (earlier.isNotEmpty) {
      Navigator.of(context).push(AppPageRoute<void>(
          page: BodyComparisonView(
              current: entry, baselines: earlier, repository: _repository)));
    }
  }

  void _openRecord(BodyAssessment entry) => _route(
        entry.photos.isNotEmpty ||
                entry.observations.isNotEmpty ||
                entry.physiqueReport != null
            ? BodyFocusResultView(entry: entry, baselines: _baselines(entry))
            : BodyRecordView(
                entry: entry,
                canCompare: _baselines(entry).isNotEmpty,
                onCompare: () => _compare(entry)),
      );

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
            overview: data,
            onAdd: () => _route(BodyEntryView(profileWeight: _profileWeight)),
            onRecord: _openRecord)),
      ));

  void _history() => Navigator.of(context).push(AppPageRoute<void>(
        page: _details(
            (data) => BodyHistoryView(overview: data, onRecord: _openRecord)),
      ));

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        backgroundColor: FitnessTheme.canvas,
        body: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                  key: const ValueKey('body-fixed-header'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          FitnessText(
                              DateFormat(
                                      'EEEE, MMM d',
                                      Localizations.localeOf(context)
                                          .toLanguageTag())
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted)),
                          const SizedBox(height: 5),
                          const FitnessText('Body',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.8)),
                        ])),
                    IconButton.filledTonal(
                        tooltip: fitnessText(context, 'Profile'),
                        style: IconButton.styleFrom(
                            backgroundColor: FitnessTheme.surface),
                        onPressed: () => Navigator.of(context).push(
                            AppPageRoute<void>(page: const ProfileView())),
                        icon: const Icon(CupertinoIcons.person_crop_circle,
                            color: FitnessTheme.silver, size: 23)),
                  ])),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: BodySegment(
                  labels: const ['Training', 'Physique'],
                  selected: _section,
                  onChanged: (section) => setState(() => _section = section),
                ),
              ),
              Expanded(
                child: AnimatedTabStack(index: _section, children: [
                  TickerMode(
                    enabled: widget.isActive && _section == 0,
                    child: BodyTrainingView(
                      showHeader: false,
                      isActive: widget.isActive && _section == 0,
                      loadMap: _repository.trainingMap,
                      onTrain: widget.onTrain,
                    ),
                  ),
                  TickerMode(
                    enabled: widget.isActive && _section == 1,
                    child: BodyPhysiqueHome(
                        key: ValueKey(_owner),
                        overview: _data,
                        isActive: widget.isActive && _section == 1,
                        planRepository: widget.planRepository,
                        loading: _loading,
                        error: _error,
                        onRefresh: _load,
                        onCompare: _compare,
                        onMeasurements: _measurements,
                        onHistory: _history,
                        onManual: () => _route(
                            BodyEntryView(profileWeight: _profileWeight)),
                        onPhotos: () => _route(BodyPhotoReviewView(
                            female: _data?.female ?? false,
                            profileWeight: _profileWeight,
                            profileHeight: (_data?.profile?['height'] as num?)
                                ?.toDouble())),
                        onRecord: _openRecord),
                  ),
                ]),
              ),
            ])),
      ));
}
