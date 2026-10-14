import '../../../../core/theme/ds_motion.dart';
import '../../../../core/components/motion.dart';
import '../../../../core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import 'anatomical_training_map.dart';
import 'body_controls.dart';
import 'private_body_photo.dart';

class BodyPhysiqueDashboard extends StatefulWidget {
  final BodyOverview? overview;
  final BodyComparison? comparison;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd,
      onPhotos,
      onPreferences,
      onTrain,
      onCompare,
      onBaseline;
  final ValueChanged<BodyAssessment> onRecord;
  const BodyPhysiqueDashboard(
      {super.key,
      this.overview,
      this.comparison,
      this.loading = false,
      this.error,
      required this.onRefresh,
      required this.onAdd,
      required this.onPhotos,
      required this.onPreferences,
      required this.onTrain,
      required this.onCompare,
      required this.onBaseline,
      required this.onRecord});
  @override
  State<BodyPhysiqueDashboard> createState() => _BodyPhysiqueDashboardState();
}

class _BodyPhysiqueDashboardState extends State<BodyPhysiqueDashboard> {
  bool _back = false, _changes = false, _chosenMode = false;
  int _trend = 0;
  String? _selected;
  @override
  void initState() {
    super.initState();
    _changes = widget.comparison != null;
  }

  @override
  void didUpdateWidget(BodyPhysiqueDashboard old) {
    super.didUpdateWidget(old);
    if (!_chosenMode && widget.comparison != null) _changes = true;
  }

  Color _color(String id) => !_changes
      ? (widget.overview?.focus.contains(id) == true
          ? FitnessTheme.blue
          : const Color(0xFF555555))
      : switch (widget.comparison?.regions[id]) {
          'increased' => FitnessTheme.blue,
          'decreased' => FitnessTheme.coral,
          'mixed' => FitnessTheme.violet,
          'unchanged' => const Color(0xFFBBBBBB),
          _ => const Color(0xFF555555),
        };
  Color _sideColor(String metric) =>
      switch (widget.comparison?.metrics[metric]?['status']) {
        'increased' => FitnessTheme.blue,
        'decreased' => FitnessTheme.coral,
        'unchanged' => const Color(0xFFBBBBBB),
        _ => const Color(0xFF555555),
      };

  void _select(String id) {
    setState(() => _selected = id);
    final metrics =
        bodyMetricSpecs.entries.where((e) => e.value.region == id).toList();
    final notes = widget.overview?.latest?.observations
            .where((e) => e['region'] == id)
            .toList() ??
        [];
    showModalBottomSheet<void>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FitnessTheme.surface,
        showDragHandle: true,
        builder: (context) => FitnessTheme(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      FitnessText(bodyRegionNames[id] ?? id,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5)),
                      const SizedBox(height: 5),
                      FitnessText(
                          widget.overview?.focus.contains(id) == true
                              ? 'One of your chosen training priorities'
                              : 'Tap a measurement to review its source',
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      const SizedBox(height: 18),
                      for (final spec in metrics)
                        if (widget.overview?.latest?.metrics[spec.key]
                            case final metric?)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      FitnessText(spec.value.label,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 4),
                                      FitnessText(
                                          bodySourceLabel(metric.source),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: FitnessTheme.muted))
                                    ])),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FitnessText(
                                          metric.display(spec.value.unit),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500)),
                                      if (widget.comparison != null)
                                        FitnessText(
                                            widget.comparison!.label(spec.key),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: FitnessTheme.muted))
                                    ]),
                              ])),
                      if (metrics.every((s) =>
                          widget.overview?.latest?.metrics[s.key] == null))
                        const FitnessText(
                            'No size reading for this area yet. Your training history is available in Training.',
                            style: TextStyle(
                                fontSize: 13,
                                color: FitnessTheme.muted,
                                height: 1.5)),
                      for (final note in notes)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FitnessText(
                                      fitnessText(context,
                                          'Photo observation · {value} confidence',
                                          values: {
                                            'value': fitnessText(context,
                                                note['confidence'] as String)
                                          }).toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: FitnessTheme.muted)),
                                  const SizedBox(height: 6),
                                  FitnessText(note['observation'] as String,
                                      style: const TextStyle(
                                          fontSize: 13, height: 1.5)),
                                ])),
                      const SizedBox(height: 16),
                      Wrap(spacing: 12, children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onAdd();
                            },
                            child: const FitnessText('Add measurement')),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onTrain();
                            },
                            child: const FitnessText('Open training'))
                      ]),
                    ])))));
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview,
        latest = overview?.latest,
        comparison = widget.comparison;
    return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: FitnessTheme.silver,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, LiquidSilverBottomBar.scrollBottomInset(context)),
            children: [
              if (widget.error != null)
                FitnessCard(
                    child: Row(children: [
                  Expanded(
                      child: FitnessText(widget.error!,
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted))),
                  TextButton(
                      onPressed: widget.onRefresh,
                      child: const FitnessText('Retry'))
                ])),
              if (widget.loading && overview == null)
                const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CupertinoActivityIndicator()))
              else ...[
                if (latest != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FitnessText(
                          'LATEST ENTRY · ${bodyDate(latest.recordedDate).toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: .7,
                              color: FitnessTheme.muted))),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: _ReadingCard(
                          label: 'Weight',
                          metric: latest?.metrics['weightKg'],
                          unit: 'kg')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _ReadingCard(
                          label: 'Body fat',
                          metric: latest?.metrics['bodyFatPct'],
                          unit: '%')),
                ]),
                if (latest == null)
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FitnessText(
                          overview?.profile?['weight'] != null
                              ? 'Profile weight: ${overview!.profile!['weight']} kg. Add a dated reading to start tracking.'
                              : 'Start with your own measurements or a four-view photo review.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: FitnessTheme.muted,
                              height: 1.4))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _Action(
                          CupertinoIcons.add, 'Measurements', widget.onAdd)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Action(CupertinoIcons.camera, 'Photo review',
                          widget.onPhotos)),
                ]),
                BodySectionTitle('Body map',
                    action: 'Preferences', onTap: widget.onPreferences),
                FitnessCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      BodySegment(
                          labels: const ['Your focus', 'Size changes'],
                          selected: _changes ? 1 : 0,
                          onChanged: (v) => setState(() {
                                _changes = v == 1;
                                _chosenMode = true;
                              })),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: FitnessText(
                                _changes
                                    ? (comparison == null
                                        ? 'Add two entries to compare'
                                        : '${bodyDate(comparison.previous.recordedDate)} → ${bodyDate(comparison.current.recordedDate)}')
                                    : 'Priorities you chose in your profile',
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted))),
                        if (_changes && comparison != null)
                          IconButton(
                              tooltip: fitnessText(context, 'Choose baseline'),
                              onPressed: widget.onBaseline,
                              icon: const Icon(CupertinoIcons.calendar,
                                  size: 18, color: FitnessTheme.muted))
                      ]),
                      GestureDetector(
                          onHorizontalDragEnd: (d) {
                            if ((d.primaryVelocity ?? 0).abs() > 80) {
                              setState(() => _back = !_back);
                            }
                          },
                          child: SizedBox(
                              height: 290,
                              child: AnatomicalTrainingMap(
                                  back: _back,
                                  female: overview?.female ?? false,
                                  colors: {
                                    for (final id in bodyRegionNames.keys)
                                      id: _color(id),
                                    if (_changes) ...{
                                      'biceps_left': _sideColor('leftArmCm'),
                                      'biceps_right': _sideColor('rightArmCm'),
                                      'quads_left': _sideColor('leftThighCm'),
                                      'quads_right': _sideColor('rightThighCm'),
                                      'calves_left': _sideColor('leftCalfCm'),
                                      'calves_right': _sideColor('rightCalfCm'),
                                    },
                                  },
                                  selected: _selected,
                                  onSelected: _select))),
                      SizedBox(
                          width: 156,
                          child: BodySegment(
                              labels: const ['Front', 'Back'],
                              selected: _back ? 1 : 0,
                              onChanged: (v) =>
                                  setState(() => _back = v == 1))),
                      const SizedBox(height: 12),
                      Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: _changes
                              ? const [
                                  BodyLegend(FitnessTheme.blue, 'Larger'),
                                  BodyLegend(FitnessTheme.coral, 'Smaller'),
                                  BodyLegend(FitnessTheme.violet, 'Mixed'),
                                  BodyLegend(Color(0xFFBBBBBB), 'Unchanged'),
                                  BodyLegend(
                                      Color(0xFF555555), 'No matched reading')
                                ]
                              : const [
                                  BodyLegend(FitnessTheme.blue, 'Chosen focus'),
                                  BodyLegend(Color(0xFF555555), 'Other areas')
                                ]),
                      const SizedBox(height: 10),
                      FitnessText(
                          _changes
                              ? 'Tape readings only. A size change alone does not tell us whether muscle or fat changed.'
                              : 'Your focus reflects your preferences. Tap an area for readings, photo notes and training.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              color: FitnessTheme.muted,
                              height: 1.4)),
                    ])),
                BodySectionTitle('Measurements',
                    action: latest == null ? 'Add' : 'View entry',
                    onTap: latest == null
                        ? widget.onAdd
                        : () => widget.onRecord(latest)),
                FitnessCard(
                    child: latest == null
                        ? const FitnessText(
                            'Add chest, waist and hip measurements. Arms and thighs can be recorded separately for each side.',
                            style: TextStyle(
                                fontSize: 13,
                                color: FitnessTheme.muted,
                                height: 1.5))
                        : Column(children: [
                            for (final key in [
                              'chestCm',
                              'waistCm',
                              'hipsCm',
                              'leftArmCm',
                              'rightArmCm',
                              'leftThighCm',
                              'rightThighCm'
                            ])
                              _MeasurementRow(
                                  key, latest.metrics[key], comparison,
                                  last: key == 'rightThighCm'),
                          ])),
                if (latest != null &&
                    ['leftArmCm', 'leftThighCm', 'leftCalfCm'].any((k) =>
                        latest.metrics[k]?.source == 'tape' &&
                        latest.metrics[k.replaceFirst('left', 'right')]
                                ?.source ==
                            'tape')) ...[
                  const BodySectionTitle('Left & right'),
                  FitnessCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        for (final (left, right, label) in [
                          ('leftArmCm', 'rightArmCm', 'Arms'),
                          ('leftThighCm', 'rightThighCm', 'Thighs'),
                          ('leftCalfCm', 'rightCalfCm', 'Calves')
                        ])
                          if (latest.metrics[left]?.source == 'tape' &&
                              latest.metrics[right]?.source == 'tape')
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Expanded(
                                      child: FitnessText(label,
                                          style:
                                              const TextStyle(fontSize: 14))),
                                  FitnessText(
                                      '${(latest.metrics[left]!.value - latest.metrics[right]!.value).abs().toStringAsFixed(1)} cm difference',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: FitnessTheme.silver))
                                ])),
                        const FitnessText(
                            'Measured circumference difference. Repeat at the same point on both sides; this is not a strength or health assessment.',
                            style: TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                height: 1.4)),
                      ])),
                ],
                if (overview != null && overview.records.isNotEmpty) ...[
                  const BodySectionTitle('Trends'),
                  FitnessCard(
                      child: Column(children: [
                    BodySegment(
                        labels: const ['Weight', 'Waist'],
                        selected: _trend,
                        onChanged: (v) => setState(() => _trend = v)),
                    const SizedBox(height: 16),
                    BodyMetricTrend(
                        records: overview.records,
                        metricKey: _trend == 0 ? 'weightKg' : 'waistCm')
                  ])),
                ],
                if (latest != null && latest.photos.isNotEmpty) ...[
                  BodySectionTitle('Photo journal',
                      action: comparison == null ? 'View' : 'Compare',
                      onTap: comparison == null
                          ? () => widget.onRecord(latest)
                          : widget.onCompare),
                  SizedBox(
                      height: 190,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: latest.photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) => GestureDetector(
                              onTap: () => widget.onRecord(latest),
                              child: SizedBox(
                                  width: 128,
                                  child: Column(children: [
                                    Expanded(
                                        child: PrivateBodyPhoto(
                                            key: ValueKey(latest.photos[i].id),
                                            photo: latest.photos[i])),
                                    const SizedBox(height: 7),
                                    FitnessText(
                                        latest.photos[i].view.toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: FitnessTheme.muted))
                                  ]))))),
                ],
                if (latest?.summary case final summary?) ...[
                  const BodySectionTitle('Photo observations'),
                  FitnessCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        FitnessText(summary,
                            style: const TextStyle(fontSize: 13, height: 1.5)),
                        const SizedBox(height: 8),
                        const FitnessText(
                            'AI visual review · estimates are unvalidated',
                            style: TextStyle(
                                fontSize: 10, color: FitnessTheme.muted))
                      ]))
                ],
                if (overview != null && overview.records.isNotEmpty) ...[
                  BodySectionTitle('History',
                      action: 'Add entry', onTap: widget.onAdd),
                  FitnessCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(children: [
                        for (final entry in overview.records)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: FitnessText(bodyDate(entry.recordedDate),
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: FitnessText(
                                  entry.method == 'photo_review'
                                      ? fitnessText(context,
                                          'Photo review · {count} readings',
                                          values: {
                                              'count': entry.metrics.length
                                            })
                                      : fitnessText(
                                          context, '{count} entered readings',
                                          values: {
                                              'count': entry.metrics.length
                                            }),
                                  style: const TextStyle(
                                      fontSize: 11, color: FitnessTheme.muted)),
                              trailing: const Icon(CupertinoIcons.chevron_right,
                                  size: 13, color: FitnessTheme.muted),
                              onTap: () => widget.onRecord(entry))
                      ])),
                ],
              ],
            ]));
  }
}

class _ReadingCard extends StatelessWidget {
  final String label, unit;
  final BodyMetric? metric;
  const _ReadingCard({required this.label, required this.unit, this.metric});
  @override
  Widget build(BuildContext context) => FitnessCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(label,
            style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        const SizedBox(height: 8),
        FitnessText(metric?.display(unit) ?? '—',
            style: const TextStyle(
                fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -.8)),
        const SizedBox(height: 5),
        FitnessText(
            metric == null
                ? 'No dated reading'
                : bodySourceLabel(metric!.source),
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
      ]));
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
          backgroundColor: FitnessTheme.surface,
          foregroundColor: FitnessTheme.silver,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(
            child: FitnessText(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)))
      ]));
}

class _MeasurementRow extends StatelessWidget {
  final String metricKey;
  final BodyMetric? metric;
  final BodyComparison? comparison;
  final bool last;
  const _MeasurementRow(this.metricKey, this.metric, this.comparison,
      {this.last = false});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: FitnessTheme.line))),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(bodyMetricSpecs[metricKey]!.label,
              style: const TextStyle(fontSize: 14)),
          if (metric != null)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FitnessText(bodySourceLabel(metric!.source),
                    style: const TextStyle(
                        fontSize: 10, color: FitnessTheme.muted)))
        ])),
        Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          FitnessText(metric?.display('cm') ?? '—',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          if (comparison != null && metric != null)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FitnessText(comparison!.label(metricKey),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 10, color: FitnessTheme.muted)))
        ])),
      ]));
}

/// Only entered scale/tape readings are plotted, never photo midpoints.
class BodyMetricTrend extends StatelessWidget {
  final List<BodyAssessment> records;
  final String metricKey;
  const BodyMetricTrend(
      {super.key, required this.records, required this.metricKey});
  @override
  Widget build(BuildContext context) {
    final source = metricKey == 'weightKg' ? 'scale' : 'tape';
    final points = records
        .where((r) => r.metrics[metricKey]?.source == source)
        .take(12)
        .toList()
        .reversed
        .toList();
    if (points.length < 2) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: FitnessText(
              source == 'scale'
                  ? 'Add two scale readings to see a trend.'
                  : 'Add two tape readings to see a trend.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)));
    }
    final values = points.map((r) => r.metrics[metricKey]!.value).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FitnessText(
          '${values.first.toStringAsFixed(1)} → ${values.last.toStringAsFixed(1)} ${bodyMetricSpecs[metricKey]!.unit}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      FitnessText(
          '${points.length} ${bodySourceLabel(source).toLowerCase()}s · vertical range ${values.reduce(math.min).toStringAsFixed(1)}–${values.reduce(math.max).toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
      const SizedBox(height: 14),
      Semantics(
          label: points
              .map((p) =>
                  '${bodyDate(p.recordedDate)}: ${p.metrics[metricKey]!.display(bodyMetricSpecs[metricKey]!.unit)}')
              .join(', '),
          child: SizedBox(
              height: 80,
              width: double.infinity,
              child: MotionChartReveal(
                  dataKey:
                      '$metricKey:$source:${points.map((p) => '${p.recordedDate}:${p.metrics[metricKey]!.value}').join('|')}',
                  child: CustomPaint(
                      painter: _TrendPainter(
                          values,
                          points
                              .map((p) => DateTime.parse(p.recordedDate)
                                  .millisecondsSinceEpoch
                                  .toDouble())
                              .toList()))))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        FitnessText(bodyDate(points.first.recordedDate),
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted)),
        FitnessText(bodyDate(points.last.recordedDate),
            style: const TextStyle(fontSize: 10, color: FitnessTheme.muted))
      ]),
    ]);
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values, dates;
  _TrendPainter(this.values, this.dates);
  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(math.min),
        high = values.reduce(math.max),
        span = high - low;
    final offsets = [
      for (var i = 0; i < values.length; i++)
        Offset(
            4 +
                (size.width - 8) *
                    (dates.last == dates.first
                        ? i / (values.length - 1)
                        : (dates[i] - dates.first) /
                            (dates.last - dates.first)),
            span == 0
                ? size.height / 2
                : 6 + (size.height - 12) * (high - values[i]) / span)
    ];
    for (final y in [6.0, size.height / 2, size.height - 6]) {
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = FitnessTheme.line
            ..strokeWidth = .7);
    }
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = FitnessTheme.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
    for (final point in offsets) {
      canvas.drawCircle(point, 3, Paint()..color = FitnessTheme.blue);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.dates != dates;
}
