import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - Transaction Extended Tests
@MainActor
final class TransactionExtendedTests: XCTestCase {
    func testTransactionWithAccount() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Account.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Account.self, configurations: config)
        let context = container.mainContext
        
        let account = Account(name: "测试", icon: "wallet.bifold", type: .other, balance: 1000)
        context.insert(account)
        
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date(), account: account)
        context.insert(transaction)
        try context.save()
        
        XCTAssertNotNil(transaction.account)
        XCTAssertEqual(transaction.account?.name, "测试")
    }
    
    func testTransactionWithLedger() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, configurations: config)
        let context = container.mainContext
        
        let ledger = Ledger(name: "测试账本", icon: "folder", color: "blue")
        context.insert(ledger)
        
        let transaction = Transaction(amount: 50, type: .expense, category: "交通", note: "", date: Date(), ledger: ledger)
        context.insert(transaction)
        try context.save()
        
        XCTAssertNotNil(transaction.ledger)
        XCTAssertEqual(transaction.ledger?.name, "测试账本")
    }
    
    func testTransactionWithTags() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Tag.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Tag.self, configurations: config)
        let context = container.mainContext
        
        let tag = Tag(name: "重要", color: "red")
        context.insert(tag)
        
        let transaction = Transaction(amount: 200, type: .expense, category: "购物", note: "", date: Date(), tags: [tag])
        context.insert(transaction)
        try context.save()
        
        XCTAssertNotNil(transaction.tags)
        XCTAssertEqual(transaction.tags?.count, 1)
    }
}

// MARK: - Ledger Extended Tests
final class LedgerExtendedTests: XCTestCase {
    func testLedgerDefaults() {
        let ledger = Ledger(name: "默认", icon: "folder", color: "gray", isDefault: true)
        XCTAssertTrue(ledger.isDefault)
    }
    
    func testLedgerTransactions() {
        let ledger = Ledger(name: "测试", icon: "folder", color: "blue")
        XCTAssertNotNil(ledger.transactions)
        XCTAssertTrue(ledger.transactions?.isEmpty ?? true)
    }
}

// MARK: - Account Extended Tests
final class AccountExtendedTests: XCTestCase {
    func testAccountTransactions() {
        let account = Account(name: "测试", icon: "wallet.bifold", type: .other)
        XCTAssertNotNil(account.transactions)
        XCTAssertTrue(account.transactions?.isEmpty ?? true)
    }
    
    func testAccountDefaultBalance() {
        let account = Account(name: "测试", icon: "wallet.bifold", type: .other)
        XCTAssertEqual(account.balance, 0)
    }
}

// MARK: - RecurringTransaction Extended Tests
final class RecurringTransactionExtendedTests: XCTestCase {
    func testRecurringTransactionCreation() {
        let recurring = RecurringTransaction(
            amount: 100,
            type: .expense,
            category: "餐饮",
            note: "每日午餐",
            frequency: .daily,
            dayOfMonth: 1,
            dayOfWeek: 1,
            startDate: Date()
        )
        
        XCTAssertEqual(recurring.amount, 100)
        XCTAssertEqual(recurring.type, .expense)
        XCTAssertEqual(recurring.frequency, .daily)
        XCTAssertTrue(recurring.isActive)
        XCTAssertNil(recurring.lastGenerated)
    }
    
    func testRecurringTransactionDefaultValues() {
        let recurring = RecurringTransaction(
            amount: 50,
            type: .expense,
            category: "交通",
            frequency: .weekly,
            startDate: Date()
        )
        
        XCTAssertEqual(recurring.dayOfMonth, 1)
        XCTAssertEqual(recurring.dayOfWeek, 1)
        XCTAssertNil(recurring.endDate)
        XCTAssertNil(recurring.account)
    }
}

// MARK: - OverallBudget Extended Tests
final class OverallBudgetExtendedTests: XCTestCase {
    func testOverallBudgetCreation() {
        let budget = OverallBudget(amount: 5000, month: Date())
        XCTAssertEqual(budget.amount, 5000)
    }
}

// MARK: - Budget Extended Tests
final class BudgetExtendedTests: XCTestCase {
    func testBudgetCreation() {
        let budget = Budget(category: "餐饮", amount: 2000, month: Date())
        XCTAssertEqual(budget.category, "餐饮")
        XCTAssertEqual(budget.amount, 2000)
    }
}

// MARK: - Debt Extended Tests
final class DebtExtendedTests: XCTestCase {
    func testDebtWithDueDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let debt = Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: futureDate)
        
        XCTAssertNotNil(debt.dueDate)
        XCTAssertEqual(debt.amount, 1000)
        XCTAssertFalse(debt.isSettled)
    }
    
    func testDebtSettled() {
        let debt = Debt(name: "李四", amount: 500, type: .borrow)
        debt.isSettled = true
        debt.settledDate = Date()
        
        XCTAssertTrue(debt.isSettled)
        XCTAssertNotNil(debt.settledDate)
    }
}

// MARK: - Tag Extended Tests
final class TagExtendedTests: XCTestCase {
    func testTagDefaultColor() {
        let tag = Tag(name: "测试")
        XCTAssertEqual(tag.color, "blue")
    }
}

// MARK: - CustomCategory Extended Tests
final class CustomCategoryExtendedTests: XCTestCase {
    func testCustomCategoryCreation() {
        let category = CustomCategory(name: "自定义", icon: "star.fill", type: .expense)
        XCTAssertEqual(category.name, "自定义")
        XCTAssertEqual(category.icon, "star.fill")
        XCTAssertEqual(category.type, .expense)
    }
    
    func testCustomCategoryLocalizedName() {
        let category = CustomCategory(name: "自定义分类", icon: "star.fill", type: .income)
        XCTAssertEqual(category.localizedName, "自定义分类")
    }
}

// MARK: - BillReminder Extended Tests
final class BillReminderExtendedTests: XCTestCase {
    func testBillReminderDisabled() {
        let reminder = BillReminder(title: "测试", dueDate: Date())
        reminder.isEnabled = false
        XCTAssertFalse(reminder.isEnabled)
    }
    
    func testBillReminderPaid() {
        let reminder = BillReminder(title: "已付", amount: 100, dueDate: Date())
        reminder.isPaid = true
        XCTAssertTrue(reminder.isPaid)
        XCTAssertFalse(reminder.isOverdue)
    }
    
    func testBillReminderNotDueSoon() {
        let farFuture = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let reminder = BillReminder(title: "测试", dueDate: farFuture)
        XCTAssertFalse(reminder.isDueSoon)
    }
}

// MARK: - SavingsGoal Extended Tests 2
final class SavingsGoalExtendedTests2: XCTestCase {
    func testSavingsGoalCompleted() {
        let goal = SavingsGoal(name: "完成", icon: "checkmark", targetAmount: 100)
        goal.currentAmount = 100
        goal.isCompleted = true
        
        XCTAssertTrue(goal.isCompleted)
        XCTAssertEqual(goal.progress, 1.0)
        XCTAssertEqual(goal.remaining, 0)
    }
}

// MARK: - VoiceCommandParser Extended Tests
final class VoiceCommandParserExtendedTests: XCTestCase {
    func testParseWithAllElements() {
        let parser = VoiceCommandParser()
        let result = parser.parse("午餐外卖花了35元")
        
        XCTAssertEqual(result.amount, 35)
        XCTAssertNotNil(result.type)
    }
    
    func testParseIncome() {
        let parser = VoiceCommandParser()
        let result = parser.parse("收到工资15000元")
        
        XCTAssertEqual(result.amount, 15000)
        XCTAssertNotNil(result.type)
    }
    
    func testParseNoAmount() {
        let parser = VoiceCommandParser()
        let result = parser.parse("午餐")
        
        XCTAssertNil(result.amount)
    }
    
    func testParseMultipleNumbers() {
        let parser = VoiceCommandParser()
        let result = parser.parse("花了100.5元")
        
        XCTAssertEqual(result.amount, 100.5)
    }
}

// MARK: - TrendPredictor Extended Tests
final class TrendPredictorExtendedTests: XCTestCase {
    func testAnalyzeTrendStable() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 105, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
            Transaction(amount: 95, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -2, to: today)!),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currentMonth, 100)
        XCTAssertEqual(result?.lastMonth, 105)
    }
    
    func testAnalyzeTrendDecreasing() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 50, type: .expense, category: "餐饮", note: "", date: today),
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
            Transaction(amount: 200, type: .expense, category: "餐饮", note: "", date: calendar.date(byAdding: .month, value: -2, to: today)!),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.trend.description, "下降")
    }
    
    func testAnalyzeTrendIncome() {
        let calendar = Calendar.current
        let today = Date()
        let transactions = [
            Transaction(amount: 15000, type: .income, category: "工资", note: "", date: today),
            Transaction(amount: 12000, type: .income, category: "工资", note: "", date: calendar.date(byAdding: .month, value: -1, to: today)!),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .income)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currentMonth, 15000)
        XCTAssertEqual(result?.lastMonth, 12000)
    }
    
    func testAnalyzeTrendNoData() {
        let result = TrendPredictor.shared.analyzeTrend(transactions: [], type: .expense)
        XCTAssertNil(result)
    }
    
    func testAnalyzeTrendSingleMonth() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let result = TrendPredictor.shared.analyzeTrend(transactions: transactions, type: .expense)
        XCTAssertNil(result)
    }
    
    func testDetectAnomaliesEmpty() {
        let result = TrendPredictor.shared.detectAnomalies(transactions: [])
        XCTAssertTrue(result.isEmpty)
    }
    
    func testDetectAnomaliesSingle() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        let result = TrendPredictor.shared.detectAnomalies(transactions: transactions)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testAnalyzeAllCategoriesEmpty() {
        let result = TrendPredictor.shared.analyzeAllCategories(transactions: [])
        XCTAssertTrue(result.isEmpty)
    }
    
    func testAnalyzeAllCategoriesNoExpense() {
        let transactions = [
            Transaction(amount: 100, type: .income, category: "工资", note: "", date: Date()),
        ]
        let result = TrendPredictor.shared.analyzeAllCategories(transactions: transactions)
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - ExportService Extended Tests
@MainActor
final class ExportServiceExtendedTests: XCTestCase {
    func testExportFormatAllCases() {
        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }
    
    func testExportFormatRawValues() {
        XCTAssertEqual(ExportFormat.csv.rawValue, "CSV")
        XCTAssertEqual(ExportFormat.excel.rawValue, "Excel")
        XCTAssertEqual(ExportFormat.json.rawValue, "JSON")
    }
}

// MARK: - ImportService Extended Tests
@MainActor
final class ImportServiceExtendedTests: XCTestCase {
    func testSupportedFileTypes() {
        let types = ImportService.shared.supportedFileTypes()
        XCTAssertEqual(types.count, 3)
        XCTAssertTrue(types.contains("csv"))
        XCTAssertTrue(types.contains("json"))
        XCTAssertTrue(types.contains("txt"))
    }
}

// MARK: - BackupService Extended Tests 3
@MainActor
final class BackupServiceExtendedTests3: XCTestCase {
    func testBackupDataStructure() {
        let backup = BackupData(
            version: "1.0",
            exportDate: Date(),
            transactions: []
        )
        XCTAssertEqual(backup.version, "1.0")
        XCTAssertTrue(backup.transactions.isEmpty)
    }
    
    func testBackupTransactionStructure() {
        let tx = BackupTransaction(
            id: UUID(),
            amount: 100,
            type: "支出",
            category: "餐饮",
            note: "午餐",
            date: Date(),
            createdAt: Date()
        )
        XCTAssertEqual(tx.amount, 100)
        XCTAssertEqual(tx.type, "支出")
        XCTAssertEqual(tx.category, "餐饮")
    }
}

// MARK: - Localization Extended Tests 2
final class LocalizationExtendedTests2: XCTestCase {
    func testAllTabStrings() {
        XCTAssertFalse(L.tabHome.isEmpty)
        XCTAssertFalse(L.tabStatistics.isEmpty)
        XCTAssertFalse(L.tabSettings.isEmpty)
    }
    
    func testAllHomeStrings() {
        XCTAssertFalse(L.homeTitle.isEmpty)
        XCTAssertFalse(L.monthlyBalance.isEmpty)
        XCTAssertFalse(L.income.isEmpty)
        XCTAssertFalse(L.expense.isEmpty)
        XCTAssertFalse(L.recentTransactions.isEmpty)
    }
    
    func testAllTransactionStrings() {
        XCTAssertFalse(L.addTransaction.isEmpty)
        XCTAssertFalse(L.transactionType.isEmpty)
        XCTAssertFalse(L.amount.isEmpty)
        XCTAssertFalse(L.category.isEmpty)
    }
    
    func testAllSettingsStrings() {
        XCTAssertFalse(L.settingsTitle.isEmpty)
        XCTAssertFalse(L.basicSettings.isEmpty)
        XCTAssertFalse(L.security.isEmpty)
        XCTAssertFalse(L.tools.isEmpty)
    }
    
    func testAllBudgetStrings() {
        XCTAssertFalse(L.budgetManagement.isEmpty)
        XCTAssertFalse(L.totalBudget.isEmpty)
        XCTAssertFalse(L.overallBudget.isEmpty)
    }
    
    func testAllAccountStrings() {
        XCTAssertFalse(L.accountManagement.isEmpty)
        XCTAssertFalse(L.myAccounts.isEmpty)
        XCTAssertFalse(L.addAccount.isEmpty)
    }
    
    func testAllLedgerStrings() {
        XCTAssertFalse(L.ledgerManagement.isEmpty)
        XCTAssertFalse(L.myLedgers.isEmpty)
        XCTAssertFalse(L.addLedger.isEmpty)
    }
    
    func testAllRecurringStrings() {
        XCTAssertFalse(L.recurringTransactions.isEmpty)
        XCTAssertFalse(L.recurringList.isEmpty)
        XCTAssertFalse(L.addRecurring.isEmpty)
    }
    
    func testAllSavingsStrings() {
        XCTAssertFalse(L.savingsGoals.isEmpty)
        XCTAssertFalse(L.myGoals.isEmpty)
        XCTAssertFalse(L.addGoal.isEmpty)
    }
    
    func testAllBillReminderStrings() {
        XCTAssertFalse(L.billReminders.isEmpty)
        XCTAssertFalse(L.billReminder.isEmpty)
        XCTAssertFalse(L.addReminder.isEmpty)
    }
    
    func testAllExportStrings() {
        XCTAssertFalse(L.exportData.isEmpty)
        XCTAssertFalse(L.exportFormat.isEmpty)
        XCTAssertFalse(L.exportHistory.isEmpty)
    }
    
    func testAllImportStrings() {
        XCTAssertFalse(L.importData.isEmpty)
        XCTAssertFalse(L.importFromCSV.isEmpty)
        XCTAssertFalse(L.importSuccess.isEmpty)
    }
    
    func testAllBackupStrings() {
        XCTAssertFalse(L.backupRestore.isEmpty)
        XCTAssertFalse(L.backupData.isEmpty)
        XCTAssertFalse(L.restoreData.isEmpty)
    }
    
    func testAllShareStrings() {
        XCTAssertFalse(L.shareData.isEmpty)
        XCTAssertFalse(L.shareAsText.isEmpty)
        XCTAssertFalse(L.shareAsJSON.isEmpty)
    }
    
    func testAllVoiceStrings() {
        XCTAssertFalse(L.voiceInput.isEmpty)
        XCTAssertFalse(L.stopRecording.isEmpty)
        XCTAssertFalse(L.voiceResult.isEmpty)
    }
    
    func testAllReportStrings() {
        XCTAssertFalse(L.reportShare.isEmpty)
        XCTAssertFalse(L.generateReport.isEmpty)
    }
    
    func testAllAppLockStrings() {
        XCTAssertFalse(L.appLock.isEmpty)
        XCTAssertFalse(L.appLockSettings.isEmpty)
        XCTAssertFalse(L.enableAppLock.isEmpty)
    }
    
    func testAllNotificationStrings() {
        XCTAssertFalse(L.notificationSettings.isEmpty)
        XCTAssertFalse(L.notificationsEnabled.isEmpty)
        XCTAssertFalse(L.notificationsDisabled.isEmpty)
    }
    
    func testAllCategoryStrings() {
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
    }
    
    func testAllStatisticsStrings() {
        XCTAssertFalse(L.statisticsTitle.isEmpty)
        XCTAssertFalse(L.periodWeek.isEmpty)
        XCTAssertFalse(L.periodMonth.isEmpty)
        XCTAssertFalse(L.periodYear.isEmpty)
    }
    
    func testAllTrendStrings() {
        XCTAssertFalse(L.trendAnalysis.isEmpty)
        XCTAssertFalse(L.trendDirection.isEmpty)
        XCTAssertFalse(L.prediction.isEmpty)
    }
    
    func testAllDebtStrings2() {
        XCTAssertFalse(L.debtManagement.isEmpty)
        XCTAssertFalse(L.debtLend.isEmpty)
        XCTAssertFalse(L.debtBorrow.isEmpty)
        XCTAssertFalse(L.debtLent.isEmpty)
        XCTAssertFalse(L.debtBorrowed.isEmpty)
        XCTAssertFalse(L.unsettledDebts.isEmpty)
        XCTAssertFalse(L.settledDebts.isEmpty)
        XCTAssertFalse(L.noDebts.isEmpty)
        XCTAssertFalse(L.addDebt.isEmpty)
    }
    
    func testAllTagStrings2() {
        XCTAssertFalse(L.tagManagement.isEmpty)
        XCTAssertFalse(L.tags.isEmpty)
        XCTAssertFalse(L.noTags.isEmpty)
        XCTAssertFalse(L.addTag.isEmpty)
        XCTAssertFalse(L.editTag.isEmpty)
    }
    
    func testAllCalendarStrings2() {
        XCTAssertFalse(L.calendar.isEmpty)
        XCTAssertFalse(L.today.isEmpty)
        XCTAssertFalse(L.dailySummary.isEmpty)
    }
    
    func testAllBudgetComparisonStrings() {
        XCTAssertFalse(L.budgetComparison.isEmpty)
        XCTAssertFalse(L.actualVsPlanned.isEmpty)
    }
    
    func testAllMonthlyReportStrings() {
        XCTAssertFalse(L.monthlyReport.isEmpty)
        XCTAssertFalse(L.monthlyReportScheduled.isEmpty)
    }
    
    func testAllReceiptScanStrings() {
        XCTAssertFalse(L.receiptScan.isEmpty)
        XCTAssertFalse(L.scanningReceipt.isEmpty)
        XCTAssertFalse(L.receiptScanned.isEmpty)
        XCTAssertFalse(L.estimatedAmount.isEmpty)
        XCTAssertFalse(L.useThisAmount.isEmpty)
    }
    
    func testAllCurrencyStrings() {
        XCTAssertFalse(L.currencyConverter.isEmpty)
        XCTAssertFalse(L.baseCurrency.isEmpty)
        XCTAssertFalse(L.selectCurrency.isEmpty)
        XCTAssertFalse(L.exchangeRate.isEmpty)
        XCTAssertFalse(L.lastUpdated.isEmpty)
        XCTAssertFalse(L.updateRates.isEmpty)
    }
}
