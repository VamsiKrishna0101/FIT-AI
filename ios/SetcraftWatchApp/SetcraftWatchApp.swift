import SwiftUI

@main
struct SetcraftWatchApp: App {
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

