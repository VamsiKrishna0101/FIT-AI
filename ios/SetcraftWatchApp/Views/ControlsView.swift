import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text(workoutManager.snapshot?.title ?? "Active Session")
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
            
            Button(action: {
                workoutManager.finishWorkout()
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text("End Workout")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 1.0, green: 0.32, blue: 0.32).opacity(0.85)) // Red
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            Text("Finishing will save this session to Apple Health and sync with Setcraft.")
                .font(.system(size: 8))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 6)
    }
}

