import SwiftUI
import SwiftData

public struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var showingAddSheet = false
    @State private var newName: String = ""
    @State private var selectedIcon: String = "cart.fill"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var isIncome: Bool = false
    @State private var budgetLimitString: String = ""

    private let availableIcons = [
        "cart.fill", "fork.knife", "bag.fill", "car.fill", "fuelpump.fill",
        "bolt.fill", "film.fill", "cross.case.fill", "airplane", "book.closed.fill",
        "gamecontroller.fill", "tv.fill", "gift.fill", "tshirt.fill", "cup.and.saucer.fill",
        "banknote.fill", "chart.line.uptrend.xyaxis", "building.columns.fill", "tag.fill"
    ]

    private let availableColors = [
        "#FF6B6B", "#4ECDC4", "#FFD93D", "#6C5CE7", "#FF8E53",
        "#A8E6CF", "#FF7675", "#00CEC9", "#74B9FF", "#2ECC71",
        "#E84393", "#F39C12", "#34495E", "#B2BEC3"
    ]

    public init() {}

    public var body: some View {
        List {
            Section("Expense Categories") {
                ForEach(categories.filter { !$0.isIncomeCategory }) { cat in
                    categoryRow(cat: cat)
                }
                .onDelete(perform: deleteExpenseCategories)
            }

            Section("Income Categories") {
                ForEach(categories.filter { $0.isIncomeCategory }) { cat in
                    categoryRow(cat: cat)
                }
                .onDelete(perform: deleteIncomeCategories)
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            addCategorySheet
        }
    }

    private func categoryRow(cat: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(cat.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: cat.iconName)
                    .foregroundColor(cat.color)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(cat.name)
                    .font(.body)
                    .fontWeight(.medium)

                if let budget = cat.budgetLimit {
                    Text("Budget: \(CurrencyFormatter.format(budget)) / mo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Name (e.g. Gym & Fitness)", text: $newName)
                    Toggle("Is Income Category?", isOn: $isIncome)
                    if !isIncome {
                        TextField("Monthly Budget Limit (Optional)", text: $budgetLimitString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Select Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .padding(8)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Select Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .gray)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 2.5 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveNewCategory()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveNewCategory() {
        let budget = Double(budgetLimitString.trimmingCharacters(in: .whitespacesAndNewlines))
        let newCat = ExpenseCategory(
            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: selectedIcon,
            colorHex: selectedColorHex,
            budgetLimit: budget,
            isIncomeCategory: isIncome
        )
        modelContext.insert(newCat)
        try? modelContext.save()
        newName = ""
        budgetLimitString = ""
        showingAddSheet = false
    }

    private func deleteExpenseCategories(at offsets: IndexSet) {
        let expenses = categories.filter { !$0.isIncomeCategory }
        for index in offsets {
            modelContext.delete(expenses[index])
        }
        try? modelContext.save()
    }

    private func deleteIncomeCategories(at offsets: IndexSet) {
        let incomes = categories.filter { $0.isIncomeCategory }
        for index in offsets {
            modelContext.delete(incomes[index])
        }
        try? modelContext.save()
    }
}
