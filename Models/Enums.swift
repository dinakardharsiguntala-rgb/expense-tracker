import Foundation
import SwiftUI

/// Type of financial transaction
public enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"
    case transfer = "Transfer"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }

    public var color: Color {
        switch self {
        case .expense: return .red
        case .income: return .green
        case .transfer: return .blue
        }
    }

    public var iconName: String {
        switch self {
        case .expense: return "arrow.up.right.circle.fill"
        case .income: return "arrow.down.left.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

/// Payment method used for the transaction
public enum PaymentMode: String, Codable, CaseIterable, Identifiable {
    case upi = "UPI"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case netBanking = "Net Banking"
    case cash = "Cash"
    case other = "Other"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .upi: return "qrcode"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .netBanking: return "building.columns.fill"
        case .cash: return "banknote.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Supported display currencies
public enum Currency: String, Codable, CaseIterable, Identifiable {
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case aud = "AUD"
    case cad = "CAD"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .aud: return "A$"
        case .cad: return "C$"
        }
    }

    public var displayName: String {
        "\(symbol) \(rawValue)"
    }
}
