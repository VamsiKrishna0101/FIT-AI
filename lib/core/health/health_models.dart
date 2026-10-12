// MARK: - Universal Health Models for Google Health Connect & Apple HealthKit

enum HealthProviderType {
  googleHealthConnect,
  appleHealthKit,
  manual;

  String get displayName {
    switch (this) {
      case HealthProviderType.googleHealthConnect:
        return 'Health Connect';
      case HealthProviderType.appleHealthKit:
        return 'Apple Health';
      case HealthProviderType.manual:
        return 'Manual Telemetry';
    }
  }

  String get badgeLabel {
    switch (this) {
      case HealthProviderType.googleHealthConnect:
        return 'HEALTH CONNECT';
      case HealthProviderType.appleHealthKit:
        return 'HEALTHKIT';
      case HealthProviderType.manual:
        return 'MANUAL';
    }
  }

  String get providerKey {
    switch (this) {
      case HealthProviderType.googleHealthConnect:
        return 'GOOGLE_HEALTH_CONNECT';
      case HealthProviderType.appleHealthKit:
        return 'APPLE_HEALTHKIT';
      case HealthProviderType.manual:
        return 'MANUAL';
    }
  }
}

enum HealthConnectionState {
  unsupported,
  needsInstall,
  disconnected,
  authorizing,
  connected,
  syncing,
  synced,
  error;

  bool get isConnected =>
      this == HealthConnectionState.connected ||
      this == HealthConnectionState.syncing ||
      this == HealthConnectionState.synced;
}

class HealthWorkoutPayload {
  final String externalId;
  final String workoutType;
  final double durationMinutes;
  final double? activeCalories;
  final double? totalDistance;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgWatts;
  final double? elevationAscent;
  final double? hrZone1Minutes;
  final double? hrZone2Minutes;
  final double? hrZone3Minutes;
  final double? hrZone4Minutes;
  final double? hrZone5Minutes;
  final String source;
  final DateTime startedAt;
  final DateTime endedAt;

  const HealthWorkoutPayload({
    required this.externalId,
    required this.workoutType,
    required this.durationMinutes,
    required this.activeCalories,
    this.totalDistance,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgWatts,
    this.elevationAscent,
    this.hrZone1Minutes,
    this.hrZone2Minutes,
    this.hrZone3Minutes,
    this.hrZone4Minutes,
    this.hrZone5Minutes,
    required this.source,
    required this.startedAt,
    required this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'externalId': externalId,
        'workoutType': workoutType,
        'durationMinutes': durationMinutes,
        if (activeCalories != null) 'activeCalories': activeCalories,
        if (totalDistance != null) 'totalDistance': totalDistance,
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
        if (avgWatts != null) 'avgWatts': avgWatts,
        if (elevationAscent != null) 'elevationAscent': elevationAscent,
        if (hrZone1Minutes != null) 'hrZone1Minutes': hrZone1Minutes,
        if (hrZone2Minutes != null) 'hrZone2Minutes': hrZone2Minutes,
        if (hrZone3Minutes != null) 'hrZone3Minutes': hrZone3Minutes,
        if (hrZone4Minutes != null) 'hrZone4Minutes': hrZone4Minutes,
        if (hrZone5Minutes != null) 'hrZone5Minutes': hrZone5Minutes,
        'source': source,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
      };
}

class HealthSnapshotPayload {
  final String date; // YYYY-MM-DD
  final String sourceProvider; // "GOOGLE_HEALTH_CONNECT" | "APPLE_HEALTHKIT"
  final double? sleepTotalMinutes;
  final double? sleepDeepMinutes;
  final double? sleepRemMinutes;
  final double? sleepCoreMinutes;
  final double? sleepEfficiency;
  final double? hrv;
  final String? hrvMethod;
  final int? utcOffsetMinutes;
  final Map<String, Map<String, String>> metricMetadata;
  final double? restingHR;
  final double? avgDayHR;
  final double? activeCalories;
  final double? basalCalories;
  final int? steps;
  final int? flightsClimbed;
  final double? weight;
  final double? bodyFatPct;
  final double? leanMassKg;
  final double? vo2Max;
  final double? bloodOxygen;
  final double? respiratoryRate;
  final double? wristTempDeviation;
  final double? bloodGlucoseAvg;
  final double? cardioRecoveryHr;
  final String? cyclePhase;
  final double? healthAge;
  final List<HealthWorkoutPayload> externalWorkouts;

  const HealthSnapshotPayload({
    required this.date,
    required this.sourceProvider,
    this.sleepTotalMinutes,
    this.sleepDeepMinutes,
    this.sleepRemMinutes,
    this.sleepCoreMinutes,
    this.sleepEfficiency,
    this.hrv,
    this.hrvMethod,
    this.utcOffsetMinutes,
    this.metricMetadata = const {},
    this.restingHR,
    this.avgDayHR,
    this.activeCalories,
    this.basalCalories,
    this.steps,
    this.flightsClimbed,
    this.weight,
    this.bodyFatPct,
    this.leanMassKg,
    this.vo2Max,
    this.bloodOxygen,
    this.respiratoryRate,
    this.wristTempDeviation,
    this.bloodGlucoseAvg,
    this.cardioRecoveryHr,
    this.cyclePhase,
    this.healthAge,
    this.externalWorkouts = const [],
  });

  factory HealthSnapshotPayload.fromJson(Map<String, dynamic> j) =>
      HealthSnapshotPayload(
          date: j['date'] as String,
          sourceProvider: j['sourceProvider'] as String,
          steps: (j['steps'] as num?)?.toInt(),
          activeCalories: (j['activeCalories'] as num?)?.toDouble(),
          sleepTotalMinutes: (j['sleepTotalMinutes'] as num?)?.toDouble(),
          hrv: (j['hrv'] as num?)?.toDouble(),
          hrvMethod: j['hrvMethod'] as String?,
          restingHR: (j['restingHR'] as num?)?.toDouble(),
          weight: (j['weight'] as num?)?.toDouble(),
          bodyFatPct: (j['bodyFatPct'] as num?)?.toDouble());

  Map<String, dynamic> toJson() => {
        'date': date,
        'sourceProvider': sourceProvider,
        if (sleepTotalMinutes != null) 'sleepTotalMinutes': sleepTotalMinutes,
        if (sleepDeepMinutes != null) 'sleepDeepMinutes': sleepDeepMinutes,
        if (sleepRemMinutes != null) 'sleepRemMinutes': sleepRemMinutes,
        if (sleepCoreMinutes != null) 'sleepCoreMinutes': sleepCoreMinutes,
        if (sleepEfficiency != null) 'sleepEfficiency': sleepEfficiency,
        if (hrv != null) 'hrv': hrv,
        if (hrvMethod != null) 'hrvMethod': hrvMethod,
        if (utcOffsetMinutes != null) 'utcOffsetMinutes': utcOffsetMinutes,
        if (metricMetadata.isNotEmpty) 'metricMetadata': metricMetadata,
        if (restingHR != null) 'restingHR': restingHR,
        if (avgDayHR != null) 'avgDayHR': avgDayHR,
        if (activeCalories != null) 'activeCalories': activeCalories,
        if (basalCalories != null) 'basalCalories': basalCalories,
        if (steps != null) 'steps': steps,
        if (flightsClimbed != null) 'flightsClimbed': flightsClimbed,
        if (weight != null) 'weight': weight,
        if (bodyFatPct != null) 'bodyFatPct': bodyFatPct,
        if (leanMassKg != null) 'leanMassKg': leanMassKg,
        if (vo2Max != null) 'vo2Max': vo2Max,
        if (bloodOxygen != null) 'bloodOxygen': bloodOxygen,
        if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
        if (wristTempDeviation != null)
          'wristTempDeviation': wristTempDeviation,
        if (bloodGlucoseAvg != null) 'bloodGlucoseAvg': bloodGlucoseAvg,
        if (cardioRecoveryHr != null) 'cardioRecoveryHr': cardioRecoveryHr,
        if (cyclePhase != null) 'cyclePhase': cyclePhase,
        if (healthAge != null) 'healthAge': healthAge,
        if (externalWorkouts.isNotEmpty)
          'externalWorkouts': externalWorkouts.map((w) => w.toJson()).toList(),
      };
}

class HealthSyncResult {
  final bool success;
  final String? message;
  final HealthSnapshotPayload? snapshot;
  final double? recoveryScore;
  final String? aiNote;

  const HealthSyncResult({
    required this.success,
    this.message,
    this.snapshot,
    this.recoveryScore,
    this.aiNote,
  });
}
