import 'dart:math' as math;
import 'package:health/health.dart';
import 'health_models.dart';

/// Keeps daily movement separate from overnight sleep and retains provenance.
class HealthNormalizer {
  const HealthNormalizer();
  static const sleepTypes = {
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_IN_BED,
  };

  HealthSnapshotPayload normalize(
      {required DateTime targetDate,
      required HealthProviderType provider,
      required List<HealthDataPoint> dataPoints,
      int? aggregatedSteps,
      double? aggregatedActiveCalories,
      bool energyAggregated = false,
      DateTime? readAt}) {
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day + 1);
    final date =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final unique = <String, HealthDataPoint>{};
    for (final p in dataPoints) {
      // A Health Connect UUID can contain several stages or series samples.
      final key =
          '${_origin(p)}:${p.type.name}:${p.uuid}:${p.dateFrom}:${p.dateTo}:${_number(p)}';
      unique[key] = p;
    }
    final points = unique.values.toList()
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final daily = points
        .where((p) =>
            !sleepTypes.contains(p.type) &&
            !p.dateFrom.toLocal().isBefore(start) &&
            p.dateFrom.toLocal().isBefore(end))
        .toList();
    final sleep = _sleepForDay(
        points
            .where((p) =>
                sleepTypes.contains(p.type) && !p.dateTo.isAfter(readAt ?? end))
            .toList(),
        start,
        end);
    final meta = <String, Map<String, String>>{};
    void record(String name, List<HealthDataPoint> samples, {String? method}) {
      if (samples.isEmpty) return;
      final p = samples.last;
      final source = p.sourceName.isEmpty ? provider.displayName : p.sourceName;
      meta[name] = {
        'source': source.substring(0, math.min(200, source.length)),
        'measuredAt': p.dateTo.toUtc().toIso8601String(),
        if (method != null) 'method': method
      };
    }

    List<HealthDataPoint> of(HealthDataType type) => _singleSource(
        daily.where((p) => p.type == type && (_number(p) ?? -1) >= 0).toList());
    double? mean(HealthDataType type, String name) {
      final samples = of(type).where((p) => _number(p)! > 0).toList();
      record(name, samples);
      return samples.isEmpty
          ? null
          : _round(samples.fold<double>(0, (sum, p) => sum + _number(p)!) /
              samples.length);
    }

    double? latest(HealthDataType type, String name) {
      final samples = daily
          .where((p) => p.type == type && (_number(p) ?? -1) >= 0)
          .toList();
      record(name, samples);
      return samples.isEmpty ? null : _number(samples.last);
    }

    double? sum(HealthDataType type, String name) {
      final samples = of(type);
      record(name, samples, method: 'single_source');
      return samples.isEmpty
          ? null
          : _round(samples.fold<double>(0, (sum, p) => sum + _number(p)!));
    }

    double? duration(HealthDataType type) {
      final samples = sleep.where((p) => p.type == type).toList();
      return samples.isEmpty ? null : _minutes(samples);
    }

    final asleep = sleep
        .where((p) => {
              HealthDataType.SLEEP_DEEP,
              HealthDataType.SLEEP_REM,
              HealthDataType.SLEEP_LIGHT,
              HealthDataType.SLEEP_ASLEEP,
            }.contains(p.type))
        .toList();
    final sessions =
        sleep.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList();
    final awake =
        sleep.where((p) => p.type == HealthDataType.SLEEP_AWAKE).toList();
    final total = asleep.isNotEmpty
        ? _minutes(asleep, subtract: awake)
        : sessions.isNotEmpty
            ? _minutes(sessions, subtract: awake)
            : null;
    final bed = sleep
        .where((p) =>
            p.type == HealthDataType.SLEEP_SESSION ||
            p.type == HealthDataType.SLEEP_IN_BED)
        .toList();
    final inBed = bed.isEmpty ? null : _minutes(bed);
    record('sleepTotalMinutes', asleep.isNotEmpty ? asleep : sessions,
        method: asleep.isNotEmpty ? 'sleep_intervals' : 'sleep_session');
    final hrvType = provider == HealthProviderType.googleHealthConnect
        ? HealthDataType.HEART_RATE_VARIABILITY_RMSSD
        : HealthDataType.HEART_RATE_VARIABILITY_SDNN;
    final hrv = mean(hrvType, 'hrv');
    final method = hrv == null
        ? null
        : provider == HealthProviderType.googleHealthConnect
            ? 'RMSSD'
            : 'SDNN';
    if (method != null) meta['hrv']!['method'] = method;
    if (aggregatedSteps != null) {
      meta['steps'] = {
        'source': provider.displayName,
        'measuredAt': (readAt ?? end).toUtc().toIso8601String(),
        'method': 'platform_aggregate'
      };
    }
    final workouts = daily
        .where((p) => p.type == HealthDataType.WORKOUT)
        .map((p) => _workout(p, provider))
        .whereType<HealthWorkoutPayload>()
        .toList();
    final energy = energyAggregated
        ? aggregatedActiveCalories
        : sum(HealthDataType.ACTIVE_ENERGY_BURNED, 'activeCalories');
    if (energyAggregated && energy != null) {
      meta['activeCalories'] = {
        'source': provider.displayName,
        'measuredAt': (readAt ?? end).toUtc().toIso8601String(),
        'method': 'platform_aggregate'
      };
    }
    return HealthSnapshotPayload(
        date: date,
        sourceProvider: provider.providerKey,
        utcOffsetMinutes: start.timeZoneOffset.inMinutes,
        hrv: hrv,
        hrvMethod: method,
        sleepTotalMinutes: total == null ? null : _round(total),
        sleepDeepMinutes: duration(HealthDataType.SLEEP_DEEP),
        sleepRemMinutes: duration(HealthDataType.SLEEP_REM),
        sleepCoreMinutes: duration(HealthDataType.SLEEP_LIGHT),
        sleepEfficiency: total != null && inBed != null && inBed > 0
            ? _round((total / inBed * 100).clamp(0, 100))
            : null,
        restingHR: mean(HealthDataType.RESTING_HEART_RATE, 'restingHR'),
        avgDayHR: mean(HealthDataType.HEART_RATE, 'avgDayHR'),
        steps: aggregatedSteps,
        activeCalories: energy,
        weight: latest(HealthDataType.WEIGHT, 'weight'),
        bodyFatPct: latest(HealthDataType.BODY_FAT_PERCENTAGE, 'bodyFatPct'),
        externalWorkouts: workouts,
        metricMetadata: meta);
  }

  String _origin(HealthDataPoint point) =>
      point.sourceId.isEmpty ? point.sourceName : point.sourceId;

  List<HealthDataPoint> _sleepForDay(
      List<HealthDataPoint> points, DateTime start, DateTime end) {
    // Assign a night's stages to its wake-up date, including stages before midnight.
    final origins = <String, List<HealthDataPoint>>{};
    for (final p in points) {
      (origins[_origin(p)] ??= []).add(p);
    }
    final selected = <HealthDataPoint>[];
    for (final origin in origins.values) {
      origin.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      var cluster = <HealthDataPoint>[];
      DateTime? finish;
      void commit() {
        if (finish != null &&
            !finish.toLocal().isBefore(start) &&
            finish.toLocal().isBefore(end)) {
          selected.addAll(cluster);
        }
      }

      for (final p in origin) {
        if (finish != null &&
            p.dateFrom.difference(finish) > const Duration(minutes: 90)) {
          commit();
          cluster = [];
          finish = null;
        }
        cluster.add(p);
        if (finish == null || p.dateTo.isAfter(finish)) {
          finish = p.dateTo;
        }
      }
      commit();
    }
    return _singleSource(selected)
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
  }

  // Choose one originating app so mirrored records from other apps are not added.
  List<HealthDataPoint> _singleSource(List<HealthDataPoint> points) {
    if (points.isEmpty) return points;
    final groups = <String, List<HealthDataPoint>>{};
    for (final p in points) {
      (groups[_origin(p)] ??= []).add(p);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final count = b.value.length.compareTo(a.value.length);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    return sorted.first.value;
  }

  double _minutes(List<HealthDataPoint> points,
      {List<HealthDataPoint> subtract = const []}) {
    final events = <({int time, int asleep, int awake})>[];
    for (final group in [points, subtract]) {
      final isAwake = identical(group, subtract);
      for (final p in group) {
        if (!p.dateTo.isAfter(p.dateFrom)) continue;
        events.add((
          time: p.dateFrom.millisecondsSinceEpoch,
          asleep: isAwake ? 0 : 1,
          awake: isAwake ? 1 : 0
        ));
        events.add((
          time: p.dateTo.millisecondsSinceEpoch,
          asleep: isAwake ? 0 : -1,
          awake: isAwake ? -1 : 0
        ));
      }
    }
    events.sort((a, b) => a.time.compareTo(b.time));
    int asleep = 0, awake = 0, duration = 0;
    int? last;
    for (final event in events) {
      if (last != null && asleep > 0 && awake == 0) {
        duration += event.time - last;
      }
      asleep += event.asleep;
      awake += event.awake;
      last = event.time;
    }
    return _round(duration / 60000);
  }

  HealthWorkoutPayload? _workout(
      HealthDataPoint p, HealthProviderType provider) {
    if (!p.dateTo.isAfter(p.dateFrom) || p.value is! WorkoutHealthValue) {
      return null;
    }
    final value = p.value as WorkoutHealthValue;
    final duration = _round(p.dateTo.difference(p.dateFrom).inSeconds / 60);
    if (duration <= 0) {
      return null;
    }
    return HealthWorkoutPayload(
        externalId:
            '${provider.providerKey}:${_origin(p)}:${p.uuid.isEmpty ? '${p.dateFrom.toUtc().toIso8601String()}:${value.workoutActivityType.name}' : p.uuid}',
        workoutType: value.workoutActivityType.name,
        durationMinutes: duration,
        activeCalories: value.totalEnergyBurned?.toDouble(),
        totalDistance: value.totalDistance?.toDouble(),
        source: provider.providerKey,
        startedAt: p.dateFrom,
        endedAt: p.dateTo);
  }

  double? _number(HealthDataPoint p) => p.value is NumericHealthValue
      ? (p.value as NumericHealthValue).numericValue.toDouble()
      : null;
  double _round(double value) => (value * 10).round() / 10;
}
