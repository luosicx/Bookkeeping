import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - ExportService Tests
@MainActor
final class ExportServiceTests: XCTestCase {
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
    
    func testExportCSV() throws {
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        modelContext.insert(transaction)
        try modelContext.save()
        
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .csv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "csv")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportJSON() throws {
        let transaction = Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date())
        modelContext.insert(transaction)
        try modelContext.save()
        
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .json)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "json")
        
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? String, "1.0")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportExcel() throws {
        let transaction = Transaction(amount: 50, type: .expense, category: "交通", note: "地铁", date: Date())
        modelContext.insert(transaction)
        try modelContext.save()
        
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .excel)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.pathExtension == "xls")
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportEmptyData() throws {
        let url = try ExportService.shared.exportData(modelContext: modelContext, format: .csv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportFormatProperties() throws {
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.excel.fileExtension, "xls")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportFormat.json.mimeType, "application/json")
    }
    
    func testGetExportFiles() throws {
        let files = ExportService.shared.getExportFiles()
        XCTAssertNotNil(files)
    }
}

// MARK: - ImportService Tests
@MainActor
final class ImportServiceTests: XCTestCase {
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
    
    func testImportFromCSV() throws {
        let csv = "日期,类型,分类,金额,备注\n2024-01-15,支出,餐饮,35.5,午餐\n2024-01-16,收入,工资,5000,月薪"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 2)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try modelContext.fetch(descriptor)
        XCTAssertEqual(transactions.count, 2)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testImportFromJSON() throws {
        let now = Date()
        let json: [String: Any] = [
            "version": "1.0",
            "exportDate": now.timeIntervalSince1970,
            "transactions": [
                ["id": UUID().uuidString, "amount": 100, "type": "支出", "category": "餐饮", "note": "测试", "date": now.timeIntervalSince1970, "createdAt": now.timeIntervalSince1970]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.json")
        try data.write(to: url)
        
        let count = try ImportService.shared.importFromJSON(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 1)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testImportEmptyCSV() throws {
        let csv = "日期,类型,分类,金额\n"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        let count = try ImportService.shared.importFromCSV(url: url, modelContext: modelContext)
        XCTAssertEqual(count, 0)
        try? FileManager.default.removeItem(at: url)
    }
    
    func testSupportedFileTypes() {
        let types = ImportService.shared.supportedFileTypes()
        XCTAssertTrue(types.contains("csv"))
        XCTAssertTrue(types.contains("json"))
        XCTAssertTrue(types.contains("txt"))
    }
}

// MARK: - ShareService Tests
@MainActor
final class ShareServiceTests: XCTestCase {
    func testShareAsText() throws {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date()),
        ]
        
        let text = ShareService.shared.shareAsText(transactions: transactions)
        XCTAssertFalse(text.isEmpty)
        XCTAssertTrue(text.contains("记账本"))
    }
    
    func testShareAsTextEmpty() {
        let text = ShareService.shared.shareAsText(transactions: [])
        XCTAssertFalse(text.isEmpty)
    }
    
    func testShareAsJSON() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
        ]
        
        let data = ShareService.shared.shareAsJSON(transactions: transactions)
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? String, "1.0")
    }
    
    func testShareAsJSONEmpty() {
        let data = ShareService.shared.shareAsJSON(transactions: [])
        XCTAssertNotNil(data)
    }
    
    func testGenerateShareItems() {
        let transactions = [
            Transaction(amount: 50, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let items = ShareService.shared.generateShareItems(transactions: transactions)
        XCTAssertFalse(items.isEmpty)
    }
}

// MARK: - SampleData Tests
@MainActor
final class SampleDataTests: XCTestCase {
    func testInsertSampleData() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, configurations: config)
        let context = container.mainContext
        
        SampleData.insertSampleData(modelContext: context)
        
        let ledgerDescriptor = FetchDescriptor<Ledger>()
        let ledgerCount = try context.fetchCount(ledgerDescriptor)
        XCTAssertGreaterThan(ledgerCount, 0)
        
        let accountDescriptor = FetchDescriptor<Account>()
        let accountCount = try context.fetchCount(accountDescriptor)
        XCTAssertGreaterThan(accountCount, 0)
        
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactionCount = try context.fetchCount(transactionDescriptor)
        XCTAssertGreaterThan(transactionCount, 0)
    }
    
    func testInsertSampleDataIdempotent() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, Account.self, configurations: config)
        let context = container.mainContext
        
        SampleData.insertSampleData(modelContext: context)
        let firstCount = try context.fetchCount(FetchDescriptor<Transaction>())
        
        SampleData.insertSampleData(modelContext: context)
        let secondCount = try context.fetchCount(FetchDescriptor<Transaction>())
        
        XCTAssertEqual(firstCount, secondCount)
    }
}

// MARK: - TrendPredictor Tests
final class TrendPredictorTests: XCTestCase {
    func testAnalyzeTrendWithInsufficientData() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNil(result)
    }
    
    func testAnalyzeTrendWithData() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
            Transaction(amount: 300, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -2, to: today)!),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currentMonth, 100)
        XCTAssertEqual(result?.lastMonth, 200)
    }
    
    func testTrendDirectionIncreasing() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 300, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNotNil(result)
    }
    
    func testDetectAnomaliesEmpty() {
        let result = TrendPredictor.shared.detectAnomalies(transactions: [])
        XCTAssertTrue(result.isEmpty)
    }
    
    func testDetectAnomaliesWithAnomalies() {
        let transactions = [
            Transaction(amount: 10, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 11, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 9, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 10, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 12, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 5000, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let anomalies = TrendPredictor.shared.detectAnomalies(transactions: transactions)
        XCTAssertGreaterThan(anomalies.count, 0)
    }
    
    func testDetectAnomaliesNoAnomalies() {
        let transactions = [
            Transaction(amount: 10, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 12, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 8, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let anomalies = TrendPredictor.shared.detectAnomalies(transactions: transactions)
        XCTAssertTrue(anomalies.isEmpty)
    }
    
    func testAnalyzeAllCategories() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
            Transaction(amount: 50, type: .expense, category: "交通", note: "", date: today),
            Transaction(amount: 80, type: .expense, category: "交通", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
        ]
        
        let results = TrendPredictor.shared.analyzeAllCategories(transactions: transactions)
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }
    
    func testTrendDirectionProperties() {
        XCTAssertEqual(TrendPredictor.TrendDirection.increasing.description, "上升")
        XCTAssertEqual(TrendPredictor.TrendDirection.stable.description, "稳定")
        XCTAssertEqual(TrendPredictor.TrendDirection.decreasing.description, "下降")
        XCTAssertFalse(TrendPredictor.TrendDirection.increasing.icon.isEmpty)
        XCTAssertFalse(TrendPredictor.TrendDirection.stable.color.isEmpty)
    }
}

// MARK: - BillReminder Model Tests
final class BillReminderModelTests: XCTestCase {
    func testBillReminderCreation() {
        let reminder = BillReminder(title: "电费", amount: 200, dueDate: Date(), repeatFrequency: .monthly, note: "每月缴费")
        XCTAssertEqual(reminder.title, "电费")
        XCTAssertEqual(reminder.amount, 200)
        XCTAssertEqual(reminder.repeatFrequency, .monthly)
        XCTAssertEqual(reminder.note, "每月缴费")
        XCTAssertFalse(reminder.isPaid)
        XCTAssertTrue(reminder.isEnabled)
    }
    
    func testBillReminderWithoutAmount() {
        let reminder = BillReminder(title: "保险", dueDate: Date())
        XCTAssertNil(reminder.amount)
        XCTAssertEqual(reminder.repeatFrequency, .monthly)
    }
    
    func testBillReminderIsOverdue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let reminder = BillReminder(title: "过期", dueDate: pastDate)
        XCTAssertTrue(reminder.isOverdue)
    }
    
    func testBillReminderIsDueSoon() {
        let soonDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let reminder = BillReminder(title: "快到期", dueDate: soonDate)
        XCTAssertTrue(reminder.isDueSoon)
    }
    
    func testBillReminderDaysUntilDue() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let reminder = BillReminder(title: "测试", dueDate: futureDate)
        XCTAssertGreaterThanOrEqual(reminder.daysUntilDue, 9)
        XCTAssertLessThanOrEqual(reminder.daysUntilDue, 10)
    }
}

// MARK: - SavingsGoal Model Tests
final class SavingsGoalModelTests: XCTestCase {
    func testSavingsGoalCreation() {
        let goal = SavingsGoal(name: "旅行基金", icon: "airplane", targetAmount: 10000, deadline: Date())
        XCTAssertEqual(goal.name, "旅行基金")
        XCTAssertEqual(goal.icon, "airplane")
        XCTAssertEqual(goal.targetAmount, 10000)
        XCTAssertEqual(goal.currentAmount, 0)
        XCTAssertFalse(goal.isCompleted)
    }
    
    func testSavingsGoalProgress() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 1000)
        goal.currentAmount = 500
        XCTAssertEqual(goal.progress, 0.5)
    }
    
    func testSavingsGoalProgressComplete() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 100)
        goal.currentAmount = 150
        XCTAssertEqual(goal.progress, 1.0)
    }
    
    func testSavingsGoalRemaining() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 1000)
        goal.currentAmount = 300
        XCTAssertEqual(goal.remaining, 700)
    }
    
    func testSavingsGoalRemainingZero() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 100)
        goal.currentAmount = 200
        XCTAssertEqual(goal.remaining, 0)
    }
    
    func testSavingsGoalDaysRemaining() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 1000, deadline: futureDate)
        XCTAssertNotNil(goal.daysRemaining)
        XCTAssertGreaterThanOrEqual(goal.daysRemaining!, 29)
        XCTAssertLessThanOrEqual(goal.daysRemaining!, 30)
    }
    
    func testSavingsGoalNoDeadline() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 1000)
        XCTAssertNil(goal.daysRemaining)
    }
}

// MARK: - SavingsGoalViewModel Tests
@MainActor
final class SavingsGoalViewModelTests: XCTestCase {
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
    
    func testAddGoal() {
        viewModel.addGoal(name: "旅行", icon: "airplane", targetAmount: 5000, deadline: nil)
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.count, 1)
    }
    
    func testDeleteGoal() {
        viewModel.addGoal(name: "测试", icon: "target", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.deleteGoal(goal)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.count, 0)
    }
    
    func testUpdateGoal() {
        viewModel.addGoal(name: "旧名", icon: "target", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.updateGoal(goal, name: "新名", targetAmount: 2000)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.name, "新名")
        XCTAssertEqual(viewModel.goals.first?.targetAmount, 2000)
    }
    
    func testAddDeposit() {
        viewModel.addGoal(name: "测试", icon: "target", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 500)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.currentAmount, 500)
    }
    
    func testAddDepositComplete() {
        viewModel.addGoal(name: "测试", icon: "target", targetAmount: 100, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 150)
        }
        viewModel.fetchGoals()
        XCTAssertTrue(viewModel.goals.first?.isCompleted ?? false)
    }
    
    func testWithdraw() {
        viewModel.addGoal(name: "测试", icon: "target", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 500)
            viewModel.withdraw(from: goal, amount: 200)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.goals.first?.currentAmount, 300)
        XCTAssertFalse(viewModel.goals.first?.isCompleted ?? true)
    }
    
    func testTotalTarget() {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 1000, deadline: nil)
        viewModel.addGoal(name: "B", icon: "b", targetAmount: 2000, deadline: nil)
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.totalTarget, 3000)
    }
    
    func testTotalSaved() {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 300)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.totalSaved, 300)
    }
    
    func testOverallProgress() {
        viewModel.addGoal(name: "A", icon: "a", targetAmount: 1000, deadline: nil)
        viewModel.fetchGoals()
        if let goal = viewModel.goals.first {
            viewModel.addDeposit(to: goal, amount: 500)
        }
        viewModel.fetchGoals()
        XCTAssertEqual(viewModel.overallProgress, 0.5)
    }
}

// MARK: - BudgetViewModel Tests
@MainActor
final class BudgetViewModelTests: XCTestCase {
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
    
    func testAddBudget() {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.fetchBudgets()
        XCTAssertEqual(viewModel.budgets.count, 1)
        XCTAssertEqual(viewModel.budgets.first?.amount, 2000)
    }
    
    func testUpdateBudget() {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.fetchBudgets()
        viewModel.addBudget(category: "餐饮", amount: 3000)
        viewModel.fetchBudgets()
        XCTAssertEqual(viewModel.budgets.first?.amount, 3000)
    }
    
    func testDeleteBudget() {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.fetchBudgets()
        if let budget = viewModel.budgets.first {
            viewModel.deleteBudget(budget)
        }
        viewModel.fetchBudgets()
        XCTAssertEqual(viewModel.budgets.count, 0)
    }
    
    func testSetOverallBudget() {
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchOverallBudget()
        XCTAssertEqual(viewModel.overallBudgets.first?.amount, 5000)
    }
    
    func testTotalBudget() {
        viewModel.addBudget(category: "餐饮", amount: 2000)
        viewModel.addBudget(category: "交通", amount: 1000)
        viewModel.fetchBudgets()
        XCTAssertEqual(viewModel.totalBudget, 3000)
    }
    
    func testGetBudgetStatus() {
        viewModel.addBudget(category: "餐饮", amount: 1000)
        viewModel.fetchBudgets()
        
        let transactions = [
            Transaction(amount: 300, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let status = viewModel.getBudgetStatus(for: "餐饮", transactions: transactions)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.spent, 300)
    }
    
    func testGetBudgetStatusNoBudget() {
        viewModel.fetchBudgets()
        let status = viewModel.getBudgetStatus(for: "不存在", transactions: [])
        XCTAssertNil(status)
    }
    
    func testGetOverallBudgetStatus() {
        viewModel.setOverallBudget(amount: 5000)
        viewModel.fetchOverallBudget()
        
        let transactions = [
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let status = viewModel.getOverallBudgetStatus(transactions: transactions)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.spent, 1000)
    }
    
    func testGetOverallBudgetStatusNoBudget() {
        viewModel.fetchOverallBudget()
        let status = viewModel.getOverallBudgetStatus(transactions: [])
        XCTAssertNil(status)
    }
    
    func testGetAllBudgetStatus() {
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
}

// MARK: - NotificationService Extended Tests
@MainActor
final class NotificationServiceExtendedTests: XCTestCase {
    func testCancelAllReminders() {
        NotificationService.shared.cancelAllReminders()
    }
    
    func testGetPendingReminders() {
        let expectation = XCTestExpectation(description: "Get pending reminders")
        NotificationService.shared.getPendingReminders { requests in
            XCTAssertNotNil(requests)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}

// MARK: - BackupService Extended Tests
@MainActor
final class BackupServiceExtendedTests: XCTestCase {
    func testGetBackupFiles() {
        let files = BackupService.shared.getBackupFiles()
        XCTAssertNotNil(files)
    }
}

// MARK: - CurrencyService Extended Tests
@MainActor
final class CurrencyServiceExtendedTests: XCTestCase {
    func testCurrencyAllCases() {
        XCTAssertEqual(CurrencyService.Currency.all.count, 8)
    }
    
    func testCurrencyProperties() {
        let cny = CurrencyService.Currency.all.first { $0.id == "CNY" }
        XCTAssertNotNil(cny)
        XCTAssertEqual(cny?.symbol, "¥")
    }
}

// MARK: - Localization Extended Tests
final class LocalizationExtendedTests: XCTestCase {
    func testDebtStrings() {
        XCTAssertFalse(L.debtManagement.isEmpty)
        XCTAssertFalse(L.debtLend.isEmpty)
        XCTAssertFalse(L.debtBorrow.isEmpty)
        XCTAssertFalse(L.noDebts.isEmpty)
    }
    
    func testTagStrings() {
        XCTAssertFalse(L.tagManagement.isEmpty)
        XCTAssertFalse(L.tags.isEmpty)
        XCTAssertFalse(L.noTags.isEmpty)
    }
    
    func testCalendarStrings() {
        XCTAssertFalse(L.calendar.isEmpty)
    }
    
    func testBudgetComparisonStrings() {
        XCTAssertFalse(L.budgetComparison.isEmpty)
    }
    
    func testReceiptScanStrings() {
        XCTAssertFalse(L.receiptScan.isEmpty)
        XCTAssertFalse(L.scanningReceipt.isEmpty)
    }
    
    func testCurrencyStrings() {
        XCTAssertFalse(L.currencyConverter.isEmpty)
        XCTAssertFalse(L.exchangeRate.isEmpty)
    }
    
    func testMonthlyReportStrings() {
        XCTAssertFalse(L.monthlyReport.isEmpty)
    }
}
