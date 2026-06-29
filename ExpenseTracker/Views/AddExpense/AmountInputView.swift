//
//  AmountInputView.swift
//  ExpenseTracker
//
//  A large amount display with a custom numeric keypad and a KM/EUR toggle.
//  The entered value lives in `amountString`; the live conversion to the other
//  currency is shown underneath so the user always sees both.
//
//  Test case #2: enter 10.00 with EUR selected → the conversion line reads
//  "≈ 19.56 KM", and AddExpenseView stores 19.56 KM.
//

import SwiftUI

struct AmountInputView: View {
    @Binding var amountString: String
    @Binding var currency: Currency

    private let keys: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]

    private var amount: Double { Double(amountString) ?? 0 }

    var body: some View {
        VStack(spacing: 16) {
            // Live amount in the selected input currency.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(amountString.isEmpty ? "0" : amountString)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.kmPrimary)
                    .contentTransition(.numericText())
                Text(currency.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Conversion preview into the opposite currency.
            Text(conversionPreview)
                .font(.callout)
                .foregroundStyle(.secondary)

            CurrencyToggleView(currency: $currency)
                .frame(maxWidth: 240)

            keypad
        }
    }

    // MARK: - Keypad

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(keys, id: \.self) { key in
                Button {
                    handleTap(key)
                } label: {
                    Text(key)
                        .font(.title2.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Conversion text

    private var conversionPreview: String {
        switch currency {
        case .km:
            return "≈ \(CurrencyManager.formatEUR(fromKM: amount))"
        case .eur:
            let km = ExchangeRateService.eurToKM(amount)
            return "≈ \(CurrencyManager.formatKM(km))"
        }
    }

    // MARK: - Input handling

    private func handleTap(_ key: String) {
        switch key {
        case "⌫":
            if !amountString.isEmpty { amountString.removeLast() }
        case ".":
            if amountString.isEmpty {
                amountString = "0."
            } else if !amountString.contains(".") {
                amountString.append(".")
            }
        default: // a digit
            guard amountString.count < 10 else { return }
            // Limit to two decimal places.
            if let dotIndex = amountString.firstIndex(of: ".") {
                let decimals = amountString.distance(from: dotIndex, to: amountString.endIndex) - 1
                if decimals >= 2 { return }
            }
            // Avoid a leading zero like "05".
            if amountString == "0" {
                amountString = key == "0" ? "0" : key
            } else {
                amountString.append(key)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amountString = "10.00"
        @State private var currency: Currency = .eur
        var body: some View {
            AmountInputView(amountString: $amountString, currency: $currency)
                .padding()
        }
    }
    return PreviewWrapper()
}
