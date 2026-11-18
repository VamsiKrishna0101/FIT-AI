import SwiftUI

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    // Default to ExerciseDetailView. Debug simulator runs can pick a page with
    // `-SetcraftDemoTab 0|2` and open the list with `-SetcraftDemoList YES`.
    @State private var selectedTab: Int = {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "SetcraftDemoTab") != nil {
            return UserDefaults.standard.integer(forKey: "SetcraftDemoTab")
        }
        #endif
        return 1
    }()
    @State private var showExerciseList: Bool = {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "SetcraftDemoList")
        #else
        return false
        #endif
    }()
    
    var body: some View {
        Group {
            if let snapshot = workoutManager.snapshot, !snapshot.items.isEmpty {
                // Check if rest is active
                if let rest = workoutManager.rest, rest.isActive {
                    RestTimerView(rest: rest)
                } else {
                    TabView(selection: $selectedTab) {
                        ControlsView()
                            .tag(0)
                        
                        ExerciseDetailView(onOpenList: { showExerciseList = true })
                            .tag(1)
                        
                        MetricsView()
                            .tag(2)
                    }
                    .tabViewStyle(.page)
                    .sheet(isPresented: $showExerciseList) {
                        ExerciseListView(items: snapshot.items, activeIndex: workoutManager.activeItemIndex) { itemId in
                            showExerciseList = false
                            workoutManager.selectExercise(itemId: itemId)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.69))
                    Text("No Active Workout")
                        .font(.headline)
                    Text("Start a workout on your iPhone to mirror here.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}

