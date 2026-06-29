//
//  Period.swift
//  ExpenseTracker
//
//  The time window the dashboard is currently showing. Centralizes all the
//  date-range math so Dashboard and Analytics agree on what "this week" means.
//

import Foundation

enum Period: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        }
    }

    /// SF Symbol used in empty states for this period.
    var emptyStateSymbol: String {
        switch self {
        case .day:   return "sun.max"
        case .week:  return "calendar"
        case .month: return "calendar.badge.clock"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .day:   return "No expenses recorded today"
        case .week:  return "No expenses recorded this week"
        case .month: return "No expenses recorded this month"
        }
    }

    /// Returns true if `date` falls inside this period relative to `now`.
    func contains(_ date: Date, now: Date = Date(), calendar: Calendar = .expenseWeek) -> Bool {
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
    }
}
