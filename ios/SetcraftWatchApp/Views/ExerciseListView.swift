import SwiftUI

struct ExerciseListView: View {
    let items: [WatchExerciseItem]
    let activeIndex: Int
    let onSelect: (String) -> Void
    
    var body: some View {
        List {
            Section(header: Text("Today's Exercises").font(.caption2).foregroundColor(.gray)) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button(action: { onSelect(item.id) }) {
                        HStack(spacing: 8) {
                            if item.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.69))
                                    .font(.system(size: 14))
                            } else if index == activeIndex {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(Color(red: 0.35, green: 0.78, blue: 0.98))
                                    .font(.system(size: 14))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exerciseName)
                                    .font(.system(size: 12, weight: index == activeIndex ? .bold : .regular))
                                    .foregroundColor(item.isCompleted ? .gray : .white)
                                    .strikethrough(item.isCompleted)
                                    .lineLimit(1)
                                
                                Text("\(item.targetSets) sets · \(item.targetReps) reps")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(
                        index == activeIndex ? Color.white.opacity(0.1) : Color.clear
                    )
                }
            }
        }
    }
}

