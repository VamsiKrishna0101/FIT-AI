import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/components/content_transition.dart';
import '../components/exercise_muscle_map.dart';
import '../components/exercise_insights.dart';
import '../components/exercise_recommendation_card.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/media/fit_video_surface.dart';
import '../../../core/cache/cache_scope.dart';
import '../../profile/repositories/settings_repository.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import '../components/workout_item_actions.dart';

class ExerciseDetailView extends StatefulWidget {
  final TodayPlanItemModel? planItem;
  final Map<String, dynamic>? recommendation;
  final WorkoutExerciseModel exercise;
  final VoidCallback? onStatusChanged;
  final Future<bool> Function()? onAddToPlan;
  final String addLabel;
  final bool loadDetail;
  final String? mediaGender;
  final ExerciseProgressLoader? historyLoader;
  final bool? female;
  final Future<String?> Function()? profileGenderLoader;
  const ExerciseDetailView(
      {super.key,
      this.planItem,
      this.recommendation,
      required this.exercise,
      this.onStatusChanged,
      this.onAddToPlan,
      this.addLabel = 'Add to today',
      this.loadDetail = true,
      this.mediaGender,
      this.historyLoader,
      this.female,
      this.profileGenderLoader});
  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  late WorkoutExerciseModel _exercise;
  late final TextEditingController _sets, _reps, _weight, _rest;
  bool _busy = false, _loading = false, _detailFailed = false;
  String _locale = '';
  int _request = 0;
  int _tab = 0;
  bool _visitedProgress = false;
  bool? _female;
  String? _demoGender;
  bool _loadingBodyStyle = false;
  TodayPlanItemModel? _planItem;
  StreamSubscription<TodayPlanModel?>? _planSubscription;
  @override
  void initState() {
    super.initState();
    _demoGender = widget.mediaGender ??
        (widget.female == null
            ? null
            : widget.female!
                ? 'female'
                : 'male');
    _exercise = _demoGender == null
        ? widget.exercise
        : widget.exercise.withDemo(_demoGender!);
    _female = _demoGender == null ? null : _demoGender == 'female';
    _loadingBodyStyle = _female == null;
    if (_loadingBodyStyle) unawaited(_loadBodyStyle());
    _locale = LanguageManager.shared.currentLanguage.code;
    final item = widget.planItem;
    _planItem = item;
    _planSubscription = WorkoutRepository.shared.planStream.listen((plan) {
      final current =
          plan?.items.where((entry) => entry.id == item?.id).firstOrNull;
      if (mounted && current != null) setState(() => _planItem = current);
    });
    _sets = TextEditingController(text: '${item?.targetSets ?? 3}');
    _reps = TextEditingController(text: item?.targetReps ?? '10');
    _weight = TextEditingController(text: '${item?.targetWeight ?? 0}');
    _rest = TextEditingController(text: '${item?.restSeconds ?? 60}');
    LanguageManager.shared.addListener(_languageChanged);
    if (widget.loadDetail) unawaited(_load());
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) return;
    _locale = locale;
    if (widget.loadDetail) unawaited(_load());
  }

  Future<void> _loadBodyStyle() async {
    final owner = await CacheScope.userId();
    try {
      final gender = widget.profileGenderLoader != null
          ? await widget.profileGenderLoader!()
          : (await SettingsRepository().profile())['gender'] as String?;
      if (!mounted || owner != await CacheScope.userId()) return;
      final selected = gender?.toUpperCase();
      setState(() {
        _female = selected == 'FEMALE';
        _loadingBodyStyle = false;
        if (selected == 'MALE' || selected == 'FEMALE') {
          _demoGender = selected!.toLowerCase();
          _exercise = _exercise.withDemo(_demoGender!);
        }
      });
      if (widget.loadDetail && _demoGender != null) unawaited(_load());
    } catch (_) {
      if (mounted && owner == await CacheScope.userId()) {
        setState(() {
          _female = false;
          _loadingBodyStyle = false;
          // An unavailable profile cannot validate the cached demonstrator.
          _exercise = WorkoutExerciseModel.fromJson({
            ..._exercise.toJson(),
            'url': null,
            'thumbnailUrl': null,
          });
        });
      }
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _detailFailed = false;
    });
    final exercise = await WorkoutRepository.shared
        .getExerciseDetail(widget.exercise.id, mediaGender: _demoGender);
    if (mounted && request == _request) {
      setState(() {
        if (exercise != null) _exercise = exercise;
        _loading = false;
        _detailFailed = exercise == null;
      });
    }
  }

  @override
  void dispose() {
    _planSubscription?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    for (final controller in [_sets, _reps, _weight, _rest]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _failed() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(fitnessText(context, 'Could not save. Please try again.'))));
  Future<void> _act(Future<bool> Function() action, {bool close = true}) async {
    if (_busy) return;
    setState(() => _busy = true);
    var success = false;
    try {
      success = await action();
    } catch (_) {/* Keep the exercise open on failure. */}
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      widget.onStatusChanged?.call();
      if (close) Navigator.of(context).pop();
    } else {
      _failed();
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final sets = int.tryParse(_sets.text),
        weight = double.tryParse(_weight.text.replaceAll(',', '.')),
        rest = int.tryParse(_rest.text);
    if (sets == null ||
        sets < 1 ||
        sets > 20 ||
        weight == null ||
        weight < 0 ||
        weight > 500 ||
        rest == null ||
        rest < 0 ||
        rest > 600 ||
        _reps.text.trim().isEmpty ||
        _reps.text.trim().length > 20) {
      _failed();
      return;
    }
    setState(() => _busy = true);
    var success = false;
    try {
      success = await WorkoutRepository.shared.updateWorkoutItem(
          widget.planItem!.id,
          targetSets: sets,
          targetReps: _reps.text.trim(),
          targetWeight: weight,
          restSeconds: rest);
    } catch (_) {/* Keep targets available for retry. */}
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      widget.onStatusChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fitnessText(context, 'Targets saved'))));
    } else {
      _failed();
    }
  }

  Widget _field(String label, TextEditingController controller) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(fitnessText(context, label),
            style: const TextStyle(fontSize: 11, color: DSColors.muted)),
        const SizedBox(height: 8),
        TextField(
            controller: controller,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 14, color: DSColors.silver),
            decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DSColors.border, width: .7)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DSColors.border, width: .7)))),
      ]);

  Widget _demo() {
    final available = !_loadingBodyStyle &&
        (_exercise.url?.isNotEmpty == true ||
            _exercise.thumbnailUrl?.isNotEmpty == true);
    Widget unavailable() => Center(
        child: _loadingBodyStyle
            ? const CupertinoActivityIndicator()
            : Text(fitnessText(context, 'Demo unavailable'),
                style: const TextStyle(fontSize: 13, color: DSColors.muted)));
    final surface = RepaintBoundary(
        child: FitVideoSurface(
            url: _loadingBodyStyle ? null : _exercise.url,
            fit: BoxFit.contain,
            backgroundColor: available ? Colors.white : DSColors.bgCard,
            neutralBackground: true,
            tapToToggle: false,
            placeholder: available && _exercise.thumbnailUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: _exercise.thumbnailUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => unavailable())
                : unavailable()));
    return ContentResize(
        child: ClipRRect(
            key: const ValueKey('exercise-demo-stage'),
            borderRadius: BorderRadius.circular(18),
            child: available
                ? AspectRatio(
                    aspectRatio: _exercise.demoAspectRatio, child: surface)
                : SizedBox(
                    width: double.infinity, height: 88, child: surface)));
  }

  Widget _targetFields() => LayoutBuilder(builder: (context, box) {
        final fields = [
          _field('Sets', _sets),
          _field('Reps', _reps),
          _field('Load (kg)', _weight),
          _field('Rest (seconds)', _rest)
        ];
        final twoColumns = box.maxWidth >= 280 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final width = twoColumns ? (box.maxWidth - 12) / 2 : box.maxWidth;
        return Wrap(spacing: 12, runSpacing: 16, children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ]);
      });

  Widget _targets(TodayPlanItemModel item) => PremiumSurface(
        radius: 18,
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: PageStorageKey('exercise-targets-${_exercise.id}'),
          iconColor: DSColors.muted,
          collapsedIconColor: DSColors.muted,
          textColor: DSColors.silver,
          collapsedTextColor: DSColors.silver,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: Text(fitnessText(context, 'Your targets'),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text('${item.targetSets} × ${item.targetReps}',
                style: const TextStyle(fontSize: 12, color: DSColors.muted)),
          ),
          children: [
            _targetFields(),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _busy ? null : _save,
                child: Text(fitnessText(context, 'Save targets'))),
          ],
        ),
      );

  Widget _guide(List<String> steps) {
    String copy(String text) => fitnessText(context, text);
    if (_loading && steps.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CupertinoActivityIndicator()));
    }
    if (_detailFailed && steps.isEmpty) {
      return PremiumSurface(
          child: Column(children: [
        Text(copy('Could not load the form guide.')),
        TextButton(onPressed: _load, child: Text(copy('Retry'))),
      ]));
    }
    if (steps.isEmpty) return const SizedBox.shrink();
    return PremiumSurface(
      key: const ValueKey('exercise-instructions'),
      radius: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(copy('How to perform'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 18),
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: DSColors.border)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 28,
                child: Text('${index + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                        fontSize: 12, color: DSColors.muted, height: 1.7))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(steps[index],
                    style: const TextStyle(
                        fontSize: 13, height: 1.6, color: DSColors.silver))),
          ]),
        ],
        if (_exercise.contentLanguage == 'en' &&
            Localizations.localeOf(context).languageCode != 'en') ...[
          const SizedBox(height: 14),
          Text(
              copy(
                  'English instructions shown while this translation is unavailable.'),
              style: const TextStyle(fontSize: 12, color: DSColors.muted)),
        ],
      ]),
    );
  }

  Widget _muscles() => PremiumSurface(
      radius: 18,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
          key: PageStorageKey('exercise-muscles-${_exercise.id}'),
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: DSColors.muted,
          collapsedIconColor: DSColors.muted,
          textColor: DSColors.silver,
          collapsedTextColor: DSColors.silver,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(fitnessText(context, 'Target muscles'),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                  _exercise.targetLabel ??
                      fitnessText(context, _exercise.target),
                  style: const TextStyle(fontSize: 12, color: DSColors.muted))),
          children: [
            ExerciseMuscleMap(
                exercise: _exercise,
                female: _female ?? false,
                anatomyReady: _female != null,
                showHeading: false,
                diagramHeight: 240)
          ]));

  Widget _info(TodayPlanItemModel? item, List<String> steps) => ListView(
          key: PageStorageKey('exercise-info-${_exercise.id}'),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            if (widget.recommendation
                case final Map<String, dynamic> recommendation) ...[
              Text(fitnessText(context, 'Recommended for you'),
                  style: const TextStyle(fontSize: 12, color: DSColors.muted)),
              const SizedBox(height: 10),
              ExerciseRecommendationCard(exercise: recommendation),
              const SizedBox(height: 16),
            ],
            _demo(),
            const SizedBox(height: 12),
            _muscles(),
            const SizedBox(height: 12),
            _guide(steps),
            if (item != null) ...[
              const SizedBox(height: 12),
              _targets(item),
            ],
          ]);

  Widget _pane(int index, Widget child) {
    final active = _tab == index;
    return IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(
            excluding: !active,
            child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: DSMotion.duration(context, DSMotion.regular),
                curve: DSMotion.contentIn,
                child: TickerMode(enabled: active, child: child))));
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    final item = _planItem;
    String copy(String text) => fitnessText(context, text);
    final title = exercise.name.isEmpty
        ? exercise.name
        : '${exercise.name.characters.first.toUpperCase()}${exercise.name.characters.skip(1)}';
    final steps = exercise.localizedInstructionSteps(
        Localizations.localeOf(context).toLanguageTag());

    return FitnessTheme(
        child: PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: DSColors.bg,
        appBar: AppBar(
          backgroundColor: DSColors.bg,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: (MediaQuery.textScalerOf(context).scale(17) * 2.4 +
                  MediaQuery.textScalerOf(context).scale(11) * 1.4 +
                  12)
              .clamp(68.0, 160.0),
          leadingWidth: 44,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        letterSpacing: -.4)),
                const SizedBox(height: 4),
                Text(
                    [
                      exercise.targetLabel ?? copy(exercise.target),
                      exercise.equipmentLabel ?? copy(exercise.equipment)
                    ].where((label) => label.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, height: 1.4, color: DSColors.muted)),
              ],
            ),
          ),
          leading: IconButton(
              tooltip: copy('Back'),
              icon: const Icon(CupertinoIcons.chevron_left, size: 21),
              onPressed: _busy ? null : () => Navigator.of(context).maybePop()),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: SegmentedButton<int>(
                  key: const ValueKey('exercise-detail-tabs'),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
                      backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? DSColors.bgRaised
                              : const Color(0xFF0D0D0D)),
                      foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? DSColors.silver
                              : DSColors.muted),
                      side: const WidgetStatePropertyAll(
                          BorderSide(color: DSColors.border, width: .7)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
                  segments: [
                    ButtonSegment(
                        value: 0,
                        label: Text(copy('Info'),
                            style: const TextStyle(fontSize: 13))),
                    ButtonSegment(
                        value: 1,
                        label: Text(copy('Progress'),
                            style: const TextStyle(fontSize: 13))),
                  ],
                  selected: {_tab},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _tab = selection.first;
                            _visitedProgress |= _tab == 1;
                          });
                        })),
          Expanded(
              child: Stack(fit: StackFit.expand, children: [
            _pane(0, _info(item, steps)),
            if (_visitedProgress)
              _pane(
                  1,
                  ExerciseInsights(
                      key: ValueKey(exercise.id),
                      exerciseId: exercise.id,
                      loader: widget.historyLoader)),
          ])),
        ]),
        bottomNavigationBar: _tab == 0 &&
                (item != null ||
                    (widget.onAddToPlan != null && exercise.supportsRepLogging))
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  child: item != null
                      ? WorkoutItemActions(
                          item: item,
                          busy: _busy,
                          onDone: () => _act(
                              () => WorkoutRepository.shared
                                  .markItemComplete(item.id),
                              close: false),
                          onSkip: () => _act(
                              () => WorkoutRepository.shared
                                  .markItemSkip(item.id),
                              close: false),
                          onUndo: () => _act(
                              () => WorkoutRepository.shared
                                  .resetItemStatus(item.id),
                              close: false),
                        )
                      : FilledButton(
                          onPressed:
                              _busy ? null : () => _act(widget.onAddToPlan!),
                          style: FilledButton.styleFrom(
                              backgroundColor: DSColors.silver,
                              foregroundColor: DSColors.bg,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: _busy
                              ? const CupertinoActivityIndicator()
                              : Text(copy(widget.addLabel),
                                  style: const TextStyle(fontSize: 14)),
                        ),
                ))
            : null,
      ),
    ));
  }
}
