import SwiftUI
import WatchKit
import HealthKit

/// Receives the launch request sent by the iPhone through
/// `HKHealthStore.startWatchApp(with:)` when a workout starts on the phone.
final class SetcraftWatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WorkoutManager.shared.startHealthKitWorkout()
    }
}

@main
struct SetcraftWatchApp: App {
    @WKApplicationDelegateAdaptor(SetcraftWatchAppDelegate.self) private var appDelegate
    @StateObject private var workoutManager = WorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SessionPagingView()
                    .environmentObject(workoutManager)
            }
        }
    }
}
