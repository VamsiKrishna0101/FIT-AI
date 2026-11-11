import Foundation

struct WatchWorkoutSnapshot: Codable {
    let type: String?
    let sessionId: String
    let date: String
    let title: String
    let activeItemIndex: Int
    let items: [WatchExerciseItem]
    let rest: WatchRestPayload?
    let hapticRestAlerts: Bool?
    let heartRateEnabled: Bool?
}

struct WatchExerciseItem: Codable, Identifiable {
    let id: String
    let exerciseName: String
    let orderIndex: Int
    let targetSets: Int
    let targetReps: String
    let targetWeight: Double
    let restSeconds: Int
    let status: String
    let loggedSets: [WatchSetLog]
    
    var isCompleted: Bool { status == "COMPLETED" }
    var isSkipped: Bool { status == "SKIPPED" }
    var isPending: Bool { !isCompleted && !isSkipped }
}

struct WatchSetLog: Codable, Identifiable {
    var id: Int { setNumber }
    let setNumber: Int
    let weight: Double
    let reps: Int
    let completed: Bool
    let rpe: Double?
}

struct WatchRestPayload: Codable {
    let isActive: Bool
    let exerciseName: String
    let setNumber: Int
    let remainingSeconds: Int
    let duration: Int
    let isPaused: Bool
    let endTimeEpochMs: Int
}

