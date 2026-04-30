import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var showAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showDeleteAlert = false
    @State private var monthlyBudget: Double = 0
    @State private var isEditingBudget = false
    @State private var selectedMonth = Date()
    
    var totalSpending: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var categoryTotals: [(category: String, total: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })

        return grouped.map { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            return (category: category, total: total)
        }
    }
    
    var topCategory: String {
        categoryTotals.max(by: { $0.total < $1.total })?.category ?? "None"
    }

    var topCategoryAmount: Double {
        categoryTotals.max(by: { $0.total < $1.total })?.total ?? 0
    }
    
    var highestExpense: Expense? {
        filteredExpenses.max(by: { $0.amount < $1.amount })
    }
    
    var averageExpense: Double {
        guard !filteredExpenses.isEmpty else { return 0 }
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        return total / Double(filteredExpenses.count)
    }
    
    var weeklyTotal: Double {
        let calendar = Calendar.current
        
        return filteredExpenses.filter { expense in
            calendar.isDate(expense.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
        .reduce(0) { $0 + $1.amount }
    }
    
    var isOverBudget: Bool {
        totalSpending > monthlyBudget
    }
    
    var lastWeekTotal: Double {
        let calendar = Calendar.current
        guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) else {
            return 0
        }

        return expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: lastWeek, toGranularity: .weekOfYear)
        }
        .reduce(0) { $0 + $1.amount }
    }
    
    var weeklyChangePercentage: Double {
        guard lastWeekTotal > 0 else { return 0 }
        return ((weeklyTotal - lastWeekTotal) / lastWeekTotal) * 100
    }
    
    var trendText: String {
        if weeklyTotal > lastWeekTotal {
            return "↑ Spending increased"
        } else if weeklyTotal < lastWeekTotal {
            return "↓ Spending decreased"
        } else {
            return "No change"
        }
    }
    
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        
        return expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Food":
            return "fork.knife"
        case "Transport":
            return "car.fill"
        case "Shopping":
            return "bag.fill"
        case "Bills":
            return "doc.text.fill"
        default:
            return "tag.fill"
        }
    }

    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Food":
            return .orange
        case "Transport":
            return .blue
        case "Shopping":
            return .purple
        case "Bills":
            return .green
        default:
            return .gray
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)

                        Spacer()

                        Button {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Spending")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(totalSpending, format: .currency(code: "USD"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(selectedMonth.formatted(.dateTime.month(.wide).year())) overview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Budget")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            if isEditingBudget {
                                TextField("Budget", value: $monthlyBudget, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(monthlyBudget, format: .currency(code: "USD"))
                                    .font(.headline)
                            }

                            Spacer()

                            Button {
                                isEditingBudget.toggle()
                            } label: {
                                Image(systemName: isEditingBudget ? "checkmark" : "pencil")
                            }
                        }

                        if isOverBudget {
                            Text("⚠️ You are over budget!")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("Within budget")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Text("Spending by Category")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Chart(categoryTotals, id: \.category) { item in
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Amount", item.total)
                        )
                        .foregroundStyle(colorForCategory(item.category))
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Smart Insights")
                            .font(.headline)

                        HStack {
                            Text("Top Category")
                            Spacer()
                            Text(topCategory)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Highest Expense")
                            Spacer()
                            Text(highestExpense?.title ?? "None")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("This Week")
                            Spacer()
                            Text(weeklyTotal, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Average")
                            Spacer()
                            Text(averageExpense, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                        }
                        
                        Text("\(trendText) (\(weeklyChangePercentage, specifier: "%.1f")%)")
                            .font(.subheadline)
                            .foregroundColor(
                                weeklyTotal > lastWeekTotal ? .red :
                                weeklyTotal < lastWeekTotal ? .green : .gray
                            )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Text("Recent Expenses")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    if filteredExpenses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("No expenses for this month")
                                .font(.headline)
                            
                            Text("Tap + to add your first expense")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        LazyVStack {
                            ForEach(filteredExpenses) { expense in
                                HStack {
                                    Image(systemName: iconForCategory(expense.category))
                                        .foregroundColor(colorForCategory(expense.category))
                                        .font(.title2)
                                        .frame(width: 35)

                                    VStack(alignment: .leading) {
                                        Text(expense.title)
                                            .font(.headline)

                                        Text(expense.category)
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text(expense.amount, format: .currency(code: "USD"))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.red)

                                        Button {
                                            expenseToDelete = expense
                                            showDeleteAlert = true
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 1)
                                .padding(.horizontal)
                                .onTapGesture {
                                    selectedExpense = expense
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            
            .toolbar {
                Button {
                    showAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView { newExpense in
                    withAnimation {
                        modelContext.insert(newExpense)

                        do {
                            try modelContext.save()
                        } catch {
                            print("Save error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            .sheet(item: $selectedExpense) { expense in
                EditExpenseView(expense: expense) { updatedExpense in
                    expense.title = updatedExpense.title
                    expense.amount = updatedExpense.amount
                    expense.category = updatedExpense.category
                    expense.date = updatedExpense.date
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("Edit save error: \(error.localizedDescription)")
                    }
                }
            }
            
            .alert("Delete Expense?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    if let expenseToDelete {
                        withAnimation {
                            modelContext.delete(expenseToDelete)

                            do {
                                try modelContext.save()
                            } catch {
                                print("Delete save error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } message: {
                Text("This expense will be permanently removed.")
            }
        }
    }
}

#Preview {
    ContentView()
}
