import '../../../core/theme/ds_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_trend_summary.dart';

const progressSourceLabels = {
  'preview': 'Preview data',
  'scale': 'Scale',
  'tape': 'Tape',
  'profile': 'Profile baseline',
  'health_sync': 'Health sync',
  'smart_scale': 'Smart scale',
  'dexa': 'DEXA',
  'calipers': 'Calipers',
  'manual_estimate': 'Entered estimate',
  'photo_estimate': 'Photo estimate',
  'contour_estimate': 'Photo estimate',
  'entered': 'Entered',
};

class BodyProgressContent extends StatefulWidget {
  final ProgressJson data;
  final VoidCallback onAdd;
  final ValueChanged<String> onRecord;
  const BodyProgressContent(
      {super.key,
      required this.data,
      required this.onAdd,
      required this.onRecord});
  @override
  State<BodyProgressContent> createState() => _BodyProgressContentState();
}

class _BodyProgressContentState extends State<BodyProgressContent> {
  String _metric = 'weightKg';
  String? _source;
  @override
  Widget build(BuildContext context) {
    final metrics = progressRows(widget.data['metrics']);
    if (metrics.isEmpty) {
      return const ProgressEmpty('No readings in this period');
    }
    final selected = metrics.firstWhere((row) => row['id'] == _metric,
        orElse: () => metrics.first);
    final sources = progressRows(selected['series']);
    final series =
        sources.where((row) => row['source'] == _source).firstOrNull ??
            sources.firstOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final latestPoint = progressRows(series?['points']).lastOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(
            initialValue: selected['id'] as String,
            decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: metrics
                .map((row) => DropdownMenuItem(
                    value: row['id'] as String,
                    child: Text(fitnessText(context, row['label'] as String),
                        style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (value) => setState(() {
                  _metric = value!;
                  _source = null;
                })),
        if (sources.length > 1)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ProgressChoices(
                  choices: {
                    for (final row in sources)
                      row['source'] as String:
                          progressSourceLabels[row['source']] ?? 'Entered'
                  },
                  selected: series!['source'] as String,
                  onChanged: (value) => setState(() => _source = value))),
        const SizedBox(height: 18),
        ProgressChart(
            points:
                ProgressPoint.parse(progressRows(series?['points']), 'value'),
            color: progressCyan,
            height: 175,
            unit: selected['unit'] as String),
        ProgressTrendSummary(
            points:
                ProgressPoint.parse(progressRows(series?['points']), 'value'),
            unit: selected['unit'] as String,
            color: progressCyan),
        if (series != null) ...[
          const SizedBox(height: 12),
          Text(
              fitnessText(
                  context, progressSourceLabels[series['source']] ?? 'Entered'),
              style: const TextStyle(color: progressMuted, fontSize: 11)),
          if (series['source'] == 'photo_estimate' ||
              series['source'] == 'contour_estimate')
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    fitnessText(context,
                        'Photo estimates are shown separately from measured readings.'),
                    style: const TextStyle(
                        color: progressMuted, fontSize: 11, height: 1.4))),
        ],
      ])),
      if (widget.data['profileBaseline'] != null)
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
                '${fitnessText(context, 'Profile baseline')} · ${progressValue(context, progressNumber(widget.data['profileBaseline']), unit: 'kg')}',
                style: const TextStyle(color: progressMuted, fontSize: 12))),
      if (latestPoint?['low'] != null)
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                '${fitnessText(context, 'Estimated range')} · ${progressValue(context, progressNumber(latestPoint!['low']))}–${progressValue(context, progressNumber(latestPoint['high']), unit: selected['unit'] as String)}',
                style: const TextStyle(color: progressMuted, fontSize: 11))),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: widget.onAdd,
          style: FilledButton.styleFrom(
              backgroundColor: progressSilver, foregroundColor: DSColors.bg),
          child: Text(fitnessText(context, 'Add a reading'))),
      const ProgressHeading('Measurements'),
      ProgressSurface(
          child: Column(
              children: metrics.map((row) {
        final latest = row['latest'] as Map?;
        return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => setState(() {
                  _metric = row['id'] as String;
                  _source = null;
                }),
            title: Text(fitnessText(context, row['label'] as String),
                style: const TextStyle(fontSize: 14)),
            subtitle: latest == null
                ? null
                : Text(
                    '${progressDate(latest['date'] as String?, locale)} · ${fitnessText(context, progressSourceLabels[latest['source']] ?? 'Entered')}',
                    style: const TextStyle(color: progressMuted, fontSize: 11)),
            trailing: Text(
                progressValue(context, progressNumber(latest?['value']),
                    unit: row['unit'] as String),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)));
      }).toList())),
      const ProgressHeading('Saved assessments'),
      if (progressRows(widget.data['assessments']).isEmpty)
        const ProgressEmpty('No saved assessments in this period')
      else
        ProgressSurface(
            child: Column(
                children: progressRows(widget.data['assessments'])
                    .map((row) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => widget.onRecord(row['id'] as String),
                        title:
                            Text(progressDate(row['date'] as String?, locale, year: true),
                                style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                            fitnessText(
                                context,
                                row['method'] == 'entered'
                                    ? 'Entered readings'
                                    : 'Photo assessment'),
                            style: const TextStyle(
                                fontSize: 12, color: progressMuted)),
                        trailing: const Icon(Icons.chevron_right,
                            size: 18, color: progressMuted)))
                    .toList())),
      const SizedBox(height: 16),
      Text(fitnessText(context, 'Compare · Coming soon'),
          style: const TextStyle(color: progressMuted, fontSize: 12)),
    ]);
  }
}
