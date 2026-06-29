//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  App entry point. SwiftData is wired up with a single line — the model
//  container for `Expense` is created and injected into the environment, so
//  every view can use `@Query` and `@Environment(\.modelContext)` with zero
//  additional setup.
//

import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Expense.self)
    }
}
