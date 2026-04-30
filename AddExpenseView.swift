import SwiftUI

struct AddExpenseView: View {
    var onSave: (Expense) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var customCategory = ""

    let categories = ["Food", "Transport", "Shopping", "Bills", "Other", "Custom"]
    
    var isFormValid: Bool {
        !title.isEmpty &&
        Double(amount) != nil &&
        (category != "Custom" || !customCategory.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense title", text: $title)

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                
                if category == "Custom" {
                    TextField("Enter custom category", text: $customCategory)
                }
            }
            .navigationTitle("Add Expense")
            
            .toolbar {
                Button("Save") {
                    if let amountValue = Double(amount) {
                        let newExpense = Expense(
                            title: title,
                            amount: amountValue,
                            category: category == "Custom" ? customCategory : category,
                            date: Date()
                        )

                        onSave(newExpense)
                        dismiss()
                    }
                }
                .disabled(!isFormValid)
            }
        }
    }
}

#Preview {
    AddExpenseView { expense in
        print(expense)
    }
}
