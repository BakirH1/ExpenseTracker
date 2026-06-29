//
//  ChartModels.swift
//  ExpenseTracker
//
//  Lightweight value types fed into the Charts framework. Shared by the
//  dashboard summary card and the analytics screen so both compute spend the
//  same way.
//

import Foundation

/// One bar in a bar/sparkline chart. `value` is always in KM.
struct PeriodBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

/// One slice of the category donut. `total` is always in KM.
struct CategorySlice: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let total: Double
}

/// One point on a line chart (daily spend over a month). `value` in KM.
struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Spend-aggregation helpers shared across views.
enum SpendAggregator {
    /// Total KM across a set of expenses.
    static func total(_ expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// 24 hourly buckets (00–23) for the given day's expenses.
    static func hourlyBars(_ expenses: [Expense], calendar: Calendar = .expenseWeek) -> [PeriodBar] {
        var totals = Array(repeating: 0.0, count: 24)
        for expense in expenses {
            let hour = calendar.component(.hour, from: expense.date)
            totals[hour] += expense.amount
        }
        return totals.enumerated().map { PeriodBar(label: String($0.offset), value: $0.element) }
    }

    /// 7 weekday buckets Mon→Sun for the week containing `reference`.
    static func weekdayBars(_ expenses: [Expense], reference: Date = Date(), calendar: Calendar = .expenseWeek) -> [PeriodBar] {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let startOfWeek = calendar.startOfWeek(for: reference)
        var totals = Array(repeating: 0.0, count: 7)
        for expense in expenses {
            let days = calendar.dateComponents([.day], from: startOfWeek, to: expense.date).day ?? 0
            if days >= 0 && days < 7 {
                totals[days] += expense.amount
            }
        }
        return zip(labels, totals).map { PeriodBar(label: $0.0, value: $0.1) }
    }

    /// Category slices, sorted by spend descending, excluding empty categories.
    static func categorySlices(_ expenses: [Expense]) -> [CategorySlice] {
        var totals: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            totals[expense.categoryValue, default: 0] += expense.amount
        }
        return totals
            .map { CategorySlice(category: $0.key, total: $0.value) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    /// Daily totals for every day of the month containing `reference`.
    static func dailyPoints(_ expenses: [Expense], reference: Date = Date(), calendar: Calendar = .expenseWeek) -> [DailyPoint] {
        let startOfMonth = calendar.startOfMonth(for: reference)
        let dayCount = calendar.daysInMonth(for: reference)
        var totals = Array(repeating: 0.0, count: dayCount)
        for expense in expenses {
            let index = calendar.dateComponents([.day], from: startOfMonth, to: expense.date).day ?? -1
            if index >= 0 && index < dayCount {
                totals[index] += expense.amount
            }
        }
        return totals.enumerated().compactMap { offset, value in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth) else { return nil }
            return DailyPoint(date: date, value: value)
        }
    }
}
