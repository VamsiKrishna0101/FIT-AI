import '../../../models/home_models.dart';

/// Sync availability is separate from permission/connection state. Movement
/// records do not imply that sleep or heart data has been shared.
class ReadinessAvailability {
  final bool synced, sleep, heart;
  final bool enteredSleep, noWearable;
  final List<String> missingAnswers;
  const ReadinessAvailability(
      {required this.synced,
      required this.sleep,
      required this.heart,
      this.enteredSleep = false,
      this.noWearable = false,
      this.missingAnswers = const []});
  factory ReadinessAvailability.fromMetrics(HomeHealthMetrics? metrics,
          {Map<String, dynamic>? sleepLog, bool noWearable = false}) =>
      ReadinessAvailability(
          synced: metrics != null,
          sleep: (metrics?.sleepMinutes ?? 0) > 0 ||
              ((sleepLog?['sleepMinutes'] as num?) ?? 0) > 0,
          enteredSleep: sleepLog != null,
          noWearable: noWearable,
          missingAnswers: [
            if (sleepLog?['rested'] == null) 'rest',
            if (sleepLog?['energy'] == null) 'energy',
            if (sleepLog?['soreness'] == null) 'soreness',
          ],
          heart: (metrics?.restingHR ?? 0) > 0 || (metrics?.hrv ?? 0) > 0);
  String get title => noWearable
      ? 'Your readiness check-in'
      : enteredSleep
          ? 'Sleep logged'
          : synced
              ? 'Health data synced'
              : 'No readiness for this day';
  String get description => noWearable
      ? !sleep
          ? 'Log sleep and how you feel to add your daily check-in.'
          : missingAnswers.isNotEmpty
              ? 'Sleep saved. Complete your check-in: ${missingAnswers.join(', ')}.'
              : 'Your check-in is saved. Refresh to update your estimate.'
      : enteredSleep && !heart
          ? 'Sleep saved. Watch heart readings have not synced. No wearable? Choose manual check-in in Sleep preferences.'
          : !synced
              ? 'No synced sleep or heart readings for this day.'
              : !sleep && !heart
                  ? 'Steps can sync without sleep or heart readings. Both are still missing for this day.'
                  : !sleep
                      ? 'Heart data synced. Sleep is still missing for this day.'
                      : !heart
                          ? 'Sleep synced. Heart readings have not synced from your health app.'
                          : 'Sleep and heart readings are available. Refresh to update readiness.';
}
