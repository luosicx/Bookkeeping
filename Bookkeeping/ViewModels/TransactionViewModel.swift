import Foundation
import SwiftData
import SwiftUI

@Observable
class TransactionViewModel {
    var modelContext: ModelContext?
    var transactions: [Transaction] = []
    var pendingAlerts: [BudgetAlertManager.BudgetAlert] = []
    var showAlertSheet = false
    
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    func fetchTransactions() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            transactions = try modelContext.fetch(descriptor)
            updateWidgetData()
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    func addTransaction(amount: Double, type: TransactionType, category: String, note: String, date: Date, account: Account? = nil, ledger: Ledger? = nil) {
        guard let modelContext = modelContext else { return }
        let transaction = Transaction(amount: amount, type: type, category: category, note: note, date: date, account: account, ledger: ledger)
        modelContext.insert(transaction)
        
        if let account = account {
            switch type {
            case .income:
                account.balance += amount
            case .expense:
                account.balance -= amount
            }
        }
        
        saveContext()
        fetchTransactions()
        
        if type == .expense {
            checkBudgetAlerts(for: date)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        guard let modelContext = modelContext else { return }
        
        if let account = transaction.account {
            switch transaction.type {
            case .income:
                account.balance -= transaction.amount
            case .expense:
                account.balance += transaction.amount
            }
        }
        
        modelContext.delete(transaction)
        saveContext()
        fetchTransactions()
    }
    
    func checkBudgetAlerts(for date: Date = Date()) {
        guard let modelContext = modelContext else { return }
        
        let overallDescriptor = FetchDescriptor<OverallBudget>()
        let overallBudgets = (try? modelContext.fetch(overallDescriptor)) ?? []
        let currentOverallBudget = overallBudgets.first
        
        let budgetDescriptor = FetchDescriptor<Budget>()
        let categoryBudgets = (try? modelContext.fetch(budgetDescriptor)) ?? []
        
        let alerts = BudgetAlertManager.shared.checkBudgets(
            transactions: transactions,
            overallBudget: currentOverallBudget,
            categoryBudgets: categoryBudgets,
            date: date
        )
        
        if !alerts.isEmpty {
            pendingAlerts = alerts
            showAlertSheet = true
            
            for alert in alerts {
                BudgetAlertManager.shared.sendAlert(alert)
            }
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
    
    private func updateWidgetData() {
        let calendar = Calendar.current
        let now = Date()
        
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        
        let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let balance = income - expense
        
        SharedDataManager.shared.saveWidgetData(income: income, expense: expense, balance: balance)
    }
    
    func filteredTransactions(by type: TransactionType?) -> [Transaction] {
        if let type = type {
            return transactions.filter { $0.type == type }
        }
        return transactions
    }
    
    func transactionsForMonth(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }
    
    func totalIncomeForMonth(_ date: Date) -> Double {
        transactionsForMonth(date).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenseForMonth(_ date: Date) -> Double {
        transactionsForMonth(date).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    func balanceForMonth(_ date: Date) -> Double {
        totalIncomeForMonth(date) - totalExpenseForMonth(date)
    }
}
