import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/localization/fitai_copy.dart';
import '../models/workout_exercise_models.dart';
import '../repositories/workout_repository.dart';
import '../components/workout_item_actions.dart';
import 'exercise_detail_view.dart';
import 'exercise_library_view.dart';

class TodayPlanView extends StatefulWidget {
  const TodayPlanView({super.key});
  @override
  State<TodayPlanView> createState() => _TodayPlanViewState();
}

class _TodayPlanViewState extends State<TodayPlanView> {
  TodayPlanModel? _plan;
  bool _loading = true, _edit = false;
  String _locale = '';
  int _request = 0;
  final _saving = <String>{};
  StreamSubscription<TodayPlanModel?>? _subscription;
  @override
  void initState() {
    super.initState();
    _plan = WorkoutRepository.shared.currentPlan;
    _locale = LanguageManager.shared.currentLanguage.code;
    _loading = _plan == null;
    LanguageManager.shared.addListener(_languageChanged);
    _subscription = WorkoutRepository.shared.planStream.listen((plan) {
      if (mounted) {
        setState(() {
          _plan = plan;
          _loading = false;
        });
      }
    });
    unawaited(_load());
  }

  void _languageChanged() {
    final locale = LanguageManager.shared.currentLanguage.code;
    if (_locale == locale) return;
    _locale = locale;
    setState(() {
      _plan = null;
      _loading = true;
    });
    unawaited(_load(refresh: true));
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    final plan = await WorkoutRepository.shared
        .getTodayWorkoutPlan(forceRefresh: refresh);
    if (mounted && request == _request) {
      setState(() {
        _plan = plan;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() => _plan = WorkoutRepository.shared.currentPlan);
  }

  void _library() => Navigator.of(context).push(CupertinoPageRoute<void>(
      builder: (_) => ExerciseLibraryView(onExerciseAdded: _sync)));
  void _detail(TodayPlanItemModel item) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(
          builder: (_) => ExerciseDetailView(
              exercise: item.exercise,
              planItem: item,
              onStatusChanged: _sync)));
  Future<void> _action(
      TodayPlanItemModel item, Future<bool> Function() action) async {
    if (_saving.contains(item.id)) return;
    setState(() => _saving.add(item.id));
    final success = await action();
    if (!mounted) return;
    setState(() {
      _saving.remove(item.id);
      _plan = WorkoutRepository.shared.currentPlan;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(fitnessText(context, 'Could not save. Please try again.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = FitAiCopy.of(context);
    String text(String value) => fitnessText(context, value);
    final plan = _plan;
    return Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFE2E2E2),
                secondary: const Color(0xFFE2E2E2))),
        child: Scaffold(
          backgroundColor: const Color(0xFF111111),
          appBar: AppBar(
              backgroundColor: const Color(0xFF111111),
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              titleSpacing: 0,
              leading: IconButton(
                  tooltip: text('Back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(CupertinoIcons.chevron_left, size: 22)),
              title: Text(text('Today’s workout'),
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.4)),
              actions: [
                if (_edit)
                  TextButton(
                      onPressed: () => setState(() => _edit = false),
                      child: Text(text('Done')))
                else
                  PopupMenuButton<String>(
                      tooltip: text('Edit'),
                      icon: const Icon(CupertinoIcons.ellipsis, size: 22),
                      color: const Color(0xFF282828),
                      onSelected: (_) => setState(() => _edit = true),
                      itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'edit',
                                enabled: plan?.items.isNotEmpty == true,
                                child: Text(text('Edit')))
                          ]),
                IconButton(
                    tooltip: text('Add Exercise'),
                    onPressed: _library,
                    icon: const Icon(CupertinoIcons.plus))
              ]),
          body: SafeArea(
              top: false,
              child: RefreshIndicator(
                  color: const Color(0xFFE2E2E2),
                  onRefresh: () => _load(refresh: true),
                  child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      slivers: [
                        if (_loading)
                          const SliverFillRemaining(
                              child:
                                  Center(child: CupertinoActivityIndicator()))
                        else if (plan == null || plan.items.isEmpty)
                          SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    Text(copy.text('noPlan'),
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(height: 12),
                                    TextButton(
                                        onPressed: _library,
                                        child: Text(text('Explore exercises'))),
                                  ])))
                        else ...[
                          SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 22),
                              sliver: SliverToBoxAdapter(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                fitnessText(context,
                                                    '{completed} of {total} completed',
                                                    values: {
                                                      'completed':
                                                          plan.completedCount,
                                                      'total': plan.totalCount
                                                    }),
                                                style: const TextStyle(
                                                    fontSize: 21,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: -.6)),
                                            const SizedBox(height: 12),
                                            ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                    value: plan.progress,
                                                    minHeight: 3,
                                                    backgroundColor:
                                                        const Color(0xFF383838),
                                                    color: const Color(
                                                        0xFFE2E2E2))),
                                            if (plan.skippedCount > 0)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 9),
                                                  child: Text(
                                                      '${plan.skippedCount} ${text('Skipped')}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                              0xFF969696)))),
                                            if (plan.aiNote?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 12),
                                              Theme(
                                                  data: Theme.of(context)
                                                      .copyWith(
                                                          dividerColor: Colors
                                                              .transparent),
                                                  child: ExpansionTile(
                                                      dense: true,
                                                      tilePadding: EdgeInsets
                                                          .zero,
                                                      childrenPadding:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      title: Text(
                                                          text('Overview'),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                      children: [
                                                        Text(plan.aiNote!,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                    0xFF969696),
                                                                height: 1.5))
                                                      ])),
                                            ]
                                          ])))),
                          SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              sliver: SliverToBoxAdapter(
                                  child: Text(text('Exercises'),
                                      style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.35)))),
                          SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                              sliver: SliverList.separated(
                                  itemCount: plan.items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, index) {
                                    final item = plan.items[index],
                                        exercise = plan.items[index].exercise;
                                    return PremiumSurface(
                                        key:
                                            ValueKey('workout-card-${item.id}'),
                                        color: const Color(0xFF202020),
                                        radius: 20,
                                        padding: const EdgeInsets.all(14),
                                        child: Column(children: [
                                          InkWell(
                                              onTap: _saving.contains(item.id)
                                                  ? null
                                                  : () => _detail(item),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Row(children: [
                                                ExercisePoster(
                                                    exercise: exercise,
                                                    size: 56),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                          exercise.name.isEmpty
                                                              ? exercise.name
                                                              : '${exercise.name.characters.first.toUpperCase()}${exercise.name.characters.skip(1)}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  height: 1.3)),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                          '${item.targetSets} ${text('Sets')} · ${item.targetReps} ${text('Reps')}',
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Color(
                                                                  0xFF969696))),
                                                      if (item.targetWeight > 0)
                                                        Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 3),
                                                            child: Text(
                                                                '${text('Load (kg)')}: ${NumberFormat('0.##', Localizations.localeOf(context).toLanguageTag()).format(item.targetWeight)}',
                                                                style: const TextStyle(
                                                                    color: Color(
                                                                        0xFF969696),
                                                                    fontSize:
                                                                        12))),
                                                    ])),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                    CupertinoIcons
                                                        .chevron_right,
                                                    size: 13,
                                                    color: Color(0xFF737373)),
                                              ])),
                                          const SizedBox(height: 12),
                                          if (_edit)
                                            Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton.icon(
                                                    onPressed: _saving.contains(item.id)
                                                        ? null
                                                        : () => _action(
                                                            item,
                                                            () => WorkoutRepository.shared
                                                                .deleteWorkoutItem(
                                                                    item.id)),
                                                    icon: const Icon(CupertinoIcons.minus_circle,
                                                        size: 17),
                                                    label: Text(text(
                                                        'Remove exercise'))))
                                          else
                                            WorkoutItemActions(
                                                item: item,
                                                busy: _saving.contains(item.id),
                                                onDone: () => _action(item, () => WorkoutRepository.shared.markItemComplete(item.id)),
                                                onSkip: () => _action(item, () => WorkoutRepository.shared.markItemSkip(item.id)),
                                                onUndo: () => _action(item, () => WorkoutRepository.shared.resetItemStatus(item.id))),
                                        ]));
                                  })),
                        ]
                      ]))),
        ));
  }
}
