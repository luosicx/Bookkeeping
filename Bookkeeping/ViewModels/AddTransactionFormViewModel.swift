import Foundation
import SwiftData

@Observable
class AddTransactionFormViewModel {
    var amount: String = ""
    var type: TransactionType = .expense
    var selectedCategoryId: String?
    var note: String = ""
    var date: Date = Date()
    var selectedAccount: Account?
    var selectedLedger: Ledger?
    var selectedTags: [Tag] = []
    var accounts: [Account] = []
    var availableTags: [Tag] = []
    
    var selectedCategory: Category? {
        guard let id = selectedCategoryId else { return nil }
        return Category.categories(for: type).first { $0.id == id }
    }
    
    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return selectedCategoryId != nil
    }
    
    func loadAccounts(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.name)])
        accounts = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func loadTags(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        availableTags = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func resetCategory() {
        selectedCategoryId = nil
    }
    
    func saveTransaction(viewModel: TransactionViewModel) {
        guard let amountValue = Double(amount), let category = selectedCategory else { return }
        viewModel.addTransaction(
            amount: amountValue,
            type: type,
            category: category.localizedName,
            note: note,
            date: date,
            account: selectedAccount,
            ledger: selectedLedger,
            tags: selectedTags.isEmpty ? nil : selectedTags
        )
    }
}
