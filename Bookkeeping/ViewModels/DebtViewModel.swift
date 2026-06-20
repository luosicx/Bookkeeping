import Foundation
import SwiftData

@Observable
class DebtViewModel {
    var modelContext: ModelContext?
    var debts: [Debt] = []
    
    var totalLent: Double {
        debts.filter { $0.type == .lend && !$0.isSettled }.reduce(0) { $0 + $1.amount }
    }
    
    var totalBorrowed: Double {
        debts.filter { $0.type == .borrow && !$0.isSettled }.reduce(0) { $0 + $1.amount }
    }
    
    var unsettledDebts: [Debt] {
        debts.filter { !$0.isSettled }
    }
    
    var overdueDebts: [Debt] {
        debts.filter { !$0.isSettled && ($0.dueDate ?? Date.distantFuture) < Date() }
    }
    
    func fetchDebts() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Debt>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            debts = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch debts failed: \(error)")
        }
    }
    
    func addDebt(name: String, amount: Double, type: DebtType, note: String, date: Date, dueDate: Date?) {
        guard let modelContext = modelContext else { return }
        let debt = Debt(name: name, amount: amount, type: type, note: note, date: date, dueDate: dueDate)
        modelContext.insert(debt)
        saveContext()
        fetchDebts()
    }
    
    func settleDebt(_ debt: Debt) {
        debt.isSettled = true
        debt.settledDate = Date()
        saveContext()
        fetchDebts()
    }
    
    func deleteDebt(_ debt: Debt) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(debt)
        saveContext()
        fetchDebts()
    }
    
    func debtsForType(_ type: DebtType) -> [Debt] {
        debts.filter { $0.type == type }
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
