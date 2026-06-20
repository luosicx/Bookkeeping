import SwiftUI
import SwiftData

@main
struct BookkeepingApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    NotificationService.shared.requestPermission { _ in } // Permission result handled elsewhere
                    initializeWidgetData()
                }
        }
        .modelContainer(for: [Transaction.self, Budget.self, OverallBudget.self, Account.self, RecurringTransaction.self, Ledger.self, SavingsGoal.self, BillReminder.self, CustomCategory.self, Debt.self, Tag.self]) { result in
            switch result {
            case .success(let container):
                SampleData.insertSampleData(modelContext: container.mainContext)
                self.updateWidgetData(modelContext: container.mainContext)
            case .failure(let error):
                print("Failed to create model container: \(error)")
            }
        }
    }
    
    private func initializeWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.bookkeeping.app")
        if defaults?.object(forKey: "widget_income") == nil {
            SharedDataManager.shared.saveWidgetData(income: 0, expense: 0, balance: 0)
        }
    }
    
    private func updateWidgetData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Transaction>()
        do {
            let transactions = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let now = Date()
            
            let monthTransactions = transactions.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let balance = income - expense
            
            SharedDataManager.shared.saveWidgetData(income: income, expense: expense, balance: balance)
        } catch {
            print("Failed to fetch transactions for widget: \(error)")
        }
    }
}
