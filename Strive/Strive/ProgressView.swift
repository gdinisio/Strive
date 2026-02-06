//
//  ProgressView.swift
//  Strive
//
//  Created by Giovanni Di Nisio on 07/12/2025.
//

import SwiftUI
import Charts

struct ProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedExerciseID: Exercise.ID?

    private var selectedExercise: Exercise? {
        if let id = selectedExerciseID {
            return store.exercises.first { $0.id == id }
        }
        return store.exercises.first
    }

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.largeTitle).fontWeight(.black)
                            .fontDesign(.rounded)
                        Spacer()
                        Menu {
                            ForEach(store.exercises) { exercise in
                                Button(exercise.name) {
                                    selectedExerciseID = exercise.id
                                }
                            }
                        } label: {
                            Label(selectedExercise?.name ?? "Pick exercise", systemImage: "line.3.horizontal.decrease")
                        }
                        .tint(AppTheme.accent)
                    }
                    .padding(.horizontal, 16)
                    Text("Track weight across time for each movement.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)
                    Divider()
                    if let exercise = selectedExercise, !exercise.history.isEmpty {
                        ProgressChart(exercise: exercise)
                        ProgressStats(exercise: exercise)
                    } else {
                        Card {
                            VStack(spacing: 8) {
                                Text("No data yet")
                                    .font(.headline)
                                Text("Add sets in a workout to unlock progress.")
                                    .foregroundStyle(AppTheme.faint)
                                    .font(.callout)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ProgressChart: View {
    let exercise: Exercise

    var body: some View {
        let sorted = exercise.history.sorted { $0.date < $1.date }
        let volumeValues = sorted.map { $0.weight * Double($0.reps) }
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(exercise.name) Progress")
                    .font(.headline)
                HStack(spacing: 12) {
                    Label("Weight", systemImage: "scalemass.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.caption)
                    Label("Volume", systemImage: "figure.strengthtraining.traditional")
                        .foregroundStyle(AppTheme.secondary)
                        .font(.caption)
                }
                ZStack {
                    Chart {
                        ForEach(sorted) { set in
                            LineMark(
                                x: .value("Date", set.date),
                                y: .value("Weight", set.weight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.accent)
                            PointMark(
                                x: .value("Date", set.date),
                                y: .value("Weight", set.weight)
                            )
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }

                    Chart {
                        ForEach(Array(zip(sorted, volumeValues)), id: \.0.id) { item in
                            let set = item.0
                            let volume = item.1
                            LineMark(
                                x: .value("Date", set.date),
                                y: .value("Volume", volume)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.secondary)
                            PointMark(
                                x: .value("Date", set.date),
                                y: .value("Volume", volume)
                            )
                            .foregroundStyle(AppTheme.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis(.hidden)
                }
                .frame(height: 240)
            }
        }
    }
}

struct ProgressStats: View {
    let exercise: Exercise

    var body: some View {
        let history = exercise.history.sorted { $0.date < $1.date }
        let best = history.max(by: { $0.weight < $1.weight })

        HStack() {
            StatTile(title: "Best", value: best.map { String(format: "%.1f kg", $0.weight) } ?? "--")
            StatTile(title: "Sessions", value: "\(history.count)")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }
}
