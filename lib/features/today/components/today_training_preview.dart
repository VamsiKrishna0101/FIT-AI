import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../body_scan/models/training_map_models.dart';
import '../../body_scan/views/widgets/anatomical_training_map.dart';

/// A preview of direct logged sets, never a physique or body-fat assessment.
class TodayTrainingPreview extends StatelessWidget {
  final TrainingMapData? data;
  const TodayTrainingPreview({super.key, this.data});
  @override
  Widget build(BuildContext context) {
    final regions = data?.regions ?? [];
    final peak = regions.fold<int>(0, (n, r) => math.max(n, r.completedSets));
    final colors = <String, Color>{
      for (final region in regions)
        region.id: region.completedSets > 0
            ? Color.lerp(const Color(0xFF48668B), const Color(0xFF8BAAFF),
                region.completedSets / peak)!
            : const Color(0xFF555555),
    };
    return RepaintBoundary(
        child: SizedBox(
            width: 76,
            height: 76,
            child: IgnorePointer(
                child: ExcludeSemantics(
                    child: Row(children: [
              for (final back in [false, true])
                SizedBox(
                    width: 38,
                    height: 76,
                    child: AnatomicalTrainingMap(
                        back: back,
                        female: data?.gender == 'FEMALE',
                        colors: colors,
                        onSelected: (_) {})),
            ])))));
  }
}
