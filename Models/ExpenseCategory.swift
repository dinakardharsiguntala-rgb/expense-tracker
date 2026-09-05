import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@Model
public final class ExpenseCategory {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var budgetLimit: Double?
    public var isIncomeCategory: Bool

    @Relationship(deleteRule: .nullify, inverse: \ExpenseTransaction.category)
    public var transactions: [ExpenseTransaction]?

    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        budgetLimit: Double? = nil,
        isIncomeCategory: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.budgetLimit = budgetLimit
        self.isIncomeCategory = isIncomeCategory
        self.transactions = []
    }

    public var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    /// Predefined standard categories seeded on first launch
    public static func defaultCategories() -> [ExpenseCategory] {
        [
            ExpenseCategory(name: "Food & Dining", iconName: "fork.knife", colorHex: "#FF6B6B", budgetLimit: 500),
            ExpenseCategory(name: "Groceries", iconName: "cart.fill", colorHex: "#4ECDC4", budgetLimit: 400),
            ExpenseCategory(name: "Shopping", iconName: "bag.fill", colorHex: "#FFD93D", budgetLimit: 300),
            ExpenseCategory(name: "Transportation & Fuel", iconName: "car.fill", colorHex: "#6C5CE7", budgetLimit: 200),
            ExpenseCategory(name: "Bills & Utilities", iconName: "bolt.fill", colorHex: "#FF8E53", budgetLimit: 250),
            ExpenseCategory(name: "Entertainment", iconName: "film.fill", colorHex: "#A8E6CF", budgetLimit: 150),
            ExpenseCategory(name: "Healthcare & Pharmacy", iconName: "cross.case.fill", colorHex: "#FF7675", budgetLimit: 100),
            ExpenseCategory(name: "Travel & Hotels", iconName: "airplane", colorHex: "#00CEC9", budgetLimit: 400),
            ExpenseCategory(name: "Education & Subscriptions", iconName: "book.closed.fill", colorHex: "#74B9FF", budgetLimit: 80),
            ExpenseCategory(name: "Investments & Savings", iconName: "chart.line.uptrend.xyaxis", colorHex: "#2ED573", isIncomeCategory: false),
            ExpenseCategory(name: "Salary & Wages", iconName: "banknote.fill", colorHex: "#2ECC71", isIncomeCategory: true),
            ExpenseCategory(name: "Other Income", iconName: "plus.circle.fill", colorHex: "#1ABC9C", isIncomeCategory: true),
            ExpenseCategory(name: "General / Miscellaneous", iconName: "tag.fill", colorHex: "#B2BEC3", budgetLimit: 100)
        ]
    }
}

// Color Hex Extension for SwiftUI
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#888888"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        #else
        return "#888888"
        #endif
    }
}
