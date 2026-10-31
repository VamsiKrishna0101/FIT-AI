import 'body_assessment_models.dart';

/// The same required baseline is enforced by the planner API.
class BodyMeasurementBaseline {
  final BodyOverview overview;
  final DateTime now;

  BodyMeasurementBaseline(this.overview, {DateTime? now})
      : now = now ?? DateTime.now();

  double? get height {
    final value = (overview.profile?['height'] as num?)?.toDouble();
    return value != null && value.isFinite && value >= 100 && value <= 250
        ? value
        : null;
  }

  BodyMetric? latest(String key) {
    final today = DateTime(now.year, now.month, now.day);
    final entries = [...overview.records]..sort((a, b) {
        final date = b.recordedDate.compareTo(a.recordedDate);
        return date != 0 ? date : b.createdAt.compareTo(a.createdAt);
      });
    for (final entry in entries) {
      final date = DateTime.tryParse(entry.recordedDate);
      final metric = entry.metrics[key];
      final spec = bodyMetricSpecs[key];
      if (entry.status != 'SAVED' ||
          entry.synthetic ||
          date == null ||
          date.isAfter(today) ||
          metric == null ||
          spec == null) {
        continue;
      }
      final sources =
          key == 'weightKg' ? const ['scale', 'smart_scale'] : const ['tape'];
      if (sources.contains(metric.source) &&
          metric.value.isFinite &&
          metric.value >= spec.min &&
          metric.value <= spec.max) {
        return metric;
      }
    }
    return null;
  }

  List<String> get missing => [
        if (height == null) 'height',
        if (latest('weightKg') == null) 'weightKg',
        if (latest('waistCm') == null) 'waistCm',
      ];

  bool get isComplete => missing.isEmpty;
}
