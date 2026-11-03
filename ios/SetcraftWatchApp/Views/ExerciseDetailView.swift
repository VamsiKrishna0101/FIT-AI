import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var onOpenList: () -> Void
    
    @State private var crownRepsDelta: Double = 0
    @State private var crownWeightDelta: Double = 0
    @FocusState private var isRepsFocused: Bool
    
    private var currentExercise: WatchExerciseItem? {
        guard let items = workoutManager.snapshot?.items, !items.isEmpty else { return nil }
        let index = min(max(0, workoutManager.activeItemIndex), items.count - 1)
        return items[index]
    }
    
    private var nextSetNumber: Int {
        guard let item = currentExercise else { return 1 }
        let logged = Set(item.loggedSets.map { $0.setNumber })
        for i in 1...item.targetSets {
            if !logged.contains(i) { return i }
        }
        return item.targetSets + 1
    }
    
    private var effectiveWeight: Double {
        guard let item = currentExercise else { return 0.0 }
        return max(0.0, item.targetWeight + crownWeightDelta)
    }
    
    private var effectiveReps: Int {
        guard let item = currentExercise else { return 10 }
        let baseReps = Int(item.targetReps.components(separatedBy: CharacterSet.decimalDigits.inverted).first ?? "10") ?? 10
        return max(1, baseReps + Int(crownRepsDelta))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if let item = currentExercise {
                    // Header: Exercise Title & Switcher
                    Button(action: onOpenList) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(workoutManager.activeItemIndex + 1)/\(workoutManager.snapshot?.items.count ?? 1) \(item.exerciseName)")
                                    .font(.system(size: 14, weight: .bold))
                                    .lineLimit(1)
                                
                                Text("SET \(nextSetNumber) OF \(item.targetSets)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.69))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Steppers Row (Reps & Weight)
                    HStack(spacing: 6) {
                        // Reps
                        VStack(spacing: 2) {
                            Text("REPS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            HStack {
                                Button(action: { crownRepsDelta -= 1 }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(effectiveReps)")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(minWidth: 24)
                                
                                Button(action: { crownRepsDelta += 1 }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                        
                        // Weight
                        VStack(spacing: 2) {
                            Text("KG")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            HStack {
                                Button(action: { crownWeightDelta -= 2.5 }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                                
                                Text(String(format: effectiveWeight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", effectiveWeight))
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(minWidth: 28)
                                
                                Button(action: { crownWeightDelta += 2.5 }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                    }
                    
                    // Primary Action: LOG SET Button
                    Button(action: {
                        workoutManager.logSet(
                            itemId: item.id,
                            setNumber: nextSetNumber,
                            weight: effectiveWeight,
                            reps: effectiveReps
                        )
                        crownRepsDelta = 0
                        crownWeightDelta = 0
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("LOG SET \(nextSetNumber)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.4, green: 0.85, blue: 0.69))
                        .foregroundColor(.black)
                        .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    
                    // Skip exercise shortcut
                    HStack {
                        Spacer()
                        Button(action: { workoutManager.skipExercise(itemId: item.id) }) {
                            Text("Skip Exercise")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

