import Foundation
import SwiftUI
import Combine

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case fullBody = "Full Body"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "burst.fill"
        case .back: return "triangle.fill"
        case .legs: return "figure.run.circle.fill"
        case .shoulders: return "circle.grid.2x2.fill"
        case .arms: return "flame.fill"
        case .core: return "circle.hexagonpath.fill"
        case .fullBody: return "bolt.heart.fill"
        }
    }
}

struct WorkoutSet: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var weight: Double
    var reps: Int
}

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var muscleGroup: MuscleGroup
    var history: [WorkoutSet]

    var latestSet: WorkoutSet? {
        history.sorted { $0.date > $1.date }.first
    }
}

struct WorkoutExercise: Identifiable, Hashable {
    let id = UUID()
    var exercise: Exercise
    var sets: [WorkoutSet]
}

struct LoggedWorkout: Identifiable, Hashable {
    let id = UUID()
    var startedAt: Date
    var endedAt: Date
    var exercises: [WorkoutExercise]

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

struct ActiveWorkout: Identifiable {
    let id = UUID()
    var startedAt: Date = Date()
    var exercises: [WorkoutExercise] = []
}

final class WorkoutStore: ObservableObject {
    @Published var exercises: [Exercise]
    @Published var activeWorkout: ActiveWorkout?
    @Published var history: [LoggedWorkout]

    init(exercises: [Exercise] = [], history: [LoggedWorkout] = []) {
        self.exercises = exercises
        self.history = history
    }

    func startWorkout() {
        activeWorkout = ActiveWorkout()
    }

    func endWorkout() {
        if let active = activeWorkout, !active.exercises.isEmpty {
            let finished = LoggedWorkout(startedAt: active.startedAt, endedAt: Date(), exercises: active.exercises)
            history.insert(finished, at: 0)
        }
        activeWorkout = nil
    }

    func addExerciseToWorkout(_ exercise: Exercise) {
        guard var active = activeWorkout else {
            startWorkout()
            addExerciseToWorkout(exercise)
            return
        }

        if active.exercises.contains(where: { $0.exercise.id == exercise.id }) {
            activeWorkout = active
            return
        }

        active.exercises.append(WorkoutExercise(exercise: exercise, sets: []))
        activeWorkout = active
    }

    func addNewExercise(name: String, muscleGroup: MuscleGroup) -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: muscleGroup, history: [])
        exercises.append(exercise)
        return exercise
    }

    func addSet(to workoutExerciseID: UUID, weight: Double, reps: Int) {
        guard var active = activeWorkout else { return }
        guard let index = active.exercises.firstIndex(where: { $0.id == workoutExerciseID }) else { return }

        let set = WorkoutSet(date: Date(), weight: weight, reps: reps)
        active.exercises[index].sets.append(set)
        activeWorkout = active

        // Store history for progress/exercises screens
        if let exerciseIndex = exercises.firstIndex(where: { $0.id == active.exercises[index].exercise.id }) {
            exercises[exerciseIndex].history.append(set)
            active.exercises[index].exercise = exercises[exerciseIndex]
            activeWorkout = active
        }
    }

    func latestWeight(for exercise: Exercise) -> Double? {
        exercise.latestSet?.weight
    }
}

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.04, blue: 0.1),
            Color(red: 0.05, green: 0.07, blue: 0.15),
            Color(red: 0.06, green: 0.08, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.35, green: 0.9, blue: 0.75)
    static let secondary = Color(red: 0.56, green: 0.6, blue: 0.97)
    static let card = Color(red: 0.12, green: 0.15, blue: 0.25)

    static let glow = Color(red: 0.4, green: 0.9, blue: 0.8).opacity(0.28)
    static let faint = Color.white.opacity(0.25)
}

extension WorkoutStore {
    static func sampleExercises() -> [Exercise] {
        []
    }

    static func sampleWorkouts(from exercises: [Exercise]) -> [LoggedWorkout] {
        []
    }
}
