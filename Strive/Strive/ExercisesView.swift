//
//  ExercisesView.swift
//  Strive
//
//  Created by Giovanni Di Nisio on 08/12/2025.
//

import SwiftUI

struct ExercisesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: WorkoutStore

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases
            .map { group in (group, store.exercises.filter { $0.muscleGroup == group }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Exercises")
                        .font(.largeTitle).fontWeight(.black)
                        .fontDesign(.rounded)
                        .padding(.horizontal, 16)
                    Text("Sorted by muscle group.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    
                    Divider()
                    
                    ForEach(groupedExercises, id: \.0) { group, exercises in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.rawValue)
                                .font(.headline)
                                .padding(.top, 8)
                                .padding(.leading, 16)
                            LazyVStack(spacing: 10) {
                                ForEach(exercises) { exercise in
                                    ExerciseRow(exercise: exercise) {
                                        store.deleteExercise(exercise.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    var onDelete: (() -> Void)?

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                    if let latest = exercise.latestSet {
                        Text("Last: \(String(format: "%.1f", latest.weight)) kg × \(latest.reps)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.faint)
                    } else {
                        Text("No history yet.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.faint)
                    }
                }
                Spacer()
                if let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.red)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
            }
        }
    }
}
