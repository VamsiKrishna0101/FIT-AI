import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/network/api_client.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/components/content_transition.dart';
import '../../../core/localization/language_manager.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../repositories/body_assessment_repository.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../onboarding/views/training_preferences_view.dart';
import '../../profile/views/profile_view.dart';
import '../../train/repositories/workout_repository.dart';
import '../../train/repositories/training_repository.dart';
import '../../train/models/training_session.dart';
import '../../train/models/workout_exercise_models.dart';
import '../../train/views/exercise_detail_view.dart';
import '../models/training_map_models.dart';
import 'widgets/anatomical_training_map.dart';

String _dayLabel(BuildContext context, String day) {
  const days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
  final index = days.indexOf(day);
  if (index < 0) return fitnessText(context, day);
  return DateFormat.EEEE(Localizations.localeOf(context).toLanguageTag())
      .format(DateTime(2024, 1, 1).add(Duration(days: index)));
}

class BodyTrainingView extends StatefulWidget {
  final VoidCallback onTrain;
  final bool isActive;
  final bool showHeader;
  final Future<TrainingMapData> Function()? loadMap;
  const BodyTrainingView(
      {super.key,
      required this.onTrain,
      this.isActive = true,
      this.showHeader = true,
      this.loadMap});
  @override
  State<BodyTrainingView> createState() => _BodyTrainingViewState();
}

class _BodyTrainingViewState extends State<BodyTrainingView>
    with WidgetsBindingObserver {
  TrainingMapData? _data;
  String _locale = LanguageManager.shared.currentLanguage.code;
  String? _dataUser;
  bool _loading = true, _failed = false;
  int _request = 0;
  StreamSubscription<TodayPlanModel?>? _subscription;
  StreamSubscription<TrainingDay>? _setSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LanguageManager.shared.addListener(_languageChanged);
    _subscription = WorkoutRepository.shared.planStream.listen((_) {
      if (widget.isActive) unawaited(_load());
    });
    _setSubscription = TrainingRepository.shared.changes.stream.listen((_) {
      if (widget.isActive) unawaited(_load());
    });
    unawaited(_load());
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) return;
    _locale = locale;
    ++_request;
    setState(() {
      _data = null;
      _loading = widget.isActive;
      _failed = false;
    });
    if (widget.isActive) unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(BodyTrainingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) unawaited(_load());
  }

  Future<void> _load() async {
    if (!widget.isActive) return;
    final request = ++_request, user = await CacheScope.userId();
    if (!mounted || request != _request) return;
    if (user == 'anonymous' && widget.loadMap == null) {
      setState(() {
        _data = null;
        _loading = false;
        _failed = true;
      });
      return;
    }
    final now = DateTime.now();
    if (user != _dataUser || _data?.date != CacheScope.todayKey(now)) {
      setState(() {
        _data = null;
        _dataUser = user;
        _loading = true;
        _failed = false;
      });
    }
    try {
      TrainingMapData data;
      if (widget.loadMap != null) {
        data = await widget.loadMap!();
      } else {
        data = await BodyAssessmentRepository.shared.trainingMap(date: now);
      }
      final currentUser = await CacheScope.userId();
      if (mounted && request == _request && currentUser == user) {
        setState(() {
          _data = data;
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      final currentUser = await CacheScope.userId();
      if (mounted && request == _request && currentUser == user) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _checkIn(String muscle, int soreness) async {
    final now = DateTime.now();
    await ApiClient.shared
        .put<Map<String, dynamic>>('/api/heatmap/check-in', data: {
      'muscleId': muscle,
      'soreness': soreness,
      'date': CacheScope.todayKey(now),
      'utcOffsetMinutes': now.timeZoneOffset.inMinutes
    });
    await UserDataCache.shared.invalidate('training_map');
    await _load();
  }

  Future<void> _preferences() async {
    final route = AppPageRoute<void>(
        page: const TrainingPreferencesView(editProfile: true));
    await Navigator.of(context).push(route);
    await route.completed;
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _setSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    LanguageManager.shared.removeListener(_languageChanged);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          body: SafeArea(
              bottom: false,
              child: Stack(
                key: ValueKey(_dataUser),
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    ignoring: _loading && _data == null,
                    child: AnimatedOpacity(
                      opacity: _loading && _data == null ? 0 : 1,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : ContentTransition.duration,
                      curve: Curves.easeOutCubic,
                      child: TrainingMapDashboard(
                          showHeader: widget.showHeader,
                          data: _data,
                          loading: _loading,
                          failed: _failed,
                          onRefresh: _load,
                          onTrain: widget.onTrain,
                          onPreferences: _preferences,
                          onCheckIn: _checkIn,
                          onProfile: () => Navigator.of(context).push(
                              AppPageRoute<void>(page: const ProfileView()))),
                    ),
                  ),
                  if (_loading && _data == null)
                    const SingleChildScrollView(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: LoadingPlaceholder(),
                    ),
                ],
              ))));
}

class TrainingMapDashboard extends StatefulWidget {
  final TrainingMapData? data;
  final bool loading, failed;
  final bool showHeader;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String, int) onCheckIn;
  final VoidCallback onTrain, onPreferences, onProfile;
  const TrainingMapDashboard(
      {super.key,
      this.data,
      this.loading = false,
      this.failed = false,
      this.showHeader = true,
      required this.onRefresh,
      required this.onCheckIn,
      required this.onTrain,
      required this.onPreferences,
      required this.onProfile});
  @override
  State<TrainingMapDashboard> createState() => _TrainingMapDashboardState();
}

class _TrainingMapDashboardState extends State<TrainingMapDashboard> {
  bool _back = false, _all = false;
  String? _selected;
  Color _color(MuscleRegion r) {
    if (r.completedSets == 0) return const Color(0xFF606060);
    return Color.lerp(const Color(0xFF486687), FitnessTheme.blue,
        (r.completedSets / 12).clamp(0, 1))!;
  }

  void _select(String id) {
    final region = widget.data?.regions.where((r) => r.id == id).firstOrNull;
    if (region == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = id);
    showModalBottomSheet<void>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FitnessTheme.surface,
        showDragHandle: true,
        builder: (_) => FitnessTheme(
            child: _MuscleDetail(
                region: region,
                onCheckIn: widget.onCheckIn,
                onTrain: widget.onTrain)));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final date = DateTime.tryParse(data?.date ?? '') ?? DateTime.now();
    final regions = [...?data?.regions]
      ..sort((a, b) => (b.isFocus ? 1 : 0).compareTo(a.isFocus ? 1 : 0));
    return Column(children: [
      if (widget.showHeader)
        Padding(
            key: const ValueKey('body-fixed-header'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(
                        DateFormat('EEEE, MMM d',
                                Localizations.localeOf(context).toLanguageTag())
                            .format(date),
                        style: const TextStyle(
                            fontSize: 12, color: FitnessTheme.muted)),
                    const SizedBox(height: 5),
                    const FitnessText('Your body',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.8))
                  ])),
              IconButton.filledTonal(
                  onPressed: widget.onProfile,
                  tooltip: fitnessText(context, 'Profile'),
                  style: IconButton.styleFrom(
                      backgroundColor: FitnessTheme.surface),
                  icon: const Icon(CupertinoIcons.person_crop_circle,
                      color: FitnessTheme.silver, size: 23))
            ])),
      Expanded(
          child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: FitnessTheme.silver,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(16, 4, 16,
                      LiquidSilverBottomBar.scrollBottomInset(context)),
                  children: [
                    if (widget.failed) ...[
                      FitnessCard(
                          child: Row(children: [
                        const Expanded(
                            child: FitnessText(
                                'Could not refresh your training map.',
                                style: TextStyle(
                                    fontSize: 13, color: FitnessTheme.muted))),
                        TextButton(
                            onPressed: widget.onRefresh,
                            child: const FitnessText('Retry'))
                      ])),
                      const SizedBox(height: 12)
                    ],
                    if (widget.loading && data == null)
                      const Padding(
                          padding: EdgeInsets.all(50),
                          child: Center(child: CupertinoActivityIndicator()))
                    else if (data == null)
                      FitnessCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const FitnessText('Your training, mapped',
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const FitnessText(
                                'Refresh to load your muscle map.',
                                style: TextStyle(color: FitnessTheme.muted)),
                            TextButton(
                                onPressed: widget.onRefresh,
                                child: const FitnessText('Try again'))
                          ]))
                    else ...[
                      FitnessCard(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          child: Row(children: [
                            _Stat(
                                '${data.summary['loggedSets']}', 'Logged sets'),
                            _Stat('${data.summary['trainedMuscles']}',
                                'Areas trained'),
                            _Stat(
                                '${data.summary['sessions']}', 'Training days'),
                            IconButton(
                                onPressed: widget.onPreferences,
                                tooltip: fitnessText(
                                    context, 'Training preferences'),
                                icon: const Icon(
                                    CupertinoIcons.slider_horizontal_3,
                                    color: FitnessTheme.muted,
                                    size: 21)),
                          ])),
                      const SizedBox(height: 16),
                      FitnessCard(
                          child: Column(children: [
                        Row(children: [
                          const Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                FitnessText('Muscles trained',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                FitnessText('Direct sets logged this week',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted))
                              ])),
                          SizedBox(
                              width: 126,
                              child: _Segment(
                                  labels: const ['Front', 'Back'],
                                  selected: _back ? 1 : 0,
                                  onChanged: (v) =>
                                      setState(() => _back = v == 1)))
                        ]),
                        const SizedBox(height: 8),
                        GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if ((details.primaryVelocity ?? 0).abs() > 80) {
                                setState(() => _back = !_back);
                              }
                            },
                            child: SizedBox(
                                height: 340,
                                child: AnatomicalTrainingMap(
                                    back: _back,
                                    female: data.gender == 'FEMALE',
                                    colors: {
                                      for (final r in data.regions)
                                        r.id: _color(r)
                                    },
                                    selected: _selected,
                                    onSelected: _select))),
                        const SizedBox(height: 6),
                        const Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _Legend(Color(0xFF606060), 'No direct sets'),
                              _Legend(Color(0xFF486687), 'Fewer sets'),
                              _Legend(FitnessTheme.blue, 'More sets')
                            ]),
                        const SizedBox(height: 12),
                        const FitnessText(
                            'Blue intensity compares set counts · tap to explore',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: FitnessTheme.muted))
                      ])),
                      const SizedBox(height: 22),
                      _NextFocus(
                          regions: regions,
                          onSelect: _select,
                          onTrain: widget.onTrain),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Expanded(
                            child: FitnessText('Weekly balance',
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.3))),
                        TextButton(
                            onPressed: () => setState(() => _all = !_all),
                            child: FitnessText(
                                _all ? 'Show less' : 'All muscles',
                                style: const TextStyle(
                                    color: FitnessTheme.muted, fontSize: 12)))
                      ]),
                      FitnessCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Column(children: [
                            for (final r in (_all ? regions : regions.take(5)))
                              InkWell(
                                  onTap: () => _select(r.id),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 11),
                                      child: Row(children: [
                                        Expanded(
                                            flex: 3,
                                            child: Row(children: [
                                              if (r.isFocus)
                                                const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 5),
                                                    child: Icon(
                                                        CupertinoIcons
                                                            .star_fill,
                                                        size: 10,
                                                        color: FitnessTheme
                                                            .silver)),
                                              Flexible(
                                                  child: FitnessText(r.label,
                                                      style: const TextStyle(
                                                          fontSize: 13)))
                                            ])),
                                        Expanded(
                                            flex: 3,
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                child: MotionValue(
                                                    value: (r.targetSets > 0
                                                            ? (r.completedSets /
                                                                    r
                                                                        .targetSets)
                                                                .clamp(0, 1)
                                                            : 0)
                                                        .toDouble(),
                                                    builder: (context,
                                                            animatedValue) =>
                                                        LinearProgressIndicator(
                                                            value:
                                                                animatedValue,
                                                            minHeight: 4,
                                                            color: _color(r),
                                                            backgroundColor:
                                                                FitnessTheme
                                                                    .line)))),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                            width: 55,
                                            child: FitnessText(
                                                r.targetSets > 0
                                                    ? '${r.completedSets}/${r.targetSets}'
                                                    : fitnessText(
                                                        context, '{count} sets',
                                                        values: {
                                                            'count':
                                                                r.completedSets
                                                          }),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: FitnessTheme.muted)))
                                      ])))
                          ])),
                      const SizedBox(height: 16),
                      if (data.summary['loggedSets'] == 0)
                        FitnessCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const FitnessText(
                                  'Your next set starts the story',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 7),
                              const FitnessText(
                                  'Log sets in Train to see your coverage and progress here.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.muted,
                                      height: 1.4)),
                              TextButton(
                                  onPressed: widget.onTrain,
                                  child: const FitnessText('Open Train →'))
                            ])),
                      if (data.unmapped.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FitnessText(
                                '${data.unmapped.length} exercises need muscle tags and are not colored on the map.',
                                style: const TextStyle(
                                    fontSize: 12, color: FitnessTheme.muted))),
                    ],
                  ]))),
    ]);
  }
}

class _NextFocus extends StatelessWidget {
  final List<MuscleRegion> regions;
  final ValueChanged<String> onSelect;
  final VoidCallback onTrain;
  const _NextFocus(
      {required this.regions, required this.onSelect, required this.onTrain});
  @override
  Widget build(BuildContext context) {
    final due = regions
        .where((region) => region.dueSets > region.completedSets)
        .toList();
    due.sort((first, second) {
      final firstCaution = first.hasLimitation || (first.soreness ?? 0) > 0;
      final secondCaution = second.hasLimitation || (second.soreness ?? 0) > 0;
      if (firstCaution != secondCaution) return firstCaution ? 1 : -1;
      if (first.isFocus != second.isFocus) return first.isFocus ? -1 : 1;
      return (first.completedSets / first.dueSets)
          .compareTo(second.completedSets / second.dueSets);
    });
    final upcoming =
        regions.where((region) => region.nextExercises.isNotEmpty).firstOrNull;
    return FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(
            child: FitnessText('Next in your plan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        TextButton(
            onPressed: onTrain,
            child: const FitnessText('Open Train',
                style: TextStyle(color: FitnessTheme.silver, fontSize: 12)))
      ]),
      if (due.isEmpty)
        FitnessText(
            upcoming != null
                ? 'Your scheduled targets are up to date. Review your next session in Train.'
                : 'Add a workout plan in Train to see what needs attention.',
            style: const TextStyle(
                fontSize: 13, color: FitnessTheme.muted, height: 1.4)),
      for (final region in due.take(3))
        InkWell(
            onTap: () => onSelect(region.id),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                      width: 3,
                      height: 30,
                      decoration: BoxDecoration(
                          color: FitnessTheme.coral,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        FitnessText(region.label,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        FitnessText(
                            (region.soreness ?? 0) > 0
                                ? 'Soreness reported · review before training'
                                : region.hasLimitation
                                    ? 'Movement limitation · review your exercises'
                                    : '${region.dueSets - region.completedSets} planned sets due',
                            style: const TextStyle(
                                fontSize: 11, color: FitnessTheme.muted)),
                      ])),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 13, color: FitnessTheme.muted),
                ]))),
      if (due.isNotEmpty)
        const Padding(
            padding: EdgeInsets.only(top: 4),
            child: FitnessText('Based on your schedule and logged sets.',
                style: TextStyle(fontSize: 11, color: FitnessTheme.muted))),
    ]));
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        FitnessText(value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.7)),
        const SizedBox(height: 4),
        FitnessText(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted))
      ]));
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        FitnessText(label,
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted))
      ]);
}

class _Segment extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Segment(
      {required this.labels, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
              child: Semantics(
                  selected: i == selected,
                  button: true,
                  child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                              color: selected == i
                                  ? const Color(0xFF484848)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9)),
                          child: FitnessText(labels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected == i
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected == i
                                      ? Colors.white
                                      : FitnessTheme.muted))))))
      ]));
}

class _MuscleDetail extends StatefulWidget {
  final MuscleRegion region;
  final Future<void> Function(String, int) onCheckIn;
  final VoidCallback onTrain;
  const _MuscleDetail(
      {required this.region, required this.onCheckIn, required this.onTrain});
  @override
  State<_MuscleDetail> createState() => _MuscleDetailState();
}

class _MuscleDetailState extends State<_MuscleDetail> {
  bool _saving = false;
  int? _soreness;
  String? _error;
  @override
  void initState() {
    super.initState();
    _soreness = widget.region.soreness;
  }

  Future<void> _save(int value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onCheckIn(widget.region.id, value);
      if (mounted) setState(() => _soreness = value);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openExercise(String id) async {
    try {
      final exercise = await WorkoutRepository.shared.getExerciseDetail(id);
      if (exercise == null) throw StateError('Could not open this exercise.');
      if (mounted) {
        await Navigator.of(context).push(
            AppPageRoute<void>(page: ExerciseDetailView(exercise: exercise)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText('Could not open this exercise.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.region;
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            children: [
              Row(children: [
                Expanded(
                    child: FitnessText(r.label,
                        style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.6))),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(CupertinoIcons.xmark, size: 18))
              ]),
              FitnessText(
                  r.lastTrained == null
                      ? 'No direct sets logged yet'
                      : 'Last trained ${DateFormat('MMM d', Localizations.localeOf(context).toLanguageTag()).format(DateTime.parse(r.lastTrained!))}',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              if (r.lastExposure != null &&
                  r.lastExposure != r.lastTrained) ...[
                const SizedBox(height: 5),
                FitnessText(
                    'Last assisting exposure ${DateFormat('MMM d', Localizations.localeOf(context).toLanguageTag()).format(DateTime.parse(r.lastExposure!))}',
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
              ],
              const SizedBox(height: 20),
              Row(children: [
                _Stat('${r.completedSets}', 'Direct sets'),
                _Stat('${r.assistingSets}', 'Assisting sets'),
                _Stat('${r.previousWeekSets}', 'Last week total')
              ]),
              const SizedBox(height: 20),
              FitnessText(r.insight,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5, color: FitnessTheme.silver)),
              const SizedBox(height: 12),
              FitnessText(
                  r.targetSets > 0
                      ? fitnessText(context,
                          '{count} of {total} direct sets · weekly plan',
                          values: {
                              'count': r.completedSets,
                              'total': r.targetSets
                            })
                      : 'No weekly target set',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              if (r.targetSets > 0) ...[
                const SizedBox(height: 9),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: MotionValue(
                        value: ((r.completedSets / r.targetSets).clamp(0, 1))
                            .toDouble(),
                        builder: (context, animatedValue) =>
                            LinearProgressIndicator(
                                value: animatedValue,
                                minHeight: 5,
                                color: FitnessTheme.blue,
                                backgroundColor: FitnessTheme.line)))
              ],
              const SizedBox(height: 26),
              const FitnessText('How does it feel today?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (var i = 0; i < 4; i++)
                  ChoiceChip(
                      label: FitnessText(
                          const [
                            'Comfortable',
                            'Light soreness',
                            'Sore',
                            'Very sore'
                          ][i],
                          style: const TextStyle(fontSize: 12)),
                      selected: _soreness == i,
                      onSelected: _saving ? null : (_) => _save(i),
                      selectedColor: const Color(0xFF484848),
                      backgroundColor: const Color(0xFF2A2A2A),
                      side: BorderSide.none)
              ]),
              if (_saving)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                        minHeight: 2, color: FitnessTheme.silver)),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FitnessText(_error!,
                        style: const TextStyle(
                            color: FitnessTheme.coral, fontSize: 12))),
              const SizedBox(height: 10),
              const FitnessText(
                  'Your check-in records how this area feels today.',
                  style: TextStyle(
                      fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
              const SizedBox(height: 26),
              const FitnessText('Load trend',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              FitnessText(
                  r.trendExercise ?? 'Log weighted sets to build your trend.',
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              if (r.trend.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                    height: 80,
                    child: MotionChartReveal(
                        dataKey: r.trend
                            .map((p) => '${p['date']}:${p['weightKg']}')
                            .join('|'),
                        child: CustomPaint(
                            size: Size.infinite,
                            painter: _LoadChart(r.trend)))),
                const SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final point in r.trend.length > 1
                          ? [r.trend.first, r.trend.last]
                          : [r.trend.first])
                        FitnessText(
                            DateFormat(
                                    'MMM d',
                                    Localizations.localeOf(context)
                                        .toLanguageTag())
                                .format(
                                    DateTime.parse(point['date'] as String)),
                            style: const TextStyle(
                                fontSize: 10, color: FitnessTheme.muted))
                    ]),
                const SizedBox(height: 10),
                FitnessText(
                    fitnessText(
                        context, 'Latest best load: {weight} kg × {reps} reps',
                        values: {
                          'weight': r.trend.last['weightKg'] as num,
                          'reps': r.trend.last['reps'] as num
                        }),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                const FitnessText(
                    'Highest logged load each day for this exercise. Reps may vary.',
                    style: TextStyle(fontSize: 11, color: FitnessTheme.muted))
              ],
              const SizedBox(height: 26),
              const FitnessText('Direct training history',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              if (r.sessions.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: FitnessText('Your logged sessions will appear here.',
                        style: TextStyle(
                            fontSize: 12, color: FitnessTheme.muted))),
              for (final session in r.sessions)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 55,
                              child: FitnessText(
                                  DateFormat(
                                          'MMM d',
                                          Localizations.localeOf(context)
                                              .toLanguageTag())
                                      .format(DateTime.parse(
                                          session['date'] as String)),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: FitnessTheme.muted))),
                          Expanded(
                              child: FitnessText(
                                  (session['exercises'] as List).join(' · '),
                                  style: const TextStyle(
                                      fontSize: 12, height: 1.4))),
                          const SizedBox(width: 10),
                          FitnessText('{count} sets',
                              values: {'count': session['sets'] as num},
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))
                        ])),
              if (r.nextExercises.isNotEmpty) ...[
                const SizedBox(height: 17),
                const FitnessText('In your plan',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                for (final exercise in r.nextExercises)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: FitnessText(exercise['name'] as String,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: FitnessText(
                          fitnessText(context, '{day} · {count} sets', values: {
                            'day': _dayLabel(
                                context, exercise['dayOfWeek'] as String),
                            'count': exercise['sets'] as num
                          }),
                          style: const TextStyle(
                              fontSize: 11, color: FitnessTheme.muted)),
                      trailing: const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: FitnessTheme.muted),
                      onTap: () => _openExercise(exercise['id'] as String))
              ],
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onTrain();
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: FitnessTheme.silver,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 48)),
                  child: const FitnessText('Open Train')),
            ]));
  }
}

class _LoadChart extends CustomPainter {
  final List<Map<String, dynamic>> points;
  _LoadChart(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final values =
        points.map((p) => (p['weightKg'] as num).toDouble()).toList();
    final low = values.reduce(math.min),
        high = values.reduce(math.max),
        span = math.max(5.0, high - low);
    final positions = [
      for (var i = 0; i < values.length; i++)
        Offset(
            values.length == 1
                ? size.width / 2
                : 4 + i / (values.length - 1) * (size.width - 8),
            size.height -
                8 -
                (values[i] - low + 2) / (span + 4) * (size.height - 16))
    ];
    for (final y in [0.25, .75]) {
      canvas.drawLine(
          Offset(0, y * size.height),
          Offset(size.width, y * size.height),
          Paint()..color = FitnessTheme.line);
    }
    final path = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (final p in positions.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = FitnessTheme.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (final p in positions) {
      canvas.drawCircle(p, 3, Paint()..color = FitnessTheme.blue);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadChart old) => old.points != points;
}
