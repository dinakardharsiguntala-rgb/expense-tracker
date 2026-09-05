import SwiftUI
import Charts

public struct SpendingChartView: View {
    let categoryShares: [DashboardViewModel.CategoryShare]
    let dailyTrends: [DashboardViewModel.DailyTrend]
    @State private var selectedChartTab = 0 // 0: Category Breakdown, 1: Daily Trend

    public init(
        categoryShares: [DashboardViewModel.CategoryShare],
        dailyTrends: [DashboardViewModel.DailyTrend]
    ) {
        self.categoryShares = categoryShares
        self.dailyTrends = dailyTrends
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Picker
            HStack {
                Text(selectedChartTab == 0 ? "Spending by Category" : "Last 7 Days Spending")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Picker("Chart View", selection: $selectedChartTab) {
                    Text("Categories").tag(0)
                    Text("Daily Trend").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            if selectedChartTab == 0 {
                categoryDonutChart
            } else {
                dailyTrendBarChart
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Donut Chart (Category Breakdown)
    @ViewBuilder
    private var categoryDonutChart: some View {
        if categoryShares.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No expense data recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            VStack(spacing: 14) {
                Chart(categoryShares) { share in
                    SectorMark(
                        angle: .value("Amount", share.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 2.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(share.color)
                }
                .frame(height: 190)

                // Category Legends
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(categoryShares.prefix(6)) { share in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(share.color)
                                .frame(width: 8, height: 8)

                            Text(share.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(String(format: "%.0f%%", share.percentage))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bar Chart (7-Day Trend)
    @ViewBuilder
    private var dailyTrendBarChart: some View {
        let hasData = dailyTrends.contains { $0.amount > 0 }
        if !hasData {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No expenses in the past 7 days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            Chart(dailyTrends) { trend in
                BarMark(
                    x: .value("Day", trend.label),
                    y: .value("Amount", trend.amount)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
            }
            .frame(height: 190)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(CurrencyFormatter.formatCompact(doubleValue))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
}
