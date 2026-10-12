import 'body_assessment_models.dart';

class BodyReading {
  final String key, date, sourceLabel, series;
  final BodyMetric metric;
  final BodyAssessment? assessment;
  final String updatedAt;

  const BodyReading(
      {required this.key,
      required this.date,
      required this.sourceLabel,
      required this.series,
      required this.metric,
      this.assessment,
      this.updatedAt = ''});
}

/// A display summary of saved readings. Estimates never become measured trends.
class BodyProgressSummary {
  final BodyOverview? overview;
  late final List<BodyReading> readings = _readings();

  BodyProgressSummary(this.overview);

  List<BodyReading> _readings() {
    final result = <BodyReading>[];
    for (final entry in overview?.records ?? <BodyAssessment>[]) {
      for (final reading in entry.metrics.entries) {
        if (reading.value.source == 'preview') continue;
        result.add(BodyReading(
            key: reading.key,
            date: entry.recordedDate,
            metric: reading.value,
            sourceLabel: bodySourceLabel(reading.value.source),
            series: reading.value.source,
            assessment: entry,
            updatedAt: entry.createdAt));
      }
    }
    for (final entry
        in overview?.syncedMeasurements ?? <SyncedBodyMeasurement>[]) {
      for (final reading in {
        'weightKg': entry.weight,
        'bodyFatPct': entry.bodyFatPct
      }.entries) {
        if (reading.value == null) continue;
        result.add(BodyReading(
            key: reading.key,
            date: entry.date,
            metric: BodyMetric.fromJson(
                {'value': reading.value, 'source': entry.source}),
            sourceLabel: entry.sourceLabel,
            series: entry.source,
            updatedAt: entry.updatedAt ?? ''));
      }
    }
    result.sort((first, second) {
      final date = second.date.compareTo(first.date);
      return date != 0 ? date : second.updatedAt.compareTo(first.updatedAt);
    });
    return result;
  }

  BodyReading? latest(String key) =>
      readings.where((reading) => reading.key == key).firstOrNull;

  BodyReading? get weight => readings
      .where((reading) =>
          reading.key == 'weightKg' &&
          !reading.metric.isPhotoEstimate &&
          reading.metric.source != 'profile')
      .firstOrNull;

  List<BodyReading> get weightTrend {
    final latestWeight = weight;
    if (latestWeight == null) return [];
    final days = <String>{};
    return readings
        .where((reading) =>
            reading.key == 'weightKg' &&
            reading.series == latestWeight.series &&
            !reading.metric.isPhotoEstimate &&
            days.add(reading.date))
        .take(12)
        .toList()
        .reversed
        .toList();
  }

  List<BodyReading> get measurements => bodyMetricSpecs.keys
      .where((key) => key != 'weightKg')
      .map(latest)
      .whereType<BodyReading>()
      .toList();

  BodyAssessment? get report => overview?.records
      .where((entry) =>
          entry.physiqueReport != null ||
          entry.observations.isNotEmpty ||
          entry.photos.isNotEmpty)
      .firstOrNull;

  BodyAssessment? get comparisonEntry => overview?.records
      .where((entry) => overview!.records.any((previous) =>
          previous.isEarlierThan(entry) &&
          (entry.metrics.keys.any(previous.metrics.containsKey) ||
              (entry.physiqueReport != null &&
                  previous.physiqueReport != null))))
      .firstOrNull;
}
