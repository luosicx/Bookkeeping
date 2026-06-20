import Foundation
import SwiftData
import SwiftUI

@Observable
class BudgetViewModel {
    var modelContext: ModelContext?
    var budgets: [Budget] = []
    var overallBudgets: [OverallBudget] = []
    
    func fetchBudgets(for date: Date = Date()) {
        guard let modelContext = modelContext else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else { return }
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return }
        
        let descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.category)])
        do {
            let allBudgets = try modelContext.fetch(descriptor)
            budgets = allBudgets.filter { budget in
                budget.month >= startOfMonth && budget.month < endOfMonth
            }
        } catch {
            print("Fetch budgets failed: \(error)")
        }
    }
    
    func fetchOverallBudget(for date: Date = Date()) {
        guard let modelContext = modelContext else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else { return }
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return }
        
        let descriptor = FetchDescriptor<OverallBudget>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            let allBudgets = try modelContext.fetch(descriptor)
            overallBudgets = allBudgets.filter { budget in
                budget.month >= startOfMonth && budget.month < endOfMonth
            }
        } catch {
            print("Fetch overall budgets failed: \(error)")
        }
    }
    
    func setOverallBudget(amount: Double, month: Date = Date()) {
        guard let modelContext = modelContext else { return }
        
        if let existing = overallBudgets.first {
            existing.amount = amount
        } else {
            let budget = OverallBudget(amount: amount, month: month)
            modelContext.insert(budget)
        }
        
        saveContext()
        fetchOverallBudget(for: month)
    }
    
    func addBudget(category: String, amount: Double, month: Date = Date()) {
        guard let modelContext = modelContext else { return }
        
        let existingBudget = budgets.first { $0.category == category }
        if let existing = existingBudget {
            existing.amount = amount
        } else {
            let budget = Budget(category: category, amount: amount, month: month)
            modelContext.insert(budget)
        }
        
        saveContext()
        fetchBudgets(for: month)
    }
    
    func deleteBudget(_ budget: Budget) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(budget)
        saveContext()
        fetchBudgets(for: budget.month)
    }
    
    func getBudgetStatus(for category: String, transactions: [Transaction], date: Date = Date()) -> BudgetStatus? {
        guard let budget = budgets.first(where: { $0.category == category }) else { return nil }
        
        let calendar = Calendar.current
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            $0.category == category &&
            $0.type == .expense
        }
        
        let spent = monthTransactions.reduce(0) { $0 + $1.amount }
        
        return BudgetStatus(budget: budget, spent: spent)
    }
    
    func getOverallBudgetStatus(transactions: [Transaction], date: Date = Date()) -> OverallBudgetStatus? {
        guard let budget = overallBudgets.first else { return nil }
        
        let calendar = Calendar.current
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            $0.type == .expense
        }
        
        let spent = monthTransactions.reduce(0) { $0 + $1.amount }
        
        return OverallBudgetStatus(budget: budget, spent: spent)
    }
    
    func getAllBudgetStatus(transactions: [Transaction], date: Date = Date()) -> [BudgetStatus] {
        return budgets.compactMap { budget in
            getBudgetStatus(for: budget.category, transactions: transactions, date: date)
        }
    }
    
    var totalBudget: Double {
        budgets.reduce(0) { $0 + $1.amount }
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
