import SwiftUI
import SwiftData

public struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @Query private var accounts: [BankAccount]

    @State private var amountString: String = ""
    @State private var type: TransactionType = .expense
    @State private var merchant: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedAccount: BankAccount?
    @State private var paymentMode: PaymentMode = .other
    @State private var date: Date = Date()
    @State private var note: String = ""

    public init() {}

    private var isValid: Bool {
        guard let amount = Double(amountString.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            return false
        }
        return !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Amount & Type
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(CurrencyFormatter.symbol())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $amountString)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Amount & Type")
                }

                // Section 2: Details
                Section {
                    TextField("Merchant or Payee (e.g. Starbucks)", text: $merchant)

                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as ExpenseCategory?)
                        ForEach(categories.filter { type == .income ? $0.isIncomeCategory : !$0.isIncomeCategory }) { cat in
                            HStack {
                                Image(systemName: cat.iconName)
                                Text(cat.name)
                            }
                            .tag(cat as ExpenseCategory?)
                        }
                    }

                    Picker("Account", selection: $selectedAccount) {
                        Text("None").tag(nil as BankAccount?)
                        ForEach(accounts) { acc in
                            Text(acc.displayName).tag(acc as BankAccount?)
                        }
                    }

                    Picker("Payment Mode", selection: $paymentMode) {
                        ForEach(PaymentMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Transaction Details")
                }

                // Section 3: Notes
                Section {
                    TextField("Add optional note or description", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = categories.first(where: { type == .income ? $0.isIncomeCategory : !$0.isIncomeCategory })
                }
            }
        }
    }

    private func save() {
        guard let amount = Double(amountString.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            return
        }

        let transaction = ExpenseTransaction(
            amount: amount,
            type: type,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            category: selectedCategory,
            account: selectedAccount,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            paymentMode: paymentMode,
            isAutoParsed: false
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }
}
