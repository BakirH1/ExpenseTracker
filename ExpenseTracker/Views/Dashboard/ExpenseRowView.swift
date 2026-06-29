//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  A single expense list item: category glyph, name + place/time, and the
//  amount shown in KM (primary) with the EUR equivalent muted underneath.
//
//  Test case #7: every row renders KM primary + EUR secondary — see the
//  trailing VStack below.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private var category: ExpenseCategory { expense.categoryValue }

    var body: some View {
        HStack(spacing: 14) {
            // Category glyph in a tinted circle.
            Image(systemName: category.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(category.color.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                // Primary: KM amount.
                Text(CurrencyManager.formatKM(expense.amount))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.kmPrimary)

                // Secondary: EUR equivalent, muted.
                Text(CurrencyManager.formatEUR(fromKM: expense.amount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// "Place · 14:32" when a place exists, otherwise just the time.
    private var subtitle: String {
        let time = expense.date.formatted(date: .omitted, time: .shortened)
        if let place = expense.place, !place.isEmpty {
            return "\(place) · \(time)"
        }
        return time
    }
}

#Preview {
    List {
        ExpenseRowView(expense: Expense(name: "Konzum", amount: 42.80, category: .food, place: "Sarajevo"))
        ExpenseRowView(expense: Expense(name: "Petrol", amount: 80.00, category: .transport, place: "Ilidža"))
        ExpenseRowView(expense: Expense(name: "Kino", amount: 15.50, category: .entertainment))
    }
}
