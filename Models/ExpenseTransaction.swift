import Foundation
import SwiftData
import SwiftUI

@Model
public final class ExpenseTransaction {
    @Attribute(.unique) public var id: UUID
    public var amount: Double
    public var typeRaw: String
    public var merchant: String
    public var date: Date
    public var note: String
    public var rawSMS: String?
    public var bankName: String?
    public var accountLast4: String?
    public var paymentModeRaw: String
    public var isAutoParsed: Bool

    public var category: ExpenseCategory?
    public var account: BankAccount?

    public init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType = .expense,
        merchant: String,
        date: Date = Date(),
        category: ExpenseCategory? = nil,
        account: BankAccount? = nil,
        note: String = "",
        rawSMS: String? = nil,
        bankName: String? = nil,
        accountLast4: String? = nil,
        paymentMode: PaymentMode = .other,
        isAutoParsed: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.typeRaw = type.rawValue
        self.merchant = merchant
        self.date = date
        self.category = category
        self.account = account
        self.note = note
        self.rawSMS = rawSMS
        self.bankName = bankName
        self.accountLast4 = accountLast4
        self.paymentModeRaw = paymentMode.rawValue
        self.isAutoParsed = isAutoParsed
    }

    public var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    public var paymentMode: PaymentMode {
        get { PaymentMode(rawValue: paymentModeRaw) ?? .other }
        set { paymentModeRaw = newValue.rawValue }
    }

    public var categoryName: String {
        category?.name ?? "Uncategorized"
    }

    public var categoryColor: Color {
        category?.color ?? .gray
    }

    public var categoryIcon: String {
        category?.iconName ?? "questionmark.circle"
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
