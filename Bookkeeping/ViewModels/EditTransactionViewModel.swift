import Foundation

@Observable
class EditTransactionViewModel {
    var amount: String = ""
    var type: TransactionType = .expense
    var selectedCategoryId: String?
    var note: String = ""
    var date: Date = Date()
    
    var selectedCategory: Category? {
        guard let id = selectedCategoryId else { return nil }
        return Category.categories(for: type).first { $0.id == id }
    }
    
    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategoryId != nil
    }
    
    func loadFromTransaction(_ transaction: Transaction) {
        amount = String(format: "%.2f", transaction.amount)
        type = transaction.type
        note = transaction.note
        date = transaction.date
        
        let categories = Category.categories(for: transaction.type)
        let matchedCategory = categories.first { $0.localizedName == transaction.category }
        selectedCategoryId = matchedCategory?.id
    }
    
    func saveChanges(transaction: Transaction) {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        
        transaction.amount = amountValue
        transaction.type = type
        transaction.category = category.localizedName
        transaction.note = note
        transaction.date = date
    }
}
