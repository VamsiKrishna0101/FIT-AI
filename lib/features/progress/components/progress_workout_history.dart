import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressWorkoutTile extends StatelessWidget {
  final ProgressJson session;
  final VoidCallback onTap;
  const ProgressWorkoutTile(
      {super.key, required this.session, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime.tryParse(session['date']?.toString() ?? '');
    final seconds = progressNumber(session['durationSeconds']);
    final exercises = progressRows(session['exercises']);
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(13)),
                  child: Column(children: [
                    Text(date == null ? '—' : DateFormat.d(locale).format(date),
                        style: const TextStyle(
                            color: progressSilver,
                            fontSize: 19,
                            fontWeight: FontWeight.w600)),
                    Text(
                        date == null ? '' : DateFormat.MMM(locale).format(date),
                        style: const TextStyle(
                            color: progressSilver, fontSize: 10)),
                  ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        progressTitle(fitnessText(
                            context, session['name'] as String? ?? 'Workout')),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Text(
                        [
                          if (exercises.isNotEmpty)
                            '${exercises.length} ${fitnessText(context, 'exercises')}',
                          '${session['sets'] ?? 0} ${fitnessText(context, 'sets')}',
                          if (seconds != null && seconds > 0)
                            '${(seconds / 60).round()} ${fitnessText(context, 'min')}',
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11, color: progressMuted, height: 1.5)),
                    if ((progressNumber(session['records']) ?? 0) > 0) ...[
                      const SizedBox(height: 7),
                      _RecordBadge(count: (session['records'] as num).toInt()),
                    ],
                    if (session['status'] != 'COMPLETED') ...[
                      const SizedBox(height: 4),
                      Text(fitnessText(context, 'In progress'),
                          style: const TextStyle(
                              color: progressMuted, fontSize: 11)),
                    ],
                  ])),
              const SizedBox(width: 8),
              const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(Icons.chevron_right,
                      size: 18, color: progressMuted)),
            ])));
  }
}

class _RecordBadge extends StatelessWidget {
  final int count;
  const _RecordBadge({required this.count});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
            child: Text('${fitnessText(context, 'New records')} · $count',
                style: const TextStyle(
                    color: progressMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))),
      ]);
}

class ProgressWorkoutHistory extends StatelessWidget {
  final List<ProgressJson> sessions;
  final ValueChanged<ProgressJson> onSession;
  const ProgressWorkoutHistory(
      {super.key, required this.sessions, required this.onSession});
  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const ProgressEmpty('No workouts in this period');
    }
    final groups = <String, List<ProgressJson>>{};
    for (final session in sessions) {
      final date = session['date'] as String? ?? '';
      final key = date.length >= 7 ? date.substring(0, 7) : '';
      groups.putIfAbsent(key, () => []).add(session);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final group in groups.entries) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(4, 17, 4, 10),
            child: Text(
                group.key.isEmpty
                    ? fitnessText(context, 'Workout history')
                    : DateFormat.yMMMM(locale)
                        .format(DateTime.parse('${group.key}-01')),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600))),
        ProgressSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              for (var i = 0; i < group.value.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, color: Color(0x12FFFFFF), indent: 60),
                ProgressWorkoutTile(
                    session: group.value[i],
                    onTap: () => onSession(group.value[i])),
              ],
            ])),
      ],
    ]);
  }
}

/// Uses the saved session payload; opening a recap never modifies the workout.
class ProgressWorkoutRecap extends StatelessWidget {
  final ProgressJson session;
  final ValueChanged<ProgressJson>? onExercise;
  const ProgressWorkoutRecap(
      {super.key, required this.session, this.onExercise});
  @override
  Widget build(BuildContext context) {
    final exercises = progressRows(session['exercises']);
    final seconds = progressNumber(session['durationSeconds']);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FitnessTheme(
        child: Scaffold(
        backgroundColor: DSColors.bg,
            appBar: AppBar(
            backgroundColor: DSColors.bg,
                surfaceTintColor: Colors.transparent,
                title: Text(fitnessText(context, 'Workout'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600))),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
                children: [
                  Text(
                      progressDate(session['date'] as String?, locale,
                          year: true),
                      style:
                          const TextStyle(color: progressSilver, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                      progressTitle(fitnessText(
                          context, session['name'] as String? ?? 'Workout')),
                      style: const TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.8)),
                  const SizedBox(height: 18),
                  ProgressSurface(
                      accent: progressBlue,
                      child: ProgressFactGrid(color: progressSilver, facts: [
                        ('Exercises', '${exercises.length}'),
                        ('Logged sets', '${session['sets'] ?? 0}'),
                        if (seconds != null && seconds > 0)
                          (
                            'Duration',
                            '${(seconds / 60).round()} ${fitnessText(context, 'min')}'
                          ),
                      ])),
                  if (progressNumber(session['volume']) != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                            '${fitnessText(context, 'Volume')} · ${progressValue(context, progressNumber(session['volume']), unit: 'kg·reps', digits: 0)}',
                            style: const TextStyle(
                                color: progressMuted, fontSize: 12))),
                  if ((progressNumber(session['records']) ?? 0) > 0)
                    Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _RecordBadge(
                            count: (session['records'] as num).toInt())),
                  const ProgressHeading('Exercises'),
                  for (final exercise in exercises)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProgressSurface(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 3),
                            child: _RecapExercise(
                                exercise: exercise,
                                onTrend: onExercise == null
                                    ? null
                                    : () => onExercise!(exercise)))),
                  if (exercises.isEmpty)
                    const ProgressEmpty('No sets in this period'),
                ])));
  }
}

class _RecapExercise extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback? onTrend;
  const _RecapExercise({required this.exercise, this.onTrend});
  @override
  Widget build(BuildContext context) {
    final entries = progressRows(exercise['entries']);
    final sorted = [...entries]..sort((a, b) =>
        (progressNumber(b['weight']) ?? -1)
            .compareTo(progressNumber(a['weight']) ?? -1));
    final best = sorted.firstOrNull;
    return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 10),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(progressTitle(exercise['name'] as String? ?? ''),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
                '${entries.length} ${fitnessText(context, 'sets')} · ${best == null ? '—' : progressSetLabel(context, best)}',
                style: const TextStyle(fontSize: 11, color: progressMuted))),
        children: [
          ProgressSetTable(entries: entries),
          if (onTrend != null)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: onTrend,
                    style:
                        TextButton.styleFrom(foregroundColor: progressSilver),
                    child: Text(fitnessText(context, 'Exercise progress')))),
        ]);
  }
}

String progressSetLabel(BuildContext context, ProgressJson set) {
  final weight = progressNumber(set['weight']);
  return '${weight != null && weight > 0 ? '${progressValue(context, weight, unit: 'kg')} × ' : ''}${set['reps'] ?? '—'} ${fitnessText(context, 'reps')}';
}

class ProgressSetTable extends StatelessWidget {
  final List<ProgressJson> entries;
  const ProgressSetTable({super.key, required this.entries});
  @override
  Widget build(BuildContext context) {
    final showEffort = entries.any((entry) => entry['rpe'] != null);
    Widget row(List<String> cells, {bool heading = false}) => Padding(
        padding: EdgeInsets.symmetric(vertical: heading ? 8 : 10),
        child: Row(children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
                flex: i == 0 ? 1 : 2,
                child: Text(cells[i],
                    textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                    style: TextStyle(
                        fontSize: heading ? 10 : 12,
                        color:
                            heading || i == 0 ? progressMuted : progressSilver,
                        fontWeight:
                            heading ? FontWeight.w500 : FontWeight.w600)))
        ]));
    return Column(children: [
      row([
        fitnessText(context, 'Set'),
        'kg',
        fitnessText(context, 'Reps'),
        if (showEffort) 'RPE'
      ], heading: true),
      for (final entry in entries) ...[
        const Divider(height: 1, color: Color(0x0FFFFFFF)),
        row([
          '${entry['setNumber'] ?? '—'}',
          progressValue(context, progressNumber(entry['weight'])),
          '${entry['reps'] ?? '—'}',
          if (showEffort) progressValue(context, progressNumber(entry['rpe']))
        ]),
      ],
    ]);
  }
}
