import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - TransactionViewModel 完整测试
@MainActor
final class TransactionViewModelCompleteTests: XCTestCase {
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
    
    func testAddTransactionWithAccount() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 1000)
        modelContext.insert(account)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date(), account: account)
        
        XCTAssertEqual(account.balance, 900)
        XCTAssertEqual(viewModel.transactions.count, 1)
    }
    
    func testAddIncomeTransactionWithAccount() throws {
        let account = Account(name: "银行卡", icon: "building.columns", type: .bank, balance: 5000)
        modelContext.insert(account)
        
        viewModel.addTransaction(amount: 3000, type: .income, category: "工资", note: "", date: Date(), account: account)
        
        XCTAssertEqual(account.balance, 8000)
    }
    
    func testDeleteTransactionWithAccount() throws {
        let account = Account(name: "现金", icon: "banknote", type: .cash, balance: 1000)
        modelContext.insert(account)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date(), account: account)
        XCTAssertEqual(account.balance, 900)
        
        if let transaction = viewModel.transactions.first {
            viewModel.deleteTransaction(transaction)
        }
        
        XCTAssertEqual(account.balance, 1000)
    }
    
    func testDeleteIncomeTransactionWithAccount() throws {
        let account = Account(name: "银行卡", icon: "building.columns", type: .bank, balance: 5000)
        modelContext.insert(account)
        
        viewModel.addTransaction(amount: 3000, type: .income, category: "工资", note: "", date: Date(), account: account)
        XCTAssertEqual(account.balance, 8000)
        
        if let transaction = viewModel.transactions.first {
            viewModel.deleteTransaction(transaction)
        }
        
        XCTAssertEqual(account.balance, 5000)
    }
    
    func testAddTransactionWithLedger() throws {
        let ledger = Ledger(name: "旅行", icon: "airplane", color: "orange")
        modelContext.insert(ledger)
        
        viewModel.addTransaction(amount: 500, type: .expense, category: "住宿", note: "酒店", date: Date(), ledger: ledger)
        
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.ledger?.name, "旅行")
    }
    
    func testAddTransactionWithTags() throws {
        let tag1 = Tag(name: "重要", color: "red")
        let tag2 = Tag(name: "工作", color: "blue")
        modelContext.insert(tag1)
        modelContext.insert(tag2)
        
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date(), tags: [tag1, tag2])
        
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.tags?.count, 2)
    }
    
    func testFilterTransactionsCombined() throws {
        let ledger = Ledger(name: "个人", icon: "person", color: "blue")
        modelContext.insert(ledger)
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date(), ledger: ledger)
        viewModel.addTransaction(amount: 200, type: .income, category: "工资", note: "", date: Date(), ledger: ledger)
        viewModel.addTransaction(amount: 300, type: .expense, category: "交通", note: "打车", date: Date())
        
        viewModel.fetchTransactions()
        
        viewModel.filterTransactions(type: .expense, searchText: "午餐", date: Date(), ledger: ledger)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.first?.note, "午餐")
    }
    
    func testCategoryDataSorted() throws {
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "交通", note: "", date: Date())
        viewModel.addTransaction(amount: 30, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let data = viewModel.categoryData(for: Date())
        XCTAssertEqual(data[0].1, 100)
        XCTAssertEqual(data[1].1, 80)
    }
    
    func testDailyDataMultipleDays() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        viewModel.addTransaction(amount: 100, type: .income, category: "工资", note: "", date: today)
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: today)
        viewModel.addTransaction(amount: 200, type: .income, category: "奖金", note: "", date: yesterday)
        viewModel.fetchTransactions()
        
        let data = viewModel.dailyData(for: today)
        XCTAssertEqual(data.count, 4)
    }
    
    func testTopCategoriesWithTies() throws {
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "交通", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top.count, 2)
    }
    
    func testMonthlyIncomeExpense() throws {
        viewModel.addTransaction(amount: 5000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 1000, type: .income, category: "奖金", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "交通", note: "", date: Date())
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.totalIncome, 6000)
        XCTAssertEqual(viewModel.totalExpense, 300)
        XCTAssertEqual(viewModel.balance, 5700)
        XCTAssertEqual(viewModel.totalIncomeForMonth(Date()), 6000)
        XCTAssertEqual(viewModel.totalExpenseForMonth(Date()), 300)
        XCTAssertEqual(viewModel.balanceForMonth(Date()), 5700)
    }
    
    func testFilteredTransactionsByType() throws {
        viewModel.addTransaction(amount: 100, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.fetchTransactions()
        
        let incomeOnly = viewModel.filteredTransactions(by: .income)
        let expenseOnly = viewModel.filteredTransactions(by: .expense)
        let all = viewModel.filteredTransactions(by: nil)
        
        XCTAssertEqual(incomeOnly.count, 1)
        XCTAssertEqual(expenseOnly.count, 1)
        XCTAssertEqual(all.count, 2)
    }
    
    func testTransactionsForMonthDifferentMonths() throws {
        let calendar = Calendar.current
        let thisMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: Date())!
        
        viewModel.addTransaction(amount: 100, type: .expense, category: "餐饮", note: "", date: thisMonth)
        viewModel.addTransaction(amount: 200, type: .expense, category: "交通", note: "", date: lastMonth)
        viewModel.addTransaction(amount: 300, type: .expense, category: "购物", note: "", date: twoMonthsAgo)
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.transactionsForMonth(thisMonth).count, 1)
        XCTAssertEqual(viewModel.transactionsForMonth(lastMonth).count, 1)
        XCTAssertEqual(viewModel.transactionsForMonth(twoMonthsAgo).count, 1)
    }
}

// MARK: - StatisticsViewModel 完整测试
@MainActor
final class StatisticsViewModelCompleteTests: XCTestCase {
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
    
    func testFetchEmptyTransactions() throws {
        viewModel.fetchTransactions()
        XCTAssertTrue(viewModel.transactions.isEmpty)
    }
    
    func testTransactionsForMonthEmpty() throws {
        let result = viewModel.transactionsForMonth(Date())
        XCTAssertTrue(result.isEmpty)
    }
    
    func testMonthlyStatsEmpty() throws {
        XCTAssertEqual(viewModel.totalIncomeForMonth(Date()), 0)
        XCTAssertEqual(viewModel.totalExpenseForMonth(Date()), 0)
        XCTAssertEqual(viewModel.balanceForMonth(Date()), 0)
    }
    
    func testMonthlyStatsWithIncome() throws {
        let tx = Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.totalIncomeForMonth(Date()), 5000)
        XCTAssertEqual(viewModel.totalExpenseForMonth(Date()), 0)
        XCTAssertEqual(viewModel.balanceForMonth(Date()), 5000)
    }
    
    func testMonthlyStatsWithExpense() throws {
        let tx = Transaction(amount: 500, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.totalIncomeForMonth(Date()), 0)
        XCTAssertEqual(viewModel.totalExpenseForMonth(Date()), 500)
        XCTAssertEqual(viewModel.balanceForMonth(Date()), -500)
    }
    
    func testCategoryDataSingleCategory() throws {
        let tx = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let data = viewModel.categoryData(for: Date())
        XCTAssertEqual(data.count, 1)
        XCTAssertEqual(data[0].0, "餐饮")
        XCTAssertEqual(data[0].1, 100)
    }
    
    func testCategoryDataMultipleCategories() throws {
        let tx1 = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        let tx2 = Transaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        let tx3 = Transaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        modelContext.insert(tx3)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let data = viewModel.categoryData(for: Date())
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0].0, "交通")
        XCTAssertEqual(data[0].1, 200)
        XCTAssertEqual(data[1].0, "餐饮")
        XCTAssertEqual(data[1].1, 150)
    }
    
    func testDailyDataSingleDay() throws {
        let tx1 = Transaction(amount: 100, type: .income, category: "工资", note: "", date: Date())
        let tx2 = Transaction(amount: 50, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let data = viewModel.dailyData(for: Date())
        XCTAssertEqual(data.count, 2)
    }
    
    func testDailyDataMultipleDays() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let tx1 = Transaction(amount: 100, type: .income, category: "工资", note: "", date: today)
        let tx2 = Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: yesterday)
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let data = viewModel.dailyData(for: today)
        XCTAssertTrue(data.count >= 2)
    }
    
    func testTopCategoriesEmpty() throws {
        let top = viewModel.topCategories(for: Date())
        XCTAssertTrue(top.isEmpty)
    }
    
    func testTopCategoriesSingleCategory() throws {
        let tx = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        modelContext.insert(tx)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top.count, 1)
        XCTAssertEqual(top[0].0, "餐饮")
        XCTAssertEqual(top[0].1, 100)
        XCTAssertEqual(top[0].2, 1)
    }
    
    func testTopCategoriesMultipleWithCount() throws {
        let tx1 = Transaction(amount: 30, type: .expense, category: "餐饮", note: "", date: Date())
        let tx2 = Transaction(amount: 25, type: .expense, category: "餐饮", note: "", date: Date())
        let tx3 = Transaction(amount: 50, type: .expense, category: "交通", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        modelContext.insert(tx3)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top.count, 2)
        
        let foodCategory = top.first { $0.0 == "餐饮" }
        XCTAssertEqual(foodCategory?.1, 55)
        XCTAssertEqual(foodCategory?.2, 2)
        
        let transportCategory = top.first { $0.0 == "交通" }
        XCTAssertEqual(transportCategory?.1, 50)
        XCTAssertEqual(transportCategory?.2, 1)
    }
    
    func testTopCategoriesSorted() throws {
        let tx1 = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        let tx2 = Transaction(amount: 200, type: .expense, category: "交通", note: "", date: Date())
        let tx3 = Transaction(amount: 50, type: .expense, category: "购物", note: "", date: Date())
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        modelContext.insert(tx3)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        let top = viewModel.topCategories(for: Date())
        XCTAssertEqual(top[0].1, 200)
        XCTAssertEqual(top[1].1, 100)
        XCTAssertEqual(top[2].1, 50)
    }
    
    func testTransactionsForMonthWithDifferentMonths() throws {
        let calendar = Calendar.current
        let thisMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        let tx1 = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: thisMonth)
        let tx2 = Transaction(amount: 200, type: .expense, category: "交通", note: "", date: lastMonth)
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        try modelContext.save()
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.transactionsForMonth(thisMonth).count, 1)
        XCTAssertEqual(viewModel.transactionsForMonth(lastMonth).count, 1)
    }
}

// MARK: - EditTransactionViewModel 完整测试
@MainActor
final class EditTransactionViewModelCompleteTests: XCTestCase {
    func testLoadFromTransactionAllFields() throws {
        let viewModel = EditTransactionViewModel()
        let transaction = Transaction(amount: 150.50, type: .income, category: "奖金", note: "年终奖", date: Date())
        
        viewModel.loadFromTransaction(transaction)
        
        XCTAssertEqual(viewModel.amount, "150.50")
        XCTAssertEqual(viewModel.type, .income)
        XCTAssertEqual(viewModel.note, "年终奖")
    }
    
    func testLoadFromTransactionWithCategory() throws {
        let viewModel = EditTransactionViewModel()
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date())
        
        viewModel.loadFromTransaction(transaction)
        
        XCTAssertNotNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.selectedCategory?.id, "food")
    }
    
    func testIsValidVariousStates() throws {
        let viewModel = EditTransactionViewModel()
        
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "100"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.selectedCategoryId = "food"
        XCTAssertTrue(viewModel.isValid)
        
        viewModel.amount = "0"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "-100"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.amount = "abc"
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testSaveChanges() throws {
        let viewModel = EditTransactionViewModel()
        let transaction = Transaction(amount: 50, type: .income, category: "工资", note: "旧备注", date: Date())
        
        viewModel.amount = "200"
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        viewModel.note = "新备注"
        
        viewModel.saveChanges(transaction: transaction)
        
        XCTAssertEqual(transaction.amount, 200)
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(transaction.category, "餐饮")
        XCTAssertEqual(transaction.note, "新备注")
    }
    
    func testSelectedCategory() throws {
        let viewModel = EditTransactionViewModel()
        
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        XCTAssertEqual(viewModel.selectedCategory?.id, "food")
        
        viewModel.type = .income
        viewModel.selectedCategoryId = "salary"
        XCTAssertEqual(viewModel.selectedCategory?.id, "salary")
        
        viewModel.selectedCategoryId = nil
        XCTAssertNil(viewModel.selectedCategory)
    }
}

// MARK: - AddTransactionFormViewModel 完整测试
@MainActor
final class AddTransactionFormViewModelCompleteTests: XCTestCase {
    var viewModel: AddTransactionFormViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = AddTransactionFormViewModel()
        let config = ModelConfiguration(
            schema: Schema([Account.self, Tag.self, Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Account.self, Tag.self, Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    func testDefaultValues() throws {
        XCTAssertEqual(viewModel.amount, "")
        XCTAssertEqual(viewModel.type, .expense)
        XCTAssertNil(viewModel.selectedCategoryId)
        XCTAssertEqual(viewModel.note, "")
        XCTAssertNil(viewModel.selectedAccount)
        XCTAssertNil(viewModel.selectedLedger)
        XCTAssertTrue(viewModel.selectedTags.isEmpty)
        XCTAssertTrue(viewModel.accounts.isEmpty)
        XCTAssertTrue(viewModel.availableTags.isEmpty)
    }
    
    func testIsValidEmpty() throws {
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testIsValidWithAmountOnly() throws {
        viewModel.amount = "100"
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testIsValidWithCategoryOnly() throws {
        viewModel.selectedCategoryId = "food"
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testIsValidComplete() throws {
        viewModel.amount = "100"
        viewModel.selectedCategoryId = "food"
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testIsValidZeroAmount() throws {
        viewModel.amount = "0"
        viewModel.selectedCategoryId = "food"
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testIsValidNegativeAmount() throws {
        viewModel.amount = "-100"
        viewModel.selectedCategoryId = "food"
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testSelectedCategory() throws {
        viewModel.type = .expense
        viewModel.selectedCategoryId = "food"
        XCTAssertNotNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.selectedCategory?.id, "food")
        
        viewModel.type = .income
        viewModel.selectedCategoryId = "salary"
        XCTAssertNotNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.selectedCategory?.id, "salary")
    }
    
    func testLoadAccounts() throws {
        let account1 = Account(name: "现金", icon: "banknote", type: .cash, balance: 1000)
        let account2 = Account(name: "银行卡", icon: "building.columns", type: .bank, balance: 5000)
        modelContext.insert(account1)
        modelContext.insert(account2)
        try modelContext.save()
        
        viewModel.loadAccounts(modelContext: modelContext)
        
        XCTAssertEqual(viewModel.accounts.count, 2)
    }
    
    func testLoadTags() throws {
        let tag1 = Tag(name: "重要", color: "red")
        let tag2 = Tag(name: "工作", color: "blue")
        modelContext.insert(tag1)
        modelContext.insert(tag2)
        try modelContext.save()
        
        viewModel.loadTags(modelContext: modelContext)
        
        XCTAssertEqual(viewModel.availableTags.count, 2)
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
        XCTAssertEqual(txViewModel.transactions.first?.category, "餐饮")
        XCTAssertEqual(txViewModel.transactions.first?.note, "午餐")
    }
    
    func testSaveTransactionWithTags() throws {
        let tag = Tag(name: "重要", color: "red")
        modelContext.insert(tag)
        try modelContext.save()
        
        viewModel.amount = "200"
        viewModel.type = .income
        viewModel.selectedCategoryId = "salary"
        viewModel.note = ""
        viewModel.selectedTags = [tag]
        
        let txViewModel = TransactionViewModel()
        txViewModel.modelContext = modelContext
        
        viewModel.saveTransaction(viewModel: txViewModel)
        
        txViewModel.fetchTransactions()
        XCTAssertEqual(txViewModel.transactions.count, 1)
        XCTAssertEqual(txViewModel.transactions.first?.tags?.count, 1)
    }
}

// MARK: - BudgetViewModel 完整测试
@MainActor
final class BudgetViewModelCompleteTests: XCTestCase {
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
    
    func testAddMultipleBudgets() throws {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.addBudget(category: "交通", amount: 1000)
        viewModel.addBudget(category: "购物", amount: 3000)
        viewModel.fetchBudgets()
        
        XCTAssertEqual(viewModel.budgets.count, 3)
        XCTAssertEqual(viewModel.totalBudget, 6000)
    }
    
    func testUpdateBudget() throws {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.fetchBudgets()
        
        viewModel.addBudget(category: "餐饮", amount: 3000)
        viewModel.fetchBudgets()
        
        XCTAssertEqual(viewModel.budgets.count, 1)
        XCTAssertEqual(viewModel.budgets.first?.amount, 3000)
    }
    
    func testDeleteBudget() throws {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.addBudget(category: "交通", amount: 1000)
        viewModel.fetchBudgets()
        
        if let budget = viewModel.budgets.first {
            viewModel.deleteBudget(budget)
        }
        
        viewModel.fetchBudgets()
        XCTAssertEqual(viewModel.budgets.count, 1)
    }
    
    func testSetOverallBudget() throws {
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchOverallBudget()
        
        XCTAssertEqual(viewModel.overallBudgets.count, 1)
        XCTAssertEqual(viewModel.overallBudgets.first?.amount, 5000)
    }
    
    func testUpdateOverallBudget() throws {
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchOverallBudget()
        
        viewModel.setOverallBudget(amount: 8000)
        viewModel.fetchOverallBudget()
        
        XCTAssertEqual(viewModel.overallBudgets.count, 1)
        XCTAssertEqual(viewModel.overallBudgets.first?.amount, 8000)
    }
    
    func testGetBudgetStatus() throws {
        viewModel.addBudget(category: "餐饮", amount: 1000)
        viewModel.fetchBudgets()
        
        let transactions = [
            Transaction(amount: 300, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let status = viewModel.getBudgetStatus(for: "餐饮", transactions: transactions)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.spent, 500)
        XCTAssertEqual(status?.remaining, 500)
    }
    
    func testGetBudgetStatusNoBudget() throws {
        viewModel.fetchBudgets()
        let status = viewModel.getBudgetStatus(for: "不存在", transactions: [])
        XCTAssertNil(status)
    }
    
    func testGetOverallBudgetStatus() throws {
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchOverallBudget()
        
        let transactions = [
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 500, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let status = viewModel.getOverallBudgetStatus(transactions: transactions)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.spent, 1500)
    }
    
    func testGetOverallBudgetStatusNoBudget() throws {
        viewModel.fetchOverallBudget()
        let status = viewModel.getOverallBudgetStatus(transactions: [])
        XCTAssertNil(status)
    }
    
    func testGetAllBudgetStatus() throws {
        viewModel.addBudget(category: "餐饮", amount: 1000)
        viewModel.addBudget(category: "交通", amount: 500)
        viewModel.fetchBudgets()
        
        let transactions = [
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 50, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let statuses = viewModel.getAllBudgetStatus(transactions: transactions)
        XCTAssertEqual(statuses.count, 2)
    }
    
    func testGetAllBudgetStatusEmpty() throws {
        viewModel.fetchBudgets()
        let statuses = viewModel.getAllBudgetStatus(transactions: [])
        XCTAssertEqual(statuses.count, 0)
    }
    
    func testTotalBudget() throws {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.addBudget(category: "交通", amount: 1000)
        viewModel.addBudget(category: "购物", amount: 3000)
        viewModel.fetchBudgets()
        
        XCTAssertEqual(viewModel.totalBudget, 6000)
    }
}

// MARK: - DebtViewModel 完整测试
@MainActor
final class DebtViewModelCompleteTests: XCTestCase {
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
    
    func testAddMultipleDebts() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "李四", amount: 500, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "王五", amount: 200, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        XCTAssertEqual(viewModel.debts.count, 3)
        XCTAssertEqual(viewModel.totalLent, 1200)
        XCTAssertEqual(viewModel.totalBorrowed, 500)
    }
    
    func testSettleDebt() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        if let debt = viewModel.debts.first {
            viewModel.settleDebt(debt)
        }
        
        viewModel.fetchDebts()
        XCTAssertTrue(viewModel.debts.first?.isSettled ?? false)
        XCTAssertNotNil(viewModel.debts.first?.settledDate)
    }
    
    func testDeleteDebt() throws {
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "", date: Date(), dueDate: nil)
        viewModel.addDebt(name: "李四", amount: 500, type: .borrow, note: "", date: Date(), dueDate: nil)
        viewModel.fetchDebts()
        
        if let debt = viewModel.debts.first {
            viewModel.deleteDebt(debt)
        }
        
        viewModel.fetchDebts()
        XCTAssertEqual(viewModel.debts.count, 1)
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
        
        XCTAssertEqual(viewModel.debtsForType(.lend).count, 2)
        XCTAssertEqual(viewModel.debtsForType(.borrow).count, 1)
    }
    
    func testAddDebtWithDueDate() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        viewModel.addDebt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: futureDate)
        viewModel.fetchDebts()
        
        XCTAssertNotNil(viewModel.debts.first?.dueDate)
        XCTAssertEqual(viewModel.debts.first?.note, "借款")
    }
}

// MARK: - SavingsGoalViewModel 完整测试
@MainActor
final class SavingsGoalViewModelCompleteTests: XCTestCase {
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
    
    func testAddMultipleGoals() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.addGoal(name: "买车", icon: "car", targetAmount: 100000, deadline: nil)
        viewModel.fetchGoals()
        
        XCTAssertEqual(viewModel.goals.count, 2)
        XCTAssertEqual(viewModel.totalTarget, 110000)
    }
    
    func testUpdateGoal() throws {
        viewModel.addGoal(name: "旧名", icon: "target", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.updateGoal(goal, name: "新名", icon: "star", targetAmount: 2000)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.name, "新名")
        XCTAssertEqual(viewModel.goals.first?.icon, "star")
        XCTAssertEqual(viewModel.goals.first?.targetAmount, 2000)
    }
    
    func testDeleteGoal() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 1000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 2000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.deleteGoal(goal)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.count, 1)
    }
    
    func testAddDeposit() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 5000)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.currentAmount, 5000)
        XCTAssertEqual(viewModel.goals.first?.progress, 0.5)
    }
    
    func testAddDepositComplete() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 15000)
        }
        
        viewModel.fetchGoals()
        XCTAssertTrue(viewModel.goals.first?.isCompleted ?? false)
        XCTAssertEqual(viewModel.goals.first?.progress, 1.0)
    }
    
    func testWithdraw() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 5000)
            viewModel.withdraw(from: goal, amount: 2000)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.currentAmount, 3000)
        XCTAssertFalse(viewModel.goals.first?.isCompleted ?? true)
    }
    
    func testWithdrawToZero() throws {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 1000)
            viewModel.withdraw(from: goal, amount: 2000)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.currentAmount, 0)
    }
    
    func testTotalTarget() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 5000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        XCTAssertEqual(viewModel.totalTarget, 15000)
    }
    
    func testTotalSaved() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 5000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 10000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 1000)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.totalSaved, 1000)
    }
    
    func testOverallProgress() throws {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 5000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 5000, deadline: nil)
        viewModel.fetchGoals()
        
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 2500)
        }
        
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.overallProgress, 0.25)
    }
}

// MARK: - BillReminderViewModel 完整测试
@MainActor
final class BillReminderViewModelCompleteTests: XCTestCase {
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
    
    func testAddMultipleReminders() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.addReminder(title: "电费", amount: 200, dueDate: soonDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "房租", amount: 3000, dueDate: laterDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.reminders.count, 2)
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
    
    func testUpdateReminder() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "旧标题", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.updateReminder(reminder, title: "新标题", amount: 200, note: "新备注")
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.reminders.first?.title, "新标题")
        XCTAssertEqual(viewModel.reminders.first?.amount, 200)
        XCTAssertEqual(viewModel.reminders.first?.note, "新备注")
    }
    
    func testDeleteReminder() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "A", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "B", amount: 200, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.deleteReminder(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.reminders.count, 1)
    }
    
    func testUpcomingReminders() throws {
        let soonDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let laterDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.addReminder(title: "即将到期", amount: 100, dueDate: soonDate, repeatFrequency: .monthly, note: "")
        viewModel.addReminder(title: "很久以后", amount: 200, dueDate: laterDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.upcomingReminders.count, 2)
    }
    
    func testOverdueReminders() throws {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        viewModel.addReminder(title: "过期", amount: 100, dueDate: pastDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertEqual(viewModel.overdueReminders.count, 1)
    }
    
    func testPaidReminders() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "已付", amount: 100, dueDate: futureDate, repeatFrequency: .monthly, note: "")
        viewModel.fetchReminders()
        
        if let reminder = viewModel.reminders.first {
            viewModel.markAsPaid(reminder)
        }
        
        viewModel.fetchReminders()
        XCTAssertEqual(viewModel.paidReminders.count, 1)
    }
    
    func testReminderWithoutAmount() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        viewModel.addReminder(title: "保险", amount: nil, dueDate: futureDate, repeatFrequency: .yearly, note: "")
        viewModel.fetchReminders()
        
        XCTAssertNil(viewModel.reminders.first?.amount)
    }
}

// MARK: - RecurringTransactionViewModel 完整测试
@MainActor
final class RecurringTransactionViewModelCompleteTests: XCTestCase {
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
    
    func testAddMultipleRecurring() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "每日午餐", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.addRecurringTransaction(amount: 200, type: .expense, category: "交通", note: "每周打车", frequency: .weekly, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        XCTAssertEqual(viewModel.recurringTransactions.count, 2)
    }
    
    func testDeleteRecurring() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.deleteRecurringTransaction(recurring)
        }
        
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.count, 0)
    }
    
    func testToggleActive() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
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
    
    func testUpdateRecurring() throws {
        viewModel.addRecurringTransaction(amount: 100, type: .expense, category: "餐饮", note: "", frequency: .daily, dayOfMonth: 1, dayOfWeek: 1, startDate: Date(), endDate: nil, account: nil)
        viewModel.fetchRecurringTransactions()
        
        if let recurring = viewModel.recurringTransactions.first {
            viewModel.updateRecurringTransaction(recurring, amount: 200, note: "更新")
        }
        
        viewModel.fetchRecurringTransactions()
        XCTAssertEqual(viewModel.recurringTransactions.first?.amount, 200)
        XCTAssertEqual(viewModel.recurringTransactions.first?.note, "更新")
    }
}
