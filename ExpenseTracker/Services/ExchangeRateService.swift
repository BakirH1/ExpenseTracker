//
//  ExchangeRateService.swift
//  ExpenseTracker
//
//  The single source of truth for BAM (KM) <-> EUR conversion.
//
//  The Bosnia & Herzegovina convertible mark is pegged to the euro by law via
//  the country's currency board. The rate is fixed and does not float:
//
//      1 EUR = 1.95583 KM   (and therefore 1 KM = 0.51129... EUR)
//
//  Because the peg is fixed, there is no network call here — the conversion is
//  deterministic and offline. This service exists so the constant lives in
//  exactly one place.
//

import Foundation

enum ExchangeRateService {
    /// Official, legally fixed peg: how many KM (BAM) one euro is worth.
    static let bamPerEur: Double = 1.95583

    /// Convert an amount expressed in euros into KM (the storage currency).
    static func eurToKM(_ eur: Double) -> Double {
        eur * bamPerEur
    }

    /// Convert an amount expressed in KM into euros (for display only).
    static func kmToEUR(_ km: Double) -> Double {
        km / bamPerEur
    }
}
