import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';

class WorkoutRest {
  final DateTime end;
  final int duration;
  final String exercise;
  final int? setNumber;
  final int? pausedSeconds;
  bool get isPaused => pausedSeconds != null;

  const WorkoutRest(
      {required this.end,
      required this.duration,
      this.exercise = '',
      this.setNumber,
      this.pausedSeconds});

  static WorkoutRest? fromJson(Map<String, dynamic>? data, DateTime now) {
    if (data?['end'] is! num) return null;
    final end =
        DateTime.fromMillisecondsSinceEpoch((data!['end'] as num).toInt());
    final paused = (data['pausedSeconds'] as num?)?.toInt();
    if (paused == null && !end.isAfter(now)) return null;
    if (paused != null && (paused < 1 || paused > 1800)) return null;
    return WorkoutRest(
        end: end,
        duration: ((data['duration'] as num?)?.toInt() ??
                (end.difference(now).inMilliseconds / 1000).ceil())
            .clamp(1, 1800),
        exercise: data['exercise'] as String? ?? '',
        setNumber: (data['setNumber'] as num?)?.toInt(),
        pausedSeconds: paused);
  }

  int remaining(DateTime now) =>
      pausedSeconds ??
      (end.difference(now).inMilliseconds / 1000).ceil().clamp(0, 1800);

  double progress(DateTime now) =>
      ((pausedSeconds ?? end.difference(now).inMilliseconds / 1000) / duration)
          .clamp(0, 1);

  WorkoutRest extend(DateTime now) {
    final active = remaining(now) > 0;
    final seconds = (remaining(now) + 30).clamp(0, 1800);
    final extended = active && !isPaused
        ? end.add(const Duration(seconds: 30))
        : now.add(Duration(seconds: seconds));
    final maximum = now.add(const Duration(minutes: 30));
    return WorkoutRest(
        end: extended.isAfter(maximum) ? maximum : extended,
        duration: active ? (duration + 30).clamp(1, 1800) : 30,
        exercise: exercise,
        setNumber: setNumber,
        pausedSeconds: isPaused ? seconds : null);
  }

  WorkoutRest togglePause(DateTime now) {
    final seconds = remaining(now);
    if (seconds == 0) return this;
    return WorkoutRest(
        end: now.add(Duration(seconds: seconds)),
        duration: duration,
        exercise: exercise,
        setNumber: setNumber,
        pausedSeconds: isPaused ? null : seconds);
  }

  Map<String, dynamic> toJson() => {
        'end': end.millisecondsSinceEpoch,
        'duration': duration,
        'exercise': exercise,
        'setNumber': setNumber,
        'pausedSeconds': pausedSeconds,
      };
}

/// The same countdown is used in the rest sheet and the minimized bar.
class WorkoutRestTimer extends StatelessWidget {
  final WorkoutRest rest;
  final DateTime now;
  final bool compact;
  final VoidCallback onAdd, onSkip, onMinimize, onTogglePause;

  const WorkoutRestTimer(
      {super.key,
      required this.rest,
      required this.now,
      required this.onAdd,
      required this.onSkip,
      required this.onMinimize,
      required this.onTogglePause,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    String copy(String key, {Map<String, Object> values = const {}}) =>
        fitnessText(context, key, values: values);
    final remaining = rest.remaining(now);
    final ready = remaining == 0;
    final time =
        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';

    Widget ring(double size, Widget child) => RepaintBoundary(
          child: SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: rest.progress(now)),
              duration: DSMotion.reduced(context)
                  ? Duration.zero
                  : const Duration(seconds: 1),
              curve: Curves.linear,
              child: Center(child: child),
              builder: (_, value, child) => CustomPaint(
                  painter: _RestRing(value, compact: compact), child: child),
            ),
          ),
        );

    if (compact) {
      final title = InkWell(
          key: const ValueKey('expand-rest-timer'),
          onTap: onMinimize,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                ring(
                    32,
                    Icon(
                        ready
                            ? CupertinoIcons.checkmark
                            : rest.isPaused
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.timer,
                        size: 14,
                        color: DSColors.silver)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        ready
                            ? copy('Ready for your next set')
                            : '${copy(rest.isPaused ? 'Paused' : 'Rest')} · $time',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()]))),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_up,
                    size: 10, color: DSColors.muted),
              ])));
      final actions = Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
        if (!ready)
          TextButton(
              onPressed: onAdd,
              child: Text('+ ${copy('30 s')}',
                  style:
                      const TextStyle(fontSize: 12, color: DSColors.silver))),
        TextButton(
            onPressed: onSkip,
            child: Text(copy(ready ? 'Continue workout' : 'Skip rest'),
                style: const TextStyle(fontSize: 12, color: DSColors.silver))),
      ]);
      return LayoutBuilder(
          builder: (context, box) => box.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(13) > 18
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [title, actions])
              : Row(children: [Expanded(child: title), actions]));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                  child: Text(copy('Rest'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500))),
              IconButton(
                  tooltip: copy('Minimize timer'),
                  onPressed: onMinimize,
                  icon: const Icon(CupertinoIcons.chevron_down,
                      size: 20, color: DSColors.muted)),
            ]),
            const SizedBox(height: 10),
            if (rest.exercise.isNotEmpty)
              Text(rest.exercise,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            if (rest.setNumber != null) ...[
              const SizedBox(height: 6),
              Text(
                  copy('Set {number} saved',
                      values: {'number': rest.setNumber!}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: DSColors.muted)),
            ],
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final size = math.min(250.0, constraints.maxWidth - 24);
              return Center(
                  child: ring(
                      size,
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(time,
                                key: const ValueKey('rest-countdown'),
                                style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -2,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ]))),
                        const SizedBox(height: 8),
                        Icon(
                            ready
                                ? CupertinoIcons.checkmark
                                : CupertinoIcons.timer,
                            color: DSColors.muted,
                            size: 20),
                      ])));
            }),
            if (!ready) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                  key: const ValueKey('rest-pause'),
                  onPressed: onTogglePause,
                  icon: Icon(
                      rest.isPaused
                          ? CupertinoIcons.play_fill
                          : CupertinoIcons.pause_fill,
                      size: 15),
                  label: Text(
                      copy(rest.isPaused ? 'Resume timer' : 'Pause timer')),
                  style:
                      TextButton.styleFrom(foregroundColor: DSColors.silver)),
            ],
            const SizedBox(height: 16),
            Semantics(
                liveRegion: ready,
                child: Text(
                    copy(ready
                        ? 'Ready for your next set'
                        : rest.isPaused
                            ? 'Paused'
                            : 'Take a breather'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500))),
            const SizedBox(height: 8),
            Text(copy('Take longer if you need it.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: DSColors.muted)),
            const SizedBox(height: 26),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(CupertinoIcons.plus, size: 16),
                      label: const Text('30 s'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: DSColors.silver,
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: DSColors.borderHi)))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: onSkip,
                      style: FilledButton.styleFrom(
                          backgroundColor: DSColors.silver,
                          foregroundColor: DSColors.bg,
                          minimumSize: const Size(0, 48)),
                      child: Text(
                          copy(ready ? 'Continue workout' : 'Skip rest'),
                          textAlign: TextAlign.center))),
            ]),
          ]),
    );
  }
}

class _RestRing extends CustomPainter {
  final double progress;
  final bool compact;
  _RestRing(this.progress, {required this.compact});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - (compact ? 3 : 12);
    final stroke = compact ? 2.5 : 5.0;
    final track = Paint()
      ..color = DSColors.bgRaised
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);
    if (!compact) {
      final tick = Paint()
        ..color = DSColors.borderHi
        ..strokeWidth = 1;
      for (var i = 0; i < 60; i++) {
        final angle = i * math.pi / 30;
        final offset = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(center + offset * (radius + 7),
            center + offset * (radius + (i % 5 == 0 ? 11 : 9)), tick);
      }
    }
    final arc = Paint()
      ..color = DSColors.silver
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RestRing old) =>
      old.progress != progress || old.compact != compact;
}
