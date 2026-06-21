import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - BillReminderViewModel 完整测试
@MainActor
final class BillReminderViewModelFullTests: XCTestCase {
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
    
    func testMarkAsUnpaid() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "水费", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.markAsPaid(reminder)
            viewModel.fetchReminders()
            XCTAssertTrue(viewModel.reminders.first?.isPaid ?? false)
            
            viewModel.markAsUnpaid(reminder)
            viewModel.fetchReminders()
            XCTAssertFalse(viewModel.reminders.first?.isPaid ?? true)
        }
    }
    
    func testToggleEnabled() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "水费", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.toggleEnabled(reminder)
            viewModel.fetchReminders()
            XCTAssertFalse(viewModel.reminders.first?.isEnabled ?? true)
            
            viewModel.toggleEnabled(reminder)
            viewModel.fetchReminders()
            XCTAssertTrue(viewModel.reminders.first?.isEnabled ?? false)
        }
    }
    
    func testUpdateReminderAllFields() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "旧标题", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "旧备注", )
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.updateReminder(reminder, title: "新标题", amount: 200, dueDate: Date(), repeatFrequency: .yearly, note: "新备注", isEnabled: false)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.reminders.first?.title, "新标题")
        XCTAssertEqual(viewModel.reminders.first?.amount, 200)
        XCTAssertEqual(viewModel.reminders.first?.repeatFrequency, .yearly)
        XCTAssertEqual(viewModel.reminders.first?.note, "新备注")
        XCTAssertFalse(viewModel.reminders.first?.isEnabled ?? true)
    }
    
    func testUpcomingRemindersSorted() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.addReminder(title: "很久以后", amount: 200, dueDate: laterDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "即将到期", amount: 100, dueDate: soonDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.upcomingReminders.first?.title, "即将到期")
    }
    
    func testUpcomingRemindersFilterPaid() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "已付", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "未付", amount: 200, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first(where: { $0.title == "已付" }) {
            viewModel.markAsPaid(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.upcomingReminders.count, 1)
        XCTAssertEqual(viewModel.upcomingReminders.first?.title, "未付")
    }
    
    func testOverdueRemindersMultiple() throws {
        let pastDate1 = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let pastDate2 = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        
        viewModel.addReminder(title: "过期1", amount: 100, dueDate: pastDate1, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "过期2", amount: 200, dueDate: pastDate2, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.overdueReminders.count, 2)
    }
    
    func testPaidRemindersMultiple() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "A", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "B", amount: 200, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        for reminder in viewModel.reminders {
            viewModel.markAsPaid(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.paidReminders.count, 2)
    }
    
    func testDeleteReminderWithNotification() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "测试", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.reminders.count, 1)
        
        if let reminder = viewModel.reminders.first {
            viewModel.deleteReminder(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.reminders.count, 0)
    }
}

// MARK: - LedgerViewModel 完整测试
@MainActor
final class LedgerViewModelFullTests: XCTestCase {
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
    
    func testAddMultipleLedgers() throws {
        viewModel.addLedger(name: "个人", icon: "person", color: "blue", isDefault: true)
        viewModel.addLedger(name: "家庭", icon: "house", color: "green")
        viewModel.addLedger(name: "旅行", icon: "airplane", color: "orange")
        viewModel.fetchLedgers()
        
        XCTAssertEqual(viewModel.ledgers.count, 3)
        XCTAssertEqual(viewModel.getDefaultLedger()?.name, "个人")
    }
    
    func testUpdateLedger() throws {
        viewModel.addLedger(name: "旧名", icon: "folder", color: "gray")
        viewModel.fetchLedgers()
        
        if let ledger = viewModel.ledgers.first {
            viewModel.updateLedger(ledger, name: "新名", icon: "star", color: "red")
        }
        
        viewModel.fetchLedgers()
        XCTAssertEqual(viewModel.ledgers.first?.name, "新名")
        XCTAssertEqual(viewModel.ledgers.first?.icon, "star")
        XCTAssertEqual(viewModel.ledgers.first?.color, "red")
    }
    
    func testUpdateLedgerDefault() throws {
        viewModel.addLedger(name: "A", icon: "a", color: "blue", isDefault: true)
        viewModel.addLedger(name: "B", icon: "b", color: "green")
        viewModel.fetchLedgers()
        
        if let ledger = viewModel.ledgers.first(where: { $0.name == "B" }) {
            viewModel.updateLedger(ledger, isDefault: true)
        }
        
        viewModel.fetchLedgers()
        let defaultLedger = viewModel.ledgers.first { $0.isDefault }
        XCTAssertEqual(defaultLedger?.name, "B")
    }
    
    func testDeleteLedger() throws {
        viewModel.addLedger(name: "A", icon: "a", color: "blue")
        viewModel.addLedger(name: "B", icon: "b", color: "green")
        viewModel.fetchLedgers()
        
        if let ledger = viewModel.ledgers.first {
            viewModel.deleteLedger(ledger)
        }
        
        viewModel.fetchLedgers()
        XCTAssertEqual(viewModel.ledgers.count, 1)
    }
    
    func testDeleteSelectedLedger() throws {
        viewModel.addLedger(name: "A", icon: "a", color: "blue")
        viewModel.addLedger(name: "B", icon: "b", color: "green")
        viewModel.fetchLedgers()
        
        viewModel.selectLedger(viewModel.ledgers.first)
        
        if let ledger = viewModel.ledgers.first {
            viewModel.deleteLedger(ledger)
        }
        
        viewModel.fetchLedgers()
        XCTAssertNotNil(viewModel.selectedLedger)
    }
    
    func testSelectLedger() throws {
        viewModel.addLedger(name: "A", icon: "a", color: "blue")
        viewModel.fetchLedgers()
        
        viewModel.selectLedger(viewModel.ledgers.first)
        XCTAssertEqual(viewModel.selectedLedger?.name, "A")
        
        viewModel.selectLedger(nil)
        XCTAssertNil(viewModel.selectedLedger)
    }
    
    func testGetTransactionsForLedger() throws {
        let ledger = Ledger(name: "个人", icon: "person", color: "blue")
        modelContext.insert(ledger)
        
        let tx1 = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date(), ledger: ledger)
        let tx2 = Transaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()
        
        let allTransactions = [tx1, tx2]
        
        let filtered = viewModel.getTransactions(for: ledger, allTransactions: allTransactions)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, tx1.id)
        
        let noLedger = viewModel.getTransactions(for: nil, allTransactions: allTransactions)
        XCTAssertEqual(noLedger.count, 1)
        XCTAssertEqual(noLedger.first?.id, tx2.id)
    }
}

// MARK: - AccountViewModel 完整测试
@MainActor
final class AccountViewModelFullTests: XCTestCase {
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
    
    func testUpdateAccount() throws {
        viewModel.addAccount(name: "旧名", type: .cash, icon: "banknote", balance: 1000)
        viewModel.fetchAccounts()
        
        if let account = viewModel.accounts.first {
            viewModel.updateAccount(account, name: "新名", icon: "wallet.bifold", balance: 2000)
        }
        
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.first?.name, "新名")
        XCTAssertEqual(viewModel.accounts.first?.balance, 2000)
    }
    
    func testUpdateAccountDefault() throws {
        viewModel.addAccount(name: "A", type: .cash, icon: "banknote", balance: 1000, isDefault: true)
        viewModel.addAccount(name: "B", type: .bank, icon: "building.columns", balance: 2000)
        viewModel.fetchAccounts()
        
        if let account = viewModel.accounts.first(where: { $0.name == "B" }) {
            viewModel.updateAccount(account, isDefault: true)
        }
        
        viewModel.fetchAccounts()
        let defaultAccount = viewModel.accounts.first { $0.isDefault }
        XCTAssertEqual(defaultAccount?.name, "B")
    }
    
    func testUpdateBalance() throws {
        viewModel.addAccount(name: "现金", type: .cash, icon: "banknote", balance: 1000)
        viewModel.fetchAccounts()
        
        if let account = viewModel.accounts.first {
            viewModel.updateBalance(for: account, amount: 200, type: .income)
            XCTAssertEqual(account.balance, 1200)
            
            viewModel.updateBalance(for: account, amount: 100, type: .expense)
            XCTAssertEqual(account.balance, 1100)
        }
    }
    
    func testGetDefaultAccount() throws {
        viewModel.addAccount(name: "默认", type: .cash, icon: "banknote", balance: 1000, isDefault: true)
        viewModel.fetchAccounts()
        
        let defaultAccount = viewModel.getDefaultAccount()
        XCTAssertNotNil(defaultAccount)
        XCTAssertEqual(defaultAccount?.name, "默认")
    }
    
    func testGetDefaultAccountNoDefault() throws {
        viewModel.addAccount(name: "A", type: .cash, icon: "banknote", balance: 1000)
        viewModel.fetchAccounts()
        
        let defaultAccount = viewModel.getDefaultAccount()
        XCTAssertNotNil(defaultAccount)
        XCTAssertEqual(defaultAccount?.name, "A")
    }
    
    func testDeleteAccountWithTransactions() throws {
        let account = Account(name: "测试", type: .cash, icon: "banknote", balance: 1000)
        modelContext.insert(account)
        
        let tx = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date(), account: account)
        modelContext.insert(tx)
        try modelContext.save()
        
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.count, 1)
        
        if let acc = viewModel.accounts.first {
            viewModel.deleteAccount(acc)
        }
        
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.count, 0)
        XCTAssertNil(tx.account)
    }
}

// MARK: - DebtViewModel 完整测试
@MainActor
final class DebtViewModelFullTests: XCTestCase {
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
    
    func testAddDebtWithAllFields() throws {
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: dueDate)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.debts.count, 1)
        XCTAssertEqual(viewModel.debts.first?.name, "张三")
        XCTAssertEqual(viewModel.debts.first?.amount, 1000)
        XCTAssertEqual(viewModel.debts.first?.type, .lend)
        XCTAssertEqual(viewModel.debts.first?.note, "借款")
        XCTAssertNotNil(viewModel.debts.first?.dueDate)
        XCTAssertFalse(viewModel.debts.first?.isSettled ?? true)
    }
    
    func testSettleDebtUpdatesTotals() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "李四", amount: 500, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.totalLent, 1500)
        
        if let debt = viewModel.debts.first {
            viewModel.settleDebt(debt)
        }
        
        viewModel.fetchDebts()
        XCTAssertEqual(viewModel.totalLent, 500)
        XCTAssertEqual(viewModel.unsettledDebts.count, 1)
    }
    
    func testDebtsForTypeComplete() throws {
        viewModel.addDebt(name: "借出1", amount: 100, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "借出2", amount: 200, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "借入1", amount: 300, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "借入2", amount: 400, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.debtsForType(.lend).count, 2)
        XCTAssertEqual(viewModel.debtsForType(.borrow).count, 2)
        XCTAssertEqual(viewModel.totalLent, 300)
        XCTAssertEqual(viewModel.totalBorrowed, 700)
    }
}

// MARK: - TagViewModel 完整测试
@MainActor
final class TagViewModelFullTests: XCTestCase {
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
    
    func testAddMultipleTags() throws {
        viewModel.addTag(name: "重要", color: "red")
        viewModel.addTag(name: "工作", color: "blue")
        viewModel.addTag(name: "个人", color: "green")
        viewModel.fetchTags()
        
        XCTAssertEqual(viewModel.tags.count, 3)
    }
    
    func testUpdateTag() throws {
        viewModel.addTag(name: "旧名", color: "red")
        viewModel.fetchTags()
        
        if let tag = viewModel.tags.first {
            viewModel.updateTag(tag, name: "新名", color: "blue")
        }
        
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.first?.name, "新名")
        XCTAssertEqual(viewModel.tags.first?.color, "blue")
    }
    
    func testDeleteTag() throws {
        viewModel.addTag(name: "A", color: "red")
        viewModel.addTag(name: "B", color: "blue")
        viewModel.fetchTags()
        
        if let tag = viewModel.tags.first {
            viewModel.deleteTag(tag)
        }
        
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.count, 1)
    }
}

// MARK: - SavingsGoalViewModel 完整测试
@MainActor
final class SavingsGoalViewModelFullTests: XCTestCase {
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
    
    func testDepositAndWithdraw() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 5000)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.currentAmount, 5000)
            
            viewModel.addDeposit(to: goal, amount: 3000)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.currentAmount, 8000)
            
            viewModel.withdraw(from: goal, amount: 2000)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.currentAmount, 6000)
        }
    }
    
    func testProgressCalculations() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 200, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 100)
            viewModel.fetchGoals()
            XCTAssertEqual(viewModel.goals.first?.progress, 0.5)
            XCTAssertEqual(viewModel.goals.first?.remaining, 100)
        }
    }
    
    func testCompletionTracking() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 100, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 50)
            viewModel.fetchGoals()
            XCTAssertFalse(viewModel.goals.first?.isCompleted ?? true)
            
            viewModel.addDeposit(to: goal, amount: 50)
            viewModel.fetchGoals()
            XCTAssertTrue(viewModel.goals.first?.isCompleted ?? false)
        }
    }
    
    func testOverallProgressMultipleGoals() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 1000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 500)
        }
        if let goal = viewModel.goals.last {
            viewModel.addDeposit(to: goal, amount: 250)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.totalTarget, 2000)
        XCTAssertEqual(viewModel.totalSaved, 750)
        XCTAssertEqual(viewModel.overallProgress, 0.375)
    }
}

// MARK: - RecurringTransactionViewModel 完整测试
@MainActor
final class RecurringTransactionViewModelFullTests: XCTestCase {
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
    
    func testAddWithAllFrequencies() throws {
        let startDate = Date()
        
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "每日", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: startDate, endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 200, type: .expense, category: "交通", note: "每周", frequency: .weekly, dayOfMonth: 1, dayOfWeek: 1, startDate: startDate, endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 300, type: .expense, category: "购物", note: "每月", frequency: .monthly, dayOfMonth: 1, dayOfWeek: 1, startDate: startDate, endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 400, type: .expense, category: "娱乐", note: "每年", frequency: .yearly, dayOfMonth: 1, dayOfWeek: 1, startDate: startDate, endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        XCTAssertEqual(viewModel.recurringTransactions.count, 4)
    }
    
    func testToggleActiveMultiple() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 200, type: .expense, category: "交通", note: "", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        XCTAssertEqual(viewModel.recurringTransactions.filter { $0.isActive }.count, 2)
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.toggleActive(recurring)
        }
        
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.filter { $0.isActive }.count, 1)
    }
    
    func testUpdateRecurringComplete() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "旧备注", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        if let recurring = viewModel.recurringTransactions.first {
            let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            viewModel.updateRecurringTransaction(recurring, amount: 200, type: .income, category: "工资", note: "新备注", frequency: .monthly, dayOfMonth: 15, dayOfWeek: 1, startDate: Date(), endDate: futureDate, isActive: false)
        }
        
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.first?.amount, 200)
        XCTAssertEqual(viewModel.recurringTransactions.first?.type, .income)
        XCTAssertEqual(viewModel.recurringTransactions.first?.category, "工资")
        XCTAssertEqual(viewModel.recurringTransactions.first?.note, "新备注")
        XCTAssertEqual(viewModel.recurringTransactions.first?.frequency, .monthly)
        XCTAssertFalse(viewModel.recurringTransactions.first?.isActive ?? true)
    }
}

// MARK: - CurrencyService 完整测试
@MainActor
final class CurrencyServiceFullTests: XCTestCase {
    func testCurrencyAllProperties() throws {
        for currency in CurrencyService.Currency.all {
            XCTAssertFalse(currency.id.isEmpty)
            XCTAssertFalse(currency.name.isEmpty)
            XCTAssertFalse(currency.symbol.isEmpty)
        }
    }
    
    func testConvertSameCurrency() throws {
        let service = CurrencyService.shared
        XCTAssertEqual(service.convert(100, from: "CNY", to: "CNY"), 100)
    }
    
    func testFormatAmount() throws {
        let service = CurrencyService.shared
        let formatted = service.formatAmount(1234.56, currency: "CNY")
        XCTAssertTrue(formatted.contains("1234.56"))
        XCTAssertTrue(formatted.contains("¥"))
    }
    
    func testFormatAmountUSD() throws {
        let service = CurrencyService.shared
        let formatted = service.formatAmount(100, currency: "USD")
        XCTAssertTrue(formatted.contains("100"))
        XCTAssertTrue(formatted.contains("$"))
    }
    
    func testFormatAmountUnknown() throws {
        let service = CurrencyService.shared
        let formatted = service.formatAmount(100, currency: "XYZ")
        XCTAssertTrue(formatted.contains("100"))
        XCTAssertTrue(formatted.contains("XYZ"))
    }
}

// MARK: - MonthlyReportService 完整测试
@MainActor
final class MonthlyReportServiceFullTests: XCTestCase {
    func testReportWithMultipleTransactions() throws {
        let service = MonthlyReportService.shared
        let transactions = [
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date()),
            Transaction(amount: 3000, type: .income, category: "奖金", note: "", date: Date()),
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 500, type: .expense, category: "交通", note: "", date: Date()),
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        
        XCTAssertEqual(report.totalIncome, 8000)
        XCTAssertEqual(report.totalExpense, 1700)
        XCTAssertEqual(report.balance, 6300)
        XCTAssertEqual(report.transactionCount, 5)
        XCTAssertEqual(report.topCategory, "餐饮")
    }
    
    func testReportEmptyTransactions() throws {
        let service = MonthlyReportService.shared
        let report = service.generateReport(transactions: [], for: Date())
        
        XCTAssertEqual(report.totalIncome, 0)
        XCTAssertEqual(report.totalExpense, 0)
        XCTAssertEqual(report.balance, 0)
        XCTAssertEqual(report.transactionCount, 0)
        XCTAssertNil(report.topCategory)
    }
    
    func testReportSingleTransaction() throws {
        let service = MonthlyReportService.shared
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        
        XCTAssertEqual(report.totalIncome, 0)
        XCTAssertEqual(report.totalExpense, 100)
        XCTAssertEqual(report.balance, -100)
        XCTAssertEqual(report.transactionCount, 1)
        XCTAssertEqual(report.topCategory, "餐饮")
    }
    
    func testReportMultipleCategories() throws {
        let service = MonthlyReportService.shared
        let transactions = [
            Transaction(amount: 30, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 25, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 50, type: .expense, category: "交通", note: "", date: Date()),
            Transaction(amount: 40, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        
        XCTAssertEqual(report.topCategory, "交通")
    }
}

// MARK: - BackupService 完整测试
@MainActor
final class BackupServiceFullTests: XCTestCase {
    func testGetBackupFilesEmpty() throws {
        let files = BackupService.shared.getBackupFiles()
        XCTAssertNotNil(files)
    }
    
    func testDeleteBackupFile() throws {
        let url = URL(fileURLWithPath: "/nonexistent/file.json")
        XCTAssertThrowsError(try BackupService.shared.deleteBackupFile(at: url))
    }
}

// MARK: - ExportService 完整测试
@MainActor
final class ExportServiceFullTests: XCTestCase {
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
    
    func testExportCSVEmpty() throws {
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .csv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "csv")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportJSONEmpty() throws {
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .json)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "json")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportExcelEmpty() throws {
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .excel)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "xls")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportCSVWithData() throws {
        let tx = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .csv)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("餐饮"))
        XCTAssertTrue(content.contains("100"))
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportJSONWithData() throws {
        let tx = Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .json)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? String, "1.0")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testGetExportFiles() throws {
        let files = ExportService.shared.getExportFiles()
        XCTAssertNotNil(files)
    }
    
    func testExportFormatProperties() throws {
        XCTAssertEqual(ExportFormat.csv.rawValue, "CSV")
        XCTAssertEqual(ExportFormat.excel.rawValue, "Excel")
        XCTAssertEqual(ExportFormat.json.rawValue, "JSON")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.excel.fileExtension, "xls")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
    }
}

// MARK: - ImportService 完整测试
@MainActor
final class ImportServiceFullTests: XCTestCase {
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
    
    func testImportCSV() throws {
        let csv = "日期,类型,分类,金额,备注\n2024-01-15,支出,餐饮,35.5,午餐\n2024-01-16,收入,工资,5000,月薪"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 2)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try modelContext.fetch(descriptor)
        XCTAssertEqual(transactions.count, 2)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testImportCSVEmpty() throws {
        let csv = "日期,类型,分类,金额\n"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 0)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testImportCSVInvalidRows() throws {
        let csv = "日期,类型,分类,金额\n2024-01-15,支出,餐饮\n2024-01-16,收入,工资,5000,月薪"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 1)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testSupportedFileTypes() throws {
        let types = ImportService.shared.supportedFileTypes()
        XCTAssertTrue(types.contains("csv"))
        XCTAssertTrue(types.contains("json"))
        XCTAssertTrue(types.contains("txt"))
    }
}

// MARK: - ShareService 完整测试
@MainActor
final class ShareServiceFullTests: XCTestCase {
    func testShareAsTextEmpty() throws {
        let text = ShareService.shared.shareAsText(transactions: [])
        XCTAssertTrue(text.contains("记账本"))
    }
    
    func testShareAsTextWithData() throws {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date()),
        ]
        
        let text = ShareService.shared.shareAsText(transactions: transactions)
        XCTAssertTrue(text.contains("餐饮"))
        XCTAssertTrue(text.contains("工资"))
    }
    
    func testShareAsJSONEmpty() throws {
        let data = ShareService.shared.shareAsJSON(transactions: [])
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        XCTAssertEqual(json?["totalRecords"] as? Int, 0)
    }
    
    func testShareAsJSONWithData() throws {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
        ]
        
        let data = ShareService.shared.shareAsJSON(transactions: transactions)
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        XCTAssertEqual(json?["totalRecords"] as? Int, 1)
    }
    
    func testGenerateShareItems() throws {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let items = ShareService.shared.generateShareItems(transactions: transactions)
        XCTAssertGreaterThanOrEqual(items.count, 1)
    }
}

// MARK: - SampleData 完整测试
@MainActor
final class SampleDataFullTests: XCTestCase {
    func testInsertSampleDataCreatesAllEntities() throws {
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
    }
    
    func testSampleDataAccountBalance() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, configurations: config)
        let context = container.mainContext
        
        SampleData.insertSampleData(modelContext: context)
        
        let accounts = try context.fetch(FetchDescriptor<Account>())
        let defaultAccount = accounts.first { $0.isDefault }
        XCTAssertNotNil(defaultAccount)
    }
}
