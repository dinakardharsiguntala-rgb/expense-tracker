import SwiftUI
import SwiftData

public struct QuickSMSInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @Query private var accounts: [BankAccount]

    @State private var smsText: String = ""
    @State private var parsedResult: ParsedSMSResult?
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedAccount: BankAccount?
    @State private var showingShortcutsGuide = false
    @State private var showingSavedToast = false

    // Preset sample SMS templates for quick testing
    private let sampleMessages: [(title: String, text: String)] = [
        ("HDFC Card", "Alert: You've spent Rs.1,499.00 on your HDFC Bank Credit Card ending 4321 at STARBUCKS COFFEE on 05-SEP-26. Avl Bal: Rs.45,200.00."),
        ("UPI Payment", "Dear SBI User, A/C 1234 debited by Rs 420.00 on 05Sep26 transfer to SWIGGY UPI: swiggy@icici Ref 429381. Bal: Rs 8,310.00"),
        ("Chase Bank", "Chase Alert: You made a $45.50 debit card transaction at WHOLE FOODS with card ending in 8892 on 09/05/2026."),
        ("Salary Credit", "Your A/C ending in 1234 has been CREDITED with Rs 75,000.00 on 01-Sep-26 towards SALARY by ACME CORP. Avl Bal: Rs 82,450.00"),
        ("Uber Ride", "Paid Rs 385.00 for your Uber ride using Paytm Wallet / ICICI NetBanking. Transaction ID: UB839201.")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    headerCard

                    // Input Text Area
                    smsInputSection

                    // Quick Sample Buttons
                    sampleButtonsSection

                    // Parsed Output Card
                    if let result = parsedResult, result.isValidTransaction {
                        parsedResultCard(result: result)
                    } else if !smsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        unrecognizedAlertCard
                    }

                    // iOS Shortcuts Automation banner
                    shortcutsPromoBanner
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Bank SMS Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let result = parsedResult, result.isValidTransaction {
                        Button("Save") {
                            saveTransaction(from: result)
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .sheet(isPresented: $showingShortcutsGuide) {
                SMSAutomationGuideView()
            }
            .overlay(alignment: .bottom) {
                if showingSavedToast {
                    toastView
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("On-Device SMS Parser")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Paste any bank transaction notification. Our smart local engine extracts amount, merchant, and category.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.08))
        )
    }

    private var smsInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bank SMS Text")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                if !smsText.isEmpty {
                    Button("Clear") {
                        smsText = ""
                        parsedResult = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            TextEditor(text: $smsText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: smsText) { _, newValue in
                    triggerParse(text: newValue)
                }
        }
    }

    private var sampleButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try Sample Bank Messages")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sampleMessages, id: \.title) { sample in
                        Button {
                            smsText = sample.text
                            triggerParse(text: sample.text)
                        } label: {
                            Text(sample.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appSecondaryBackground)
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    private func parsedResultCard(result: ParsedSMSResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Extracted Information", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                Text("\(Int(result.confidenceScore * 100))% Match")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }

            Divider()

            // Amount & Type
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(result.amount ?? 0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(result.type == .income ? .green : .red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(result.type.color)
                }
            }

            Divider()

            // Details Grid
            VStack(spacing: 10) {
                detailRow(title: "Merchant / Payee", value: result.merchant, icon: "building.2.fill")

                if let bank = result.bankName {
                    detailRow(title: "Bank", value: bank, icon: "building.columns.fill")
                }

                if let last4 = result.accountLast4 {
                    detailRow(title: "Account / Card", value: "••\(last4)", icon: "creditcard.fill")
                }

                detailRow(title: "Payment Mode", value: result.paymentMode.rawValue, icon: result.paymentMode.iconName)

                if let bal = result.remainingBalance {
                    detailRow(title: "Account Balance", value: CurrencyFormatter.format(bal), icon: "banknote")
                }
            }

            Divider()

            // Category Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Assigned Category")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Category", selection: $selectedCategory) {
                    Text("Select Category").tag(nil as ExpenseCategory?)
                    ForEach(categories) { cat in
                        HStack {
                            Image(systemName: cat.iconName)
                            Text(cat.name)
                        }
                        .tag(cat as ExpenseCategory?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appTertiaryBackground)
                .cornerRadius(10)
            }

            // Save Button
            Button {
                saveTransaction(from: result)
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save to My Expenses")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }

    private var unrecognizedAlertCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Could not detect a valid transaction")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Make sure the text contains an amount and debit/credit indicator.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private var shortcutsPromoBanner: some View {
        Button {
            showingShortcutsGuide = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Want Automatic SMS Logging?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Learn how to set up iOS Shortcuts to parse bank SMS automatically when they arrive.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSecondaryBackground)
            )
        }
    }

    private var toastView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Transaction Saved Locally!")
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Actions

    private func triggerParse(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parsedResult = nil
            return
        }

        let res = BankSMSParser.parse(message: text)
        parsedResult = res

        // Match or select category
        if let match = categories.first(where: { $0.name.lowercased() == res.suggestedCategoryName.lowercased() }) {
            selectedCategory = match
        } else {
            selectedCategory = categories.first(where: { !$0.isIncomeCategory })
        }

        // Match or select account if last 4 digits match
        if let last4 = res.accountLast4 {
            selectedAccount = accounts.first(where: { $0.accountLast4 == last4 })
        }
    }

    private func saveTransaction(from result: ParsedSMSResult) {
        guard let amount = result.amount else { return }

        let transaction = ExpenseTransaction(
            amount: amount,
            type: result.type,
            merchant: result.merchant,
            date: result.date,
            category: selectedCategory,
            account: selectedAccount,
            note: "Auto-parsed from bank message",
            rawSMS: result.rawMessage,
            bankName: result.bankName,
            accountLast4: result.accountLast4,
            paymentMode: result.paymentMode,
            isAutoParsed: true
        )

        modelContext.insert(transaction)
        try? modelContext.save()

        withAnimation {
            showingSavedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingSavedToast = false
            dismiss()
        }
    }
}
