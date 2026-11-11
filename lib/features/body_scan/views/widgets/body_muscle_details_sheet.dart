import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_map_models.dart';
import '../../models/planned_physique_models.dart';
import 'body_controls.dart';
import 'body_muscle_map_card.dart';

class BodyMuscleDetailsSheet extends StatelessWidget {
  final String id, period;
  final BodyMapRegion? region;
  final bool trained;
  final Color accent;
  final List<PlannedPhysiqueDay> workouts;

  const BodyMuscleDetailsSheet({
    super.key,
    required this.id,
    required this.region,
    required this.trained,
    required this.period,
    required this.workouts,
    this.accent = FitnessTheme.silver,
  });

  String _formatWeight(dynamic weight, dynamic unit) {
    if (weight == null || weight == 0) return 'Bodyweight';
    final num val = weight is num ? weight : (num.tryParse('$weight') ?? 0);
    if (val <= 0) return 'Bodyweight';
    final str = val == val.roundToDouble() ? '${val.toInt()}' : '$val';
    final u = unit != null && '$unit'.isNotEmpty ? ' $unit' : ' kg';
    return '$str$u';
  }

  String _formatReps(PlannedPhysiqueExercise exercise) {
    if (exercise.targetReps.isNotEmpty) {
      return exercise.targetReps;
    }
    return '—';
  }

  String _formatLoad(PlannedPhysiqueExercise exercise) {
    if (exercise.weightBasis == 'bodyweight') return 'Bodyweight';
    if (exercise.weightKg == null || exercise.weightKg! <= 0) {
      return 'Target load';
    }
    final val = exercise.weightKg!;
    final str = val == val.roundToDouble() ? '${val.toInt()}' : '$val';
    final unit = exercise.weightUnit == 'per_hand'
        ? ' / hand'
        : exercise.weightUnit == 'total_load'
            ? ' total'
            : '';
    return '$str kg$unit';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final muscleName = bodyRegionNames[id] ?? id;

    // Planned items
    final planned =
        <({PlannedPhysiqueDay day, List<PlannedPhysiqueExercise> exercises})>[
      for (final day in workouts)
        if (!day.restDay)
          (
            day: day,
            exercises: day.exercises
                .where((ex) =>
                    ex.primary.contains(id) || ex.secondary.contains(id))
                .toList()
          ),
    ]..removeWhere((group) => group.exercises.isEmpty);

    final plannedSets = planned.fold(
        0,
        (sum, group) =>
            sum + group.exercises.fold(0, (s, ex) => s + ex.sets));
    final totalPlannedExercises =
        planned.fold(0, (sum, g) => sum + g.exercises.length);

    // Trained items
    final logged = region?.loggedExercises ?? <Map<String, dynamic>>[];
    final completedSets = region?.completedSets ?? 0;
    final assistingSets = region?.assistingSets ?? 0;
    final totalSets = region?.involvedSets ?? (completedSets + assistingSets);

    int totalReps = 0;
    for (final ex in logged) {
      final sets = (ex['sets'] as List? ?? []).whereType<Map>();
      for (final s in sets) {
        totalReps += (s['reps'] as num?)?.toInt() ?? 0;
      }
    }

    final bool isCompleted = (region != null &&
        ((region!.plannedSets > 0 &&
                region!.completedSets >= region!.plannedSets) ||
            region!.status == 'completed' ||
            (region!.plannedSets == 0 && region!.completedSets >= 3)));
    final bool isInProgress = !isCompleted &&
        region != null &&
        (region!.status == 'in_progress' ||
            region!.completedSets > 0 ||
            region!.assistingSets > 0 ||
            region!.status == 'logged');

    final Color statusColor;
    final String statusLabel;

    if (!trained) {
      statusColor = BodyMapPalette.planned;
      statusLabel = 'PLANNED TARGET';
    } else if (isCompleted) {
      statusColor = BodyMapPalette.completed;
      statusLabel = 'COMPLETED';
    } else if (isInProgress) {
      statusColor = BodyMapPalette.progress;
      statusLabel = 'IN PROGRESS';
    } else {
      statusColor = FitnessTheme.muted;
      statusLabel = 'UNTRAINED';
    }

    return FitnessTheme(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383C44),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Row (Clean, premium, NO stupid icons)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.35),
                                    width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                period,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FitnessText(
                          muscleName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: fitnessText(context, 'Close'),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF24272C),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(CupertinoIcons.xmark,
                        size: 14, color: FitnessTheme.silver),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Premium Stat Strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF191B20),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0x18FFFFFF), width: 0.8),
                ),
                child: Row(
                  children: trained
                      ? [
                          _statItem(
                              'TOTAL SETS', '$totalSets', statusColor),
                          _statDivider(),
                          _statItem(
                              'TOTAL REPS', '$totalReps', Colors.white),
                          _statDivider(),
                          _statItem(
                              'EXERCISES', '${logged.length}', FitnessTheme.silver),
                        ]
                      : [
                          _statItem('PLANNED SETS', '$plannedSets',
                              BodyMapPalette.planned),
                          _statDivider(),
                          _statItem('EXERCISES', '$totalPlannedExercises',
                              Colors.white),
                          _statDivider(),
                          _statItem('SESSIONS', '${planned.length}',
                              FitnessTheme.silver),
                        ],
                ),
              ),
              const SizedBox(height: 16),

              // Content List
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: trained
                        ? _buildTrainedContent(context, logged, muscleName)
                        : _buildPlannedContent(context, planned, locale, muscleName),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: FitnessTheme.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: const Color(0x1AFFFFFF),
      );

  Widget _buildTrainedContent(
      BuildContext context, List<Map<String, dynamic>> logged, String muscleName) {
    if (region == null) {
      return _emptyMessage(
        title: 'Training data unavailable',
        detail: 'Pull to refresh the Body tab to reload your training history.',
      );
    }

    if (logged.isEmpty) {
      return _emptyMessage(
        title: 'No logged sets in this period',
        detail:
            'Completed exercises and logged reps for $muscleName will automatically appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final exercise in logged) ...[
          _buildTrainedExerciseCard(context, exercise),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTrainedExerciseCard(
      BuildContext context, Map<String, dynamic> exercise) {
    final sets = (exercise['sets'] as List? ?? []).whereType<Map>().toList();
    final directSets = (exercise['directSets'] as num?)?.toInt() ?? 0;
    final assistingSets = (exercise['assistingSets'] as num?)?.toInt() ?? 0;
    final exerciseSetsCount = directSets + assistingSets;

    int exerciseReps = 0;
    for (final s in sets) {
      exerciseReps += (s['reps'] as num?)?.toInt() ?? 0;
    }

    final isDirect = directSets > 0;
    final tagText = isDirect ? 'Direct Target' : 'Assisting Muscle';
    final tagColor = isDirect ? BodyMapPalette.completed : BodyMapPalette.progress;

    return Material(
      color: const Color(0xFF1A1D22),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('body-muscle-exercise-${exercise['exerciseId']}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(
            context, BodyExerciseSelection('${exercise['exerciseId']}')),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exercise Name & Focus Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${exercise['name'] ?? 'Exercise'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tagText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tagColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$exerciseSetsCount sets',
                              style: const TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: FitnessTheme.muted,
                  ),
                ],
              ),

              // Reps Table
              if (sets.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131518),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0x10FFFFFF), width: 0.7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              'SET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FitnessTheme.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Spacer(),
                          Text(
                            'REPS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: FitnessTheme.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 28),
                          SizedBox(
                            width: 85,
                            child: Text(
                              'LOAD',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FitnessTheme.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < sets.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 10, color: Color(0x0CFFFFFF)),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22262B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${sets[i]['setNumber'] ?? i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${sets[i]['reps'] ?? 0} reps',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 28),
                            SizedBox(
                              width: 85,
                              child: Text(
                                _formatWeight(
                                    sets[i]['weight'], sets[i]['weightUnit']),
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: FitnessTheme.silver,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        'Total: $exerciseReps reps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FitnessTheme.silver,
                        ),
                      ),
                      const Spacer(),
                      if (exercise['lastDate'] case final String lastDate
                          when lastDate.isNotEmpty)
                        Text(
                          'Last logged $lastDate',
                          style: const TextStyle(
                            fontSize: 10,
                            color: FitnessTheme.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlannedContent(
      BuildContext context,
      List<({PlannedPhysiqueDay day, List<PlannedPhysiqueExercise> exercises})>
          planned,
      String locale,
      String muscleName) {
    if (planned.isEmpty) {
      return _emptyMessage(
        title: 'No plan for this week',
        detail:
            'This muscle has no scheduled exercises in your active training plan.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in planned) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.MMMEd(locale)
                        .format(DateTime.parse(group.day.date)),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (group.day.status == 'COMPLETED')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: BodyMapPalette.completed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: BodyMapPalette.completed,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final exercise in group.exercises) ...[
            _buildPlannedExerciseCard(context, exercise, group.day.date),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _buildPlannedExerciseCard(BuildContext context,
      PlannedPhysiqueExercise exercise, String date) {
    final sets = (exercise.setPrescriptions).whereType<Map>().toList();
    final isPrimary = exercise.primary.contains(id);
    final focusLabel = isPrimary ? 'Primary Focus' : 'Assisting';
    final focusColor =
        isPrimary ? BodyMapPalette.planned : FitnessTheme.silver;

    return Material(
      color: const Color(0xFF1A1D22),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(
          context,
          BodyExerciseSelection(exercise.exerciseId,
              recommendation: exercise, date: date),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: focusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                focusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: focusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${exercise.sets} sets × ${_formatReps(exercise)} reps',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: FitnessTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatLoad(exercise),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FitnessTheme.silver,
                    ),
                  ),
                ],
              ),

              // Set prescriptions list if available
              if (sets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131518),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0x0EFFFFFF), width: 0.6),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < sets.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 8, color: Color(0x0CFFFFFF)),
                        Row(
                          children: [
                            Text(
                              'Set ${sets[i]['setNumber'] ?? i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: FitnessTheme.muted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${sets[i]['targetReps'] ?? sets[i]['reps'] ?? _formatReps(exercise)} reps',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              _formatWeight(
                                  sets[i]['weightKg'] ?? sets[i]['weight'],
                                  sets[i]['weightUnit']),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: FitnessTheme.silver,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Targets & Cues
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (exercise.restSeconds case final num rest when rest > 0)
                    Text(
                      '${rest.toInt()}s rest',
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted),
                    ),
                  if (exercise.targetRpe case final num rpe when rpe > 0)
                    Text(
                      'Target RPE $rpe',
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted),
                    ),
                ],
              ),

              // Coaching Note
              if (exercise.reason case final String reason
                  when reason.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131518),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reason.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: FitnessTheme.muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyMessage({required String title, required String detail}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2E323A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            FitnessText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            FitnessText(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: FitnessTheme.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
