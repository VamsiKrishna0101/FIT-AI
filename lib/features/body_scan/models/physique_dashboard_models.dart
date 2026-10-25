class PhysiqueDashboardMetric {
  final String id, label, unit, source, detail;
  final String? recordedDate;
  final double? value;
  const PhysiqueDashboardMetric(
      {required this.id,
      required this.label,
      required this.unit,
      required this.source,
      required this.detail,
      this.value,
      this.recordedDate});
  String get formatted => value == null
      ? '—'
      : value!.toStringAsFixed(id == 'v_taper'
          ? 2
          : unit == '/100'
              ? 0
              : value! % 1 == 0
                  ? 0
                  : 1);
  String get sourceLabel => switch (source) {
        'member_reading' => 'Entered reading',
        'ai_visual_rating' => 'AI visual rating',
        'photo_geometry' => id == 'v_taper' ? 'Photo ratio' : 'Photo index',
        _ => id == 'body_fat' || id == 'muscle_mass'
            ? 'Add a reading'
            : 'View photo guidance',
      };
}

class PhysiqueDashboardData {
  final double? score;
  final List<PhysiqueDashboardMetric> metrics;
  final List<String> notes;
  final List<String> issues;
  final Map<String, dynamic>? readings;
  final String? geometryVersion;
  const PhysiqueDashboardData(
      {this.score,
      required this.metrics,
      this.notes = const [],
      this.issues = const [],
      this.readings,
      this.geometryVersion});
  factory PhysiqueDashboardData.fromJson(Map? json) {
    final geometry = json?['geometry'] is Map ? json!['geometry'] as Map : null;
    final rawScore = geometry?['status'] == 'experimental' &&
            const ['visual-contour-index-v1', 'visual-contour-index-v2']
                .contains(geometry?['version'])
        ? geometry!['score']
        : null;
    final score =
        rawScore is num && rawScore.isFinite && rawScore >= 0 && rawScore <= 100
            ? rawScore.toDouble()
            : null;
    final saved =
        (json?['metrics'] is List ? json!['metrics'] as List : const [])
            .whereType<Map>();
    const names = {
      'body_fat': 'Body fat',
      'muscle_mass': 'Muscle mass',
      'v_taper': 'V-taper',
      'definition': 'Definition',
      'chest': 'Chest balance',
      'shoulders': 'Shoulder balance'
    };
    const units = {
      'body_fat': '%',
      'muscle_mass': 'kg',
      'v_taper': '×',
      'definition': '/100',
      'chest': '/100',
      'shoulders': '/100'
    };
    return PhysiqueDashboardData(
        score: score,
        geometryVersion: geometry?['version'] as String?,
        issues: geometry?['metricNotes'] is Map
            ? (geometry!['metricNotes'] as Map)
                .values
                .whereType<String>()
                .toSet()
                .toList()
            : (geometry?['qualityNotes'] as List? ?? [])
                .whereType<String>()
                .toList(),
        readings: json?['readings'] is Map
            ? Map<String, dynamic>.from(json!['readings'] as Map)
            : null,
        notes: (geometry?['qualityNotes'] as List? ?? [])
            .whereType<String>()
            .toList(),
        metrics: [
          for (final entry in names.entries)
            () {
              final raw = saved.where((m) => m['id'] == entry.key).firstOrNull;
              final number = raw?['value'];
              final source = raw?['source'] as String? ?? 'unavailable';
              final supported = switch (entry.key) {
                'body_fat' || 'muscle_mass' => source == 'member_reading',
                'definition' => source == 'ai_visual_rating',
                _ => source == 'photo_geometry',
              };
              final maximum = entry.key == 'muscle_mass'
                  ? 150
                  : entry.key == 'v_taper'
                      ? 2.5
                      : entry.key == 'body_fat'
                          ? 75
                          : 100;
              final valid = supported &&
                  number is num &&
                  number.isFinite &&
                  number >= 0 &&
                  number <= maximum;
              return PhysiqueDashboardMetric(
                  id: entry.key,
                  label: entry.value,
                  unit: units[entry.key]!,
                  value: valid ? number.toDouble() : null,
                  source: valid ? source : 'unavailable',
                  recordedDate: raw?['recordedDate'] as String?,
                  detail: raw?['detail'] as String? ??
                      (entry.key == 'body_fat' || entry.key == 'muscle_mass'
                          ? 'Add a reading from your smart scale or report. This photo engine does not calculate body composition.'
                          : 'No supported numeric result for this area. Update using a clear front photo.'));
            }()
        ]);
  }
}
