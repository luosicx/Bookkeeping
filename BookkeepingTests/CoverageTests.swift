import XCTest
import SwiftData
@testable import Bookkeeping

// MARK: - ChartTheme Tests
final class ChartThemeTests: XCTestCase {
    func testChartColors() {
        XCTAssertFalse(ChartTheme.gradientColors.isEmpty)
    }
    
    func testChartColorForIndex() {
        let color1 = ChartTheme.color(for: 0)
        let color2 = ChartTheme.color(for: 1)
        XCTAssertNotEqual(color1, color2)
    }
    
    func testChartColorWrapsAround() {
        let color1 = ChartTheme.color(for: 0)
        let colorWraps = ChartTheme.color(for: ChartTheme.gradientColors.count)
        XCTAssertEqual(color1, colorWraps)
    }
    
    func testCategoryColors() {
        XCTAssertFalse(ChartTheme.categoryColors.isEmpty)
    }
    
    func testIncomeGradient() {
        let gradient = ChartTheme.incomeGradient()
        XCTAssertNotNil(gradient)
    }
    
    func testExpenseGradient() {
        let gradient = ChartTheme.expenseGradient()
        XCTAssertNotNil(gradient)
    }
    
    func testBalanceGradient() {
        let gradient = ChartTheme.balanceGradient()
        XCTAssertNotNil(gradient)
    }
}

// MARK: - Category Extended Tests
final class CategoryExtendedTests: XCTestCase {
    func testCategoryProperties() {
        for category in Category.expenseCategories {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertEqual(category.type, .expense)
        }
        
        for category in Category.incomeCategories {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertEqual(category.type, .income)
        }
    }
    
    func testCategoryLocalizedName() {
        for category in Category.expenseCategories {
            XCTAssertFalse(category.localizedName.isEmpty)
        }
        for category in Category.incomeCategories {
            XCTAssertFalse(category.localizedName.isEmpty)
        }
    }
    
    func testAllExpenseCategoryIds() {
        let ids = Category.expenseCategories.map(\.id)
        XCTAssertTrue(ids.contains("food"))
        XCTAssertTrue(ids.contains("transport"))
        XCTAssertTrue(ids.contains("shopping"))
        XCTAssertTrue(ids.contains("entertainment"))
        XCTAssertTrue(ids.contains("housing"))
        XCTAssertTrue(ids.contains("medical"))
        XCTAssertTrue(ids.contains("education"))
        XCTAssertTrue(ids.contains("other_expense"))
    }
    
    func testAllIncomeCategoryIds() {
        let ids = Category.incomeCategories.map(\.id)
        XCTAssertTrue(ids.contains("salary"))
        XCTAssertTrue(ids.contains("bonus"))
        XCTAssertTrue(ids.contains("investment"))
        XCTAssertTrue(ids.contains("other_income"))
    }
}

// MARK: - AccountType Extended Tests
final class AccountTypeExtendedTests: XCTestCase {
    func testAllAccountTypes() {
        XCTAssertEqual(AccountType.allCases.count, 6)
    }
    
    func testAccountTypeDefaultNames() {
        XCTAssertEqual(AccountType.cash.defaultName, "现金")
        XCTAssertEqual(AccountType.bank.defaultName, "银行卡")
        XCTAssertEqual(AccountType.alipay.defaultName, "支付宝")
        XCTAssertEqual(AccountType.wechat.defaultName, "微信")
        XCTAssertEqual(AccountType.credit.defaultName, "信用卡")
        XCTAssertEqual(AccountType.other.defaultName, "其他")
    }
    
    func testAccountTypeIcons() {
        for type in AccountType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
}

// MARK: - DebtType Extended Tests
final class DebtTypeExtendedTests: XCTestCase {
    func testAllDebtTypes() {
        XCTAssertEqual(DebtType.allCases.count, 2)
    }
    
    func testDebtTypeColors() {
        XCTAssertEqual(DebtType.lend.color, "orange")
        XCTAssertEqual(DebtType.borrow.color, "purple")
    }
}

// MARK: - TransactionType Extended Tests
final class TransactionTypeExtendedTests: XCTestCase {
    func testAllTransactionTypes() {
        XCTAssertEqual(TransactionType.allCases.count, 2)
    }
    
    func testTransactionTypeColors() {
        XCTAssertEqual(TransactionType.income.color, "green")
        XCTAssertEqual(TransactionType.expense.color, "red")
    }
    
    func testTransactionTypeLocalizedName() {
        XCTAssertFalse(TransactionType.income.localizedName.isEmpty)
        XCTAssertFalse(TransactionType.expense.localizedName.isEmpty)
    }
}

// MARK: - Frequency Extended Tests
final class FrequencyExtendedTests: XCTestCase {
    func testAllFrequencies() {
        XCTAssertEqual(Frequency.allCases.count, 4)
    }
    
    func testFrequencyIcons() {
        for freq in Frequency.allCases {
            XCTAssertFalse(freq.icon.isEmpty)
        }
    }
    
    func testFrequencyLocalizedName() {
        for freq in Frequency.allCases {
            XCTAssertFalse(freq.localizedName.isEmpty)
        }
    }
}

// MARK: - LedgerType Extended Tests
final class LedgerTypeExtendedTests: XCTestCase {
    func testAllLedgerTypes() {
        XCTAssertEqual(LedgerType.allCases.count, 5)
    }
    
    func testLedgerTypeProperties() {
        for type in LedgerType.allCases {
            XCTAssertFalse(type.localizedName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.color.isEmpty)
        }
    }
}

// MARK: - AppTheme Extended Tests
final class AppThemeExtendedTests: XCTestCase {
    func testAppThemeLocalizedName() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.localizedName.isEmpty)
        }
    }
    
    func testAppThemeColorSchemes() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
}

// MARK: - Budget Status Extended Tests
final class BudgetStatusExtendedTests: XCTestCase {
    func testBudgetStatusZeroBudget() {
        let budget = Budget(category: "测试", amount: 0, month: Date())
        let status = BudgetStatus(budget: budget, spent: 100)
        XCTAssertEqual(status.percentage, 0)
        XCTAssertTrue(status.isOverBudget)
    }
    
    func testOverallBudgetStatusZeroBudget() {
        let budget = OverallBudget(amount: 0, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 100)
        XCTAssertEqual(status.percentage, 0)
        XCTAssertTrue(status.isOverBudget)
    }
    
    func testBudgetStatusExact() {
        let budget = Budget(category: "测试", amount: 100, month: Date())
        let status = BudgetStatus(budget: budget, spent: 100)
        XCTAssertEqual(status.percentage, 1.0)
        XCTAssertFalse(status.isOverBudget)
    }
    
    func testOverallBudgetStatusWarning() {
        let budget = OverallBudget(amount: 1000, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 850)
        XCTAssertEqual(status.percentage, 0.85)
        XCTAssertTrue(status.isWarning)
        XCTAssertFalse(status.isOverBudget)
    }
}

// MARK: - SavingsGoal Extended Tests
final class SavingsGoalExtendedTests: XCTestCase {
    func testSavingsGoalProgressZeroTarget() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 0)
        XCTAssertEqual(goal.progress, 0)
    }
    
    func testSavingsGoalProgressPartial() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 200)
        goal.currentAmount = 100
        XCTAssertEqual(goal.progress, 0.5)
    }
    
    func testSavingsGoalRemainingNegative() {
        let goal = SavingsGoal(name: "测试", icon: "target", targetAmount: 50)
        goal.currentAmount = 100
        XCTAssertEqual(goal.remaining, 0)
    }
}

// MARK: - SharedDataManager Extended Tests
final class SharedDataManagerExtendedTests: XCTestCase {
    func testWidgetDataDefaults() {
        let manager = SharedDataManager.shared
        manager.saveWidgetData(income: 0, expense: 0, balance: 0)
        let data = manager.getWidgetData()
        XCTAssertEqual(data.income, 0)
        XCTAssertEqual(data.expense, 0)
        XCTAssertEqual(data.balance, 0)
    }
}

// MARK: - CustomCategoryManager Tests
@MainActor
final class CustomCategoryManagerTests: XCTestCase {
    func testSharedInstance() {
        let manager = CustomCategoryManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testGetAllCategories() {
        let manager = CustomCategoryManager.shared
        let expenseCategories = manager.getAllCategories(for: .expense)
        XCTAssertFalse(expenseCategories.isEmpty)
        XCTAssertTrue(expenseCategories.contains("餐饮"))
        
        let incomeCategories = manager.getAllCategories(for: .income)
        XCTAssertFalse(incomeCategories.isEmpty)
        XCTAssertTrue(incomeCategories.contains("工资"))
    }
}

// MARK: - ReportExporter Tests
@MainActor
final class ReportExporterTests: XCTestCase {
    func testExportMonthlyReport() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, configurations: config)
        let context = container.mainContext
        
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        context.insert(transaction)
        try context.save()
        
        let image = ReportExporter.exportMonthlyReport(date: Date(), transactions: [transaction])
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
    }
}

// MARK: - NotificationService Extended Tests
@MainActor
final class NotificationServiceExtendedTests2: XCTestCase {
    func testCancelAllReminders() {
        NotificationService.shared.cancelAllReminders()
    }
}

// MARK: - BackupService Extended Tests 2
@MainActor
final class BackupServiceExtendedTests2: XCTestCase {
    func testDeleteNonExistentFile() {
        let url = URL(fileURLWithPath: "/nonexistent/path/file.json")
        XCTAssertThrowsError(try BackupService.shared.deleteBackupFile(at: url))
    }
}

// MARK: - CloudSyncService Tests
@MainActor
final class CloudSyncServiceTests: XCTestCase {
    func testSharedInstance() {
        let service = CloudSyncService.shared
        XCTAssertNotNil(service)
    }
}

// MARK: - BiometricAuth Extended Tests
final class BiometricAuthExtendedTests: XCTestCase {
    func testIsBiometricAvailable() {
        let auth = BiometricAuth.shared
        let available = auth.isBiometricAvailable()
        XCTAssertFalse(available) // Simulators don't have biometrics
    }
}

// MARK: - MonthlyReportService Extended Tests
@MainActor
final class MonthlyReportServiceExtendedTests: XCTestCase {
    func testReportWithIncomeAndExpense() {
        let service = MonthlyReportService.shared
        let transactions = [
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date()),
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        XCTAssertEqual(report.totalIncome, 5000)
        XCTAssertEqual(report.totalExpense, 1000)
        XCTAssertEqual(report.balance, 4000)
        XCTAssertEqual(report.transactionCount, 2)
    }
}

// MARK: - CurrencyService Extended Tests
@MainActor
final class CurrencyServiceExtendedTests2: XCTestCase {
    func testCurrencyConverter() {
        let service = CurrencyService.shared
        let result = service.convert(100, from: "CNY", to: "CNY")
        XCTAssertEqual(result, 100)
    }
    
    func testFormatAmountCurrency() {
        let service = CurrencyService.shared
        let formatted = service.formatAmount(1234.56, currency: "USD")
        XCTAssertFalse(formatted.isEmpty)
    }
}
