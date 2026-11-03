import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

/// The same prescription follows an exercise from Body into the weekly plan.
/// Keep the working targets visible; reveal coaching only when requested.
class ExerciseRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int? number;
  final VoidCallback? onOpenExercise;
  const ExerciseRecommendationCard({
    super.key,
    required this.exercise,
    this.number,
    this.onOpenExercise,
  });

  String _number(num value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  String _reps(Map row) {
    if (row['targetReps'] case final String reps when reps.isNotEmpty) {
      return reps;
    }
    final low = row['repsMin'], high = row['repsMax'];
    if (low == null && high == null) return '\u2014';
    return low == high || low == null || high == null
        ? '${high ?? low}'
        : '$low\u2013$high';
  }

  String _load(num? weight) {
    if (exercise['weightBasis'] == 'bodyweight') return 'Bodyweight';
    if (weight == null || weight <= 0) return 'Find starting load';
    final unit = exercise['weightUnit'];
    return '${_number(weight)} kg${unit == 'per_hand' ? ' / hand' : unit == 'total_load' ? ' total' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final sets =
        (exercise['setPrescriptions'] as List? ?? []).whereType<Map>().toList();
    final weights = sets.map((s) => s['weightKg'] as num?).toList();
    String load;
    if (weights.isNotEmpty && weights.any((w) => w == null || w <= 0)) {
      load = exercise['weightBasis'] == 'bodyweight'
          ? 'Bodyweight'
          : 'Find starting load';
    } else if (weights.isNotEmpty && weights.toSet().length > 1) {
      final sorted = weights.whereType<num>().toList()..sort();
      final unit = exercise['weightUnit'] == 'per_hand' ? ' / hand' : '';
      load = '${_number(sorted.first)}\u2013${_number(sorted.last)} kg$unit';
    } else {
      load = _load(weights.firstOrNull ?? exercise['weightKg'] as num?);
    }
    final count = sets.isEmpty ? exercise['sets'] ?? 0 : sets.length;
    final reps = sets.isNotEmpty && sets.map(_reps).toSet().length == 1
        ? _reps(sets.first)
        : sets.isNotEmpty
            ? 'Variable'
            : _reps(exercise);
    final reason = (exercise['reason'] as String? ?? '').trim();
    final progression = (exercise['progression'] as String? ?? '').trim();
    return FitnessCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(
              'prescription-${exercise['date'] ?? ''}-${exercise['itemId'] ?? exercise['exerciseId']}-${number ?? 0}'),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: FitnessTheme.muted,
          collapsedIconColor: FitnessTheme.muted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: number == null
              ? null
              : Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF272A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$number'.padLeft(2, '0'),
                      style: const TextStyle(
                          fontSize: 10, color: FitnessTheme.muted)),
                ),
          title: Text(
              '${exercise['displayName'] ?? exercise['name'] ?? 'Exercise'}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(spacing: 10, runSpacing: 4, children: [
              FitnessText('{sets} \u00d7 {reps}',
                  values: {'sets': count, 'reps': reps},
                  style:
                      const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
              FitnessText(load,
                  style: const TextStyle(
                      fontSize: 12, color: FitnessTheme.silver)),
            ]),
          ),
          children: [
            const Divider(height: 1, color: FitnessTheme.line),
            const SizedBox(height: 14),
            if (sets.isNotEmpty) ...[
              _setRow(context, 'Set', 'Reps', 'Load', heading: true),
              const SizedBox(height: 4),
              for (var i = 0; i < sets.length; i++)
                _setRow(context, '${sets[i]['setNumber'] ?? i + 1}',
                    _reps(sets[i]), _load(sets[i]['weightKg'] as num?)),
              const SizedBox(height: 10),
            ],
            Wrap(spacing: 14, runSpacing: 6, children: [
              if (exercise['restSeconds'] case final num rest)
                _cue(context, CupertinoIcons.timer, '${_number(rest)} s rest'),
              if (exercise['targetRpe'] case final num rpe)
                _cue(context, CupertinoIcons.speedometer,
                    'Effort ${_number(rpe)}/10'),
            ]),
            if (exercise['weightBasis'] == 'estimated_start') ...[
              const SizedBox(height: 10),
              const FitnessText(
                  'Starting estimate \u00b7 adjust to your effort',
                  style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
            ],
            if (reason.isNotEmpty || progression.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121416),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (reason.isNotEmpty) _coaching('Why this fits', reason),
                      if (reason.isNotEmpty && progression.isNotEmpty)
                        const SizedBox(height: 14),
                      if (progression.isNotEmpty)
                        _coaching('Next step', progression),
                    ]),
              ),
            ],
            if (onOpenExercise != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onOpenExercise,
                  icon: const Icon(CupertinoIcons.play_circle, size: 17),
                  label: const FitnessText('Form & history',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: FitnessTheme.silver),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _setRow(BuildContext context, String set, String reps, String load,
          {bool heading = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: DefaultTextStyle(
          style: TextStyle(
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              fontSize: heading ? 10 : 12,
              color: heading ? FitnessTheme.muted : FitnessTheme.silver),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 38, child: FitnessText(set)),
            Expanded(flex: 2, child: FitnessText(reps)),
            const SizedBox(width: 8),
            Expanded(
                flex: 4, child: FitnessText(load, textAlign: TextAlign.end)),
          ]),
        ),
      );

  Widget _cue(BuildContext context, IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: FitnessTheme.muted),
        const SizedBox(width: 5),
        FitnessText(text,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      ]);

  Widget _coaching(String label, String text) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        FitnessText(text,
            style: const TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
      ]);
}
