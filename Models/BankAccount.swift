import Foundation
import SwiftData
import SwiftUI

@Model
public final class BankAccount {
    @Attribute(.unique) public var id: UUID
    public var bankName: String
    public var accountType: String
    public var accountLast4: String
    public var currentBalance: Double
    public var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \ExpenseTransaction.account)
    public var transactions: [ExpenseTransaction]?

    public init(
        id: UUID = UUID(),
        bankName: String,
        accountType: String = "Savings",
        accountLast4: String = "",
        currentBalance: Double = 0.0,
        colorHex: String = "#3498DB"
    ) {
        self.id = id
        self.bankName = bankName
        self.accountType = accountType
        self.accountLast4 = accountLast4
        self.currentBalance = currentBalance
        self.colorHex = colorHex
        self.transactions = []
    }

    public var displayName: String {
        if accountLast4.isEmpty {
            return "\(bankName) (\(accountType))"
        }
        return "\(bankName) (••\(accountLast4))"
    }

    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    public static func defaultAccounts() -> [BankAccount] {
        [
            BankAccount(bankName: "Primary Bank", accountType: "Savings", accountLast4: "1234", currentBalance: 2500, colorHex: "#3498DB"),
            BankAccount(bankName: "Credit Card", accountType: "Credit Card", accountLast4: "5678", currentBalance: 0, colorHex: "#E74C3C"),
            BankAccount(bankName: "Cash in Wallet", accountType: "Cash", accountLast4: "", currentBalance: 150, colorHex: "#2ECC71")
        ]
    }
}
