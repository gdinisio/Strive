//
//  StriveApp.swift
//  Strive
//
//  Created by Giovanni Di Nisio on 06/12/2025.
//

import SwiftUI

@main
struct StriveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WorkoutStore())
        }
    }
}
