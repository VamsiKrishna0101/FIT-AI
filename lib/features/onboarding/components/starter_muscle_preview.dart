import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/views/widgets/anatomical_training_map.dart';

const _ice = Color(0xFFBFCFDF);
const _line = Color(0xFF292D33);

/// The server sends public samples only; locked rows contain no hidden workout data.
class StarterMusclePreview extends StatelessWidget {
  final Map<String, dynamic> preview;
  const StarterMusclePreview({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final groups = (preview['muscleGroups'] as List).whereType<Map>().toList();
    final samples = groups
        .where((group) => (group['exercises'] as List? ?? []).isNotEmpty)
        .toList();
    final hidden = groups
        .where((group) => (group['exercises'] as List? ?? []).isEmpty)
        .toList();
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final first = preview['firstWorkout'] as Map?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = days.where((day) => day['restDay'] != true).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Expanded(
            child: FitnessText('Your training',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5))),
        if (first?['date'] is String)
          Text(
              DateFormat.MMMd(locale)
                  .format(DateTime.parse(first!['date'] as String)),
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 16, runSpacing: 6, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.view_week_outlined, size: 13, color: _ice),
          const SizedBox(width: 6),
          const FitnessText('Training days',
              style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          const SizedBox(width: 5),
          Text(NumberFormat.decimalPattern(locale).format(count),
              style: const TextStyle(
                  fontSize: 12, color: _ice, fontWeight: FontWeight.w600)),
        ]),
        FitnessText('{count} exercises',
            values: {
              'count': groups.fold<int>(
                  0,
                  (total, group) =>
                      total + ((group['exerciseCount'] as num?)?.toInt() ?? 0))
            },
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
      ]),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF171B21), Color(0xFF0E1014)]),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < samples.length; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1, color: _line)),
            _ExerciseSample(group: samples[i]),
          ],
          if (hidden.isNotEmpty) ...[
            if (samples.isNotEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1, color: _line)),
            Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final group in hidden)
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF20252B),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FitnessText(_title('${group['region']}'),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFCDD2DA),
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 7),
                                    const Icon(Icons.lock_outline_rounded,
                                        size: 11, color: Color(0xFF8D98A5)),
                                  ])),
                      ]),
                      const SizedBox(height: 14),
                      const _LockedPreview(),
                    ])),
          ] else if (samples
              .any((group) => (group['lockedCount'] as num? ?? 0) > 0))
            const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _LockedPreview()),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _line))),
              child: const Row(children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: _ice),
                SizedBox(width: 8),
                Expanded(
                    child: FitnessText('Unlock your complete plan',
                        style: TextStyle(fontSize: 12, color: _ice))),
                Icon(Icons.arrow_forward_rounded, size: 15, color: _ice),
              ])),
        ]),
      ),
      const SizedBox(height: 12),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: const FitnessText('Your week',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        children: [
          for (final day in days)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 55,
                          child: Text(
                              DateFormat.E(locale).format(
                                  DateTime.parse(day['date'] as String)),
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                      Expanded(
                          child: FitnessText(
                              day['restDay'] == true
                                  ? 'Rest day'
                                  : '${day['name']}',
                              style: const TextStyle(fontSize: 12))),
                    ]))
        ],
      ),
      if (preview['source'] == 'rules')
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(bottom: 12),
          shape: Border(),
          collapsedShape: Border(),
          leading: Icon(Icons.info_outline_rounded,
              size: 16, color: FitnessTheme.muted),
          title: FitnessText('Rules-based starter plan',
              style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          children: [
            FitnessText(
                'AI planning is unavailable. This plan uses your confirmed setup and conservative training rules.',
                style: TextStyle(
                    fontSize: 12, color: FitnessTheme.muted, height: 1.5))
          ],
        ),
    ]);
  }
}

String _title(String value) =>
    value.isEmpty ? '' : '${value[0].toUpperCase()}${value.substring(1)}';

class _ExerciseSample extends StatelessWidget {
  final Map group;
  const _ExerciseSample({required this.group});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 44,
              height: 54,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF252D36),
                  borderRadius: BorderRadius.circular(12)),
              child: ExcludeSemantics(
                  child: RepaintBoundary(
                      child: CustomPaint(
                          painter: _MuscleGlyph('${group['region']}'))))),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: FitnessText(_title('${group['region']}'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ice))),
                  const SizedBox(width: 8),
                  FitnessText('{count} exercises',
                      values: {'count': group['exerciseCount'] ?? 0},
                      style: const TextStyle(
                          fontSize: 10, color: FitnessTheme.muted)),
                ]),
                for (final exercise in (group['exercises'] as List? ?? [])
                    .whereType<Map>()) ...[
                  const SizedBox(height: 7),
                  FitnessText(_title('${exercise['name']}'),
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.2)),
                  const SizedBox(height: 5),
                  FitnessText('{sets} sets · {reps} reps',
                      values: {
                        'sets': exercise['sets'],
                        'reps': exercise['repsMin'] == exercise['repsMax']
                            ? exercise['repsMax']
                            : '${exercise['repsMin']}–${exercise['repsMax']}'
                      },
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted)),
                ],
              ])),
        ]),
      );
}

class _LockedPreview extends StatelessWidget {
  const _LockedPreview();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: IgnorePointer(
              child: ClipRect(
                  child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final fraction in [.88, .58])
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFF778290).withValues(alpha: .28),
                            borderRadius: BorderRadius.circular(3))))),
        ]),
      ))));
}

class _MuscleGlyph extends CustomPainter {
  final String region;
  _MuscleGlyph(this.region);
  @override
  void paint(Canvas canvas, Size size) {
    final ids = switch (region) {
      'back' => {'upper_back', 'lats', 'lower_back'},
      'legs' => {'quads'},
      _ => {region},
    };
    final geometry = musclePaths(back: region == 'back');
    final contextIds = region == 'back'
        ? {
            'shoulders',
            'upper_back',
            'lats',
            'lower_back',
            'triceps',
            'forearms'
          }
        : {'chest', 'shoulders', 'biceps', 'triceps', 'core', 'forearms'};
    final paths = [for (final id in contextIds) ...?geometry[id]];
    if (paths.isEmpty) return;
    final bounds = paths
        .map((path) => path.getBounds())
        .reduce((a, b) => a.expandToInclude(b));
    final scale =
        math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    final fill = Paint();
    for (final id in contextIds) {
      fill.color = ids.contains(id) ? _ice : const Color(0xFF52606E);
      for (final path in geometry[id] ?? <Path>[]) {
        canvas.drawPath(path, fill);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MuscleGlyph oldDelegate) => oldDelegate.region != region;
}
