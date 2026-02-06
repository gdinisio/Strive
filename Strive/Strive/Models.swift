<<<<<<< HEAD
=======
//
//  Models.swift
//  Strive
//
//  Created by Giovanni Di Nisio on 07/12/2025.
//

>>>>>>> d32ae75 (version 2)
import Foundation
import SwiftUI
import Combine

<<<<<<< HEAD
enum MuscleGroup: String, CaseIterable, Identifiable {
=======
enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
>>>>>>> d32ae75 (version 2)
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case fullBody = "Full Body"

    var id: String { rawValue }
<<<<<<< HEAD

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
=======
}

struct WorkoutSet: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
>>>>>>> d32ae75 (version 2)
    var date: Date
    var weight: Double
    var reps: Int
}

<<<<<<< HEAD
struct Exercise: Identifiable, Hashable {
    let id = UUID()
=======
struct Exercise: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
>>>>>>> d32ae75 (version 2)
    var name: String
    var muscleGroup: MuscleGroup
    var history: [WorkoutSet]

    var latestSet: WorkoutSet? {
        history.sorted { $0.date > $1.date }.first
    }
}

<<<<<<< HEAD
struct WorkoutExercise: Identifiable, Hashable {
    let id = UUID()
=======
struct WorkoutExercise: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
>>>>>>> d32ae75 (version 2)
    var exercise: Exercise
    var sets: [WorkoutSet]
}

<<<<<<< HEAD
struct LoggedWorkout: Identifiable, Hashable {
    let id = UUID()
=======
struct LoggedWorkout: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
>>>>>>> d32ae75 (version 2)
    var startedAt: Date
    var endedAt: Date
    var exercises: [WorkoutExercise]

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

<<<<<<< HEAD
struct ActiveWorkout: Identifiable {
    let id = UUID()
=======
struct ActiveWorkout: Identifiable, Codable {
    var id: UUID = UUID()
>>>>>>> d32ae75 (version 2)
    var startedAt: Date = Date()
    var exercises: [WorkoutExercise] = []
}

final class WorkoutStore: ObservableObject {
    @Published var exercises: [Exercise]
    @Published var activeWorkout: ActiveWorkout?
    @Published var history: [LoggedWorkout]
<<<<<<< HEAD

    init(exercises: [Exercise] = [], history: [LoggedWorkout] = []) {
        self.exercises = exercises
        self.history = history
=======
    private var cancellables: Set<AnyCancellable> = []
    private let persistenceURL: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("workoutStore.json")
    }()

    init(exercises: [Exercise] = [], history: [LoggedWorkout] = []) {
        if let persisted = Self.loadPersisted(url: Self.defaultURL) {
            self.exercises = persisted.exercises
            self.history = persisted.history
            self.activeWorkout = persisted.activeWorkout
        } else {
            self.exercises = exercises
            self.history = history
            self.activeWorkout = nil
        }
        setupPersistence()
>>>>>>> d32ae75 (version 2)
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

<<<<<<< HEAD
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
=======
    func deleteSet(workoutExerciseID: UUID, setID: UUID) {
        guard var active = activeWorkout else { return }
        guard let exerciseIndex = active.exercises.firstIndex(where: { $0.id == workoutExerciseID }) else { return }
        active.exercises[exerciseIndex].sets.removeAll { $0.id == setID }
        activeWorkout = active
    }

    func removeExerciseFromActive(id: UUID) {
        guard var active = activeWorkout else { return }
        active.exercises.removeAll { $0.id == id }
        if active.exercises.isEmpty {
            activeWorkout = nil
        } else {
            activeWorkout = active
        }
    }

    func deleteLoggedWorkout(id: UUID) {
        history.removeAll { $0.id == id }
    }

    func deleteExerciseFromLogged(workoutID: UUID, exerciseID: UUID) {
        guard let index = history.firstIndex(where: { $0.id == workoutID }) else { return }
        history[index].exercises.removeAll { $0.id == exerciseID }
    }

    func deleteExercise(_ exerciseID: UUID) {
        exercises.removeAll { $0.id == exerciseID }
    }

    func latestWeight(for exercise: Exercise) -> Double? {
        exercise.latestSet?.weight
    }

    private func setupPersistence() {
        Publishers.CombineLatest3($exercises, $history, $activeWorkout)
            .dropFirst()
            .sink { [weak self] exercises, history, active in
                self?.persist(exercises: exercises, history: history, active: active)
            }
            .store(in: &cancellables)
    }

    private func persist(exercises: [Exercise], history: [LoggedWorkout], active: ActiveWorkout?) {
        let payload = PersistedState(exercises: exercises, history: history, activeWorkout: active)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Persistence error: \(error)")
        }
    }

    private static var defaultURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("workoutStore.json")
    }

    private static func loadPersisted(url: URL) -> PersistedState? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(PersistedState.self, from: data)
        } catch {
            return nil
        }
    }
}

private struct PersistedState: Codable {
    var exercises: [Exercise]
    var history: [LoggedWorkout]
    var activeWorkout: ActiveWorkout?
}

enum AppTheme {
    static func background(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.1),
                    Color(red: 0.15, green: 0.15, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static let accent = Color(red: 0.18, green: 0.58, blue: 0.98)
    static let secondary = Color(red: 0.12, green: 0.7, blue: 0.75)
    static let card = Color(.secondarySystemBackground)
    static let glow = Color.black.opacity(0.08)
    static let faint = Color(.secondaryLabel)
>>>>>>> d32ae75 (version 2)
}

extension WorkoutStore {
    static func sampleExercises() -> [Exercise] {
        []
    }

    static func sampleWorkouts(from exercises: [Exercise]) -> [LoggedWorkout] {
        []
    }
}
