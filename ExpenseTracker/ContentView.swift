//
//  ContentView.swift
//  ExpenseTracker
//
//  Root tab container. Two tabs — the dashboard and analytics. On iOS 26 the
//  system automatically renders the tab bar with the Liquid Glass treatment;
//  on iOS 17–18 it falls back to the standard translucent tab bar. No special
//  code is needed for either.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
        }
        .tabViewStyle(.automatic)
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
