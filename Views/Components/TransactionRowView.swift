import SwiftUI

public struct TransactionRowView: View {
    let transaction: ExpenseTransaction

    public init(transaction: ExpenseTransaction) {
        self.transaction = transaction
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Category Icon with tinted circular background
            ZStack {
                Circle()
                    .fill(transaction.categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(transaction.categoryColor)
            }

            // Transaction Details (Merchant, Category, Bank / Auto badge)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(transaction.merchant)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if transaction.isAutoParsed {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8, weight: .bold))
                            Text("SMS")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(transaction.categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bank = transaction.bankName {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(bank)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let last4 = transaction.accountLast4, !last4.isEmpty {
                        Text("••\(last4)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount and Date/Time
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")\(CurrencyFormatter.format(transaction.amount))")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type == .income ? .green : .primary)

                HStack(spacing: 4) {
                    Image(systemName: transaction.paymentMode.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(transaction.relativeDateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
