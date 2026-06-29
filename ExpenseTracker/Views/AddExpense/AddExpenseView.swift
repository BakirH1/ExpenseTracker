//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  The sheet for creating an expense by hand. Amount is entered via the custom
//  keypad in the user's preferred currency, then converted to KM at save time.
//
//  Test case #1: fill name + amount (KM) + category + place → Save → the row
//  appears on the dashboard.
//  Test case #2: toggle to EUR, enter 10.00 → saved amount is 19.56 KM.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Remembers the last currency the user typed in, across launches.
    @AppStorage("preferredInputCurrency") private var currency: Currency = .km

    @State private var amountString = ""
    @State private var name = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var place = ""
    @State private var notes = ""
    @State private var date = Date()

    private var amount: Double { Double(amountString) ?? 0 }

    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    AmountInputView(amountString: $amountString, currency: $currency)

                    detailsCard

                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Category")
                        CategoryPickerView(selected: $selectedCategory)
                    }

                    notesCard
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
            .navigationTitle("New Expense")
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

    // MARK: - Cards

    private var detailsCard: some View {
        GlassCardView(cornerRadius: 20, padding: 16) {
            VStack(spacing: 14) {
                labeledField("Name", systemImage: "tag") {
                    TextField("e.g. Konzum", text: $name)
                }
                Divider()
                labeledField("Place", systemImage: "mappin.and.ellipse") {
                    TextField("Optional", text: $place)
                }
                Divider()
                labeledField("Date", systemImage: "calendar") {
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Notes")
            GlassCardView(cornerRadius: 20, padding: 12) {
                TextField("Optional", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
    }

    // MARK: - Small builders

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func labeledField<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Spacer()
            content()
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Save

    private func save() {
        let km = CurrencyManager.amountInKM(amount, from: currency)
        let trimmedPlace = place.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let expense = Expense(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: km,
            date: date,
            category: selectedCategory,
            place: trimmedPlace.isEmpty ? nil : trimmedPlace,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(expense)
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: Expense.self, inMemory: true)
}
