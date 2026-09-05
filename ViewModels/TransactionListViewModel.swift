import Foundation
import SwiftUI
import SwiftData

@Observable
public final class TransactionListViewModel {
    public var searchText: String = ""
    public var selectedType: TransactionType? = nil
    public var selectedCategory: String? = nil
    public var selectedPaymentMode: PaymentMode? = nil
    public var sortOption: SortOption = .newestFirst

    public enum SortOption: String, CaseIterable, Identifiable {
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
        case amountHighToLow = "Amount (High to Low)"
        case amountLowToHigh = "Amount (Low to High)"

        public var id: String { rawValue }
    }

    public struct TransactionGroup: Identifiable {
        public let id = UUID()
        public let title: String
        public let transactions: [ExpenseTransaction]
        public let totalAmount: Double
    }

    public func filteredTransactions(from all: [ExpenseTransaction]) -> [ExpenseTransaction] {
        var list = all

        // Filter by text
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            list = list.filter {
                $0.merchant.lowercased().contains(query) ||
                $0.note.lowercased().contains(query) ||
                ($0.bankName?.lowercased().contains(query) ?? false) ||
                $0.categoryName.lowercased().contains(query) ||
                ($0.accountLast4?.contains(query) ?? false)
            }
        }

        // Filter by Type
        if let type = selectedType {
            list = list.filter { $0.type == type }
        }

        // Filter by Category
        if let category = selectedCategory {
            list = list.filter { $0.categoryName == category }
        }

        // Filter by Payment Mode
        if let mode = selectedPaymentMode {
            list = list.filter { $0.paymentMode == mode }
        }

        // Sort
        switch sortOption {
        case .newestFirst:
            list.sort { $0.date > $1.date }
        case .oldestFirst:
            list.sort { $0.date < $1.date }
        case .amountHighToLow:
            list.sort { $0.amount > $1.amount }
        case .amountLowToHigh:
            list.sort { $0.amount < $1.amount }
        }

        return list
    }

    public func groupedByDate(from transactions: [ExpenseTransaction]) -> [TransactionGroup] {
        let sorted = filteredTransactions(from: transactions)
        let calendar = Calendar.current
        let now = Date()

        var todayList: [ExpenseTransaction] = []
        var yesterdayList: [ExpenseTransaction] = []
        var thisMonthList: [ExpenseTransaction] = []
        var olderList: [ExpenseTransaction] = []

        for t in sorted {
            if calendar.isDateInToday(t.date) {
                todayList.append(t)
            } else if calendar.isDateInYesterday(t.date) {
                yesterdayList.append(t)
            } else if calendar.isDate(t.date, equalTo: now, toGranularity: .month) {
                thisMonthList.append(t)
            } else {
                olderList.append(t)
            }
        }

        var groups: [TransactionGroup] = []
        if !todayList.isEmpty {
            groups.append(TransactionGroup(title: "Today", transactions: todayList, totalAmount: todayList.reduce(0) { $0 + $1.amount }))
        }
        if !yesterdayList.isEmpty {
            groups.append(TransactionGroup(title: "Yesterday", transactions: yesterdayList, totalAmount: yesterdayList.reduce(0) { $0 + $1.amount }))
        }
        if !thisMonthList.isEmpty {
            groups.append(TransactionGroup(title: "Earlier This Month", transactions: thisMonthList, totalAmount: thisMonthList.reduce(0) { $0 + $1.amount }))
        }
        if !olderList.isEmpty {
            groups.append(TransactionGroup(title: "Older", transactions: olderList, totalAmount: olderList.reduce(0) { $0 + $1.amount }))
        }

        return groups
    }
}
