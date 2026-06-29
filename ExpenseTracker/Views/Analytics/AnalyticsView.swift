//
//  AnalyticsView.swift
//  ExpenseTracker
//
//  The analytics tab: this-week-vs-last-week delta, a category breakdown bar
//  chart, and a daily-spend line chart for the current month. A KM/EUR toggle
//  switches every number and axis on the screen.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var displayCurrency: Currency = .km

    private let calendar = Calendar.expenseWeek

    var body: some View {
        NavigationStack {
            ScrollView {
                if expenses.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        message: "No data to analyze yet"
                    )
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 20) {
                        CurrencyToggleView(currency: $displayCurrency)
                            .frame(maxWidth: 260)
                        weekComparisonCard
                        categoryBreakdownCard
                        dailyTrendCard
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Week vs last week

    private var weekComparisonCard: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("THIS WEEK")
                    .font(.caption).foregroundStyle(.secondary)

                Text(format(thisWeekTotal))
                    .font(.largeTitle.bold())
                    .kerning(-1)
                    .foregroundStyle(Color.kmPrimary)

                HStack(spacing: 6) {
                    Image(systemName: deltaSymbol)
                        .font(.caption.weight(.bold))
                    Text(deltaText)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(deltaColor)

                Text("vs \(format(lastWeekTotal)) last week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Category breakdown

    private var categoryBreakdownCard: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("BY CATEGORY · THIS MONTH")
                    .font(.caption).foregroundStyle(.secondary)

                if monthCategorySlices.isEmpty {
                    Text("No spending this month")
                        .font(.callout).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Chart(monthCategorySlices) { slice in
                        BarMark(
                            x: .value("Amount", convert(slice.total)),
                            y: .value("Category", slice.category.displayName)
                        )
                        .foregroundStyle(slice.category.color)
                        .cornerRadius(4)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text(format(slice.total))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(monthCategorySlices.count) * 38 + 10)
                }
            }
        }
    }

    // MARK: - Daily trend

    private var dailyTrendCard: some View {
        GlassCardView(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY SPEND · THIS MONTH")
                    .font(.caption).foregroundStyle(.secondary)

                Chart(monthDailyPoints) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Amount", convert(point.value))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.kmPrimary)

                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Amount", convert(point.value))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.kmPrimary.opacity(0.15).gradient)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Derived data

    private var thisWeekTotal: Double {
        SpendAggregator.total(expenses.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) })
    }

    private var lastWeekTotal: Double {
        guard let lastWeekRef = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return SpendAggregator.total(expenses.filter { calendar.isDate($0.date, equalTo: lastWeekRef, toGranularity: .weekOfYear) })
    }

    private var monthExpenses: [Expense] {
        expenses.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var monthCategorySlices: [CategorySlice] {
        SpendAggregator.categorySlices(monthExpenses)
    }

    private var monthDailyPoints: [DailyPoint] {
        SpendAggregator.dailyPoints(monthExpenses)
    }

    // MARK: - Delta presentation

    private var deltaFraction: Double? {
        guard lastWeekTotal > 0 else { return nil }
        return (thisWeekTotal - lastWeekTotal) / lastWeekTotal
    }

    private var deltaText: String {
        guard let fraction = deltaFraction else { return "No prior week to compare" }
        let percent = abs(fraction) * 100
        return String(format: "%.0f%% %@ than last week", percent, fraction >= 0 ? "more" : "less")
    }

    private var deltaSymbol: String {
        guard let fraction = deltaFraction else { return "minus" }
        return fraction >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private var deltaColor: Color {
        // Spending more is flagged red; spending less is green.
        guard let fraction = deltaFraction else { return .secondary }
        return fraction >= 0 ? .red : .green
    }

    // MARK: - Currency helpers

    private func convert(_ km: Double) -> Double {
        CurrencyManager.value(fromKM: km, in: displayCurrency)
    }

    private func format(_ km: Double) -> String {
        CurrencyManager.format(convert(km), in: displayCurrency)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: Expense.self, inMemory: true)
}
