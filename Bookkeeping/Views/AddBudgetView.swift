import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    let budgetViewModel: BudgetViewModel
    
    @State private var selectedCategory: Category?
    @State private var amount: String = ""
    @State private var selectedDate = Date()
    
    var availableCategories: [Category] {
        Category.expenseCategories.filter { category in
            !budgetViewModel.budgets.contains { $0.category == category.localizedName }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.month)) {
                    DatePicker(L.selectMonth, selection: $selectedDate, displayedComponents: .date)
                }
                
                Section(header: Text(L.category)) {
                    if availableCategories.isEmpty {
                        Text(L.allCategoriesHaveBudget)
                            .foregroundColor(.gray)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                            ForEach(availableCategories) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section(header: Text(L.budgetAmount)) {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle(L.addBudget)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.save) {
                        saveBudget()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategory != nil
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let month = calendar.date(from: components) else { return }
        
        budgetViewModel.addBudget(category: category.localizedName, amount: amountValue, month: month)
        dismiss()
    }
}

#Preview {
    AddBudgetView(budgetViewModel: BudgetViewModel())
}
