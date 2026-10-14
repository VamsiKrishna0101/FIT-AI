import 'dart:convert';
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/training_session.dart';
import '../repositories/training_repository.dart';
import 'training_widgets.dart';

class TrainingVolumeCard extends StatefulWidget {
  final bool isActive;
  const TrainingVolumeCard({super.key, this.isActive = true});
  @override
  State<TrainingVolumeCard> createState() => _TrainingVolumeCardState();
}

class _TrainingVolumeCardState extends State<TrainingVolumeCard> {
  List<Map<String, dynamic>> _weeks = [];
  StreamSubscription<TrainingDay>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = TrainingRepository.shared.changes.stream.listen((_) {
      if (widget.isActive) _load(refresh: true);
    });
    _load();
  }

  @override
  void didUpdateWidget(TrainingVolumeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final weeks =
          await TrainingRepository.shared.volumeHistory(refresh: refresh);
      if (mounted) setState(() => _weeks = weeks);
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String copy(String key, {Map<String, Object> values = const {}}) =>
        fitnessText(context, key, values: values);
    final last = _weeks.lastOrNull;
    final maximum = _weeks.fold<num>(
        1,
        (largest, row) => (row['totalSets'] as num) > largest
            ? row['totalSets'] as num
            : largest);
    return TrainingSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(copy('Training volume'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600))),
        Text(copy('Last 6 weeks'),
            style: const TextStyle(fontSize: 11, color: trainingMuted))
      ]),
      const SizedBox(height: 12),
      Text(
          copy('{count} logged sets',
              values: {'count': last?['totalSets'] as int? ?? 0}),
          style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -.5)),
      const SizedBox(height: 4),
      Text('${last?['totalVolume'] ?? 0} kg · ${copy('This week')}',
          style: const TextStyle(color: trainingMuted, fontSize: 12)),
      const SizedBox(height: 18),
      if (_weeks.every((row) => row['totalSets'] == 0))
        Text(copy('Log sets to see your training trend.'),
            style: const TextStyle(color: trainingMuted, fontSize: 12))
      else
        MotionProgress(
            dataKey: jsonEncode(_weeks),
            builder: (context, progress) => SizedBox(
                height: 59 + MediaQuery.textScalerOf(context).scale(10) * 1.5,
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final (index, row) in _weeks.indexed)
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${row['totalSets']}',
                                      style: const TextStyle(
                                          color: trainingMuted, fontSize: 10)),
                                  const SizedBox(height: 5),
                                  Container(
                                      height: ((row['totalSets'] as num) /
                                                  maximum *
                                                  50)
                                              .clamp(0, 50)
                                              .toDouble() *
                                          DSMotion.barProgress(
                                              progress, index, _weeks.length),
                                      decoration: BoxDecoration(
                                          color: row == last
                                              ? trainingSilver
                                              : const Color(0xFF424242),
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                ]))),
                ]))),
    ]));
  }
}
