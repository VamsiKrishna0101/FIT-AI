import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressPersonalBests extends StatelessWidget {
  final List<ProgressJson> records;
  final ValueChanged<ProgressJson> onExercise;
  const ProgressPersonalBests(
      {super.key, required this.records, required this.onExercise});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ProgressSurface(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < records.take(3).length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0x1CFFFFFF)),
            InkWell(
                key: ValueKey(
                    'progress-personal-best-${records[i]['exerciseId']}'),
                onTap: () => onExercise({
                      'id': records[i]['exerciseId'],
                      'name': records[i]['name'],
                    }),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    progressTitle(
                                        records[i]['name'] as String? ?? ''),
                                    style: const TextStyle(
                                        color: progressSilver,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4))),
                            const SizedBox(width: 12),
                            const Icon(CupertinoIcons.rosette,
                                size: 16, color: progressRecord),
                          ]),
                          const SizedBox(height: 7),
                          Text(progressSetValue(context, records[i]),
                              style: const TextStyle(
                                  color: progressSilver,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4)),
                          const SizedBox(height: 5),
                          Text(
                              '${fitnessText(context, _kind(records[i]))} · ${progressDate(records[i]['date'] as String?, locale)}',
                              style: const TextStyle(
                                  color: progressMuted,
                                  fontSize: 12,
                                  height: 1.4)),
                        ]))),
          ],
        ]));
  }

  String _kind(ProgressJson record) {
    final kinds = record['kinds'] as List? ?? const [];
    if (kinds.contains('load')) return 'Heavier weight';
    if (kinds.contains('reps_at_load')) return 'More reps at this weight';
    if (kinds.contains('set_volume')) return 'More weight × reps in one set';
    return 'Personal best';
  }
}
