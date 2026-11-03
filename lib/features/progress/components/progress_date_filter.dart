import 'package:flutter/material.dart';
import '../../../core/components/app_date_filter.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/models/body_map_models.dart';
import '../../body_scan/views/widgets/body_calendar.dart';
import '../models/progress_models.dart';

class ProgressDateFilter extends StatelessWidget {
  final String period;
  final DateTimeRange? custom;
  final String? rangeLabel;
  final bool compact;
  final double? controlWidth;
  final void Function(String, DateTimeRange?) onChanged;
  const ProgressDateFilter({
    super.key,
    required this.period,
    this.custom,
    this.rangeLabel,
    this.compact = false,
    this.controlWidth,
    required this.onChanged,
  });

  static const _options = {
    '4w': '4 weeks',
    '3m': '3 months',
    '1y': '1 year',
    'all': 'All time',
    'custom': 'Custom range',
  };

  String _label(BuildContext context, String key) {
    if (key == 'custom' && period == 'custom' && custom != null) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      return '${progressDate(calendarDateKey(custom!.start), locale)} – ${progressDate(calendarDateKey(custom!.end), locale)}';
    }
    return fitnessText(context, _options[key]!);
  }

  Future<void> _choose(BuildContext context, String chosen) async {
    if (chosen != 'custom') {
      if (chosen != period) onChanged(chosen, null);
      return;
    }
    final today = calendarDay(DateTime.now());
    final result = await showBodyDateFilter(context,
        rangeOnly: true,
        today: today,
        selection: BodyDateSelection(
            mode: BodyDateMode.range,
            start: custom?.start ??
                DateTime(today.year, today.month, today.day - 27),
            end: custom?.end ?? today));
    if (result != null && context.mounted) {
      onChanged('custom',
          DateTimeRange(start: result.start ?? result.end, end: result.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final control = SizedBox(
        width: controlWidth ?? (compact ? 140 : 160),
        child: AppFilterDropdown<String>(
          dropdownKey: const ValueKey('progress-period-dropdown'),
          value: _options.containsKey(period) ? period : '4w',
          items: [
            for (final key in _options.keys)
              DropdownMenuItem(
                  value: key,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(fitnessText(context, _options[key]!),
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
          ],
          selectedItemBuilder: (_) => [
            for (final key in _options.keys)
              Text(_label(context, key),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          onChanged: (value) => _choose(context, value),
        ));
    if (compact || controlWidth != null) return control;
    return Row(children: [
      control,
      if (period != 'custom' && rangeLabel != null)
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(rangeLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 11)))),
    ]);
  }
}
