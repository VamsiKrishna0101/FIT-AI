import '../../../models/home_models.dart';

/// Sync availability is separate from permission/connection state. Movement
/// records do not imply that sleep or heart data has been shared.
class ReadinessAvailability {
  final bool synced, sleep, heart;
  const ReadinessAvailability(
      {required this.synced, required this.sleep, required this.heart});
  factory ReadinessAvailability.fromMetrics(HomeHealthMetrics? metrics) =>
      ReadinessAvailability(
          synced: metrics != null,
          sleep: (metrics?.sleepMinutes ?? 0) > 0,
          heart: (metrics?.restingHR ?? 0) > 0 || (metrics?.hrv ?? 0) > 0);
  String get title =>
      synced ? 'Health data synced' : 'No readiness for this day';
  String get description => !synced
      ? 'No synced sleep or heart readings for this day.'
      : !sleep && !heart
          ? 'Steps can sync without sleep or heart readings. Both are still missing for this day.'
          : !sleep
              ? 'Heart data synced. Sleep is still missing for this day.'
              : !heart
                  ? 'Sleep synced. A resting heart rate or HRV reading is still missing.'
                  : 'Sleep and heart readings are available. Refresh to update readiness.';
}
