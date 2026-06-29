//
//  ScanResultView.swift
//  ExpenseTracker
//
//  Review-and-confirm screen for a parsed receipt. Every field is editable so
//  the user can fix anything the OCR got wrong. When overall confidence is low
//  (< 0.6) we show an amber banner and outline the amount/name fields in amber.
//
//  Test case #3: see the #Preview at the bottom — it injects a mock
//  ParsedReceipt (both a confident and a low-confidence variant) and verifies
//  every field populates without a camera.
//

import SwiftUI
import SwiftData

/// Bundle handed from the scanner flow to the review sheet. Identifiable so it
/// can drive `.sheet(item:)`.
struct ScanPayload: Identifiable {
    let id = UUID()
    var receipt: ParsedReceipt
    var thumbnailData: Data?
}

struct ScanResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let payload: ScanPayload
    private let confidence: Double

    @State private var amountString: String
    @State private var currency: Currency
    @State private var name: String
    @State private var place: String
    @State private var date: Date
    @State private var selectedCategory: ExpenseCategory

    init(payload: ScanPayload) {
        self.payload = payload
        let receipt = payload.receipt
        self.confidence = receipt.confidence
        _amountString = State(initialValue: String(format: "%.2f", receipt.amount))
        _currency = State(initialValue: receipt.currency)
        _name = State(initialValue: receipt.name)
        _place = State(initialValue: receipt.place ?? "")
        _date = State(initialValue: receipt.date)
        _selectedCategory = State(initialValue: receipt.category)
    }

    private var amount: Double { Double(amountString) ?? 0 }
    private var isLowConfidence: Bool { confidence < 0.6 }
    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLowConfidence {
                        confidenceBanner
                    }
                    if let image = thumbnail {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    AmountInputView(amountString: $amountString, currency: $currency)
                        .padding(.vertical, 8)
                        .overlay(amberOutline(isLowConfidence))

                    fieldsCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.caption).foregroundStyle(.secondary)
                        CategoryPickerView(selected: $selectedCategory)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var confidenceBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.warningAmber)
            Text("Some details may be inaccurate. Please double-check the amber fields before saving.")
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warningAmber.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var fieldsCard: some View {
        GlassCardView(cornerRadius: 20, padding: 16) {
            VStack(spacing: 14) {
                HStack {
                    Label("Name", systemImage: "tag")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    TextField("Merchant", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                .overlay(amberOutline(isLowConfidence))

                Divider()
                HStack {
                    Label("Place", systemImage: "mappin.and.ellipse")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    TextField("Optional", text: $place)
                        .multilineTextAlignment(.trailing)
                }
                Divider()
                HStack {
                    Label("Date", systemImage: "calendar")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
        }
    }

    private var thumbnail: Image? {
        guard let data = payload.thumbnailData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    /// An amber rounded outline shown only when confidence is low.
    @ViewBuilder
    private func amberOutline(_ show: Bool) -> some View {
        if show {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.warningAmber, lineWidth: 1.5)
        }
    }

    // MARK: - Save

    private func save() {
        let km = CurrencyManager.amountInKM(amount, from: currency)
        let trimmedPlace = place.trimmingCharacters(in: .whitespacesAndNewlines)
        let expense = Expense(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: km,
            date: date,
            category: selectedCategory,
            place: trimmedPlace.isEmpty ? nil : trimmedPlace,
            receiptImageData: payload.thumbnailData
        )
        modelContext.insert(expense)
        dismiss()
    }
}

// Test case #3 — populate from a mock ParsedReceipt, no camera required.
#Preview("Confident scan") {
    ScanResultView(payload: ScanPayload(receipt: .mock, thumbnailData: nil))
        .modelContainer(for: Expense.self, inMemory: true)
}

#Preview("Low confidence") {
    ScanResultView(payload: ScanPayload(receipt: .mockLowConfidence, thumbnailData: nil))
        .modelContainer(for: Expense.self, inMemory: true)
}
