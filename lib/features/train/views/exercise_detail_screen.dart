import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/media/fit_video_surface.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import '../components/workout_item_actions.dart';

class ExerciseDetailView extends StatefulWidget {
  final TodayPlanItemModel? planItem;
  final WorkoutExerciseModel exercise;
  final VoidCallback? onStatusChanged;
  final Future<bool> Function()? onAddToPlan;
  final bool loadDetail;
  const ExerciseDetailView(
      {super.key,
      this.planItem,
      required this.exercise,
      this.onStatusChanged,
      this.onAddToPlan,
      this.loadDetail = true});
  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  late WorkoutExerciseModel _exercise;
  late final TextEditingController _sets, _reps, _weight, _rest;
  bool _busy = false, _loading = false, _detailFailed = false;
  String _locale = '';
  int _request = 0;
  TodayPlanItemModel? _planItem;
  StreamSubscription<TodayPlanModel?>? _planSubscription;
  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
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

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _detailFailed = false;
    });
    final exercise =
        await WorkoutRepository.shared.getExerciseDetail(widget.exercise.id);
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
  @override
  Widget build(BuildContext context) {
    final exercise = _exercise, item = _planItem;
    String copy(String text) => fitnessText(context, text);
    final title = exercise.name.isEmpty
        ? exercise.name
        : '${exercise.name.characters.first.toUpperCase()}${exercise.name.characters.skip(1)}';
    final steps = exercise.localizedInstructionSteps(
        Localizations.localeOf(context).toLanguageTag());
    return Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFE2E2E2),
                secondary: const Color(0xFFE2E2E2))),
        child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: AppBar(
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              title: Text(copy('Exercise details'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB2B2B2))),
              leading: IconButton(
                  tooltip: copy('Back'),
                  icon: const Icon(CupertinoIcons.chevron_left),
                  onPressed: () => Navigator.of(context).maybePop())),
          body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        letterSpacing: -.65)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final label in [
                    exercise.targetLabel ?? copy(exercise.target),
                    exercise.equipmentLabel ?? copy(exercise.equipment)
                  ])
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                            color: const Color(0xFF242424),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB2B2B2)))),
                ]),
                const SizedBox(height: 18),
                RepaintBoundary(
                    child: Container(
                        key: const ValueKey('exercise-demo-stage'),
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: const Color(0x18FFFFFF))),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: LayoutBuilder(
                                builder: (context, bounds) => SizedBox(
                                    height: bounds.maxWidth + 56,
                                    child: FitVideoSurface(
                                        url: exercise.url,
                                        fit: BoxFit.contain,
                                        backgroundColor: DSColors.bg,
                                        neutralBackground: true,
                                        tapToToggle: true,
                                        placeholder: exercise
                                                    .thumbnailUrl?.isNotEmpty ==
                                                true
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    exercise.thumbnailUrl!,
                                                fit: BoxFit.contain,
                                                errorWidget: (_, __, ___) =>
                                                    const Center(
                                                        child: Icon(
                                                            CupertinoIcons.person,
                                                            size: 40)))
                                            : const Center(child: Icon(CupertinoIcons.person, color: Color(0xFF969696), size: 40)))))))),
                const SizedBox(height: 22),
                PremiumSurface(
                    color: DSColors.bgCard,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(copy('Target muscles'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 9),
                          Text(exercise.targetLabel ?? copy(exercise.target),
                              style: const TextStyle(color: Color(0xFFE2E2E2))),
                          if (exercise.secondaryMuscles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(copy('Secondary muscles'),
                                style: const TextStyle(
                                    color: Color(0xFF969696), fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(
                                (exercise.secondaryMuscleLabels ??
                                        exercise.secondaryMuscles
                                            .map(copy)
                                            .toList())
                                    .join(' · '),
                                style:
                                    const TextStyle(fontSize: 13, height: 1.4)),
                          ],
                        ])),
                if (item != null) ...[
                  const SizedBox(height: 22),
                  Text(copy('Your targets'),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  PremiumSurface(
                      color: DSColors.bgCard,
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: _field('Sets', _sets)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Reps', _reps))
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _field('Load (kg)', _weight)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Rest (seconds)', _rest))
                        ]),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: _busy ? null : _save,
                            child: Text(copy('Save targets'))),
                      ])),
                ],
                const SizedBox(height: 22),
                Text(copy('How to perform'),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(22),
                      child: Center(child: CupertinoActivityIndicator()))
                else if (_detailFailed && steps.isEmpty)
                  PremiumSurface(
                      child: Column(children: [
                    Text(copy('Could not load the form guide.')),
                    TextButton(onPressed: _load, child: Text(copy('Retry'))),
                  ]))
                else
                  PremiumSurface(
                      color: DSColors.bgCard,
                      child: Column(children: [
                        for (var index = 0; index < steps.length; index++) ...[
                          if (index > 0)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(
                                    height: 1, color: Color(0x14FFFFFF))),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF353535),
                                        shape: BoxShape.circle),
                                    child: Text('${index + 1}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                const SizedBox(width: 13),
                                Expanded(
                                    child: Text(steps[index],
                                        style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.55,
                                            color: Color(0xFFE2E2E2)))),
                              ]),
                        ],
                        if (exercise.contentLanguage == 'en' &&
                            Localizations.localeOf(context).languageCode !=
                                'en') ...[
                          const SizedBox(height: 14),
                          Text(
                              copy(
                                  'English instructions shown while this translation is unavailable.'),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF969696))),
                        ],
                      ])),
                if (exercise.description.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                              tilePadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(copy('Overview'),
                                  style: const TextStyle(fontSize: 14)),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(4, 0, 4, 14),
                              children: [
                                Text(exercise.description,
                                    style: const TextStyle(
                                        color: Color(0xFF969696),
                                        fontSize: 13,
                                        height: 1.5))
                              ]))),
                if (exercise.attribution?.isNotEmpty == true)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(exercise.attribution!,
                          style: const TextStyle(
                              color: Color(0xFF777777), fontSize: 10))),
              ]),
          bottomNavigationBar: item != null || widget.onAddToPlan != null
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: item != null
                        ? WorkoutItemActions(
                            item: item,
                            busy: _busy,
                            onDone: () =>
                                _act(() => WorkoutRepository.shared.markItemComplete(item.id),
                                    close: false),
                            onSkip: () =>
                                _act(() => WorkoutRepository.shared.markItemSkip(item.id),
                                    close: false),
                            onUndo: () =>
                                _act(() => WorkoutRepository.shared.resetItemStatus(item.id),
                                    close: false))
                        : SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _act(widget.onAddToPlan!),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE2E2E2),
                                    foregroundColor: DSColors.bg,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                child: _busy ? const CupertinoActivityIndicator() : Text(copy('Add to today')))),
                  ))
              : null,
        ));
  }
}
