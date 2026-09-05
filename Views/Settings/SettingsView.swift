import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [ExpenseTransaction]
    @Query private var categories: [ExpenseCategory]
    @Query private var accounts: [BankAccount]

    @AppStorage("selectedCurrency") private var selectedCurrency: String = "USD"
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var exportedCSV: String = ""
    @State private var showingShortcutsGuide = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Preferences
                Section("Preferences") {
                    Picker("Default Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases) { curr in
                            Text(curr.displayName).tag(curr.rawValue)
                        }
                    }

                    NavigationLink(destination: ManageCategoriesView()) {
                        Label("Manage Categories", systemImage: "folder.fill")
                    }
                }

                // Section 2: Bank SMS & Automation
                Section("Bank SMS & Smart Parser") {
                    Button {
                        showingShortcutsGuide = true
                    } label: {
                        HStack {
                            Label("Set Up iOS Shortcuts Automation", systemImage: "bolt.badge.automatic.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label("Parser Engine", systemImage: "cpu.fill")
                        Spacer()
                        Text("On-Device RegEx / Heuristics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Section 3: Data & Offline Backup (Zero Server)
                Section("On-Device Data & Backup") {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export Data as CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(transactions.isEmpty)

                    HStack {
                        Label("Database Engine", systemImage: "internaldrive.fill")
                        Spacer()
                        Text("SwiftData (SQLite Sandbox)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Total Transactions", systemImage: "number")
                        Spacer()
                        Text("\(transactions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Erase All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }

                // Section 4: Privacy Guarantee
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("100% Private & Serverless")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        Text("This app operates with zero servers, zero telemetry, and zero tracking. All financial records, bank messages, and analytics remain strictly encrypted on your iPhone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Section 5: About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingShortcutsGuide) {
                SMSAutomationGuideView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportedCSV])
            }
            .confirmationDialog(
                "Erase All Data",
                isPresented: $showingResetAlert,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    eraseAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All transactions will be permanently deleted from this iPhone.")
            }
        }
    }

    private func exportCSV() {
        exportedCSV = ExportImportService.exportToCSV(transactions: transactions)
        showingExportSheet = true
    }

    private func eraseAllData() {
        for t in transactions {
            modelContext.delete(t)
        }
        try? modelContext.save()
    }
}

#if canImport(UIKit)
/// UIActivityViewController wrapper for SwiftUI
public struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
public struct ShareSheet: View {
    let activityItems: [Any]
    public var body: some View {
        Text("Sharing not supported on this platform")
    }
}
#endif
