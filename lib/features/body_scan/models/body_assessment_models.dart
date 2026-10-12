const bodyMetricSpecs = <String,
    ({String label, String unit, String? region, double min, double max})>{
  'weightKg': (label: 'Weight', unit: 'kg', region: null, min: 20, max: 500),
  'bodyFatPct': (label: 'Body fat', unit: '%', region: null, min: 2, max: 75),
  'chestCm': (label: 'Chest', unit: 'cm', region: 'chest', min: 30, max: 250),
  'waistCm': (label: 'Waist', unit: 'cm', region: 'core', min: 30, max: 250),
  'hipsCm': (label: 'Hips', unit: 'cm', region: 'glutes', min: 40, max: 250),
  'leftArmCm': (
    label: 'Left arm',
    unit: 'cm',
    region: 'biceps',
    min: 10,
    max: 90
  ),
  'rightArmCm': (
    label: 'Right arm',
    unit: 'cm',
    region: 'biceps',
    min: 10,
    max: 90
  ),
  'leftThighCm': (
    label: 'Left thigh',
    unit: 'cm',
    region: 'quads',
    min: 20,
    max: 140
  ),
  'rightThighCm': (
    label: 'Right thigh',
    unit: 'cm',
    region: 'quads',
    min: 20,
    max: 140
  ),
  'leftCalfCm': (
    label: 'Left calf',
    unit: 'cm',
    region: 'calves',
    min: 10,
    max: 80
  ),
  'rightCalfCm': (
    label: 'Right calf',
    unit: 'cm',
    region: 'calves',
    min: 10,
    max: 80
  ),
  'neckCm': (label: 'Neck', unit: 'cm', region: null, min: 20, max: 80),
};
String bodySourceLabel(String source) => switch (source) {
      'preview' => 'Preview data',
      'tape' => 'Tape measurement',
      'scale' => 'Scale reading',
      'profile' => 'Onboarding weight',
      'smart_scale' => 'Smart scale',
      'dexa' => 'DEXA reading',
      'calipers' => 'Caliper estimate',
      'photo_estimate' => 'Photo estimate',
      'contour_estimate' => 'Silhouette estimate',
      _ => 'Entered estimate',
    };

class BodyMetric {
  final double value;
  final double? low, high;
  final String source;
  BodyMetric.fromJson(Map<String, dynamic> j)
      : value = (j['value'] as num).toDouble(),
        low = (j['low'] as num?)?.toDouble(),
        high = (j['high'] as num?)?.toDouble(),
        source = j['source'] as String;
  bool get isPhotoEstimate =>
      source == 'photo_estimate' || source == 'contour_estimate';
  String display(String unit) => isPhotoEstimate && low != null && high != null
      ? '${low!.toStringAsFixed(0)}–${high!.toStringAsFixed(0)}${unit == '%' ? '' : ' '}$unit'
      : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}${unit == '%' ? '' : ' '}$unit';
  Map<String, dynamic> toJson() => {
        'value': value,
        'source': source,
        if (low != null) 'low': low,
        if (high != null) 'high': high
      };
}

class BodyPhoto {
  final String id, view, url;
  BodyPhoto.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        view = j['view'] as String,
        url = j['url'] as String;
}

class BodyAssessment {
  final String id, recordedDate, status, method, updatedAt, createdAt;
  final String? photoRetention;
  final bool visualCoachingConsent;
  final String? summary, modelVersion;
  final String? focusStatus, focusBasis, gender;
  final Map<String, BodyMetric> metrics;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> bodyRegions;
  final List<String> qualityNotes;
  final List<BodyPhoto> photos;
  final Map<String, dynamic>? physiqueReport, processing;
  BodyAssessment.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        recordedDate = j['recordedDate'] as String,
        status = j['status'] as String,
        method = j['method'] as String,
        updatedAt = j['updatedAt'] as String,
        createdAt = (j['createdAt'] ?? j['updatedAt']) as String,
        photoRetention = (j['quality'] as Map?)?['photoRetention'] as String?,
        visualCoachingConsent =
            (j['quality'] as Map?)?['visualCoachingConsent'] == true,
        summary = j['summary'] as String?,
        modelVersion = j['modelVersion'] as String?,
        focusStatus = (j['quality'] as Map?)?['focusStatus'] as String?,
        focusBasis = (j['quality'] as Map?)?['focusBasis'] as String?,
        gender = j['gender'] as String?,
        physiqueReport = (j['quality'] as Map?)?['physiqueAssessment'] is Map
            ? Map<String, dynamic>.from(
                (j['quality'] as Map)['physiqueAssessment'] as Map)
            : null,
        processing = (j['quality'] as Map?)?['processing'] is Map
            ? Map<String, dynamic>.from(
                (j['quality'] as Map)['processing'] as Map)
            : null,
        metrics = (j['metrics'] as Map).map((key, value) => MapEntry(
            key as String,
            BodyMetric.fromJson(Map<String, dynamic>.from(value as Map)))),
        observations = (j['observations'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        photos = (j['photos'] as List? ?? [])
            .map((e) => BodyPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        bodyRegions = ((j['quality'] as Map?)?['bodyRegions'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        qualityNotes = ((j['quality'] as Map?)?['notes'] as List? ?? [])
            .whereType<String>()
            .toList();
  Map<String, dynamic> get metricJson =>
      metrics.map((key, value) => MapEntry(key, value.toJson()));
  bool isEarlierThan(BodyAssessment other) =>
      recordedDate.compareTo(other.recordedDate) < 0 ||
      (recordedDate == other.recordedDate &&
          DateTime.parse(createdAt).isBefore(DateTime.parse(other.createdAt)));
}

class BodyOverview {
  final Map<String, dynamic>? profile;
  final List<BodyAssessment> records;
  final List<SyncedBodyMeasurement> syncedMeasurements;
  BodyOverview.fromJson(Map<String, dynamic> j)
      : profile = j['profile'] is Map
            ? Map<String, dynamic>.from(j['profile'] as Map)
            : null,
        syncedMeasurements = (j['syncedMeasurements'] as List? ?? [])
            .map((e) => SyncedBodyMeasurement.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        records = (j['records'] as List)
            .map((e) =>
                BodyAssessment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
  BodyAssessment? get latest => records.firstOrNull;
  List<String> get focus =>
      (profile?['focusMuscles'] as List? ?? []).whereType<String>().toList();
  bool get female => profile?['gender'] == 'FEMALE';
}

class SyncedBodyMeasurement {
  final String date, source;
  final String? updatedAt;
  final double? weight, bodyFatPct;
  SyncedBodyMeasurement.fromJson(Map<String, dynamic> j)
      : date = j['date'] as String,
        source = j['sourceProvider'] as String,
        updatedAt = j['updatedAt'] as String?,
        weight = (j['weight'] as num?)?.toDouble(),
        bodyFatPct = (j['bodyFatPct'] as num?)?.toDouble();
  String get sourceLabel =>
      source == 'GOOGLE_HEALTH_CONNECT' ? 'Health Connect' : 'Apple Health';
}

class BodyComparison {
  final BodyAssessment current, previous;
  final Map<String, Map<String, dynamic>> metrics;
  final Map<String, String> regions;
  BodyComparison.fromJson(Map<String, dynamic> j)
      : current = BodyAssessment.fromJson(
            Map<String, dynamic>.from(j['current'] as Map)),
        previous = BodyAssessment.fromJson(
            Map<String, dynamic>.from(j['previous'] as Map)),
        metrics = (j['metrics'] as Map).map((key, value) =>
            MapEntry(key as String, Map<String, dynamic>.from(value as Map))),
        regions = (j['regions'] as Map)
            .map((key, value) => MapEntry(key as String, value as String));
  String label(String key) {
    final change = metrics[key];
    final delta = change?['delta'] as num?;
    if (delta != null) {
      return '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} ${bodyMetricSpecs[key]!.unit}';
    }
    return switch (change?['status']) {
      'different_method' => 'Different sources',
      'overlapping_estimates' => 'Estimate ranges overlap',
      'estimate_increased' => 'Visual range higher',
      'estimate_decreased' => 'Visual range lower',
      _ => 'No matching baseline',
    };
  }
}
