import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - TransactionViewModel 所有路径测试
@MainActor
final class TransactionViewModelAllPathsTests: XCTestCase {
    var viewModel: TransactionViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = TransactionViewModel()
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self, Tag.self, Budget.self, OverallBudget.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, Tag.self, Budget.self, OverallBudget.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testFilterTransactionsAllCombinations() throws {
        let ledger = Ledger(name: "个人", icon: "person", color: "blue")
        modelContext.insert(ledger)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date(), ledger: ledger)
        viewModel.addTransaction(amount: 200, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 50, type: .expense, category: "交通", note: "打车", date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: .expense, searchText: "午餐", date: Date(), ledger: ledger)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: ledger)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        
        viewModel.filterTransactions(type: .income, searchText: "", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
    }
    
    func testCategoryDataEmptyMonth() throws {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let data = viewModel.categoryData(for: lastMonth)
        XCTAssertTrue(data.isEmpty)
    }
    
    func testDailyDataEmptyMonth() throws {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let data = viewModel.dailyData(for: lastMonth)
        XCTAssertTrue(data.isEmpty)
    }
    
    func testTopCategoriesEmptyMonth() throws {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: lastMonth)
        XCTAssertTrue(top.isEmpty)
    }
    
    func testFilterWithSearchText() throws {
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐外卖", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "交通", note: "打车去公司", date: Date())
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "外卖", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        
        viewModel.filterTransactions(type: nil, searchText: "公司", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        
        viewModel.filterTransactions(type: nil, searchText: "不存在", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 0)
    }
    
    func testAddTransactionWithAllParameters() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 5000)
        let ledger = Ledger(name: "个人", icon: "person", color: "blue")
        let tag = Tag(name: "重要", color: "red")
        modelContext.insert(account)
        modelContext.insert(ledger)
        modelContext.insert(tag)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date(), account: account, ledger: ledger, tags: [tag])
        
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.account?.name, "现金")
        XCTAssertEqual(viewModel.transactions.first?.ledger?.name, "个人")
        XCTAssertEqual(viewModel.transactions.first?.tags?.count, 1)
        XCTAssertEqual(account.balance, 4900)
    }
    
    func testDeleteTransactionRestoreBalance() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 5000)
        modelContext.insert(account)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date(), account: account)
        XCTAssertEqual(account.balance, 4900)
        
        if let tx = viewModel.transactions.first {
            viewModel.deleteTransaction(tx)
        }
        XCTAssertEqual(account.balance, 5000)
    }
    
    func testCheckBudgetAlerts() throws {
        viewModel.addTransaction(amount: 5000, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let budget = OverallBudget(amount: 1000, month: Date())
        modelContext.insert(budget)
        try modelContext.save()
        
        viewModel.checkBudgetAlerts(for: Date())
        XCTAssertTrue(viewModel.showAlertSheet)
    }
    
    func testCheckBudgetAlertsNoBudget() throws {
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        viewModel.checkBudgetAlerts(for: Date())
        XCTAssertFalse(viewModel.showAlertSheet)
    }
}

// MARK: - StatisticsViewModel 所有路径测试
@MainActor
final class StatisticsViewModelAllPathsTests: XCTestCase {
    var viewModel: StatisticsViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = StatisticsViewModel()
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllMethods() throws {
        let calendar = Calendar.current
        let thisMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        let transactions = [
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: thisMonth),
            Transaction(amount: 3000, type: .income, category: "奖金", note: "", date: thisMonth),
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: thisMonth),
            Transaction(amount: 500, type: .expense, category: "交通", note: "", date: thisMonth),
            Transaction(amount: 300, type: .expense, category: "餐饮", note: "", date: thisMonth),
            Transaction(amount: 200, type: .expense, category: "购物", note: "", date: thisMonth),
            Transaction(amount: 1000, type: .income, category: "工资", note: "", date: lastMonth),
            Transaction(amount: 500, type: .expense, category: "餐饮", note: "", date: lastMonth),
        ]
        
        for tx in transactions {
            modelContext.insert(tx)
        }
        try modelContext.save()
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.transactions.count, 8)
        XCTAssertEqual(viewModel.transactionsForMonth(thisMonth).count, 6)
        XCTAssertEqual(viewModel.transactionsForMonth(lastMonth).count, 2)
        XCTAssertEqual(viewModel.totalIncomeForMonth(thisMonth), 8000)
        XCTAssertEqual(viewModel.totalExpenseForMonth(thisMonth), 1700)
        XCTAssertEqual(viewModel.balanceForMonth(thisMonth), 6300)
        
        let categoryData = viewModel.categoryData(for: thisMonth)
        XCTAssertEqual(categoryData.count, 3)
        
        let dailyData = viewModel.dailyData(for: thisMonth)
        XCTAssertFalse(dailyData.isEmpty)
        
        let topCategories = viewModel.topCategories(for: thisMonth)
        XCTAssertEqual(topCategories.count, 3)
        XCTAssertEqual(topCategories[0].0, "餐饮")
    }
}

// MARK: - BudgetViewModel 所有路径测试
@MainActor
final class BudgetViewModelAllPathsTests: XCTestCase {
    var viewModel: BudgetViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = BudgetViewModel()
        let config = ModelConfiguration(
            schema: Schema([Budget.self, OverallBudget.self, Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Budget.self, OverallBudget.self, Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllBudgetPaths() throws {
        viewModel.addBudget(category: "餐饮", amount: 1000)
        viewModel.addBudget(category: "交通", amount: 500)
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchBudgets()
        viewModel.fetchOverallBudget()
        
        let txs = [
            Transaction(amount: 500, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 200, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let foodStatus = viewModel.getBudgetStatus(for: "餐饮", transactions: txs)
        XCTAssertEqual(foodStatus?.spent, 500)
        
        let transportStatus = viewModel.getBudgetStatus(for: "交通", transactions: txs)
        XCTAssertEqual(transportStatus?.spent, 200)
        
        let overallStatus = viewModel.getOverallBudgetStatus(transactions: txs)
        XCTAssertEqual(overallStatus?.spent, 700)
        
        let allStatuses = viewModel.getAllBudgetStatus(transactions: txs)
        XCTAssertEqual(allStatuses.count, 2)
    }
}

// MARK: - LedgerViewModel 所有路径测试
@MainActor
final class LedgerViewModelAllPathsTests: XCTestCase {
    var viewModel: LedgerViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = LedgerViewModel()
        let config = ModelConfiguration(
            schema: Schema([Ledger.self, Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Ledger.self, Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllLedgerPaths() throws {
        viewModel.addLedger(name: "个人", icon: "person", color: "blue", isDefault: true)
        viewModel.addLedger(name: "家庭", icon: "house", color: "green")
        viewModel.fetchLedgers()
        
        XCTAssertEqual(viewModel.ledgers.count, 2)
        XCTAssertEqual(viewModel.getDefaultLedger()?.name, "个人")
        
        if let ledger = viewModel.ledgers.first {
            viewModel.updateLedger(ledger, name: "新名")
        }
        viewModel.fetchLedgers()
        XCTAssertEqual(viewModel.ledgers.first?.name, "新名")
        
        viewModel.selectLedger(viewModel.ledgers.first)
        XCTAssertEqual(viewModel.selectedLedger?.name, "新名")
        
        viewModel.selectLedger(nil)
        XCTAssertNil(viewModel.selectedLedger)
    }
}

// MARK: - DebtViewModel 所有路径测试
@MainActor
final class DebtViewModelAllPathsTests: XCTestCase {
    var viewModel: DebtViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = DebtViewModel()
        let config = ModelConfiguration(
            schema: Schema([Debt.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Debt.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllDebtPaths() throws {
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: dueDate)
        viewModel.addDebt(name: "李四", amount: 500, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.debts.count, 2)
        XCTAssertEqual(viewModel.totalLent, 1000)
        XCTAssertEqual(viewModel.totalBorrowed, 500)
        XCTAssertEqual(viewModel.unsettledDebts.count, 2)
        XCTAssertEqual(viewModel.debtsForType(.lend).count, 1)
        XCTAssertEqual(viewModel.debtsForType(.borrow).count, 1)
        
        if let debt = viewModel.debts.first {
            viewModel.settleDebt(debt)
        }
        viewModel.fetchDebts()
        XCTAssertEqual(viewModel.unsettledDebts.count, 1)
    }
}

// MARK: - BillReminderViewModel 所有路径测试
@MainActor
final class BillReminderViewModelAllPathsTests: XCTestCase {
    var viewModel: BillReminderViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = BillReminderViewModel()
        let config = ModelConfiguration(
            schema: Schema([BillReminder.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: BillReminder.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllReminderPaths() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.addReminder(title: "即将到期", amount: 100, dueDate: soonDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "已过期", amount: 200, dueDate: pastDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "很久以后", amount: nil, dueDate: laterDate, repeatFrequency: .yearly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.reminders.count, 3)
        XCTAssertEqual(viewModel.upcomingReminders.count, 2)
        XCTAssertEqual(viewModel.overdueReminders.count, 1)
        
        if let reminder = viewModel.reminders.first {
            viewModel.markAsPaid(reminder)
            viewModel.fetchReminders()
            XCTAssertEqual(viewModel.paidReminders.count, 1)
            
            viewModel.markAsUnpaid(reminder)
            viewModel.fetchReminders()
            XCTAssertEqual(viewModel.paidReminders.count, 0)
            
            viewModel.toggleEnabled(reminder)
            viewModel.fetchReminders()
            
            viewModel.updateReminder(reminder, title: "新标题", amount: 300, dueDate: Date(), repeatFrequency: .daily, note: "新备注", isEnabled: true)
            viewModel.fetchReminders()
        }
    }
}

// MARK: - SavingsGoalViewModel 所有路径测试
@MainActor
final class SavingsGoalViewModelAllPathsTests: XCTestCase {
    var viewModel: SavingsGoalViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = SavingsGoalViewModel()
        let config = ModelConfiguration(
            schema: Schema([SavingsGoal.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: SavingsGoal.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllGoalPaths() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: Date())
        viewModel.addGoal(name: "买车", icon: "car", targetAmount: 50000, deadline: nil)
        viewModel.fetchGoals()
        
        XCTAssertEqual(viewModel.goals.count, 2)
        XCTAssertEqual(viewModel.totalTarget, 60000)
        XCTAssertEqual(viewModel.totalSaved, 0)
        XCTAssertEqual(viewModel.overallProgress, 0)
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 5000)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.progress, 0.5)
            XCTAssertEqual(viewModel.goals.first?.remaining, 5000)
            
            viewModel.withdraw(from: goal, amount: 2000)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.currentAmount, 3000)
            
            viewModel.updateGoal(goal, name: "海外旅行", icon: "globe")
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.name, "海外旅行")
        }
        
        viewModel.deleteGoal(viewModel.goals.first!)
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.count, 1)
    }
}

// MARK: - RecurringTransactionViewModel 所有路径测试
@MainActor
final class RecurringTransactionViewModelAllPathsTests: XCTestCase {
    var viewModel: RecurringTransactionViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = RecurringTransactionViewModel()
        let config = ModelConfiguration(
            schema: Schema([RecurringTransaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: RecurringTransaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllRecurringPaths() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "每日午餐", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 200, type: .expense, category: "交通", note: "每周打车", frequency: .weekly, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 3000, type: .expense, category: "住房", note: "每月房租", frequency: .monthly, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 500, type: .income, category: "奖金", note: "年终奖", frequency: .yearly, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        XCTAssertEqual(viewModel.recurringTransactions.count, 4)
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.toggleActive(recurring)
            viewModel.fetchRecurringTransactions()
            XCTAssertFalse(viewModel.recurringTransactions.first?.isActive ?? true)
            
            viewModel.toggleActive(recurring)
            viewModel.fetchRecurringTransactions()
            XCTAssertTrue(viewModel.recurringTransactions.first?.isActive ?? false)
            
            viewModel.updateRecurringTransaction(recurring, amount: 200, note: "更新")
            viewModel.fetchRecurringTransactions()
            XCTAssertEqual(viewModel.recurringTransactions.first?.amount, 200)
        }
        
        viewModel.deleteRecurringTransaction(viewModel.recurringTransactions.first!)
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.count, 3)
    }
}

// MARK: - AccountViewModel 所有路径测试
@MainActor
final class AccountViewModelAllPathsTests: XCTestCase {
    var viewModel: AccountViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = AccountViewModel()
        let config = ModelConfiguration(
            schema: Schema([Account.self, Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Account.self, Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllAccountPaths() throws {
        viewModel.addAccount(name: "现金", type: .cash, icon: "banknote", balance: 1000, isDefault: true)
        viewModel.addAccount(name: "银行卡", type: .bank, icon: "building.columns", balance: 5000)
        viewModel.fetchAccounts()
        
        XCTAssertEqual(viewModel.accounts.count, 2)
        XCTAssertEqual(viewModel.totalBalance, 6000)
        XCTAssertEqual(viewModel.getDefaultAccount()?.name, "现金")
        
        if let account = viewModel.accounts.first(where: { $0.name == "现金" }) {
            viewModel.updateBalance(for: account, amount: 200, type: .income)
            XCTAssertEqual(account.balance, 1200)
            
            viewModel.updateBalance(for: account, amount: 100, type: .expense)
            XCTAssertEqual(account.balance, 1100)
            
            viewModel.updateAccount(account, name: "钱包")
        }
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.first?.name, "钱包")
    }
}

// MARK: - TagViewModel 所有路径测试
@MainActor
final class TagViewModelAllPathsTests: XCTestCase {
    var viewModel: TagViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = TagViewModel()
        let config = ModelConfiguration(
            schema: Schema([Tag.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Tag.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testAllTagPaths() throws {
        viewModel.addTag(name: "重要", color: "red")
        viewModel.addTag(name: "工作", color: "blue")
        viewModel.addTag(name: "个人", color: "green")
        viewModel.fetchTags()
        
        XCTAssertEqual(viewModel.tags.count, 3)
        
        viewModel.updateTag(viewModel.tags[0], name: "紧急", color: "orange")
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.first?.name, "紧急")
        
        viewModel.deleteTag(viewModel.tags.first!)
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.count, 2)
    }
}

// MARK: - CurrencyService 所有路径测试
@MainActor
final class CurrencyServiceAllPathsTests: XCTestCase {
    func testAllCurrencyPaths() throws {
        let service = CurrencyService.shared
        
        XCTAssertEqual(service.convert(100, from: "CNY", to: "CNY"), 100)
        XCTAssertEqual(service.convert(0, from: "CNY", to: "USD"), 0)
        
        for currency in CurrencyService.Currency.all {
            let formatted = service.formatAmount(100, currency: currency.id)
            XCTAssertFalse(formatted.isEmpty)
        }
    }
}

// MARK: - MonthlyReportService 所有路径测试
@MainActor
final class MonthlyReportServiceAllPathsTests: XCTestCase {
    func testAllReportPaths() throws {
        let service = MonthlyReportService.shared
        
        let emptyReport = service.generateReport(transactions: [], for: Date())
        XCTAssertEqual(emptyReport.totalIncome, 0)
        XCTAssertEqual(emptyReport.totalExpense, 0)
        XCTAssertEqual(emptyReport.transactionCount, 0)
        XCTAssertNil(emptyReport.topCategory)
        
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 200, type: .expense, category: "交通", note: "", date: Date()),
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        XCTAssertEqual(report.totalIncome, 5000)
        XCTAssertEqual(report.totalExpense, 300)
        XCTAssertEqual(report.balance, 4700)
        XCTAssertEqual(report.transactionCount, 3)
        XCTAssertEqual(report.topCategory, "餐饮")
    }
}

// MARK: - ExportService 所有路径测试
@MainActor
final class ExportServiceAllPathsTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    func testAllExportPaths() throws {
        let tx1 = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        let tx2 = Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()
        
        let csvUrl = try ExportService.shared.exportData(modelContext: modelContext, format: .csv)
        let jsonUrl = try ExportService.shared.exportData(modelContext: modelContext, format: .json)
        let excelUrl = try ExportService.shared.exportData(modelContext: modelContext, format: .excel)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: csvUrl.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonUrl.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: excelUrl.path))
        
        let csvContent = try String(contentsOf: csvUrl, encoding: .utf8)
        XCTAssertTrue(csvContent.contains("餐饮"))
        XCTAssertTrue(csvContent.contains("工资"))
        
        let jsonData = try Data(contentsOf: jsonUrl)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertEqual(json?["totalRecords"] as? Int, 2)
        
        let files = ExportService.shared.getExportFiles()
        XCTAssertGreaterThanOrEqual(files.count, 3)
        
        try? FileManager.default.removeItem(at: csvUrl)
        try? FileManager.default.removeItem(at: jsonUrl)
        try? FileManager.default.removeItem(at: excelUrl)
    }
}

// MARK: - ImportService 所有路径测试
@MainActor
final class ImportServiceAllPathsTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    func testAllImportPaths() throws {
        let csv = "日期,类型,分类,金额,备注\n2024-01-15,支出,餐饮,35.5,午餐\n2024-01-16,收入,工资,5000,月薪\n2024-01-17,income,奖金,1000,年终奖"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 3)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try modelContext.fetch(descriptor)
        XCTAssertEqual(transactions.count, 3)
        
        let types = transactions.map { $0.type }
        XCTAssertTrue(types.contains(.expense))
        XCTAssertTrue(types.contains(.income))
        
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - ShareService 所有路径测试
@MainActor
final class ShareServiceAllPathsTests: XCTestCase {
    func testAllSharePaths() throws {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date()),
        ]
        
        let text = ShareService.shared.shareAsText(transactions: transactions)
        XCTAssertFalse(text.isEmpty)
        XCTAssertTrue(text.contains("餐饮"))
        XCTAssertTrue(text.contains("工资"))
        XCTAssertTrue(text.contains("记账本"))
        
        let jsonData = ShareService.shared.shareAsJSON(transactions: transactions)
        XCTAssertNotNil(jsonData)
        
        let json = try? JSONSerialization.jsonObject(with: jsonData!) as? [String: Any]
        XCTAssertEqual(json?["totalRecords"] as? Int, 2)
        
        let items = ShareService.shared.generateShareItems(transactions: transactions)
        XCTAssertEqual(items.count, 2)
    }
}

// MARK: - SampleData 所有路径测试
@MainActor
final class SampleDataAllPathsTests: XCTestCase {
    func testAllSampleDataPaths() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, configurations: config)
        let context = container.mainContext
        
        SampleData.insertSampleData(modelContext: context)
        
        let ledgerCount = try context.fetchCount(FetchDescriptor<Ledger>())
        let accountCount = try context.fetchCount(FetchDescriptor<Account>())
        let transactionCount = try context.fetchCount(FetchDescriptor<Transaction>())
        
        XCTAssertGreaterThanOrEqual(ledgerCount, 1)
        XCTAssertGreaterThanOrEqual(accountCount, 1)
        XCTAssertGreaterThanOrEqual(transactionCount, 1)
        
        SampleData.insertSampleData(modelContext: context)
        let secondTransactionCount = try context.fetchCount(FetchDescriptor<Transaction>())
        XCTAssertEqual(transactionCount, secondTransactionCount)
    }
}

// MARK: - BackupService 所有路径测试
@MainActor
final class BackupServiceAllPathsTests: XCTestCase {
    func testAllBackupPaths() throws {
        let files = BackupService.shared.getBackupFiles()
        XCTAssertNotNil(files)
        
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/file.json")
        XCTAssertThrowsError(try BackupService.shared.deleteBackupFile(at: nonExistentURL))
    }
}

// MARK: - CloudSyncService 所有路径测试
@MainActor
final class CloudSyncServiceAllPathsTests: XCTestCase {
    func testSharedInstance() throws {
        let service = CloudSyncService.shared
        XCTAssertNotNil(service)
    }
}

// MARK: - NotificationService 所有路径测试
@MainActor
final class NotificationServiceAllPathsTests: XCTestCase {
    func testAllNotificationPaths() throws {
        NotificationService.shared.cancelAllReminders()
        
        let expectation = XCTestExpectation(description: "Get pending")
        NotificationService.shared.getPendingReminders { requests in
            XCTAssertNotNil(requests)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}

// MARK: - ThemeManager 所有路径测试
@MainActor
final class ThemeManagerAllPathsTests: XCTestCase {
    func testAllThemePaths() throws {
        let manager = ThemeManager.shared
        
        manager.currentTheme = .system
        XCTAssertNil(manager.colorScheme)
        
        manager.currentTheme = .light
        XCTAssertEqual(manager.colorScheme, .light)
        
        manager.currentTheme = .dark
        XCTAssertEqual(manager.colorScheme, .dark)
        
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.localizedName.isEmpty)
        }
    }
}

// MARK: - BillReminder 所有路径测试
final class BillReminderAllPathsTests: XCTestCase {
    func testAllBillReminderPaths() throws {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let soonDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        let overdue = BillReminder(title: "过期", amount: 100, dueDate: pastDate)
        XCTAssertTrue(overdue.isOverdue)
        XCTAssertFalse(overdue.isDueSoon)
        XCTAssertFalse(overdue.isPaid)
        
        let dueSoon = BillReminder(title: "快到期", amount: 200, dueDate: soonDate)
        XCTAssertFalse(dueSoon.isOverdue)
        XCTAssertTrue(dueSoon.isDueSoon)
        
        let later = BillReminder(title: "很久以后", amount: nil, dueDate: laterDate)
        XCTAssertFalse(later.isOverdue)
        XCTAssertFalse(later.isDueSoon)
        XCTAssertNil(later.amount)
        
        overdue.isPaid = true
        XCTAssertTrue(overdue.isPaid)
        XCTAssertFalse(overdue.isOverdue)
        
        overdue.isEnabled = false
        XCTAssertFalse(overdue.isEnabled)
    }
}

// MARK: - SavingsGoal 所有路径测试
final class SavingsGoalAllPathsTests: XCTestCase {
    func testAllSavingsGoalPaths() throws {
        let goal = SavingsGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: Date())
        XCTAssertEqual(goal.progress, 0)
        XCTAssertEqual(goal.remaining, 10000)
        XCTAssertFalse(goal.isCompleted)
        
        goal.currentAmount = 5000
        XCTAssertEqual(goal.progress, 0.5)
        XCTAssertEqual(goal.remaining, 5000)
        
        goal.currentAmount = 10000
        XCTAssertEqual(goal.progress, 1.0)
        XCTAssertEqual(goal.remaining, 0)
        
        goal.currentAmount = 15000
        XCTAssertEqual(goal.progress, 1.0)
        XCTAssertEqual(goal.remaining, 0)
        
        let noDeadline = SavingsGoal(name: "测试", icon: "target", targetAmount: 100)
        XCTAssertNil(noDeadline.daysRemaining)
        
        let withDeadline = SavingsGoal(name: "测试", icon: "target", targetAmount: 100, deadline: Date())
        XCTAssertNotNil(withDeadline.daysRemaining)
    }
}

// MARK: - Debt 所有路径测试
final class DebtAllPathsTests: XCTestCase {
    func testAllDebtPaths() throws {
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        let debt = Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: dueDate)
        XCTAssertEqual(debt.name, "张三")
        XCTAssertEqual(debt.amount, 1000)
        XCTAssertEqual(debt.type, .lend)
        XCTAssertEqual(debt.note, "借款")
        XCTAssertNotNil(debt.dueDate)
        XCTAssertFalse(debt.isSettled)
        
        debt.isSettled = true
        debt.settledDate = Date()
        XCTAssertTrue(debt.isSettled)
        XCTAssertNotNil(debt.settledDate)
        
        XCTAssertEqual(DebtType.lend.localizedName, "借出")
        XCTAssertEqual(DebtType.borrow.localizedName, "借入")
        XCTAssertEqual(DebtType.lend.icon, "arrow.up.circle.fill")
        XCTAssertEqual(DebtType.borrow.icon, "arrow.down.circle.fill")
        XCTAssertEqual(DebtType.lend.color, "orange")
        XCTAssertEqual(DebtType.borrow.color, "purple")
    }
}

// MARK: - Tag 所有路径测试
final class TagAllPathsTests: XCTestCase {
    func testAllTagPaths() throws {
        let tag = Tag(name: "重要", color: "red")
        XCTAssertEqual(tag.name, "重要")
        XCTAssertEqual(tag.color, "red")
        
        let defaultTag = Tag(name: "测试")
        XCTAssertEqual(defaultTag.color, "blue")
        
        XCTAssertEqual(TagColors.colors.count, 8)
    }
}

// MARK: - Category 所有路径测试
final class CategoryAllPathsTests: XCTestCase {
    func testAllCategoryPaths() throws {
        XCTAssertEqual(Category.expenseCategories.count, 8)
        XCTAssertEqual(Category.incomeCategories.count, 4)
        
        for category in Category.expenseCategories {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.localizedName.isEmpty)
        }
        
        for category in Category.incomeCategories {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.localizedName.isEmpty)
        }
    }
}

// MARK: - Account 所有路径测试
final class AccountAllPathsTests: XCTestCase {
    func testAllAccountPaths() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 1000, isDefault: true)
        XCTAssertEqual(account.name, "现金")
        XCTAssertEqual(account.icon, "banknote")
        XCTAssertEqual(account.type, .cash)
        XCTAssertEqual(account.balance, 1000)
        XCTAssertTrue(account.isDefault)
        
        XCTAssertEqual(AccountType.cash.localizedName, "现金")
        XCTAssertEqual(AccountType.bank.localizedName, "银行卡")
        XCTAssertEqual(AccountType.alipay.localizedName, "支付宝")
        XCTAssertEqual(AccountType.wechat.localizedName, "微信")
        XCTAssertEqual(AccountType.credit.localizedName, "信用卡")
        XCTAssertEqual(AccountType.other.localizedName, "其他")
        
        XCTAssertEqual(AccountType.defaultAccounts.count, 4)
    }
}

// MARK: - Transaction 所有路径测试
final class TransactionAllPathsTests: XCTestCase {
    func testAllTransactionPaths() throws {
        let tx = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        XCTAssertEqual(tx.amount, 100)
        XCTAssertEqual(tx.type, .expense)
        XCTAssertEqual(tx.category, "餐饮")
        XCTAssertEqual(tx.note, "午餐")
        
        XCTAssertEqual(TransactionType.income.rawValue, "收入")
        XCTAssertEqual(TransactionType.expense.rawValue, "支出")
        XCTAssertEqual(TransactionType.income.localizedName, "收入")
        XCTAssertEqual(TransactionType.expense.localizedName, "支出")
        XCTAssertEqual(TransactionType.income.icon, "arrow.down.circle.fill")
        XCTAssertEqual(TransactionType.expense.icon, "arrow.up.circle.fill")
        XCTAssertEqual(TransactionType.income.color, "green")
        XCTAssertEqual(TransactionType.expense.color, "red")
    }
}

// MARK: - Frequency 所有路径测试
final class FrequencyAllPathsTests: XCTestCase {
    func testAllFrequencyPaths() throws {
        XCTAssertEqual(Frequency.allCases.count, 4)
        
        for freq in Frequency.allCases {
            XCTAssertFalse(freq.localizedName.isEmpty)
            XCTAssertFalse(freq.icon.isEmpty)
            XCTAssertFalse(freq.rawValue.isEmpty)
        }
    }
}

// MARK: - ChartTheme 所有路径测试
final class ChartThemeAllPathsTests: XCTestCase {
    func testAllChartThemePaths() throws {
        XCTAssertEqual(ChartTheme.gradientColors.count, 8)
        XCTAssertFalse(ChartTheme.categoryColors.isEmpty)
        
        XCTAssertEqual(ChartTheme.color(for: 0), ChartTheme.gradientColors[0])
        XCTAssertEqual(ChartTheme.color(for: 8), ChartTheme.gradientColors[0])
        
        XCTAssertNotNil(ChartTheme.categoryGradient("餐饮"))
        XCTAssertNotNil(ChartTheme.incomeGradient())
        XCTAssertNotNil(ChartTheme.expenseGradient())
        XCTAssertNotNil(ChartTheme.balanceGradient())
    }
}

// MARK: - BudgetStatus 所有路径测试
final class BudgetStatusAllPathsTests: XCTestCase {
    func testAllBudgetStatusPaths() throws {
        let budget = Budget(category: "餐饮", amount: 1000, month: Date())
        
        let onTrack = BudgetStatus(budget: budget, spent: 500)
        XCTAssertEqual(onTrack.remaining, 500)
        XCTAssertEqual(onTrack.percentage, 0.5)
        XCTAssertFalse(onTrack.isOverBudget)
        XCTAssertFalse(onTrack.isWarning)
        
        let warning = BudgetStatus(budget: budget, spent: 850)
        XCTAssertEqual(warning.percentage, 0.85)
        XCTAssertFalse(warning.isOverBudget)
        XCTAssertTrue(warning.isWarning)
        
        let overBudget = BudgetStatus(budget: budget, spent: 1200)
        XCTAssertEqual(overBudget.remaining, -200)
        XCTAssertTrue(overBudget.isOverBudget)
        XCTAssertFalse(overBudget.isWarning)
        
        let zeroBudget = BudgetStatus(budget: Budget(category: "测试", amount: 0, month: Date()), spent: 100)
        XCTAssertEqual(zeroBudget.percentage, 0)
        XCTAssertTrue(zeroBudget.isOverBudget)
        
        let overall = OverallBudget(amount: 5000, month: Date())
        let overallStatus = OverallBudgetStatus(budget: overall, spent: 4500)
        XCTAssertEqual(overallStatus.percentage, 0.9)
        XCTAssertTrue(overallStatus.isWarning)
    }
}

// MARK: - Localization 所有路径测试
@MainActor
final class LocalizationAllPathsTests: XCTestCase {
    func testAllLocalizationPaths() throws {
        // General
        XCTAssertFalse(L.appName.isEmpty)
        XCTAssertFalse(L.cancel.isEmpty)
        XCTAssertFalse(L.save.isEmpty)
        XCTAssertFalse(L.delete.isEmpty)
        XCTAssertFalse(L.edit.isEmpty)
        XCTAssertFalse(L.search.isEmpty)
        XCTAssertFalse(L.done.isEmpty)
        XCTAssertFalse(L.confirm.isEmpty)
        XCTAssertFalse(L.close.isEmpty)
        
        // Tabs
        XCTAssertFalse(L.tabHome.isEmpty)
        XCTAssertFalse(L.tabStatistics.isEmpty)
        XCTAssertFalse(L.tabSettings.isEmpty)
        
        // Home
        XCTAssertFalse(L.homeTitle.isEmpty)
        XCTAssertFalse(L.monthlyBalance.isEmpty)
        XCTAssertFalse(L.income.isEmpty)
        XCTAssertFalse(L.expense.isEmpty)
        XCTAssertFalse(L.recentTransactions.isEmpty)
        XCTAssertFalse(L.noTransactions.isEmpty)
        XCTAssertFalse(L.addFirstRecord.isEmpty)
        XCTAssertFalse(L.all.isEmpty)
        
        // Transaction
        XCTAssertFalse(L.addTransaction.isEmpty)
        XCTAssertFalse(L.transactionType.isEmpty)
        XCTAssertFalse(L.amount.isEmpty)
        XCTAssertFalse(L.category.isEmpty)
        XCTAssertFalse(L.note.isEmpty)
        XCTAssertFalse(L.date.isEmpty)
        
        // Categories
        XCTAssertFalse(L.categoryFood.isEmpty)
        XCTAssertFalse(L.categoryTransport.isEmpty)
        XCTAssertFalse(L.categoryShopping.isEmpty)
        XCTAssertFalse(L.categoryEntertainment.isEmpty)
        XCTAssertFalse(L.categoryHousing.isEmpty)
        XCTAssertFalse(L.categoryMedical.isEmpty)
        XCTAssertFalse(L.categoryEducation.isEmpty)
        XCTAssertFalse(L.categorySalary.isEmpty)
        XCTAssertFalse(L.categoryBonus.isEmpty)
        XCTAssertFalse(L.categoryInvestment.isEmpty)
        
        // Budget
        XCTAssertFalse(L.budgetManagement.isEmpty)
        XCTAssertFalse(L.totalBudget.isEmpty)
        XCTAssertFalse(L.overallBudget.isEmpty)
        XCTAssertFalse(L.remaining.isEmpty)
        XCTAssertFalse(L.spent.isEmpty)
        
        // Account
        XCTAssertFalse(L.accountManagement.isEmpty)
        XCTAssertFalse(L.myAccounts.isEmpty)
        XCTAssertFalse(L.addAccount.isEmpty)
        
        // Ledger
        XCTAssertFalse(L.ledgerManagement.isEmpty)
        XCTAssertFalse(L.myLedgers.isEmpty)
        XCTAssertFalse(L.addLedger.isEmpty)
        
        // Debt
        XCTAssertFalse(L.debtManagement.isEmpty)
        XCTAssertFalse(L.debtLend.isEmpty)
        XCTAssertFalse(L.debtBorrow.isEmpty)
        
        // Tag
        XCTAssertFalse(L.tagManagement.isEmpty)
        XCTAssertFalse(L.tags.isEmpty)
        XCTAssertFalse(L.addTag.isEmpty)
        
        // Calendar
        XCTAssertFalse(L.calendar.isEmpty)
        
        // Currency
        XCTAssertFalse(L.currencyConverter.isEmpty)
        XCTAssertFalse(L.exchangeRate.isEmpty)
        
        // Receipt
        XCTAssertFalse(L.receiptScan.isEmpty)
        
        // Voice
        XCTAssertFalse(L.voiceInput.isEmpty)
        XCTAssertFalse(L.stopRecording.isEmpty)
    }
    
    func testFormattedStrings() throws {
        XCTAssertFalse(L.transactionCount(5).isEmpty)
        XCTAssertFalse(L.transactionCountFormat(10).isEmpty)
        XCTAssertFalse(L.budgetOverrun(100).isEmpty)
        XCTAssertFalse(L.reminderWithAmount("测试", 100).isEmpty)
        XCTAssertFalse(L.reminderWithoutAmount("测试").isEmpty)
        XCTAssertFalse(L.billDueSoon("测试", 3).isEmpty)
        XCTAssertFalse(L.importSuccessMessage(5).isEmpty)
        XCTAssertFalse(L.exportMessage("test").isEmpty)
        XCTAssertFalse(L.exportFailed("error").isEmpty)
        XCTAssertFalse(L.backupMessage("test").isEmpty)
        XCTAssertFalse(L.backupCount(5).isEmpty)
        XCTAssertFalse(L.restoreMessage(5).isEmpty)
        XCTAssertFalse(L.backupRecords(5).isEmpty)
        XCTAssertFalse(L.goalCount(5).isEmpty)
        XCTAssertFalse(L.daysRemaining(30).isEmpty)
    }
}

// MARK: - SpeechRecognizer 所有路径测试
final class SpeechRecognizerAllPathsTests: XCTestCase {
    func testVoiceCommandParserAllPaths() throws {
        let parser = VoiceCommandParser()
        
        let expenseResult = parser.parse("午餐花了30元")
        XCTAssertEqual(expenseResult.amount, 30)
        XCTAssertNotNil(expenseResult.categoryId)
        XCTAssertNotNil(expenseResult.note)
        
        let incomeResult = parser.parse("收到工资15000元")
        XCTAssertEqual(incomeResult.amount, 15000)
        XCTAssertNotNil(incomeResult.categoryId)
        
        let noAmountResult = parser.parse("午餐")
        XCTAssertNil(noAmountResult.amount)
        
        let decimalResult = parser.parse("花了100.5元")
        XCTAssertEqual(decimalResult.amount, 100.5)
        
        let emptyResult = parser.parse("")
        XCTAssertNil(emptyResult.amount)
        XCTAssertNil(emptyResult.categoryId)
    }
}

// MARK: - TrendPredictor 所有路径测试
final class TrendPredictorAllPathsTests: XCTestCase {
    func testAllTrendPaths() throws {
        let predictor = TrendPredictor.shared
        
        let emptyResult = predictor.analyzeTrend(transactions: [], type: .expense)
        XCTAssertNil(emptyResult)
        
        let singleResult = predictor.analyzeTrend(transactions: [Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())], type: .expense)
        XCTAssertNil(singleResult)
        
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 200, type: .expense, category: "交通", note: "", date: lastMonth),
        ]
        
        let result = predictor.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currentMonth, 100)
        XCTAssertEqual(result?.lastMonth, 200)
        
        let anomalies = predictor.detectAnomalies(transactions: [])
        XCTAssertTrue(anomalies.isEmpty)
        
        let noAnomalies = predictor.detectAnomalies(transactions: [
            Transaction(amount: 10, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 12, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 8, type: .expense, category: "餐饮", note: "", date: Date()),
        ])
        XCTAssertTrue(noAnomalies.isEmpty)
        
        let categoryResults = predictor.analyzeAllCategories(transactions: transactions)
        XCTAssertFalse(categoryResults.isEmpty)
    }
}

// MARK: - AddTransactionFormViewModel 所有路径测试
@MainActor
final class AddTransactionFormViewModelAllPathsTests: XCTestCase {
    func testAllFormPaths() throws {
        let viewModel = AddTransactionFormViewModel()
        
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "100"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.selectedCategoryId = "food"
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.type = .income
        viewModel.selectedCategoryId = "salary"
        XCTAssertNotNil(viewModel.selectedCategory)
        
        viewModel.resetCategory()
        XCTAssertNil(viewModel.selectedCategoryId)
    }
}

// MARK: - EditTransactionViewModel 所有路径测试
@MainActor
final class EditTransactionViewModelAllPathsTests: XCTestCase {
    func testAllEditPaths() throws {
        let viewModel = EditTransactionViewModel()
        
        let tx = Transaction(amount: 150.50, type: .income, category: "奖金", note: "年终奖", date: Date())
        viewModel.loadFromTransaction(tx)
        
        XCTAssertEqual(viewModel.amount, "150.50")
        XCTAssertEqual(viewModel.type, .income)
        XCTAssertEqual(viewModel.note, "年终奖")
        
        viewModel.amount = "200"
        viewModel.selectedCategoryId = "bonus"
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.saveChanges(transaction: tx)
        XCTAssertEqual(tx.amount, 200)
        XCTAssertEqual(tx.category, "奖金")
        
        XCTAssertNotNil(viewModel.selectedCategory)
        viewModel.selectedCategoryId = nil
        XCTAssertNil(viewModel.selectedCategory)
    }
}

// MARK: - Ledger 所有路径测试
final class LedgerAllPathsTests: XCTestCase {
    func testAllLedgerPaths() throws {
        let ledger = Ledger(name: "旅行", icon: "airplane", color: "orange")
        XCTAssertEqual(ledger.name, "旅行")
        XCTAssertEqual(ledger.icon, "airplane")
        XCTAssertEqual(ledger.color, "orange")
        XCTAssertFalse(ledger.isDefault)
        
        let defaultLedger = Ledger(name: "个人", icon: "person", color: "blue", isDefault: true)
        XCTAssertTrue(defaultLedger.isDefault)
        
        XCTAssertEqual(LedgerType.personal.localizedName, "个人")
        XCTAssertEqual(LedgerType.family.localizedName, "家庭")
        XCTAssertEqual(LedgerType.travel.localizedName, "旅行")
        XCTAssertEqual(LedgerType.work.localizedName, "工作")
        XCTAssertEqual(LedgerType.other.localizedName, "其他")
    }
}

// MARK: - Budget 所有路径测试
final class BudgetAllPathsTests: XCTestCase {
    func testAllBudgetPaths() throws {
        let budget = Budget(category: "餐饮", amount: 2000, month: Date())
        XCTAssertEqual(budget.category, "餐饮")
        XCTAssertEqual(budget.amount, 2000)
        
        let overall = OverallBudget(amount: 5000, month: Date())
        XCTAssertEqual(overall.amount, 5000)
    }
}

// MARK: - CustomCategory 所有路径测试
@MainActor
final class CustomCategoryAllPathsTests: XCTestCase {
    func testAllCustomCategoryPaths() throws {
        let category = CustomCategory(name: "自定义", icon: "star.fill", type: .expense)
        XCTAssertEqual(category.name, "自定义")
        XCTAssertEqual(category.icon, "star.fill")
        XCTAssertEqual(category.type, .expense)
        XCTAssertEqual(category.localizedName, "自定义")
        
        let manager = CustomCategoryManager.shared
        XCTAssertNotNil(manager)
        
        let categories = manager.getAllCategories(for: .expense)
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains("餐饮"))
        
        let incomeCategories = manager.getAllCategories(for: .income)
        XCTAssertFalse(incomeCategories.isEmpty)
        XCTAssertTrue(incomeCategories.contains("工资"))
    }
}

// MARK: - RecurringTransaction 所有路径测试
final class RecurringTransactionAllPathsTests: XCTestCase {
    func testAllRecurringPaths() throws {
        let recurring = RecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "每日午餐", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date())
        XCTAssertEqual(recurring.amount, 100)
        XCTAssertEqual(recurring.type, .expense)
        XCTAssertEqual(recurring.category, "餐饮")
        XCTAssertEqual(recurring.note, "每日午餐")
        XCTAssertEqual(recurring.frequency, .daily)
        XCTAssertTrue(recurring.isActive)
        XCTAssertNil(recurring.lastGenerated)
        
        let defaultRecurring = RecurringTransaction(amount: 50, type: .expense, category: "交通", frequency: .weekly, startDate: Date())
        XCTAssertEqual(defaultRecurring.dayOfMonth, 1)
        XCTAssertEqual(defaultRecurring.dayOfWeek, 1)
        XCTAssertNil(defaultRecurring.endDate)
        XCTAssertNil(defaultRecurring.account)
    }
}

// MARK: - OverallBudget 所有路径测试
final class OverallBudgetAllPathsTests: XCTestCase {
    func testAllOverallBudgetPaths() throws {
        let budget = OverallBudget(amount: 5000, month: Date())
        XCTAssertEqual(budget.amount, 5000)
    }
}
