import SwiftUI
import SwiftData

@main
public struct ExpenseTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var detectedClipboardSMS: String? = nil
    @State private var showingClipboardAlert: Bool = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExpenseTransaction.self,
            ExpenseCategory.self,
            BankAccount.self,
            Budget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create SwiftData ModelContainer: \(error)")
        }
    }()

    public init() {
        let context = ModelContext(sharedModelContainer)
        seedInitialDataIfNeeded(context: context)
        syncAutoParsedFromExtension(context: context)
    }

    public var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie.fill")
                    }

                TransactionListView()
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet.rectangle.portrait.fill")
                    }

                QuickSMSInputView()
                    .tabItem {
                        Label("SMS Reader", systemImage: "message.badge.filled.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .modelContainer(sharedModelContainer)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    let context = ModelContext(sharedModelContainer)
                    syncAutoParsedFromExtension(context: context)
                    checkClipboardForBankSMS()
                }
            }
        }
    }

    // MARK: - Initial Seeding

    private static func seedInitialDataIfNeeded(context: ModelContext) {
        var categoryDescriptor = FetchDescriptor<ExpenseCategory>()
        categoryDescriptor.fetchLimit = 1

        let existingCategoriesCount = (try? context.fetchCount(categoryDescriptor)) ?? 0
        if existingCategoriesCount == 0 {
            for cat in ExpenseCategory.defaultCategories() {
                context.insert(cat)
            }
        }

        var accountDescriptor = FetchDescriptor<BankAccount>()
        accountDescriptor.fetchLimit = 1
        let existingAccountsCount = (try? context.fetchCount(accountDescriptor)) ?? 0
        if existingAccountsCount == 0 {
            for acc in BankAccount.defaultAccounts() {
                context.insert(acc)
            }
        }

        try? context.save()
    }

    // MARK: - Background SMS Extension Sync

    private func syncAutoParsedFromExtension(context: ModelContext) {
        let pending = SharedExpenseDatabase.shared.fetchAndClearPendingRecords()
        guard !pending.isEmpty else { return }

        let categories = (try? context.fetch(FetchDescriptor<ExpenseCategory>())) ?? []
        let accounts = (try? context.fetch(FetchDescriptor<BankAccount>())) ?? []

        for record in pending {
            let matchedCategory = categories.first { $0.name.lowercased() == record.category.lowercased() }
            let matchedAccount = accounts.first {
                if let last4 = record.accountLast4, !last4.isEmpty {
                    return $0.accountLast4 == last4
                }
                return false
            }

            let transaction = ExpenseTransaction(
                amount: record.amount,
                type: TransactionType(rawValue: record.type) ?? .expense,
                merchant: record.merchant,
                date: record.timestamp,
                category: matchedCategory,
                account: matchedAccount,
                note: "Automatically read from incoming bank SMS",
                rawSMS: record.rawSMS,
                bankName: record.bankName,
                accountLast4: record.accountLast4,
                paymentMode: PaymentMode(rawValue: record.paymentMode) ?? .other,
                isAutoParsed: true
            )

            context.insert(transaction)
        }

        try? context.save()
    }

    // MARK: - Smart Clipboard Detection

    private func checkClipboardForBankSMS() {
        #if os(iOS)
        if UIPasteboard.general.hasStrings, let text = UIPasteboard.general.string {
            let res = BankSMSParser.parse(message: text)
            if res.isValidTransaction && res.confidenceScore >= 0.5 {
                detectedClipboardSMS = text
                showingClipboardAlert = true
            }
        }
        #endif
    }
}
