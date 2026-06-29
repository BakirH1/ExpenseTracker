//
//  CurrencyManager.swift
//  ExpenseTracker
//
//  High-level currency helpers used by the UI: the `Currency` the user can
//  type in, conversion into the KM storage value, and consistent formatting
//  for both KM and EUR. Conversion math is delegated to `ExchangeRateService`
//  so the peg constant lives in one place only.
//

import Foundation

/// The currencies the user can enter an amount in. Storage is always KM.
enum Currency: String, CaseIterable, Identifiable, Codable {
    case km = "KM"
    case eur = "EUR"

    var id: String { rawValue }

    /// Short symbol shown next to amounts.
    var symbol: String {
        switch self {
        case .km:  return "KM"
        case .eur: return "€"
        }
    }

    var displayName: String {
        switch self {
        case .km:  return "KM"
        case .eur: return "EUR"
        }
    }
}

enum CurrencyManager {
    /// Convert a user-entered amount (in `currency`) into the KM value we store.
    static func amountInKM(_ amount: Double, from currency: Currency) -> Double {
        switch currency {
        case .km:  return amount
        case .eur: return ExchangeRateService.eurToKM(amount)
        }
    }

    /// Take a stored KM value and express it in the requested display currency.
    static func value(fromKM km: Double, in currency: Currency) -> Double {
        switch currency {
        case .km:  return km
        case .eur: return ExchangeRateService.kmToEUR(km)
        }
    }

    // MARK: - Formatting

    /// Formats a raw number with two decimals and grouped thousands, e.g. 1.234,56 style
    /// handled by the locale-aware formatter, then suffixes the currency symbol.
    static func format(_ value: Double, in currency: Currency) -> String {
        let number = numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        switch currency {
        case .km:  return "\(number) KM"
        case .eur: return "€\(number)"
        }
    }

    /// Convenience: format a stored KM amount directly as "X KM".
    static func formatKM(_ km: Double) -> String {
        format(km, in: .km)
    }

    /// Convenience: format a stored KM amount as its EUR equivalent, e.g. "€21.94".
    static func formatEUR(fromKM km: Double) -> String {
        format(ExchangeRateService.kmToEUR(km), in: .eur)
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()
}
