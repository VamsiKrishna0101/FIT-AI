import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

/// One session on the history timeline: a tinted date badge, the workout name
/// and its volume as chips. Sessions with records carry a gold badge.
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
    final records = (progressNumber(session['records']) ?? 0).toInt();
    final tint = progressSessionColor(session);
    return InkWell(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                      color: tint.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: tint.withValues(alpha: .22), width: .7)),
                  child: Column(children: [
                    Text(date == null ? '—' : DateFormat.d(locale).format(date),
                        style: const TextStyle(
                            color: progressSilver,
                            fontSize: 18,
                            height: 1.1,
                            fontWeight: FontWeight.w700)),
                    Text(
                        date == null
                            ? ''
                            : DateFormat.MMM(locale).format(date).toUpperCase(),
                        style: TextStyle(
                            color: tint,
                            fontSize: 9.5,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w600)),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      if (exercises.isNotEmpty)
                        _Chip(
                            '${exercises.length} ${fitnessText(context, 'exercises')}'),
                      _Chip(
                          '${session['sets'] ?? 0} ${fitnessText(context, 'sets')}'),
                      if (seconds != null && seconds > 0)
                        _Chip(
                            '${(seconds / 60).round()} ${fitnessText(context, 'min')}'),
                    ]),
                    if (records > 0) ...[
                      const SizedBox(height: 8),
                      _RecordBadge(count: records),
                    ],
                    if (session['status'] != 'COMPLETED') ...[
                      const SizedBox(height: 6),
                      Text(fitnessText(context, 'In progress'),
                          style: const TextStyle(
                              color: progressMuted, fontSize: 11)),
                    ],
                  ])),
              const SizedBox(width: 6),
              const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(CupertinoIcons.chevron_right,
                      size: 13, color: progressMuted)),
            ])));
  }
}

/// Gold for a session with records, mint once completed, grey while open.
Color progressSessionColor(ProgressJson session) =>
    (progressNumber(session['records']) ?? 0) > 0
        ? progressRecord
        : session['status'] == 'COMPLETED'
            ? progressTraining
            : progressMuted;

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11, color: progressSilver, height: 1.3))));
}

class _RecordBadge extends StatelessWidget {
  final int count;
  const _RecordBadge({required this.count});
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: progressRecord.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: progressRecord.withValues(alpha: .3), width: .7)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(CupertinoIcons.rosette, size: 12, color: progressRecord),
            const SizedBox(width: 5),
            Flexible(
                child: Text('${fitnessText(context, 'New records')} · $count',
                    style: const TextStyle(
                        color: progressRecord,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
          ])));
}

/// Sessions grouped by month along a vertical rail; each dot takes the
/// session's colour so records and unfinished workouts stand out.
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
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
            child: Text(
                group.key.isEmpty
                    ? fitnessText(context, 'Workout history')
                    : DateFormat.yMMMM(locale)
                        .format(DateTime.parse('${group.key}-01')),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.4))),
        Stack(children: [
          PositionedDirectional(
              start: 7,
              top: 10,
              bottom: 10,
              child: Container(width: 1.5, color: const Color(0x1FFFFFFF))),
          Column(children: [
            for (var i = 0; i < group.value.length; i++)
              Padding(
                  padding: EdgeInsets.only(
                      bottom: i == group.value.length - 1 ? 0 : 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(top: 26),
                            child: _TimelineDot(
                                color: progressSessionColor(group.value[i]))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: ProgressSurface(
                                padding: EdgeInsets.zero,
                                child: ProgressWorkoutTile(
                                    session: group.value[i],
                                    onTap: () => onSession(group.value[i])))),
                      ])),
          ]),
        ]),
      ],
    ]);
  }
}

class _TimelineDot extends StatelessWidget {
  final Color color;
  const _TimelineDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DSColors.bg,
          border: Border.all(color: color.withValues(alpha: .45), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .35), blurRadius: 8),
          ]),
      child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)));
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
