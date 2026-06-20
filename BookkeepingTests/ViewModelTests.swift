import XCTest
import SwiftData
@testable import Bookkeeping

@MainActor
final class AccountViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddAccount() throws {
        viewModel.addAccount(name: "支付宝", type: .alipay, icon: "a.circle.fill", balance: 1000)
        viewModel.fetchAccounts()
        
        XCTAssertEqual(viewModel.accounts.count, 1)
        XCTAssertEqual(viewModel.accounts.first?.name, "支付宝")
        XCTAssertEqual(viewModel.accounts.first?.balance, 1000)
    }
    
    func testDeleteAccount() throws {
        viewModel.addAccount(name: "测试账户", type: .other, icon: "wallet.bifold", balance: 500)
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.count, 1)
        
        if let account = viewModel.accounts.first {
            viewModel.deleteAccount(account)
        }
        
        viewModel.fetchAccounts()
        XCTAssertEqual(viewModel.accounts.count, 0)
    }
    
    func testTotalBalance() throws {
        viewModel.addAccount(name: "现金", type: .cash, icon: "banknote", balance: 1000)
        viewModel.addAccount(name: "银行卡", type: .bank, icon: "building.columns", balance: 5000)
        viewModel.fetchAccounts()
        
        XCTAssertEqual(viewModel.totalBalance, 6000)
    }
    
    func testDefaultAccount() throws {
        viewModel.addAccount(name: "默认账户", type: .other, icon: "wallet.bifold", balance: 100, isDefault: true)
        viewModel.fetchAccounts()
        
        let defaultAccount = viewModel.getDefaultAccount()
        XCTAssertNotNil(defaultAccount)
        XCTAssertEqual(defaultAccount?.name, "默认账户")
    }
}

@MainActor
final class DebtViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddDebt() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.debts.count, 1)
        XCTAssertEqual(viewModel.debts.first?.name, "张三")
        XCTAssertEqual(viewModel.debts.first?.amount, 1000)
        XCTAssertEqual(viewModel.debts.first?.type, .lend)
    }
    
    func testSettleDebt() throws {
        viewModel.addDebt(name: "李四", amount: 500, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        if let debt = viewModel.debts.first {
            viewModel.settleDebt(debt)
        }
        
        viewModel.fetchDebts()
        XCTAssertTrue(viewModel.debts.first?.isSettled ?? false)
        XCTAssertNotNil(viewModel.debts.first?.settledDate)
    }
    
    func testDeleteDebt() throws {
        viewModel.addDebt(name: "测试", amount: 100, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        XCTAssertEqual(viewModel.debts.count, 1)
        
        if let debt = viewModel.debts.first {
            viewModel.deleteDebt(debt)
        }
        
        viewModel.fetchDebts()
        XCTAssertEqual(viewModel.debts.count, 0)
    }
    
    func testTotalLent() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "李四", amount: 500, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "王五", amount: 200, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.totalLent, 1500)
    }
    
    func testTotalBorrowed() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "李四", amount: 500, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "王六", amount: 300, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.totalBorrowed, 800)
    }
    
    func testUnsettledDebts() throws {
        viewModel.addDebt(name: "已结清", amount: 100, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "未结清", amount: 200, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        if let firstDebt = viewModel.debts.first(where: { $0.name == "已结清" }) {
            viewModel.settleDebt(firstDebt)
        }
        
        XCTAssertEqual(viewModel.unsettledDebts.count, 1)
        XCTAssertEqual(viewModel.unsettledDebts.first?.name, "未结清")
    }
    
    func testDebtsForType() throws {
        viewModel.addDebt(name: "借出1", amount: 100, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "借入1", amount: 200, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "借出2", amount: 300, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        let lendDebts = viewModel.debtsForType(.lend)
        let borrowDebts = viewModel.debtsForType(.borrow)
        
        XCTAssertEqual(lendDebts.count, 2)
        XCTAssertEqual(borrowDebts.count, 1)
    }
}

@MainActor
final class TagViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddTag() throws {
        viewModel.addTag(name: "重要", color: "red")
        viewModel.fetchTags()
        
        XCTAssertEqual(viewModel.tags.count, 1)
        XCTAssertEqual(viewModel.tags.first?.name, "重要")
        XCTAssertEqual(viewModel.tags.first?.color, "red")
    }
    
    func testUpdateTag() throws {
        viewModel.addTag(name: "旧标签", color: "blue")
        viewModel.fetchTags()
        
        if let tag = viewModel.tags.first {
            viewModel.updateTag(tag, name: "新标签", color: "green")
        }
        
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.first?.name, "新标签")
        XCTAssertEqual(viewModel.tags.first?.color, "green")
    }
    
    func testDeleteTag() throws {
        viewModel.addTag(name: "测试", color: "blue")
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.count, 1)
        
        if let tag = viewModel.tags.first {
            viewModel.deleteTag(tag)
        }
        
        viewModel.fetchTags()
        XCTAssertEqual(viewModel.tags.count, 0)
    }
}

@MainActor
final class LedgerViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddLedger() throws {
        viewModel.addLedger(name: "旅行账本", icon: "airplane", color: "orange")
        viewModel.fetchLedgers()
        
        XCTAssertEqual(viewModel.ledgers.count, 1)
        XCTAssertEqual(viewModel.ledgers.first?.name, "旅行账本")
    }
    
    func testDeleteLedger() throws {
        viewModel.addLedger(name: "测试账本", icon: "folder", color: "gray")
        viewModel.fetchLedgers()
        XCTAssertEqual(viewModel.ledgers.count, 1)
        
        if let ledger = viewModel.ledgers.first {
            viewModel.deleteLedger(ledger)
        }
        
        viewModel.fetchLedgers()
        XCTAssertEqual(viewModel.ledgers.count, 0)
    }
}

@MainActor
final class BillReminderViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddReminder() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "电费", amount: 200, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.reminders.count, 1)
        XCTAssertEqual(viewModel.reminders.first?.title, "电费")
        XCTAssertEqual(viewModel.reminders.first?.amount, 200)
    }
    
    func testMarkAsPaid() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "水费", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.markAsPaid(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertTrue(viewModel.reminders.first?.isPaid ?? false)
    }
    
    func testUpcomingReminders() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.addReminder(title: "即将到期", amount: 100, dueDate: soonDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "很久以后", amount: 200, dueDate: laterDate, repeatFrequency: .yearly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.upcomingReminders.count, 2)
        XCTAssertEqual(viewModel.upcomingReminders.first?.title, "即将到期")
    }
}

@MainActor
final class RecurringTransactionViewModelTests: XCTestCase {
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
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddRecurringTransaction() throws {
        viewModel.addRecurringTransaction(
            amount: 3000,
            type: .expense,
            category: "住房",
            note: "房租",
            frequency: .monthly,
            dayOfMonth: 1,
            dayOfWeek: 1,
            startDate: Date(),
            endDate: nil,
            account: nil
        )
        viewModel.fetchRecurringTransactions()
        
        XCTAssertEqual(viewModel.recurringTransactions.count, 1)
        XCTAssertEqual(viewModel.recurringTransactions.first?.amount, 3000)
        XCTAssertEqual(viewModel.recurringTransactions.first?.frequency, .monthly)
    }
    
    func testDeleteRecurringTransaction() throws {
        viewModel.addRecurringTransaction(
            amount: 100,
            type: .expense,
            category: "餐饮",
            note: "",
            frequency: .weekly,
            dayOfMonth: 1,
            dayOfWeek: 1,
            startDate: Date(),
            endDate: nil,
            account: nil
        )
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.count, 1)
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.deleteRecurringTransaction(recurring)
        }
        
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.count, 0)
    }
    
    func testToggleActive() throws {
        viewModel.addRecurringTransaction(
            amount: 50,
            type: .expense,
            category: "娱乐",
            note: "",
            frequency: .daily,
            dayOfMonth: 1,
            dayOfWeek: 1,
            startDate: Date(),
            endDate: nil,
            account: nil
        )
        viewModel.fetchRecurringTransactions()
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.toggleActive(recurring)
            viewModel.fetchRecurringTransactions()
            XCTAssertFalse(viewModel.recurringTransactions.first?.isActive ?? true)
            
            viewModel.toggleActive(recurring)
            viewModel.fetchRecurringTransactions()
            XCTAssertTrue(viewModel.recurringTransactions.first?.isActive ?? false)
        }
    }
}
