//
//  SummaryCardView.swift
//  ExpenseTracker
//
//  The dashboard hero: a glass card showing the period total in KM (with the
//  EUR equivalent muted below), a period-appropriate mini chart (hourly bars
//  for the day, 7 weekday bars for the week, a category donut for the month),
//  and the period selector integrated along the bottom.
//

import SwiftUI
import Charts

struct SummaryCardView: View {
    @Binding var period: Period
    let totalKM: Double
    let barData: [PeriodBar]
    let donutData: [CategorySlice]

    var body: some View {
        GlassCardView(cornerRadius: 24, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                header
                chart
                periodSelector
            }
        }
        .tint(.blue)
    }

    // MARK: - Header (total)

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(period.title.uppercased()) TOTAL")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(CurrencyManager.formatKM(totalKM))
                .font(.largeTitle.bold())
                .kerning(-1)
                .foregroundStyle(Color.kmPrimary)
                .contentTransition(.numericText())

            Text(CurrencyManager.formatEUR(fromKM: totalKM))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart (adapts to period)

    @ViewBuilder
    private var chart: some View {
        if period == .month {
            donutChart
        } else {
            barChart
        }
    }

    private var barChart: some View {
        Chart(barData) { bar in
            BarMark(
                x: .value("Bucket", bar.label),
                y: .value("KM", bar.value)
            )
            .foregroundStyle(Color.kmPrimary.gradient)
            .cornerRadius(3)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 70)
    }

    @ViewBuilder
    private var donutChart: some View {
        if donutData.isEmpty {
            // Keep the card height stable when there's nothing to plot.
            Color.clear.frame(height: 70)
        } else {
            HStack(spacing: 16) {
                Chart(donutData) { slice in
                    SectorMark(
                        angle: .value("KM", slice.total),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.category.color)
                    .cornerRadius(3)
                }
                .frame(width: 96, height: 96)

                // Compact legend: top categories by spend.
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(donutData.prefix(4)) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(slice.category.color)
                                .frame(width: 8, height: 8)
                            Text(slice.category.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Period selector

    private var periodSelector: some View {
        Picker("Period", selection: $period.animation(.spring(duration: 0.3))) {
            ForEach(Period.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var period: Period = .week
        var body: some View {
            ZStack {
                LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                SummaryCardView(
                    period: $period,
                    totalKM: 248.60,
                    barData: [
                        PeriodBar(label: "Mon", value: 20),
                        PeriodBar(label: "Tue", value: 55),
                        PeriodBar(label: "Wed", value: 10),
                        PeriodBar(label: "Thu", value: 80),
                        PeriodBar(label: "Fri", value: 35),
                        PeriodBar(label: "Sat", value: 40),
                        PeriodBar(label: "Sun", value: 8)
                    ],
                    donutData: [
                        CategorySlice(category: .food, total: 120),
                        CategorySlice(category: .transport, total: 80),
                        CategorySlice(category: .dining, total: 48)
                    ]
                )
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
