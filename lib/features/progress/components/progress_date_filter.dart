import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_surface.dart';

class ProgressDateFilter extends StatelessWidget {
  final String period;
  final DateTimeRange? custom;
  final String? rangeLabel;
  final bool compact;
  final void Function(String, DateTimeRange?) onChanged;
  const ProgressDateFilter(
      {super.key,
      required this.period,
      this.custom,
      this.rangeLabel,
      this.compact = false,
      required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            constraints: BoxConstraints(minHeight: compact ? 42 : 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF242527),
                borderRadius: BorderRadius.circular(14)),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: period,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(14),
                    isDense: compact,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: progressSilver,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    selectedItemBuilder: (context) => const {
                          '4w': '4 weeks',
                          '3m': '3 months',
                          '1y': '1 year',
                          'all': 'All time',
                          'custom': 'Custom range'
                        }
                            .entries
                            .map((entry) => Row(children: [
                                  Expanded(
                                      child: Text(
                                          fitnessText(context, entry.value),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)),
                                ]))
                            .toList(),
                    items: const {
                      '4w': '4 weeks',
                      '3m': '3 months',
                      '1y': '1 year',
                      'all': 'All time',
                      'custom': 'Custom range'
                    }
                        .entries
                        .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(fitnessText(context, entry.value),
                                maxLines: 1, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      if (value != 'custom') {
                        onChanged(value, null);
                        return;
                      }
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(now.year, now.month, now.day),
                          initialDateRange: custom ??
                              DateTimeRange(
                                  start: now.subtract(const Duration(days: 27)),
                                  end: now),
                          helpText: fitnessText(context, 'Custom range'),
                          saveText: fitnessText(context, 'Apply'));
                      if (picked != null) onChanged('custom', picked);
                    }))),
        if (!compact && period != 'custom' && rangeLabel != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(rangeLabel!,
                  style: const TextStyle(color: progressMuted, fontSize: 13))),
        if (!compact && period == 'custom' && custom != null)
          Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                  '${progressDate(custom!.start.toIso8601String().substring(0, 10), Localizations.localeOf(context).toLanguageTag())} – ${progressDate(custom!.end.toIso8601String().substring(0, 10), Localizations.localeOf(context).toLanguageTag())}',
                  style: const TextStyle(color: progressMuted, fontSize: 13))),
      ]);
}
