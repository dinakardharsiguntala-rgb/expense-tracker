import SwiftUI
import SwiftData

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var transactions: [ExpenseTransaction]
    @Query private var categories: [ExpenseCategory]
    @Query private var budgets: [Budget]

    @State private var viewModel = DashboardViewModel()
    @State private var showingSMSParserSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var showingBudgetSheet = false
    @State private var budgetLimitInput: String = ""

    private var currentMonthBudget: Budget? {
        let currentMonthKey = Budget.currentMonthYearString()
        return budgets.first { $0.monthYear == currentMonthKey }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Overview Card & Timeframe Picker
                    headerSection

                    // Quick Action Buttons (SMS Parser & Add Expense)
                    quickActionSection

                    // Metrics Grid (Spent, Income, Savings)
                    metricsGrid

                    // Spending Charts (Donut & 7-day Bar Trend)
                    SpendingChartView(
                        categoryShares: viewModel.categoryShares(from: transactions),
                        dailyTrends: viewModel.past7DaysTrend(from: transactions)
                    )

                    // Monthly Budget Progress
                    BudgetProgressCard(
                        spent: viewModel.totalExpense(from: transactions),
                        monthlyBudget: currentMonthBudget?.monthlyLimit ?? 0.0,
                        onEditBudget: {
                            budgetLimitInput = String(format: "%.0f", currentMonthBudget?.monthlyLimit ?? 1000.0)
                            showingBudgetSheet = true
                        }
                    )

                    // Recent Transactions List
                    recentTransactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSMSParserSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Bank SMS")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingSMSParserSheet) {
                QuickSMSInputView()
            }
            .sheet(isPresented: $showingAddTransactionSheet) {
                AddTransactionView()
            }
            .alert("Set Monthly Budget", isPresented: $showingBudgetSheet) {
                TextField("Amount", text: $budgetLimitInput)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    saveMonthlyBudget()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Set your spending target limit for this month.")
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("100% On-Device Vault")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                Text("Expense Overview")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                ForEach(DashboardViewModel.DashboardTimeframe.allCases) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .padding(.top, 8)
    }

    private var quickActionSection: some View {
        HStack(spacing: 12) {
            // Button: Paste Bank SMS
            Button {
                showingSMSParserSheet = true
            } label: {
                HStack {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.headline)
                    Text("Parse Bank SMS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            // Button: Manual Add Expense
            Button {
                showingAddTransactionSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Add Expense")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            }
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Spent",
                amount: viewModel.totalExpense(from: transactions),
                iconName: "arrow.up.right",
                accentColor: .red
            )

            StatCard(
                title: "Total Income",
                amount: viewModel.totalIncome(from: transactions),
                iconName: "arrow.down.left",
                accentColor: .green
            )

            StatCard(
                title: "Net Savings",
                amount: viewModel.netSavings(from: transactions),
                iconName: "banknote",
                accentColor: viewModel.netSavings(from: transactions) >= 0 ? .blue : .orange,
                subtitle: String(format: "%.0f%% saved", viewModel.savingsRate(from: transactions))
            )
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink(destination: TransactionListView()) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            let recent = Array(transactions.prefix(5))
            if recent.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No transactions logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Paste a bank SMS or add an expense to see it here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(recent) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionRowView(transaction: transaction)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if transaction.id != recent.last?.id {
                            Divider().padding(.leading, 74)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                )
            }
        }
    }

    private func saveMonthlyBudget() {
        guard let limit = Double(budgetLimitInput.trimmingCharacters(in: .whitespacesAndNewlines)), limit > 0 else {
            return
        }
        let currentMonthKey = Budget.currentMonthYearString()
        if let existing = currentMonthBudget {
            existing.monthlyLimit = limit
        } else {
            let newBudget = Budget(monthYear: currentMonthKey, monthlyLimit: limit)
            modelContext.insert(newBudget)
        }
        try? modelContext.save()
    }
}
