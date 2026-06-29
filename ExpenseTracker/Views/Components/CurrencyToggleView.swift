//
//  CurrencyToggleView.swift
//  ExpenseTracker
//
//  A small segmented KM <-> EUR switch. Used both for choosing the input
//  currency when adding an expense and for switching the analytics display.
//

import SwiftUI

struct CurrencyToggleView: View {
    @Binding var currency: Currency

    var body: some View {
        Picker("Currency", selection: $currency) {
            ForEach(Currency.allCases) { currency in
                Text(currency.displayName).tag(currency)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var currency: Currency = .km
        var body: some View {
            CurrencyToggleView(currency: $currency)
                .padding()
        }
    }
    return PreviewWrapper()
}
