import Foundation
import SwiftData
import SwiftUI

@Observable
class RecurringTransactionViewModel {
    var modelContext: ModelContext?
    var recurringTransactions: [RecurringTransaction] = []
    
    func fetchRecurringTransactions() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<RecurringTransaction>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            recurringTransactions = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch recurring transactions failed: \(error)")
        }
    }
    
    func addRecurringTransaction(amount: Double, type: TransactionType, category: String, note: String, frequency: Frequency, dayOfMonth: Int, dayOfWeek: Int, startDate: Date, endDate: Date?, account: Account?) {
        guard let modelContext = modelContext else { return }
        let recurring = RecurringTransaction(amount: amount, type: type, category: category, note: note, frequency: frequency, dayOfMonth: dayOfMonth, dayOfWeek: dayOfWeek, startDate: startDate, endDate: endDate, account: account)
        modelContext.insert(recurring)
        saveContext()
        fetchRecurringTransactions()
    }
    
    func updateRecurringTransaction(_ recurring: RecurringTransaction, amount: Double? = nil, type: TransactionType? = nil, category: String? = nil, note: String? = nil, frequency: Frequency? = nil, dayOfMonth: Int? = nil, dayOfWeek: Int? = nil, startDate: Date? = nil, endDate: Date? = nil, isActive: Bool? = nil, account: Account? = nil) {
        if let amount = amount { recurring.amount = amount }
        if let type = type { recurring.type = type }
        if let category = category { recurring.category = category }
        if let note = note { recurring.note = note }
        if let frequency = frequency { recurring.frequency = frequency }
        if let dayOfMonth = dayOfMonth { recurring.dayOfMonth = dayOfMonth }
        if let dayOfWeek = dayOfWeek { recurring.dayOfWeek = dayOfWeek }
        if let startDate = startDate { recurring.startDate = startDate }
        if let endDate = endDate { recurring.endDate = endDate }
        if let isActive = isActive { recurring.isActive = isActive }
        if let account = account { recurring.account = account }
        
        saveContext()
        fetchRecurringTransactions()
    }
    
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(recurring)
        saveContext()
        fetchRecurringTransactions()
    }
    
    func toggleActive(_ recurring: RecurringTransaction) {
        recurring.isActive.toggle()
        saveContext()
        fetchRecurringTransactions()
    }
    
    func generateTransactions(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        for recurring in recurringTransactions where recurring.isActive {
            guard shouldGenerate(recurring: recurring, date: today, calendar: calendar) else { continue }
            
            let transaction = Transaction(
                amount: recurring.amount,
                type: recurring.type,
                category: recurring.category,
                note: recurring.note,
                date: today,
                account: recurring.account
            )
            modelContext.insert(transaction)
            
            if let account = recurring.account {
                switch recurring.type {
                case .income:
                    account.balance += recurring.amount
                case .expense:
                    account.balance -= recurring.amount
                }
            }
            
            recurring.lastGenerated = today
        }
        
        try? modelContext.save()
    }
    
    private func shouldGenerate(recurring: RecurringTransaction, date: Date, calendar: Calendar) -> Bool {
        guard date >= recurring.startDate else { return false }
        if let endDate = recurring.endDate, date > endDate { return false }
        if let lastGenerated = recurring.lastGenerated, calendar.isDate(lastGenerated, inSameDayAs: date) { return false }
        
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        
        switch recurring.frequency {
        case .daily:
            return true
        case .weekly:
            return components.weekday == recurring.dayOfWeek
        case .monthly:
            return components.day == recurring.dayOfMonth
        case .yearly:
            let startComponents = calendar.dateComponents([.month, .day], from: recurring.startDate)
            return components.month == startComponents.month && components.day == startComponents.day
        }
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
