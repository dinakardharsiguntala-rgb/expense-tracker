import SwiftUI
import SwiftData

public struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var transactions: [ExpenseTransaction]
    @Query private var categories: [ExpenseCategory]

    @State private var viewModel = TransactionListViewModel()
    @State private var showingAddSheet = false
    @State private var showingSMSSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar (Type tabs: All / Expense / Income)
                filterBar

                // Transactions List
                if transactions.isEmpty {
                    emptyStateView
                } else {
                    let groups = viewModel.groupedByDate(from: transactions)
                    if groups.isEmpty {
                        noResultsView
                    } else {
                        List {
                            ForEach(groups) { group in
                                Section {
                                    ForEach(group.transactions) { transaction in
                                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                            TransactionRowView(transaction: transaction)
                                        }
                                        .swipeActions(edge: .destructive, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                modelContext.delete(transaction)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    HStack {
                                        Text(group.title)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text(CurrencyFormatter.format(group.totalAmount))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search merchant, note, or bank")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(TransactionListViewModel.SortOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }

                        Divider()

                        Menu("Filter by Category") {
                            Button("All Categories") {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(categories) { cat in
                                Button(cat.name) {
                                    viewModel.selectedCategory = cat.name
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingSMSSheet = true
                        } label: {
                            Label("Paste Bank SMS", systemImage: "sparkles")
                        }

                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Expense", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingSMSSheet) {
                QuickSMSInputView()
            }
        }
    }

    // MARK: - Subviews

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(title: "All", isSelected: viewModel.selectedType == nil) {
                viewModel.selectedType = nil
            }

            filterChip(title: "Expenses", isSelected: viewModel.selectedType == .expense) {
                viewModel.selectedType = .expense
            }

            filterChip(title: "Income", isSelected: viewModel.selectedType == .income) {
                viewModel.selectedType = .income
            }

            if viewModel.selectedCategory != nil {
                Button {
                    viewModel.selectedCategory = nil
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedCategory!)
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(.caption2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appSecondaryBackground)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.appTertiaryBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No Transactions Yet")
                .font(.headline)

            Text("Transactions parsed from bank SMS or added manually will show up here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingSMSSheet = true
            } label: {
                Label("Parse Your First Bank SMS", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Matching Transactions")
                .font(.headline)

            Text("Try clearing your search query or filters.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}
