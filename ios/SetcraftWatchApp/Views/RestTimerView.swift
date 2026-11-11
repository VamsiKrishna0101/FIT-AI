import SwiftUI
import WatchKit

struct RestTimerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    let rest: WatchRestPayload
    
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?
    
    private var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private var progress: Double {
        guard rest.duration > 0 else { return 0 }
        return Double(remainingSeconds) / Double(rest.duration)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("REST INTERVAL")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            
            // Circular Countdown Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color(red: 0.35, green: 0.78, blue: 0.98), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                Text(formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .frame(width: 85, height: 85)
            
            // Rest Controls: +30s and Skip
            HStack(spacing: 8) {
                Button(action: {
                    workoutManager.controlRest(operation: "EXTEND")
                }) {
                    Text("+30s")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    workoutManager.controlRest(operation: "SKIP")
                }) {
                    Text("Skip")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(red: 0.4, green: 0.85, blue: 0.69))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            refreshRemaining()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let previous = remainingSeconds
                refreshRemaining()
                guard workoutManager.hapticRestAlerts, remainingSeconds != previous else { return }
                if remainingSeconds <= 3 && remainingSeconds > 0 {
                    WKInterfaceDevice.current().play(.click)
                } else if remainingSeconds == 0 && previous > 0 {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
        }
        .onChange(of: rest.endTimeEpochMs) { _ in refreshRemaining() }
        .onChange(of: rest.isPaused) { _ in refreshRemaining() }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func refreshRemaining() {
        if rest.isPaused {
            remainingSeconds = max(0, rest.remainingSeconds)
            return
        }
        let now = Int(Date().timeIntervalSince1970 * 1000)
        remainingSeconds = max(0, Int((Double(rest.endTimeEpochMs - now) / 1000).rounded(.up)))
    }
}
