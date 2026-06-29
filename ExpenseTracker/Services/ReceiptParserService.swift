//
//  ReceiptParserService.swift
//  ExpenseTracker
//
//  The receipt OCR pipeline — the app's headline feature.
//
//  Flow: a scanned UIImage is run through Vision's text recognizer
//  (`VNRecognizeTextRequest`, .accurate), then a set of heuristic extraction
//  passes pull out the total, date, merchant, place, and a guessed category.
//  The result is a `ParsedReceipt` with a 0–1 confidence so the UI can flag
//  uncertain fields for the user to correct.
//
//  Everything here is offline and first-party (Vision / VisionKit) — no
//  third-party dependencies and no network calls.
//

import Foundation
import Vision

#if canImport(UIKit)
import UIKit
#endif

/// The structured result of parsing a receipt. All fields are best-effort and
/// meant to be reviewed/edited by the user before saving.
struct ParsedReceipt {
    var amount: Double
    /// Currency the `amount` is expressed in (KM unless the receipt clearly
    /// shows euros). Conversion to the stored KM value happens at save time.
    var currency: Currency
    var name: String
    var date: Date
    var place: String?
    var category: ExpenseCategory
    /// Overall confidence 0–1. The UI shows an amber warning below 0.6.
    var confidence: Double
    /// Full recognized text, kept for debugging / the review screen.
    var recognizedText: String

    /// A representative example used by SwiftUI previews and test case #3.
    static var mock: ParsedReceipt {
        ParsedReceipt(
            amount: 42.80,
            currency: .km,
            name: "Konzum",
            date: Date(),
            place: "Sarajevo",
            category: .food,
            confidence: 0.82,
            recognizedText: "KONZUM\nSARAJEVO\n...\nUKUPNO 42,80 KM"
        )
    }

    /// A deliberately low-confidence example to exercise the amber warning UI.
    static var mockLowConfidence: ParsedReceipt {
        ParsedReceipt(
            amount: 12.50,
            currency: .km,
            name: "Receipt",
            date: Date(),
            place: nil,
            category: .other,
            confidence: 0.41,
            recognizedText: "....blurry...."
        )
    }
}

enum ReceiptParserError: Error {
    case invalidImage
}

enum ReceiptParserService {

    /// A single recognized line of text with its normalized position and the
    /// recognizer's own confidence in that line.
    private struct RecognizedLine {
        let text: String
        /// Vision bounding box: normalized 0–1, origin at the BOTTOM-LEFT, so a
        /// larger `midY` means higher up on the receipt.
        let boundingBox: CGRect
        let confidence: Double
    }

    // MARK: - Public entry point

#if canImport(UIKit)
    /// Parse a scanned receipt image into structured fields.
    static func parseReceipt(from image: UIImage) async throws -> ParsedReceipt {
        guard let cgImage = image.cgImage else { throw ReceiptParserError.invalidImage }
        let lines = try recognizeLines(in: cgImage)
        return parse(lines: lines)
    }

    /// Downscale a captured image to a small JPEG suitable for storing as a
    /// thumbnail alongside the expense.
    static func thumbnailData(from image: UIImage, maxDimension: CGFloat = 800) -> Data? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: 0.7)
    }
#endif

    // MARK: - Vision OCR

    private static func recognizeLines(in cgImage: CGImage) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        // Receipts are not prose; language correction hurts more than it helps.
        request.usesLanguageCorrection = false
        // Bosnian/Croatian/Serbian plus English fall back gracefully if a
        // given OS build lacks a specific language pack.
        request.recognitionLanguages = ["hr", "bs", "sr", "en"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request]) // synchronous; results populated on return

        let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedLine(
                text: candidate.string,
                boundingBox: observation.boundingBox,
                confidence: Double(candidate.confidence)
            )
        }
    }

    // MARK: - Extraction orchestration
    // Split out from the Vision call so it can be unit-tested / previewed with
    // synthetic lines and never needs a camera.

    private static func parse(lines: [RecognizedLine]) -> ParsedReceipt {
        let fullText = lines.map(\.text).joined(separator: "\n")
        let avgOCR = lines.isEmpty ? 0 : lines.map(\.confidence).reduce(0, +) / Double(lines.count)

        let (total, totalConfidence) = extractTotal(from: lines)
        let detectedCurrency = detectCurrency(in: fullText)
        let parsedDate = extractDate(from: fullText)
        let merchant = extractMerchant(from: lines)
        let place = extractPlace(from: lines)
        let category = inferCategory(merchant: merchant ?? "", fullText: fullText)

        // Blend signal strength into a single confidence number.
        var score = 0.0
        score += 0.5 * totalConfidence                 // having a believable total matters most
        score += parsedDate != nil ? 0.15 : 0
        score += merchant != nil ? 0.20 : 0
        score += 0.15 * avgOCR
        let confidence = min(1.0, max(0.0, score))

        return ParsedReceipt(
            amount: total,
            currency: detectedCurrency,
            name: merchant ?? "Receipt",
            date: parsedDate ?? Date(),
            place: place,
            category: category,
            confidence: confidence,
            recognizedText: fullText
        )
    }

    // MARK: - Total extraction

    private static let totalKeywords = [
        "UKUPNO", "SVEUKUPNO", "ZA PLATITI", "ZA PLACANJE", "ZA UPLATU",
        "ZA NAPLATU", "IZNOS", "TOTAL", "UKUPAN IZNOS", "ZBROJ"
    ]

    /// Returns the detected total and a confidence (0.9 when anchored on a
    /// total keyword, 0.4 when we had to fall back to the largest amount).
    private static func extractTotal(from lines: [RecognizedLine]) -> (Double, Double) {
        let folded = lines.map { fold($0.text) }
        var keywordCandidates: [Double] = []

        for (index, line) in folded.enumerated() where totalKeywords.contains(where: line.contains) {
            var numbers = moneyValues(in: lines[index].text)
            // Some printers put the keyword and the amount on separate lines.
            if numbers.isEmpty, index + 1 < lines.count {
                numbers = moneyValues(in: lines[index + 1].text)
            }
            keywordCandidates.append(contentsOf: numbers)
        }

        if let total = keywordCandidates.max() {
            return (total, 0.9)
        }

        // Fallback: the largest money-shaped value anywhere on the receipt.
        let all = lines.flatMap { moneyValues(in: $0.text) }
        if let total = all.max() {
            return (total, 0.4)
        }
        return (0, 0)
    }

    // MARK: - Currency / date / merchant / place

    private static func detectCurrency(in text: String) -> Currency {
        let folded = fold(text)
        let mentionsKM = folded.contains("KM") || folded.contains("BAM")
        let mentionsEUR = folded.contains("EUR") || text.contains("€")
        if mentionsEUR && !mentionsKM { return .eur }
        return .km // BiH receipts are KM by default
    }

    private static func extractDate(from text: String) -> Date? {
        let calendar = Calendar.expenseWeek

        // ISO first: yyyy-MM-dd
        if let match = firstMatch(in: text, pattern: #"\b(\d{4})-(\d{1,2})-(\d{1,2})\b"#),
           let year = Int(match[1]), let month = Int(match[2]), let day = Int(match[3]),
           let date = makeDate(year: year, month: month, day: day, calendar: calendar) {
            return date
        }

        // dd.MM.yyyy / dd/MM/yyyy / dd-MM-yyyy (day first, the local convention)
        if let match = firstMatch(in: text, pattern: #"\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b"#),
           let day = Int(match[1]), let month = Int(match[2]), var year = Int(match[3]) {
            if year < 100 { year += 2000 }
            if let date = makeDate(year: year, month: month, day: day, calendar: calendar) {
                return date
            }
        }
        return nil
    }

    private static func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day), (2000...2100).contains(year) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    /// Generic header words that are never a merchant name.
    private static let merchantBlocklist = [
        "RACUN", "FISKALNI", "BLAGAJNA", "RECEIPT", "FISCAL", "KOPIJA",
        "ORIGINAL", "PDV", "BROJ", "KASA", "ID KUPCA", "IB", "ZK", "ZKI"
    ]

    private static func extractMerchant(from lines: [RecognizedLine]) -> String? {
        // Top of the receipt = highest bounding boxes. Look at the top third.
        let sorted = lines.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        let topLines = Array(sorted.prefix(max(3, sorted.count / 3)))

        for line in topLines {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let folded = fold(text)
            guard text.count >= 3 else { continue }
            guard !merchantBlocklist.contains(where: folded.contains) else { continue }
            // Skip lines that are mostly digits (totals, IDs, dates).
            let digits = text.filter(\.isNumber).count
            guard Double(digits) / Double(text.count) < 0.4 else { continue }
            return cleaned(text)
        }
        return nil
    }

    private static let knownCities = [
        "SARAJEVO", "MOSTAR", "TUZLA", "ZENICA", "BANJA LUKA", "BIHAC",
        "BRCKO", "BIJELJINA", "PRIJEDOR", "DOBOJ", "CAZIN", "GORAZDE",
        "KONJIC", "TRAVNIK", "VISOKO", "GRADACAC", "SIROKI BRIJEG", "LIVNO",
        "TESANJ", "ZIVINICE", "GRACANICA", "ILIDZA", "VOGOSCA"
    ]

    private static func extractPlace(from lines: [RecognizedLine]) -> String? {
        for line in lines {
            let folded = fold(line.text)
            // A 5-digit postal code, a street marker, or a recognizable city.
            let hasPostal = firstMatch(in: line.text, pattern: #"\b\d{5}\b"#) != nil
            let hasStreet = folded.contains("ULICA") || folded.contains("UL.")
                || folded.contains(" BB") || folded.contains("TRG")
            let hasCity = knownCities.contains { folded.contains($0) }
            if hasCity || hasPostal || hasStreet {
                return cleaned(line.text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return nil
    }

    // MARK: - Category inference

    /// Ordered keyword → category rules. First hit wins. Health is checked
    /// before transport so drugstores ("dm") map to health, not fuel.
    private static let categoryRules: [(keywords: [String], category: ExpenseCategory)] = [
        (["LJEKARNA", "APOTEKA", "PHARMACY", "DM ", "BIPA", "MEDICAL"], .health),
        (["KONZUM", "BINGO", "RODA", "MERCATOR", "AMKO", "INTEREX", "TUS",
          "MARKET", "SUPER", "FIS", "ROBOT", "HOSE"], .food),
        (["PETROL", "HELL", "INA", "ENERGOPETROL", "BENZIN", "SHELL", "OMV",
          "NIS", "GAS"], .transport),
        (["RESTORAN", "CAFFE", "KAFIC", "PIZZ", "BUREG", "CEVAB", "FAST FOOD",
          "GRILL", "BISTRO"], .dining),
        (["CINEMA", "KINO", "CINEPLEXX", "THEATRE", "KAZALISTE", "POZORISTE"], .entertainment),
        (["ELEKTRO", "VODOVOD", "TOPLANE", "TELECOM", "TELEKOM", "M:TEL",
          "TELEMACH", "GRIJANJE"], .utilities),
        (["ZARA", "H&M", "CCC", "DEICHMANN", "FASHION", "SHOPPING", "BUTIK"], .shopping),
    ]

    private static func inferCategory(merchant: String, fullText: String) -> ExpenseCategory {
        let haystack = fold(merchant + " " + fullText)
        for rule in categoryRules where rule.keywords.contains(where: haystack.contains) {
            return rule.category
        }
        return .other
    }

    // MARK: - Number parsing

    /// All money-shaped values on a line, e.g. "Ukupno 1.234,56" → [1234.56].
    private static func moneyValues(in text: String) -> [Double] {
        let pattern = #"\d{1,3}(?:[.,\s]\d{3})*[.,]\d{2}|\d+[.,]\d{2}"#
        let matches = allMatches(in: text, pattern: pattern)
        return matches.compactMap { parseAmount($0) }.filter { $0 > 0 }
    }

    /// Normalize a localized number string to a Double. Handles "42,80",
    /// "42.80", European "1.234,56", and US "1,234.56".
    static func parseAmount(_ raw: String) -> Double? {
        let allowed = Set("0123456789.,")
        var s = String(raw.filter { allowed.contains($0) })
        guard !s.isEmpty else { return nil }

        let hasComma = s.contains(",")
        let hasDot = s.contains(".")

        if hasComma && hasDot {
            // The rightmost separator is the decimal point.
            if let lastComma = s.lastIndex(of: ","), let lastDot = s.lastIndex(of: "."), lastComma > lastDot {
                // European: dots are thousands, comma is decimal.
                s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                // US: commas are thousands, dot is decimal.
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if hasComma {
            s = s.replacingOccurrences(of: ",", with: ".")
        }
        return Double(s)
    }

    // MARK: - String helpers

    /// Uppercase + strip diacritics so "Ćevabdžinica" and "CEVABDZINICA" match.
    private static func fold(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US")).uppercased()
    }

    /// Title-case-ish cleanup for display: collapse whitespace, drop stray
    /// punctuation runs, and avoid SHOUTING merchant names.
    private static func cleaned(_ s: String) -> String {
        let collapsed = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // If the source is all-caps, present it capitalized for nicer display.
        if collapsed == collapsed.uppercased() {
            return collapsed.capitalized
        }
        return collapsed
    }

    // MARK: - Regex helpers (NSRegularExpression for SDK stability)

    private static func firstMatch(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            if let r = Range(match.range(at: i), in: text) {
                groups.append(String(text[r]))
            } else {
                groups.append("")
            }
        }
        return groups
    }

    private static func allMatches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
}
