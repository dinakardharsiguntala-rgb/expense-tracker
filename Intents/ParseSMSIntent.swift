import Foundation
import AppIntents
import SwiftData

/// App Intent enabling iOS Shortcuts Automations to parse and log bank SMS in the background
public struct ParseBankSMSIntent: AppIntent {
    public static var title: LocalizedStringResource = "Parse Bank SMS Transaction"
    public static var description = IntentDescription("Extracts transaction details from a bank SMS or notification and logs it directly to your iPhone's local database.")

    @Parameter(title: "SMS Message Content", description: "The full text of the bank notification or SMS message.")
    public var messageContent: String

    public init() {}

    public init(messageContent: String) {
        self.messageContent = messageContent
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = BankSMSParser.parse(message: messageContent)

        guard let amount = result.amount, amount > 0 else {
            return .result(value: "No valid transaction detected in message.")
        }

        // Initialize SwiftData schema on-device
        let schema = Schema([
            ExpenseTransaction.self,
            ExpenseCategory.self,
            BankAccount.self,
            Budget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = ModelContext(container)

        // Find or create category
        var descriptor = FetchDescriptor<ExpenseCategory>()
        let existingCategories = (try? context.fetch(descriptor)) ?? []
        let matchedCategory = existingCategories.first {
            $0.name.lowercased() == result.suggestedCategoryName.lowercased()
        }

        // Find matching bank account
        var accountDescriptor = FetchDescriptor<BankAccount>()
        let existingAccounts = (try? context.fetch(accountDescriptor)) ?? []
        let matchedAccount = existingAccounts.first {
            if let last4 = result.accountLast4, !last4.isEmpty {
                return $0.accountLast4 == last4
            }
            return false
        }

        let transaction = ExpenseTransaction(
            amount: amount,
            type: result.type,
            merchant: result.merchant,
            date: result.date,
            category: matchedCategory,
            account: matchedAccount,
            note: "Logged via iOS Shortcuts Automation",
            rawSMS: result.rawMessage,
            bankName: result.bankName,
            accountLast4: result.accountLast4,
            paymentMode: result.paymentMode,
            isAutoParsed: true
        )

        context.insert(transaction)
        try context.save()

        let confirmation = "Successfully logged \(result.type.rawValue) of \(CurrencyFormatter.format(amount)) at \(result.merchant)!"
        return .result(value: confirmation)
    }
}

/// Automatically exposes the intent to the iOS Shortcuts app
public struct ExpenseTrackerShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ParseBankSMSIntent(),
            phrases: [
                "Parse bank SMS in \(.applicationName)",
                "Log bank transaction in \(.applicationName)",
                "Record expense from message in \(.applicationName)"
            ],
            shortTitle: "Parse Bank SMS",
            systemImageName: "sparkles"
        )
    }
}
