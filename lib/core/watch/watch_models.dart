class WatchWorkoutSnapshot {
  final String sessionId;
  final String date;
  final String title;
  final int activeItemIndex;
  final List<WatchExerciseItem> items;
  final WatchRestPayload? rest;

  const WatchWorkoutSnapshot({
    required this.sessionId,
    required this.date,
    required this.title,
    required this.activeItemIndex,
    required this.items,
    this.rest,
  });

  Map<String, dynamic> toJson() => {
        'type': 'WORKOUT_STATE',
        'sessionId': sessionId,
        'date': date,
        'title': title,
        'activeItemIndex': activeItemIndex,
        'items': items.map((e) => e.toJson()).toList(),
        if (rest != null) 'rest': rest!.toJson(),
      };

  factory WatchWorkoutSnapshot.fromJson(Map<String, dynamic> json) =>
      WatchWorkoutSnapshot(
        sessionId: (json['sessionId'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        title: (json['title'] ?? 'Workout').toString(),
        activeItemIndex: (json['activeItemIndex'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List? ?? [])
            .map((e) => WatchExerciseItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        rest: json['rest'] is Map
            ? WatchRestPayload.fromJson(Map<String, dynamic>.from(json['rest'] as Map))
            : null,
      );
}

class WatchExerciseItem {
  final String id;
  final String exerciseName;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final double targetWeight;
  final int restSeconds;
  final String status;
  final List<WatchSetLog> loggedSets;

  const WatchExerciseItem({
    required this.id,
    required this.exerciseName,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.restSeconds,
    required this.status,
    required this.loggedSets,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isSkipped => status == 'SKIPPED';
  bool get isPending => !isCompleted && !isSkipped;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'orderIndex': orderIndex,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'restSeconds': restSeconds,
        'status': status,
        'loggedSets': loggedSets.map((e) => e.toJson()).toList(),
      };

  factory WatchExerciseItem.fromJson(Map<String, dynamic> json) =>
      WatchExerciseItem(
        id: (json['id'] ?? '').toString(),
        exerciseName: (json['exerciseName'] ?? '').toString(),
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        targetSets: (json['targetSets'] as num?)?.toInt() ?? 3,
        targetReps: (json['targetReps'] ?? '8-12').toString(),
        targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 0.0,
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 60,
        status: (json['status'] ?? 'NOT_STARTED').toString(),
        loggedSets: (json['loggedSets'] as List? ?? [])
            .map((e) => WatchSetLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class WatchSetLog {
  final int setNumber;
  final double weight;
  final int reps;
  final bool completed;
  final double? rpe;

  const WatchSetLog({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.completed,
    this.rpe,
  });

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'completed': completed,
        if (rpe != null) 'rpe': rpe,
      };

  factory WatchSetLog.fromJson(Map<String, dynamic> json) => WatchSetLog(
        setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        completed: json['completed'] != false,
        rpe: (json['rpe'] as num?)?.toDouble(),
      );
}

class WatchRestPayload {
  final bool isActive;
  final String exerciseName;
  final int setNumber;
  final int remainingSeconds;
  final int duration;
  final bool isPaused;
  final int endTimeEpochMs;

  const WatchRestPayload({
    required this.isActive,
    required this.exerciseName,
    required this.setNumber,
    required this.remainingSeconds,
    required this.duration,
    required this.isPaused,
    required this.endTimeEpochMs,
  });

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'remainingSeconds': remainingSeconds,
        'duration': duration,
        'isPaused': isPaused,
        'endTimeEpochMs': endTimeEpochMs,
      };

  factory WatchRestPayload.fromJson(Map<String, dynamic> json) =>
      WatchRestPayload(
        isActive: json['isActive'] == true,
        exerciseName: (json['exerciseName'] ?? '').toString(),
        setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
        remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt() ?? 60,
        isPaused: json['isPaused'] == true,
        endTimeEpochMs: (json['endTimeEpochMs'] as num?)?.toInt() ?? 0,
      );
}

class WatchBiometrics {
  final int heartRate;
  final int hrZone;
  final double activeCalories;
  final int elapsedSeconds;

  const WatchBiometrics({
    required this.heartRate,
    required this.hrZone,
    required this.activeCalories,
    required this.elapsedSeconds,
  });

  Map<String, dynamic> toJson() => {
        'heartRate': heartRate,
        'hrZone': hrZone,
        'activeCalories': activeCalories,
        'elapsedSeconds': elapsedSeconds,
      };

  factory WatchBiometrics.fromJson(Map<String, dynamic> json) =>
      WatchBiometrics(
        heartRate: (json['heartRate'] as num?)?.toInt() ?? 0,
        hrZone: (json['hrZone'] as num?)?.toInt() ?? 1,
        activeCalories: (json['activeCalories'] as num?)?.toDouble() ?? 0.0,
        elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      );
}

sealed class WatchIncomingAction {
  const WatchIncomingAction();
}

class WatchLogSetAction extends WatchIncomingAction {
  final String itemId;
  final int setNumber;
  final double weight;
  final int reps;
  const WatchLogSetAction({
    required this.itemId,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });
}

class WatchSelectExerciseAction extends WatchIncomingAction {
  final String itemId;
  const WatchSelectExerciseAction({required this.itemId});
}

class WatchSkipExerciseAction extends WatchIncomingAction {
  final String itemId;
  const WatchSkipExerciseAction({required this.itemId});
}

class WatchRestControlAction extends WatchIncomingAction {
  final String operation; // "EXTEND", "SKIP", "TOGGLE_PAUSE"
  const WatchRestControlAction({required this.operation});
}

class WatchBiometricUpdateAction extends WatchIncomingAction {
  final WatchBiometrics biometrics;
  const WatchBiometricUpdateAction({required this.biometrics});
}

class WatchFinishWorkoutAction extends WatchIncomingAction {
  const WatchFinishWorkoutAction();
}

