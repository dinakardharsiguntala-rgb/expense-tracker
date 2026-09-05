import Foundation
import SwiftUI

public struct CurrencyFormatter {

    /// Returns the symbol for the selected currency
    public static func symbol(for currencyCode: String = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD") -> String {
        Currency(rawValue: currencyCode)?.symbol ?? "$"
    }

    /// Formats a double value with the user's currency symbol and standard grouping
    public static func format(_ amount: Double, currencyCode: String? = nil) -> String {
        let code = currencyCode ?? UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        let sym = symbol(for: code)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let numString = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(sym)\(numString)"
    }

    /// Compact format for charts and small metric badges (e.g. $1.2k, $15.5k)
    public static func formatCompact(_ amount: Double, currencyCode: String? = nil) -> String {
        let code = currencyCode ?? UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        let sym = symbol(for: code)

        if amount >= 1_000_000 {
            return String(format: "\(sym)%.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "\(sym)%.1fk", amount / 1_000)
        } else {
            return String(format: "\(sym)%.0f", amount)
        }
    }
}
