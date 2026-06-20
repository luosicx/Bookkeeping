import XCTest
import SwiftData
@testable import Bookkeeping

@MainActor
final class TransactionViewModelTests: XCTestCase {
    var viewModel: TransactionViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        viewModel = TransactionViewModel()
        
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: Transaction.self, configurations: config)
        modelContext = modelContainer.mainContext
        viewModel.modelContext = modelContext
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testAddTransaction() throws {
        viewModel.addTransaction(
            amount: 100,
            type: .expense,
            category: "餐饮",
            note: "午餐",
            date: Date()
        )
        
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.amount, 100)
        XCTAssertEqual(viewModel.transactions.first?.type, .expense)
        XCTAssertEqual(viewModel.transactions.first?.category, "餐饮")
        XCTAssertEqual(viewModel.transactions.first?.note, "午餐")
    }
    
    func testDeleteTransaction() throws {
        viewModel.addTransaction(
            amount: 50,
            type: .expense,
            category: "交通",
            note: "地铁",
            date: Date()
        )
        
        viewModel.fetchTransactions()
        XCTAssertEqual(viewModel.transactions.count, 1)
        
        if let transaction = viewModel.transactions.first {
            viewModel.deleteTransaction(transaction)
        }
        
        viewModel.fetchTransactions()
        XCTAssertEqual(viewModel.transactions.count, 0)
    }
    
    func testTotalIncome() throws {
        viewModel.addTransaction(amount: 1000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 500, type: .income, category: "奖金", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date())
        
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.totalIncome, 1500)
    }
    
    func testTotalExpense() throws {
        viewModel.addTransaction(amount: 1000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "交通", note: "", date: Date())
        
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.totalExpense, 300)
    }
    
    func testBalance() throws {
        viewModel.addTransaction(amount: 1000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date())
        
        viewModel.fetchTransactions()
        
        XCTAssertEqual(viewModel.balance, 800)
    }
    
    func testFilteredTransactions() throws {
        viewModel.addTransaction(amount: 1000, type: .income, category: "工资", note: "", date: Date())
        viewModel.addTransaction(amount: 200, type: .expense, category: "餐饮", note: "", date: Date())
        viewModel.addTransaction(amount: 100, type: .expense, category: "交通", note: "", date: Date())
        
        viewModel.fetchTransactions()
        
        let incomeTransactions = viewModel.filteredTransactions(by: .income)
        let expenseTransactions = viewModel.filteredTransactions(by: .expense)
        
        XCTAssertEqual(incomeTransactions.count, 1)
        XCTAssertEqual(expenseTransactions.count, 2)
    }
    
    func testTransactionsForMonth() throws {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        
        viewModel.addTransaction(amount: 1000, type: .income, category: "工资", note: "", date: now)
        viewModel.addTransaction(amount: 500, type: .income, category: "工资", note: "", date: lastMonth)
        
        viewModel.fetchTransactions()
        
        let thisMonthTransactions = viewModel.transactionsForMonth(now)
        let lastMonthTransactions = viewModel.transactionsForMonth(lastMonth)
        
        XCTAssertEqual(thisMonthTransactions.count, 1)
        XCTAssertEqual(lastMonthTransactions.count, 1)
    }
}

final class CategoryTests: XCTestCase {
    func testExpenseCategories() throws {
        let categories = Category.expenseCategories
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains { $0.id == "food" })
        XCTAssertTrue(categories.contains { $0.id == "transport" })
    }
    
    func testIncomeCategories() throws {
        let categories = Category.incomeCategories
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains { $0.id == "salary" })
    }
    
    func testCategoriesForType() throws {
        let expenseCategories = Category.categories(for: .expense)
        let incomeCategories = Category.categories(for: .income)
        
        XCTAssertEqual(expenseCategories.count, Category.expenseCategories.count)
        XCTAssertEqual(incomeCategories.count, Category.incomeCategories.count)
    }
}

final class TransactionTypeTests: XCTestCase {
    func testTransactionTypeRawValue() throws {
        XCTAssertEqual(TransactionType.income.rawValue, "收入")
        XCTAssertEqual(TransactionType.expense.rawValue, "支出")
    }
    
    func testTransactionTypeIcon() throws {
        XCTAssertEqual(TransactionType.income.icon, "arrow.down.circle.fill")
        XCTAssertEqual(TransactionType.expense.icon, "arrow.up.circle.fill")
    }
}

@MainActor
final class BackupServiceTests: XCTestCase {
    func testExportData() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, configurations: config)
        let context = container.mainContext
        
        let transaction = Transaction(amount: 100, type: .expense, category: "测试", note: "测试备注", date: Date())
        context.insert(transaction)
        try context.save()
        
        let url = try BackupService.shared.exportData(modelContext: context)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        let data = try Data(contentsOf: url)
        
        // 验证 JSON 格式有效
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? String, "1.0")
        
        let transactions = json?["transactions"] as? [[String: Any]]
        XCTAssertNotNil(transactions)
        XCTAssertEqual(transactions?.count, 1)
        
        let firstTransaction = transactions?.first
        XCTAssertEqual(firstTransaction?["amount"] as? Double, 100)
        XCTAssertEqual(firstTransaction?["category"] as? String, "测试")
        
        try FileManager.default.removeItem(at: url)
    }
}

final class SharedDataManagerTests: XCTestCase {
    func testSaveAndGetData() throws {
        let manager = SharedDataManager.shared
        
        manager.saveWidgetData(income: 15000, expense: 9500, balance: 5500)
        
        let data = manager.getWidgetData()
        
        XCTAssertEqual(data.income, 15000)
        XCTAssertEqual(data.expense, 9500)
        XCTAssertEqual(data.balance, 5500)
    }
}
