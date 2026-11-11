import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/home_models.dart';
import '../../../core/components/liquid_glass_box.dart';
import '../../../core/media/fit_video_surface.dart';
import '../../train/models/workout_exercise_models.dart';
import '../../train/repositories/workout_repository.dart';
import '../../train/views/exercise_detail_view.dart';
import '../../train/views/train_view.dart';

// MARK: - Silver Liquid Glass Today's Workout Card
class TodayWorkoutCard extends StatefulWidget {
  final HomeTodayWorkout? workout;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
  });

  @override
  State<TodayWorkoutCard> createState() => _TodayWorkoutCardState();
}

class _TodayWorkoutCardState extends State<TodayWorkoutCard> {
  TodayPlanModel? _plan;
  StreamSubscription<TodayPlanModel?>? _planSub;

  @override
  void initState() {
    super.initState();
    _plan = WorkoutRepository.shared.currentPlan;
    _planSub = WorkoutRepository.shared.planStream.listen((plan) {
      if (mounted) setState(() => _plan = plan);
    });
    WorkoutRepository.shared.getTodayWorkoutPlan().then((plan) {
      if (mounted && plan != null) setState(() => _plan = plan);
    });
  }

  @override
  void dispose() {
    _planSub?.cancel();
    super.dispose();
  }

  /// Opens today's full plan.
  void _openFullPlan() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => const TrainView(standalone: true)),
    );
  }

  void _openExerciseDetail(TodayPlanItemModel item) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => ExerciseDetailView(
          exercise: item.exercise,
          planItem: item,
          onStatusChanged: () {
            WorkoutRepository.shared.getTodayWorkoutPlan(forceRefresh: true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final plan = _plan;
    final items = plan?.items ?? [];
    final activeItem = items.isNotEmpty
        ? items.firstWhere((it) => it.isPending, orElse: () => items.first)
        : null;

    // Real values only — no invented fallbacks.
    final exerciseCount =
        items.isNotEmpty ? items.length : (w?.exerciseCount ?? 0);
    final durationMin = items.isNotEmpty
        ? plan!.estimatedDurationMinutes
        : (w?.durationMinutes ?? 0);
    final rpeValues =
        items.map((i) => i.targetRpe).whereType<double>().toList();
    final avgRpe = rpeValues.isEmpty
        ? null
        : rpeValues.reduce((a, b) => a + b) / rpeValues.length;
    final title = (w?.workoutTitle.isNotEmpty ?? false)
        ? w!.workoutTitle
        : (plan?.weekLabel.isNotEmpty ?? false)
            ? plan!.weekLabel
            : 'Today\'s session';
    final metaParts = <String>[
      if (exerciseCount > 0)
        '$exerciseCount ${exerciseCount == 1 ? 'EXERCISE' : 'EXERCISES'}',
      if (durationMin > 0) '$durationMin MIN',
    ];

    final isCompleted = w?.status == 'COMPLETED';
    final isInProgress = w?.status == 'IN_PROGRESS';
    final isRestDay = w?.status == 'REST_DAY';
    final hasActiveSession = w != null && !isRestDay;
    final doneCount = items.where((i) => !i.isPending).length;

    final String statusLabel = isCompleted
        ? 'COMPLETED'
        : (isInProgress
            ? 'IN PROGRESS'
            : (hasActiveSession ? 'UP NEXT' : 'REST DAY'));

    final displayTitle = isRestDay ? 'Rest & Recovery' : title;

    return LiquidGlassBox(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRestDay
                      ? const Color(0xFFD6C7F8)
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FitnessText(
                  isRestDay ? 'TODAY\'S RECOVERY' : 'TODAY\'S STRAIN TARGET',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ),
              LiquidGlassPill(
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Title & Meta ──────────────────────────────────────────────
          Text(
            displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          if (isRestDay) ...[
            const SizedBox(height: 8),
            Text(
              'Your plan has no workout scheduled today. Take time to recharge and rebuild.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE2DCF1).withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      CupertinoIcons.moon_fill,
                      size: 18,
                      color: Color(0xFFD6C7F8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Muscle Repair & Growth',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Light mobility, proper hydration, and sleep fuel your gains.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            if (metaParts.isNotEmpty || avgRpe != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < metaParts.length; i++) ...[
                    if (i > 0) const _MetaDot(),
                    Text(
                      metaParts[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  if (avgRpe != null) ...[
                    if (metaParts.isNotEmpty) const _MetaDot(),
                    Text(
                      '${avgRpe.toStringAsFixed(1)} RPE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Color(0xFF5AC8FA),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PlanProgress(done: doneCount, total: items.length),
            ],
            const SizedBox(height: 14),

            // ── Up-Next Exercise Preview ──────────────────────────────────
            if (activeItem != null)
              GestureDetector(
                onTap: () => _openExerciseDetail(activeItem),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(0.8),
                  child: FitVideoSurface(
                    url: activeItem.exercise.url,
                    fit: BoxFit.contain,
                    aspectRatio: activeItem.exercise.demoAspectRatio,
                    neutralBackground: true,
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    overlays: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                      // Primary focus glass chip
                      Positioned(
                        top: 12,
                        left: 12,
                        child: LiquidGlassPill(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FitnessText(
                                'PRIMARY FOCUS',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                activeItem.exercise.bodyPart.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    activeItem.exercise.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${activeItem.targetSets} Sets × ${activeItem.targetReps} Reps • ${activeItem.targetWeight > 0 ? '${activeItem.targetWeight} kg' : 'Bodyweight'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const LiquidOrbIcon(
                              icon: CupertinoIcons.arrow_right,
                              size: 38,
                              iconSize: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (activeItem != null) const SizedBox(height: 14),
          ],

          // ── View Full Plan (single full-width action) ─────────────────
          LiquidGlassButton(
            onTap: _openFullPlan,
            height: 54,
            borderRadius: 27,
            prominent: !isRestDay,
            padding: const EdgeInsets.only(left: 22, right: 7),
            child: Row(
              children: [
                Expanded(
                  child: FitnessText(
                    isRestDay ? 'VIEW TRAINING SCHEDULE' : 'VIEW FULL PLAN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanProgress extends StatelessWidget {
  final int done;
  final int total;

  const _PlanProgress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB9C2C9), Color(0xFFFFFFFF)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done/$total DONE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.7),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
    );
  }
}
