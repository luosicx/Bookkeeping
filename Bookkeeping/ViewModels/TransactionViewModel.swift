import Foundation
import SwiftData
import SwiftUI

@Observable
class TransactionViewModel {
    var modelContext: ModelContext?
    var transactions: [Transaction] = []
    var pendingAlerts: [BudgetAlertManager.BudgetAlert] = []
    var showAlertSheet = false
    
    // MARK: - 过滤后的交易
    var filteredTransactions: [Transaction] = []
    var filteredTotalIncome: Double = 0
    var filteredTotalExpense: Double = 0
    var filteredBalance: Double = 0
    
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    // MARK: - 过滤和计算
    func filterTransactions(type: TransactionType?, searchText: String, date: Date, ledger: Ledger?) {
        var result = transactions
        
        // 按账本过滤
        if let ledger = ledger {
            result = result.filter { $0.ledger?.id == ledger.id }
        }
        
        // 按类型过滤
        if let type = type {
            result = result.filter { $0.type == type }
        }
        
        // 按搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 按月份过滤
        let calendar = Calendar.current
        result = result.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
        
        filteredTransactions = result
        calculateFilteredTotals()
    }
    
    func calculateFilteredTotals() {
        filteredTotalIncome = filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        filteredTotalExpense = filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        filteredBalance = filteredTotalIncome - filteredTotalExpense
    }
    
    // MARK: - 数据获取
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
    
    // MARK: - CRUD 操作
    func addTransaction(amount: Double, type: TransactionType, category: String, note: String, date: Date, account: Account? = nil, ledger: Ledger? = nil, tags: [Tag]? = nil) {
        guard let modelContext = modelContext else { return }
        let transaction = Transaction(amount: amount, type: type, category: category, note: note, date: date, account: account, ledger: ledger, tags: tags)
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
    
    // MARK: - 预算检查
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
    
    // MARK: - 辅助方法
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
    
    // MARK: - 统计方法
    func categoryData(for date: Date) -> [(String, Double)] {
        var data: [String: Double] = [:]
        let monthTransactions = transactionsForMonth(date)
        for transaction in monthTransactions where transaction.type == .expense {
            data[transaction.category, default: 0] += transaction.amount
        }
        return data.sorted { $0.value > $1.value }
    }
    
    func dailyData(for date: Date) -> [(Date, Double, TransactionType)] {
        let calendar = Calendar.current
        let monthTransactions = transactionsForMonth(date)
        
        var dailyTotals: [Date: (income: Double, expense: Double)] = [:]
        
        for transaction in monthTransactions {
            let day = calendar.startOfDay(for: transaction.date)
            if dailyTotals[day] == nil {
                dailyTotals[day] = (0, 0)
            }
            if transaction.type == .income {
                dailyTotals[day]!.income += transaction.amount
            } else {
                dailyTotals[day]!.expense += transaction.amount
            }
        }
        
        var result: [(Date, Double, TransactionType)] = []
        for (date, totals) in dailyTotals.sorted(by: { $0.key < $1.key }) {
            result.append((date, totals.income, .income))
            result.append((date, totals.expense, .expense))
        }
        
        return result
    }
    
    func topCategories(for date: Date) -> [(String, Double, Int)] {
        let monthTransactions = transactionsForMonth(date).filter { $0.type == .expense }
        var categoryStats: [String: (total: Double, count: Int)] = [:]
        
        for transaction in monthTransactions {
            if categoryStats[transaction.category] == nil {
                categoryStats[transaction.category] = (0, 0)
            }
            categoryStats[transaction.category]!.total += transaction.amount
            categoryStats[transaction.category]!.count += 1
        }
        
        return categoryStats
            .map { ($0.key, $0.value.total, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    // MARK: - 私有方法
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
}
