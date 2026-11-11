import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/watch/watch_models.dart';
import 'package:setcraft/core/watch/watch_sync_service.dart';

void main() {
  group('Apple Watch Sync & Models Test Suite', () {
    test('WatchWorkoutSnapshot serializes and deserializes cleanly', () {
      const snapshot = WatchWorkoutSnapshot(
        sessionId: 'test-session-123',
        date: '2026-11-01',
        title: 'Chest Hypertrophy',
        activeItemIndex: 0,
        items: [
          WatchExerciseItem(
            id: 'item-1',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            targetSets: 4,
            targetReps: '8-10',
            targetWeight: 80.0,
            restSeconds: 90,
            status: 'IN_PROGRESS',
            loggedSets: [
              WatchSetLog(
                setNumber: 1,
                weight: 80.0,
                reps: 10,
                completed: true,
              ),
            ],
          ),
        ],
        rest: WatchRestPayload(
          isActive: true,
          exerciseName: 'Bench Press',
          setNumber: 1,
          remainingSeconds: 85,
          duration: 90,
          isPaused: false,
          endTimeEpochMs: 1793475200000,
        ),
      );

      final json = snapshot.toJson();
      expect(json['type'], 'WORKOUT_STATE');
      expect(json['sessionId'], 'test-session-123');
      expect(json['title'], 'Chest Hypertrophy');

      final reconstructed = WatchWorkoutSnapshot.fromJson(json);
      expect(reconstructed.items.length, 1);
      expect(reconstructed.items.first.exerciseName, 'Bench Press');
      expect(reconstructed.items.first.loggedSets.length, 1);
      expect(reconstructed.rest?.isActive, true);
      expect(reconstructed.rest?.remainingSeconds, 85);
    });

    test('WatchSyncService dispatches virtual actions properly', () async {
      final service = WatchSyncService.shared;
      final actions = <WatchIncomingAction>[];
      final sub = service.actions.listen(actions.add);

      // 1. Dispatch Log Set
      service.dispatchVirtualAction(
        const WatchLogSetAction(
          itemId: 'item-1',
          setNumber: 2,
          weight: 82.5,
          reps: 8,
        ),
      );

      // 2. Dispatch Select Exercise
      service.dispatchVirtualAction(
        const WatchSelectExerciseAction(itemId: 'item-2'),
      );

      // 3. Dispatch Biometrics
      service.dispatchVirtualAction(
        const WatchBiometricUpdateAction(
          biometrics: WatchBiometrics(
            heartRate: 145,
            hrZone: 3,
            activeCalories: 120.5,
            elapsedSeconds: 600,
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(actions.length, 3);
      expect(actions[0], isA<WatchLogSetAction>());
      expect((actions[0] as WatchLogSetAction).weight, 82.5);
      expect(actions[1], isA<WatchSelectExerciseAction>());
      expect((actions[1] as WatchSelectExerciseAction).itemId, 'item-2');
      expect(actions[2], isA<WatchBiometricUpdateAction>());
      expect(service.biometricsNotifier.value?.heartRate, 145);

      await sub.cancel();
    });

    test('watch payload carries rest-alert and heart-rate settings', () {
      const snapshot = WatchWorkoutSnapshot(
        sessionId: 's1',
        date: '2026-11-11',
        title: 'Legs',
        activeItemIndex: 0,
        items: [],
      );
      final payload = WatchSyncService.shared.watchPayload(snapshot);
      expect(payload['sessionId'], 's1');
      expect(payload['hapticRestAlerts'], isA<bool>());
      expect(payload['heartRateEnabled'], isA<bool>());
    });
  });
}

