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
        // Seed default initial categories and accounts on first launch
        let context = ModelContext(sharedModelContainer)
        seedInitialDataIfNeeded(context: context)
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
