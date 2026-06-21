import Foundation
import SwiftData

@Observable
class StatisticsViewModel {
    var modelContext: ModelContext?
    var transactions: [Transaction] = []
    
    func fetchTransactions() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    // MARK: - 按月过滤
    func transactionsForMonth(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }
    
    // MARK: - 统计计算
    func totalIncomeForMonth(_ date: Date) -> Double {
        transactionsForMonth(date).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenseForMonth(_ date: Date) -> Double {
        transactionsForMonth(date).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    func balanceForMonth(_ date: Date) -> Double {
        totalIncomeForMonth(date) - totalExpenseForMonth(date)
    }
    
    // MARK: - 分类数据
    func categoryData(for date: Date) -> [(String, Double)] {
        var data: [String: Double] = [:]
        let monthTransactions = transactionsForMonth(date)
        for transaction in monthTransactions where transaction.type == .expense {
            data[transaction.category, default: 0] += transaction.amount
        }
        return data.sorted { $0.value > $1.value }
    }
    
    // MARK: - 每日数据
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
    
    // MARK: - 支出排行
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
}
