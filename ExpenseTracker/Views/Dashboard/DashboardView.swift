//
//  DashboardView.swift
//  ExpenseTracker
//
//  The main tab. Shows the period summary card, the filtered expense list,
//  empty states, and the entry points for adding (manually or by scanning).
//
//  Period filtering is done IN MEMORY on the fetched array (per the project's
//  design guidance) rather than via a @Query predicate — simpler and reliable.
//
//  --- Manual test coverage (run on device/simulator) ---
//  Test #1  Add expense manually → appears in the list for the right period.
//  Test #4  Switch Day/Week/Month → list + total update to that window.
//  Test #6  Delete all expenses → the period empty state appears.
//  Test #7  Each row shows KM primary + EUR secondary (ExpenseRowView).
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var period: Period = .day
    @State private var showingAdd = false
    @State private var showingScanner = false
    @State private var isParsing = false
    @State private var scanPayload: ScanPayload?
    @State private var errorMessage: String?

    // MARK: - Derived data

    private var filteredExpenses: [Expense] {
        expenses.filter { period.contains($0.date) }
    }

    private var totalKM: Double {
        SpendAggregator.total(filteredExpenses)
    }

    private var barData: [PeriodBar] {
        switch period {
        case .day:   return SpendAggregator.hourlyBars(filteredExpenses)
        case .week:  return SpendAggregator.weekdayBars(filteredExpenses)
        case .month: return []
        }
    }

    private var donutData: [CategorySlice] {
        period == .month ? SpendAggregator.categorySlices(filteredExpenses) : []
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCardView(
                        period: $period,
                        totalKM: totalKM,
                        barData: barData,
                        donutData: donutData
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if filteredExpenses.isEmpty {
                    Section {
                        EmptyStateView(
                            symbol: period.emptyStateSymbol,
                            message: period.emptyStateMessage,
                            actionTitle: "Add your first one →",
                            action: { showingAdd = true }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(filteredExpenses) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        .onDelete(perform: deleteExpenses)
                    } header: {
                        Text("Transactions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(backgroundGradient)
            .animation(.spring(duration: 0.3), value: period)
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Scan Receipt", systemImage: "doc.viewfinder")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        // Manual entry
        .sheet(isPresented: $showingAdd) {
            AddExpenseView()
        }
        // Native document scanner
        .fullScreenCover(isPresented: $showingScanner) {
            ReceiptScannerView(
                onComplete: handleScannedImage,
                onCancel: { showingScanner = false }
            )
            .ignoresSafeArea()
        }
        // Review parsed result
        .sheet(item: $scanPayload) { payload in
            ScanResultView(payload: payload)
        }
        // "Reading receipt…" loading overlay
        .overlay {
            if isParsing {
                parsingOverlay
            }
        }
        .alert("Couldn’t read receipt", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var parsingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Reading receipt…")
                    .font(.callout.weight(.medium))
            }
            .padding(28)
            .glassCard(cornerRadius: 20, material: .regularMaterial)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    /// Called by the scanner with the first captured page. Runs OCR off the
    /// main thread, then presents the editable review screen.
    private func handleScannedImage(_ image: UIImage) {
        showingScanner = false
        isParsing = true
        let thumbnail = ReceiptParserService.thumbnailData(from: image)
        Task {
            do {
                let parsed = try await ReceiptParserService.parseReceipt(from: image)
                await MainActor.run {
                    isParsing = false
                    scanPayload = ScanPayload(receipt: parsed, thumbnailData: thumbnail)
                }
            } catch {
                await MainActor.run {
                    isParsing = false
                    errorMessage = "The text on this receipt couldn’t be recognized. Try again with better lighting, or add the expense manually."
                }
            }
        }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredExpenses[index])
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Expense.self, inMemory: true)
}
