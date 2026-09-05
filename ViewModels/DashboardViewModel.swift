import Foundation
import SwiftUI
import SwiftData

@Observable
public final class DashboardViewModel {
    public var selectedTimeframe: DashboardTimeframe = .thisMonth

    public enum DashboardTimeframe: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case allTime = "All Time"

        public var id: String { rawValue }
    }

    public struct CategoryShare: Identifiable {
        public let id = UUID()
        public let name: String
        public let amount: Double
        public let color: Color
        public let icon: String
        public let percentage: Double
    }

    public struct DailyTrend: Identifiable {
        public let id = UUID()
        public let date: Date
        public let label: String
        public let amount: Double
    }

    // MARK: - Calculations

    public func filteredTransactions(from transactions: [ExpenseTransaction]) -> [ExpenseTransaction] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedTimeframe {
        case .thisMonth:
            return transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return transactions }
            return transactions.filter { calendar.isDate($0.date, equalTo: prevMonth, toGranularity: .month) }
        case .allTime:
            return transactions
        }
    }

    public func totalExpense(from transactions: [ExpenseTransaction]) -> Double {
        filteredTransactions(from: transactions)
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    public func totalIncome(from transactions: [ExpenseTransaction]) -> Double {
        filteredTransactions(from: transactions)
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    public func netSavings(from transactions: [ExpenseTransaction]) -> Double {
        totalIncome(from: transactions) - totalExpense(from: transactions)
    }

    public func savingsRate(from transactions: [ExpenseTransaction]) -> Double {
        let income = totalIncome(from: transactions)
        guard income > 0 else { return 0.0 }
        let savings = netSavings(from: transactions)
        return max(0.0, (savings / income) * 100)
    }

    public func categoryShares(from transactions: [ExpenseTransaction]) -> [CategoryShare] {
        let expenses = filteredTransactions(from: transactions).filter { $0.type == .expense }
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var grouped: [String: (amount: Double, color: Color, icon: String)] = [:]

        for t in expenses {
            let catName = t.categoryName
            let current = grouped[catName]?.amount ?? 0.0
            let color = t.categoryColor
            let icon = t.categoryIcon
            grouped[catName] = (amount: current + t.amount, color: color, icon: icon)
        }

        return grouped.map { key, val in
            CategoryShare(
                name: key,
                amount: val.amount,
                color: val.color,
                icon: val.icon,
                percentage: (val.amount / total) * 100
            )
        }.sorted { $0.amount > $1.amount }
    }

    public func past7DaysTrend(from transactions: [ExpenseTransaction]) -> [DailyTrend] {
        let calendar = Calendar.current
        var trends: [DailyTrend] = []
        let today = calendar.startOfDay(for: Date())

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date

            let dayTotal = transactions
                .filter { $0.type == .expense && $0.date >= date && $0.date < nextDate }
                .reduce(0) { $0 + $1.amount }

            trends.append(DailyTrend(date: date, label: dayFormatter.string(from: date), amount: dayTotal))
        }

        return trends
    }
}
