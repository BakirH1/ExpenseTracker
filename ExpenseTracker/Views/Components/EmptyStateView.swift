//
//  EmptyStateView.swift
//  ExpenseTracker
//
//  Illustrated empty state: a muted SF Symbol, a one-line prompt, and an
//  optional call-to-action. Shown when a period has no expenses.
//

import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    EmptyStateView(
        symbol: "sun.max",
        message: "No expenses recorded today",
        actionTitle: "Add your first one →",
        action: {}
    )
}
