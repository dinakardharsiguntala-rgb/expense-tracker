import Foundation
import SwiftData

/// 100% on-device data export and backup helper
public struct ExportImportService {

    /// Exports transactions to CSV format
    public static func exportToCSV(transactions: [ExpenseTransaction]) -> String {
        var csv = "ID,Date,Merchant,Amount,Type,Category,PaymentMode,BankName,AccountLast4,Notes,IsAutoParsed,RawSMS\n"

        let dateFormatter = ISO8601DateFormatter()

        for t in transactions {
            let row = [
                t.id.uuidString,
                dateFormatter.string(from: t.date),
                "\"\(t.merchant.replacingOccurrences(of: "\"", with: "\"\""))\"",
                String(format: "%.2f", t.amount),
                t.type.rawValue,
                "\"\(t.categoryName)\"",
                t.paymentMode.rawValue,
                "\"\(t.bankName ?? "")\"",
                "\"\(t.accountLast4 ?? "")\"",
                "\"\(t.note.replacingOccurrences(of: "\"", with: "\"\""))\"",
                t.isAutoParsed ? "true" : "false",
                "\"\(t.rawSMS?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
            ].joined(separator: ",")
            csv.append(row + "\n")
        }

        return csv
    }
}
