import SwiftUI

struct EditExpenseView: View {
    @State private var selectedCategory: String = ""
    @State private var customCategory: String = ""
    
    @State var expense: Expense
    
    init(expense: Expense, onSave: @escaping (Expense) -> Void) {
        self._expense = State(initialValue: expense)
        self.onSave = onSave

        let predefined = ["Food", "Transport", "Shopping", "Bills", "Other"]

        if predefined.contains(expense.category) {
            _selectedCategory = State(initialValue: expense.category)
            _customCategory = State(initialValue: "")
        } else {
            _selectedCategory = State(initialValue: "Custom")
            _customCategory = State(initialValue: expense.category)
        }
    }
    
    var onSave: (Expense) -> Void
    @Environment(\.dismiss) var dismiss

    let categories = ["Food", "Transport", "Shopping", "Bills", "Other", "Custom"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense title", text: $expense.title)

                TextField("Amount", value: $expense.amount, format: .number)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                if selectedCategory == "Custom" {
                    TextField("Enter custom category", text: $customCategory)
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                Button("Save") {
                    var updated = expense
                    updated.category = selectedCategory == "Custom" ? customCategory : selectedCategory
                    onSave(updated)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    EditExpenseView(
        expense: Expense(title: "Lunch", amount: 12.50, category: "Food", date: Date())
    ) { updatedExpense in
        print(updatedExpense)
    }
}
