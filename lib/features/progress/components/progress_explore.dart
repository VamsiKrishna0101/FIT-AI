import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import 'progress_surface.dart';

class ProgressExplore extends StatelessWidget {
  final VoidCallback onMuscles, onBody, onNutrition, onRecovery;
  const ProgressExplore({
    super.key,
    required this.onMuscles,
    required this.onBody,
    required this.onNutrition,
    required this.onRecovery,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final columns = MediaQuery.textScalerOf(context).scale(14) > 20 ? 1 : 2;
        final items = [
          ('Muscles', CupertinoIcons.person, onMuscles),
          ('Body changes', CupertinoIcons.resize, onBody),
          ('Nutrition', Icons.restaurant_outlined, onNutrition),
          ('Recovery', CupertinoIcons.heart, onRecovery),
        ];
        Widget tile((String, IconData, VoidCallback) item) => ProgressSurface(
              padding: EdgeInsets.zero,
              child: InkWell(
                key: ValueKey('progress-explore-${item.$1}'),
                onTap: item.$3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
                  child: Row(children: [
                    Icon(item.$2, size: 18, color: progressMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(fitnessText(context, item.$1),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
              ),
            );
        return Column(children: [
          for (var i = 0; i < items.length; i += columns) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tile(items[i])),
                    if (columns == 2) ...[
                      const SizedBox(width: 10),
                      Expanded(child: tile(items[i + 1])),
                    ],
                  ]),
            ),
          ],
        ]);
      });
}
