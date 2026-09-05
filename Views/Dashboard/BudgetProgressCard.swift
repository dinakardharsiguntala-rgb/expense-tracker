import SwiftUI
import SwiftData

public struct BudgetProgressCard: View {
    let spent: Double
    let monthlyBudget: Double
    var onEditBudget: () -> Void

    public init(spent: Double, monthlyBudget: Double, onEditBudget: @escaping () -> Void) {
        self.spent = spent
        self.monthlyBudget = monthlyBudget
        self.onEditBudget = onEditBudget
    }

    private var progressRatio: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(spent / monthlyBudget, 1.0)
    }

    private var percentUsed: Double {
        guard monthlyBudget > 0 else { return 0 }
        return (spent / monthlyBudget) * 100
    }

    private var statusColor: Color {
        if percentUsed >= 100 {
            return .red
        } else if percentUsed >= 80 {
            return .orange
        } else {
            return .blue
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Budget Status")
                        .font(.headline)
                        .fontWeight(.bold)

                    if monthlyBudget > 0 {
                        Text("\(String(format: "%.0f%%", percentUsed)) used of \(CurrencyFormatter.format(monthlyBudget))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No monthly budget set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onEditBudget) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }

            if monthlyBudget > 0 {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.appGray5)
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor.gradient)
                            .frame(width: geometry.size.width * CGFloat(progressRatio), height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("Spent: \(CurrencyFormatter.format(spent))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Spacer()

                    let remaining = monthlyBudget - spent
                    if remaining >= 0 {
                        Text("Left: \(CurrencyFormatter.format(remaining))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else {
                        Text("Over budget by \(CurrencyFormatter.format(abs(remaining)))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Button(action: onEditBudget) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Set a Monthly Budget Limit")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}
