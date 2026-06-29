//
//  Calendar+Helpers.swift
//  ExpenseTracker
//
//  A shared calendar whose week starts on Monday (Mon–Sun), matching the
//  regional convention in Bosnia & Herzegovina, plus small date helpers used
//  by the dashboard sparkline and the analytics charts.
//

import Foundation

extension Calendar {
    /// Calendar configured so weeks run Monday → Sunday.
    static var expenseWeek: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // 1 = Sunday, 2 = Monday
        return calendar
    }

    /// The Monday 00:00 that begins the week containing `date`.
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }

    /// The 1st of the month at 00:00 for the month containing `date`.
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }

    /// Number of days in the month containing `date`.
    func daysInMonth(for date: Date) -> Int {
        range(of: .day, in: .month, for: date)?.count ?? 30
    }
}
