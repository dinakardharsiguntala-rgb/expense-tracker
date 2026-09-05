import Foundation

/// Codable record used to communicate between the background SMS Filter Extension and the Main App
public struct SharedTransactionRecord: Codable, Identifiable {
    public let id: String
    public let amount: Double
    public let type: String
    public let merchant: String
    public let category: String
    public let bankName: String?
    public let accountLast4: String?
    public let paymentMode: String
    public let rawSMS: String
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        amount: Double,
        type: String,
        merchant: String,
        category: String,
        bankName: String?,
        accountLast4: String?,
        paymentMode: String,
        rawSMS: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.merchant = merchant
        self.category = category
        self.bankName = bankName
        self.accountLast4 = accountLast4
        self.paymentMode = paymentMode
        self.rawSMS = rawSMS
        self.timestamp = timestamp
    }
}

/// Thread-safe shared database manager using Apple's App Group container
public final class SharedExpenseDatabase {
    public static let shared = SharedExpenseDatabase()
    public static let appGroupIdentifier = "group.com.local.ExpenseTracker"
    private let fileName = "auto_parsed_sms_queue.json"

    private var sharedDirectoryURL: URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
            return container
        }
        // Fallback to Documents directory for standard sandbox
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var fileURL: URL {
        sharedDirectoryURL.appendingPathComponent(fileName)
    }

    /// Called by the SMS Filter Extension when an incoming bank SMS is detected
    public func saveAutoParsedTransaction(from result: ParsedSMSResult) {
        guard let amount = result.amount, amount > 0 else { return }

        let record = SharedTransactionRecord(
            amount: amount,
            type: result.type.rawValue,
            merchant: result.merchant,
            category: result.suggestedCategoryName,
            bankName: result.bankName,
            accountLast4: result.accountLast4,
            paymentMode: result.paymentMode.rawValue,
            rawSMS: result.rawMessage
        )

        var current = loadPendingRecords()
        current.append(record)
        saveRecords(current)
    }

    /// Called by the Main App on launch/foreground to ingest automatically captured SMS transactions
    public func fetchAndClearPendingRecords() -> [SharedTransactionRecord] {
        let records = loadPendingRecords()
        if !records.isEmpty {
            saveRecords([]) // Clear queue after fetching
        }
        return records
    }

    public func loadPendingRecords() -> [SharedTransactionRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([SharedTransactionRecord].self, from: data)
        } catch {
            return []
        }
    }

    private func saveRecords(_ records: [SharedTransactionRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Error saving shared records: \(error)")
        }
    }
}

