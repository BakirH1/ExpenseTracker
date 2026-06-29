//
//  ExpenseCategory.swift
//  ExpenseTracker
//
//  The fixed set of expense categories. Each case carries its own SF Symbol
//  and semantic color so the UI never has to switch on the raw value.
//

import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food
    case transport
    case utilities
    case health
    case dining
    case shopping
    case entertainment
    case education
    case travel
    case other

    var id: String { rawValue }

    /// Human-readable label shown in pickers and chips.
    var displayName: String {
        switch self {
        case .food:          return "Groceries"
        case .transport:     return "Transport"
        case .utilities:     return "Utilities"
        case .health:        return "Health"
        case .dining:        return "Dining"
        case .shopping:      return "Shopping"
        case .entertainment: return "Entertainment"
        case .education:     return "Education"
        case .travel:        return "Travel"
        case .other:         return "Other"
        }
    }

    /// SF Symbol used everywhere the category is shown.
    var iconName: String {
        switch self {
        case .food:          return "cart.fill"
        case .transport:     return "car.fill"
        case .utilities:     return "bolt.fill"
        case .health:        return "heart.fill"
        case .dining:        return "fork.knife"
        case .shopping:      return "bag.fill"
        case .entertainment: return "tv.fill"
        case .education:     return "book.fill"
        case .travel:        return "airplane"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    /// Semantic system color — adapts automatically to light/dark mode.
    var color: Color {
        switch self {
        case .food:          return .green
        case .transport:     return .orange
        case .utilities:     return .yellow
        case .health:        return .red
        case .dining:        return .pink
        case .shopping:      return .purple
        case .entertainment: return .blue
        case .education:     return .teal
        case .travel:        return .cyan
        case .other:         return .gray
        }
    }
}
