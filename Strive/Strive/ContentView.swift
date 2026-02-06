//
//  ContentView.swift
//  Strive
//
//  Created by Giovanni Di Nisio on 06/12/2025.
//

import SwiftUI
import Charts
import Combine

#Preview {
    ContentView()
        .environmentObject(WorkoutStore())
}

struct ContentView: View {
    @EnvironmentObject var store: WorkoutStore

    var body: some View {
        Background {
            TabView {
                ActivityView()
                    .tabItem {
                        Label("Workout", systemImage: "bolt.fill")
                    }
                ExercisesView()
                    .tabItem {
                        Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                    }
                ProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
            }
            .tint(AppTheme.accent)
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        Button {
        } label: {
            VStack(alignment: .center, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundStyle(AppTheme.faint)
                Text(value)
                    .font(.headline)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: 12))
    }
}

struct Background<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
        }
    }
}

struct Card<Content: View>: View {
    private let hPadding: CGFloat
    private let vPadding: CGFloat
    private let contentPadding: CGFloat
    private let cRadius: CGFloat
    private let content: () -> Content

    init(
        hPadding: CGFloat = 12,
        vPadding: CGFloat = 8,
        contentPadding: CGFloat = 20,
        cRadius: CGFloat = 18,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.contentPadding = contentPadding
        self.cRadius = cRadius
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cRadius, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2),
                        radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
    }
}
