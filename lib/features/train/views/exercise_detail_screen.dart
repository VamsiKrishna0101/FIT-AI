import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../components/exercise_muscle_map.dart';
import '../components/exercise_insights.dart';
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
  bool? _female;
  TodayPlanItemModel? _planItem;
  StreamSubscription<TodayPlanModel?>? _planSubscription;
  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _female = widget.female;
    if (_female == null) unawaited(_loadBodyStyle());
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
      setState(() => _female = gender?.toUpperCase() == 'FEMALE');
    } catch (_) {
      if (mounted && owner == await CacheScope.userId()) {
        setState(() => _female = false);
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
        .getExerciseDetail(widget.exercise.id, mediaGender: widget.mediaGender);
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
    final success = await WorkoutRepository.shared.updateWorkoutItem(
        widget.planItem!.id,
        targetSets: sets,
        targetReps: _reps.text.trim(),
        targetWeight: weight,
        restSeconds: rest);
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

  Widget _field(String label, TextEditingController controller) => TextField(
      controller: controller,
      enabled: !_busy,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
          labelText: fitnessText(context, label),
          filled: true,
          fillColor: const Color(0xFF2B2B2B),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none)));
  Widget _demo() => ClipRRect(
        key: const ValueKey('exercise-demo-stage'),
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _exercise.demoAspectRatio,
          child: RepaintBoundary(
            child: FitVideoSurface(
              url: _exercise.url,
              fit: BoxFit.contain,
              backgroundColor: Colors.white,
              neutralBackground: true,
              tapToToggle: false,
              placeholder: _exercise.thumbnailUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: _exercise.thumbnailUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Center(
                          child: Icon(CupertinoIcons.person,
                              size: 36, color: DSColors.muted)))
                  : const Center(
                      child: Icon(CupertinoIcons.person,
                          size: 36, color: DSColors.muted)),
            ),
          ),
        ),
      );

  Widget _targets(TodayPlanItemModel item) => PremiumSurface(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
              Row(children: [
                Expanded(child: _field('Sets', _sets)),
                const SizedBox(width: 10),
                Expanded(child: _field('Reps', _reps)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Load (kg)', _weight)),
                const SizedBox(width: 10),
                Expanded(child: _field('Rest (seconds)', _rest)),
              ]),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: _busy ? null : _save,
                  child: Text(fitnessText(context, 'Save targets'))),
            ],
          ),
        ),
      );

  Widget _guide(List<String> steps) {
    String copy(String text) => fitnessText(context, text);
    if (_loading) {
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(copy('How to perform'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 18),
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
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

  Widget _info(TodayPlanItemModel? item, List<String> steps) => ListView(
        key: PageStorageKey('exercise-info-${_exercise.id}'),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          _demo(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PremiumSurface(
                child: ExerciseMuscleMap(
                    exercise: _exercise,
                    female: _female ?? false,
                    anatomyReady: _female != null)),
          ),
          if (item != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _targets(item),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _guide(steps),
          ),
        ],
      );

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

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(primary: DSColors.silver, secondary: DSColors.silver),
      ),
      child: Scaffold(
        backgroundColor: DSColors.bg,
        appBar: AppBar(
          backgroundColor: DSColors.bg,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: (MediaQuery.textScalerOf(context).scale(18) * 2.4 +
                  MediaQuery.textScalerOf(context).scale(11) * 1.4 +
                  12)
              .clamp(72.0, 180.0),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
              onPressed: () => Navigator.of(context).maybePop()),
        ),
        body: DefaultTabController(
          length: 3,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                isScrollable: MediaQuery.textScalerOf(context).scale(13) > 17,
                tabAlignment: MediaQuery.textScalerOf(context).scale(13) > 17
                    ? TabAlignment.center
                    : TabAlignment.fill,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: (tab) {
                  FocusScope.of(context).unfocus();
                  setState(() => _tab = tab);
                },
                labelColor: DSColors.silver,
                unselectedLabelColor: DSColors.muted,
                dividerColor: DSColors.border,
                dividerHeight: .7,
                indicatorColor: DSColors.silver,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 2,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(height: 38, text: copy('Info')),
                  Tab(height: 38, text: copy('Progress')),
                  Tab(height: 38, text: copy('Rank'))
                ],
              ),
            ),
            Expanded(
                child: AnimatedSwitcher(
              duration: DSMotion.duration(context, DSMotion.selection),
              switchInCurve: DSMotion.effects,
              switchOutCurve: Curves.easeIn,
              child: _tab == 0
                  ? _info(item, steps)
                  : ExerciseInsights(
                      key: ValueKey(exercise.id),
                      exerciseId: exercise.id,
                      rank: _tab == 2,
                      loader: widget.historyLoader,
                    ),
            )),
          ]),
        ),
        bottomNavigationBar: item != null ||
                (widget.onAddToPlan != null && exercise.supportsRepLogging)
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
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
    );
  }
}
