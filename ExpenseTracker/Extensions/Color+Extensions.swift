//
//  Color+Extensions.swift
//  ExpenseTracker
//
//  Centralized color system. Every color here is either a semantic system
//  color (auto-adapts to light/dark mode) or derived from a hex value via the
//  initializer below. No view should hardcode an RGB literal — pull from here.
//

import SwiftUI

extension Color {
    // MARK: - Semantic app colors

    /// Tint used for KM (BAM) amounts — the primary storage currency.
    static let kmPrimary = Color.blue
    /// Muted tone used for the secondary EUR display.
    static let eurSecondary = Color.secondary
    /// Positive / income indicator.
    static let incomeGreen = Color.green
    /// Accent used for expense emphasis.
    static let expenseBlue = Color(hex: "5EB5FF")
    /// Amber used to flag low-confidence scan fields.
    static let warningAmber = Color.orange

    // MARK: - Hex initializer

    /// Creates a `Color` from a hex string such as `"5EB5FF"` or `"#5EB5FF"`.
    /// Supports 6-digit (RGB) and 8-digit (ARGB) values. Falls back to clear
    /// for malformed input so a typo can never crash the UI.
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (value >> 24 & 0xFF, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (0, 0, 0, 0) // clear — malformed input
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
