import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    private var zoneColor: Color {
        switch workoutManager.hrZone {
        case 1: return Color.gray
        case 2: return Color.blue
        case 3: return Color(red: 0.4, green: 0.85, blue: 0.69) // Accent Lime
        case 4: return Color.orange
        default: return Color(red: 1.0, green: 0.32, blue: 0.32) // Heat Red
        }
    }
    
    private var formattedElapsed: String {
        let mins = workoutManager.elapsedSeconds / 60
        let secs = workoutManager.elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Heart Rate Hero
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                            .foregroundColor(zoneColor)
                        Text("HEART RATE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(workoutManager.heartRate))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(zoneColor)
                        Text("BPM")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("ZONE \(workoutManager.hrZone)")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(zoneColor.opacity(0.2))
                            .foregroundColor(zoneColor)
                            .cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                
                // Active Calories
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE ENERGY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", workoutManager.activeCalories))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.72, blue: 0.3)) // Gold
                        Text("CAL")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                
                // Elapsed Time
                VStack(alignment: .leading, spacing: 2) {
                    Text("ELAPSED TIME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text(formattedElapsed)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
            }
            .padding(.horizontal, 4)
        }
    }
}

