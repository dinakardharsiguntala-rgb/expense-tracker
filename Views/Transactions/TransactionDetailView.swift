import SwiftUI
import SwiftData

public struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var transaction: ExpenseTransaction

    @State private var isEditingCategory = false
    @State private var showingDeleteConfirmation = false
    @Query private var categories: [ExpenseCategory]

    public init(transaction: ExpenseTransaction) {
        self.transaction = transaction
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Amount Hero Banner
                amountBanner

                // Transaction Core Details
                detailsCard

                // Original Bank SMS Card (User requested seeing the full bank message)
                if let rawSMS = transaction.rawSMS, !rawSMS.isEmpty {
                    rawSMSCard(text: rawSMS)
                }

                // Delete Button
                deleteButton
            }
            .padding(16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete Transaction",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(transaction)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this transaction from your device?")
        }
    }

    // MARK: - Subviews

    private var amountBanner: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(transaction.categoryColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: transaction.categoryIcon)
                    .font(.system(size: 28))
                    .foregroundColor(transaction.categoryColor)
            }

            Text(transaction.merchant)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("\(transaction.type == .income ? "+" : "-")\(CurrencyFormatter.format(transaction.amount))")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(transaction.type == .income ? .green : .red)

            Text(transaction.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground)
        )
    }

    private var detailsCard: some View {
        VStack(spacing: 14) {
            rowItem(title: "Category", value: transaction.categoryName, icon: transaction.categoryIcon)

            Divider()

            rowItem(title: "Transaction Type", value: transaction.type.rawValue, icon: transaction.type.iconName)

            Divider()

            rowItem(title: "Payment Method", value: transaction.paymentMode.rawValue, icon: transaction.paymentMode.iconName)

            if let bank = transaction.bankName {
                Divider()
                rowItem(title: "Bank", value: bank, icon: "building.columns.fill")
            }

            if let last4 = transaction.accountLast4, !last4.isEmpty {
                Divider()
                rowItem(title: "Account Number", value: "•••• \(last4)", icon: "creditcard.fill")
            }

            if !transaction.note.isEmpty {
                Divider()
                rowItem(title: "Note", value: transaction.note, icon: "text.alignleft")
            }

            Divider()

            HStack {
                Label("Source", systemImage: transaction.isAutoParsed ? "sparkles" : "hand.tap.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(transaction.isAutoParsed ? "Auto-Parsed from Bank SMS" : "Manually Entered")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.isAutoParsed ? .blue : .secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSecondaryBackground)
        )
    }

    private func rawSMSCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                Text("Original Bank SMS Message")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appTertiaryBackground)
                .cornerRadius(10)

            Text("Stored securely on your iPhone. Never uploaded to any server.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSecondaryBackground)
        )
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Transaction")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func rowItem(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
