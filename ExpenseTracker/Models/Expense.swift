//
//  Expense.swift
//  ExpenseTracker
//
//  The SwiftData model. One row per recorded expense.
//
//  IMPORTANT: `amount` is ALWAYS stored in KM (BAM), the app's canonical
//  currency. Any EUR the user types is converted to KM before it reaches this
//  model (see CurrencyManager.amountInKM). EUR is a display-only projection.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var name: String
    /// Always stored in KM (BAM).
    var amount: Double
    var date: Date
    /// Raw value of `ExpenseCategory`.
    var category: String
    var place: String?
    var notes: String?
    /// JPEG thumbnail captured from a scanned receipt, if any.
    var receiptImageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        date: Date = Date(),
        category: ExpenseCategory = .other,
        place: String? = nil,
        notes: String? = nil,
        receiptImageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.category = category.rawValue
        self.place = place
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.createdAt = createdAt
    }

    /// The stored KM amount expressed in euros, using the fixed peg.
    var amountEUR: Double {
        amount / ExchangeRateService.bamPerEur
    }

    /// Strongly-typed view of the stored raw category string.
    var categoryValue: ExpenseCategory {
        ExpenseCategory(rawValue: category) ?? .other
    }
}
