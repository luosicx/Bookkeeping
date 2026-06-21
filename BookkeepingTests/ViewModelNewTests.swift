import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - TransactionViewModel 新方法测试
@MainActor
final class TransactionViewModelNewTests: XCTestCase {
    var viewModel: TransactionViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = TransactionViewModel()
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    func testFilterTransactionsByType() throws {
        addSampleTransactions()
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: .income, searchText: "", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        
        viewModel.filterTransactions(type: .expense, searchText: "", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 2)
    }
    
    func testFilterTransactionsBySearchText() throws {
        addSampleTransactions()
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "午餐", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.first?.note, "午餐")
    }
    
    func testFilterTransactionsByDate() throws {
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "本月", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "上月", date: lastMonth)
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.first?.note, "本月")
    }
    
    func testFilterTransactionsByLedger() throws {
        let ledger = Ledger(name: "旅行", icon: "airplane", color: "orange")
        modelContext.insert(ledger)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date(), ledger: ledger)
        viewModel.addTransaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: ledger)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
    }
    
    func testCalculateFilteredTotals() throws {
        viewModel.addTransaction(amount: 5000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: nil)
        
        XCTAssertEqual(viewModel.filteredTotalIncome, 5000)
        XCTAssertEqual(viewModel.filteredTotalExpense, 100)
        XCTAssertEqual(viewModel.filteredBalance, 4900)
    }
    
    func testCategoryData() throws {
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let data = viewModel.categoryData(for: Date())
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0].0, "交通")
        XCTAssertEqual(data[0].1, 200)
        XCTAssertEqual(data[1].0, "餐饮")
        XCTAssertEqual(data[1].1, 150)
    }
    
    func testDailyData() throws {
        let today = Date()
        viewModel.addTransaction(amount: 100, type: .income, category: "工资", note: "", date: today)
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: today)
        viewModel.fetchTransactions()
        
        let data = viewModel.dailyData(for: today)
        XCTAssertEqual(data.count, 2)
    }
    
    func testTopCategories() throws {
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top.count, 2)
        XCTAssertEqual(top[0].0, "交通")
        XCTAssertEqual(top[0].1, 200)
        XCTAssertEqual(top[0].2, 1)
    }
    
    func testEmptyFilters() throws {
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: nil)
        XCTAssertEqual(viewModel.filteredTransactions.count, 0)
        XCTAssertEqual(viewModel.filteredTotalIncome, 0)
        XCTAssertEqual(viewModel.filteredTotalExpense, 0)
        XCTAssertEqual(viewModel.filteredBalance, 0)
    }
    
    private func addSampleTransactions() {
        viewModel.addTransaction(amount: 5000, type: .income, category: "工资", note: "工资", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        viewModel.addTransaction(amount: 50, type: .expense, category: "交通", note: "地铁", date: Date())
    }
}

// MARK: - StatisticsViewModel 测试
@MainActor
final class StatisticsViewModelTests: XCTestCase {
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
    
    func testFetchTransactions() throws {
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(transaction)
        try modelContext.save()
        
        viewModel.fetchTransactions()
        XCTAssertEqual(viewModel.transactions.count, 1)
    }
    
    func testTransactionsForMonth() throws {
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        
        addTransactions([
            (100, TransactionType.expense, "餐饮", today),
            (200, TransactionType.expense, "交通", lastMonth),
        ])
        
        let thisMonth = viewModel.transactionsForMonth(today)
        let lastMonthTxns = viewModel.transactionsForMonth(lastMonth)
        
        XCTAssertEqual(thisMonth.count, 1)
        XCTAssertEqual(lastMonthTxns.count, 1)
    }
    
    func testTotalIncomeForMonth() throws {
        addTransactions([
            (5000, TransactionType.income, "工资", Date()),
            (1000, TransactionType.income, "奖金", Date()),
            (200, TransactionType.expense, "餐饮", Date()),
        ])
        
        XCTAssertEqual(viewModel.totalIncomeForMonth(Date()), 6000)
    }
    
    func testTotalExpenseForMonth() throws {
        addTransactions([
            (5000, TransactionType.income, "工资", Date()),
            (200, TransactionType.expense, "餐饮", Date()),
            (100, TransactionType.expense, "交通", Date()),
        ])
        
        XCTAssertEqual(viewModel.totalExpenseForMonth(Date()), 300)
    }
    
    func testBalanceForMonth() throws {
        addTransactions([
            (5000, TransactionType.income, "工资", Date()),
            (200, TransactionType.expense, "餐饮", Date()),
        ])
        
        XCTAssertEqual(viewModel.balanceForMonth(Date()), 4800)
    }
    
    func testCategoryDataEmpty() throws {
        let data = viewModel.categoryData(for: Date())
        XCTAssertTrue(data.isEmpty)
    }
    
    func testCategoryDataWithData() throws {
        addTransactions([
            (100, TransactionType.expense, "餐饮", Date()),
            (200, TransactionType.expense, "交通", Date()),
            (50, TransactionType.expense, "餐饮", Date()),
        ])
        
        let data = viewModel.categoryData(for: Date())
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0].0, "交通")
        XCTAssertEqual(data[1].0, "餐饮")
    }
    
    func testDailyDataEmpty() throws {
        let data = viewModel.dailyData(for: Date())
        XCTAssertTrue(data.isEmpty)
    }
    
    func testDailyDataWithData() throws {
        addTransactions([
            (100, TransactionType.income, "工资", Date()),
            (50, TransactionType.expense, "餐饮", Date()),
        ])
        
        let data = viewModel.dailyData(for: Date())
        XCTAssertEqual(data.count, 2)
    }
    
    func testTopCategoriesEmpty() throws {
        let top = viewModel.topCategories(for: Date())
        XCTAssertTrue(top.isEmpty)
    }
    
    func testTopCategoriesWithData() throws {
        addTransactions([
            (100, TransactionType.expense, "餐饮", Date()),
            (200, TransactionType.expense, "交通", Date()),
        ])
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top.count, 2)
        XCTAssertEqual(top[0].0, "交通")
    }
    
    func testTopCategoriesSorted() throws {
        addTransactions([
            (100, TransactionType.expense, "餐饮", Date()),
            (200, TransactionType.expense, "交通", Date()),
            (50, TransactionType.expense, "餐饮", Date()),
        ])
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top[0].1, 200)
        XCTAssertEqual(top[1].1, 150)
    }
    
    private func addTransactions(_ data: [(Double, TransactionType, String, Date)]) {
        for (amount, type, category, date) in data {
            let transaction = Transaction(amount: amount, type: type, category: category, note: "", date: date)
            modelContext.insert(transaction)
        }
        try? modelContext.save()
        viewModel.fetchTransactions()
    }
}

// MARK: - EditTransactionViewModel 测试
@MainActor
final class EditTransactionViewModelTests: XCTestCase {
    func testLoadFromTransaction() throws {
        let viewModel = EditTransactionViewModel()
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        
        viewModel.loadFromTransaction(transaction)
        
        XCTAssertEqual(viewModel.amount, "100.00")
        XCTAssertEqual(viewModel.type, .expense)
        XCTAssertEqual(viewModel.note, "午餐")
    }
    
    func testIsValid() throws {
        let viewModel = EditTransactionViewModel()
        
        viewModel.amount = "100"
        viewModel.selectedCategoryId = "food"
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.amount = ""
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "100"
        viewModel.selectedCategoryId = nil
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testSaveChanges() throws {
        let viewModel = EditTransactionViewModel()
        let transaction = Transaction(amount: 50, type: .income, category: "工资", note: "", date: Date())
        
        viewModel.amount = "200"
        viewModel.type = .expense
        viewModel.note = "新备注"
        viewModel.loadFromTransaction(transaction)
        
        viewModel.amount = "200"
        viewModel.saveChanges(transaction: transaction)
        
        XCTAssertEqual(transaction.amount, 200)
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(transaction.note, "新备注")
    }
    
    func testSelectedCategory() throws {
        let viewModel = EditTransactionViewModel()
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        
        XCTAssertNotNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.selectedCategory?.id, "food")
    }
    
    func testResetCategory() throws {
        let viewModel = EditTransactionViewModel()
        viewModel.selectedCategoryId = "food"
        XCTAssertNotNil(viewModel.selectedCategoryId)
    }
}

// MARK: - AddTransactionFormViewModel 测试
@MainActor
final class AddTransactionFormViewModelTests: XCTestCase {
    var viewModel: AddTransactionFormViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = AddTransactionFormViewModel()
        let config = ModelConfiguration(
            schema: Schema([Account.self, Tag.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Account.self, Tag.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    func testIsValid() throws {
        viewModel.amount = "100"
        viewModel.selectedCategoryId = "food"
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.amount = ""
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "100"
        viewModel.selectedCategoryId = nil
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testSelectedCategory() throws {
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        XCTAssertNotNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.selectedCategory?.id, "food")
    }
    
    func testLoadAccounts() throws {
        let account = Account(name: "支付宝", icon: "a.circle.fill", type: .alipay, balance: 1000)
        modelContext.insert(account)
        try modelContext.save()
        
        viewModel.loadAccounts(modelContext: modelContext)
        XCTAssertEqual(viewModel.accounts.count, 1)
        XCTAssertEqual(viewModel.accounts.first?.name, "支付宝")
    }
    
    func testLoadTags() throws {
        let tag = Tag(name: "重要", color: "red")
        modelContext.insert(tag)
        try modelContext.save()
        
        viewModel.loadTags(modelContext: modelContext)
        XCTAssertEqual(viewModel.availableTags.count, 1)
        XCTAssertEqual(viewModel.availableTags.first?.name, "重要")
    }
    
    func testResetCategory() throws {
        viewModel.selectedCategoryId = "food"
        viewModel.resetCategory()
        XCTAssertNil(viewModel.selectedCategoryId)
    }
    
    func testSaveTransaction() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 1000)
        modelContext.insert(account)
        try modelContext.save()
        
        viewModel.amount = "100"
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        viewModel.note = "午餐"
        viewModel.selectedAccount = account
        
        let txViewModel = TransactionViewModel()
        txViewModel.modelContext = modelContext
        
        viewModel.saveTransaction(viewModel: txViewModel)
        
        txViewModel.fetchTransactions()
        XCTAssertEqual(txViewModel.transactions.count, 1)
        XCTAssertEqual(txViewModel.transactions.first?.amount, 100)
    }
}
