import XCTest
@testable import Bookkeeping

final class CurrencyServiceTests: XCTestCase {
    func testConvertSameCurrency() throws {
        let service = CurrencyService.shared
        let result = service.convert(100, from: "CNY", to: "CNY")
        XCTAssertEqual(result, 100)
    }
    
    func testConvertDifferentCurrencies() async throws {
        let service = CurrencyService.shared
        await service.updateRates()
        
        let result = service.convert(100, from: "CNY", to: "USD")
        XCTAssertGreaterThan(result, 0)
        XCTAssertLessThan(result, 100)
    }
    
    func testFormatAmount() throws {
        let service = CurrencyService.shared
        let formatted = service.formatAmount(1234.56, currency: "CNY")
        XCTAssertTrue(formatted.contains("1234.56"))
    }
    
    func testUpdateRates() async throws {
        let service = CurrencyService.shared
        await service.updateRates()
        
        XCTAssertFalse(service.exchangeRates.isEmpty)
        XCTAssertNotNil(service.lastUpdate)
        XCTAssertEqual(service.isLoading, false)
    }
}

final class MonthlyReportServiceTests: XCTestCase {
    func testGenerateReport() throws {
        let service = MonthlyReportService.shared
        
        let transactions = [
            Transaction(amount: 5000, type: .income, category: "工资", note: "", date: Date()),
            Transaction(amount: 1000, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 500, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        
        XCTAssertEqual(report.totalIncome, 5000)
        XCTAssertEqual(report.totalExpense, 1500)
        XCTAssertEqual(report.balance, 3500)
        XCTAssertEqual(report.transactionCount, 3)
    }
    
    func testGenerateReportEmptyTransactions() throws {
        let service = MonthlyReportService.shared
        let report = service.generateReport(transactions: [], for: Date())
        
        XCTAssertEqual(report.totalIncome, 0)
        XCTAssertEqual(report.totalExpense, 0)
        XCTAssertEqual(report.balance, 0)
        XCTAssertEqual(report.transactionCount, 0)
    }
    
    func testGenerateReportTopCategory() throws {
        let service = MonthlyReportService.shared
        
        let transactions = [
            Transaction(amount: 30, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 25, type: .expense, category: "餐饮", note: "", date: Date()),
            Transaction(amount: 40, type: .expense, category: "交通", note: "", date: Date()),
        ]
        
        let report = service.generateReport(transactions: transactions, for: Date())
        
        XCTAssertEqual(report.topCategory, "餐饮")
    }
}

final class ThemeManagerTests: XCTestCase {
    func testDefaultTheme() throws {
        let manager = ThemeManager.shared
        XCTAssertTrue([AppTheme.system, .light, .dark].contains(manager.currentTheme))
    }
    
    func testColorScheme() throws {
        let manager = ThemeManager.shared
        manager.currentTheme = .light
        XCTAssertEqual(manager.colorScheme, .light)
        
        manager.currentTheme = .dark
        XCTAssertEqual(manager.colorScheme, .dark)
        
        manager.currentTheme = .system
        XCTAssertNil(manager.colorScheme)
    }
}

final class BiometricAuthTests: XCTestCase {
    func testBiometricType() throws {
        let auth = BiometricAuth.shared
        let type = auth.getBiometricType()
        XCTAssertFalse(type.isEmpty)
    }
}

final class DebtTests: XCTestCase {
    func testDebtCreation() throws {
        let debt = Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: nil)
        
        XCTAssertEqual(debt.name, "张三")
        XCTAssertEqual(debt.amount, 1000)
        XCTAssertEqual(debt.type, .lend)
        XCTAssertEqual(debt.note, "借款")
        XCTAssertFalse(debt.isSettled)
    }
    
    func testDebtTypeProperties() throws {
        XCTAssertEqual(DebtType.lend.localizedName, "借出")
        XCTAssertEqual(DebtType.borrow.localizedName, "借入")
        XCTAssertEqual(DebtType.lend.icon, "arrow.up.circle.fill")
        XCTAssertEqual(DebtType.borrow.icon, "arrow.down.circle.fill")
    }
}

final class TagTests: XCTestCase {
    func testTagCreation() throws {
        let tag = Tag(name: "重要", color: "red")
        
        XCTAssertEqual(tag.name, "重要")
        XCTAssertEqual(tag.color, "red")
    }
    
    func testTagColors() throws {
        XCTAssertEqual(TagColors.colors.count, 8)
        XCTAssertTrue(TagColors.colors.contains { $0.name == "红色" })
        XCTAssertTrue(TagColors.colors.contains { $0.name == "蓝色" })
    }
}

final class AccountTests: XCTestCase {
    func testAccountCreation() throws {
        let account = Account(name: "支付宝", icon: "a.circle.fill", type: .alipay, balance: 5000)
        
        XCTAssertEqual(account.name, "支付宝")
        XCTAssertEqual(account.icon, "a.circle.fill")
        XCTAssertEqual(account.type, .alipay)
        XCTAssertEqual(account.balance, 5000)
        XCTAssertFalse(account.isDefault)
    }
    
    func testAccountTypeProperties() throws {
        XCTAssertEqual(AccountType.cash.localizedName, "现金")
        XCTAssertEqual(AccountType.bank.localizedName, "银行卡")
        XCTAssertEqual(AccountType.alipay.localizedName, "支付宝")
        XCTAssertEqual(AccountType.wechat.localizedName, "微信")
        XCTAssertEqual(AccountType.credit.localizedName, "信用卡")
        XCTAssertEqual(AccountType.other.localizedName, "其他")
    }
    
    func testAccountTypeIcons() throws {
        XCTAssertEqual(AccountType.cash.icon, "banknote")
        XCTAssertEqual(AccountType.bank.icon, "building.columns")
        XCTAssertEqual(AccountType.credit.icon, "creditcard")
    }
    
    func testDefaultAccounts() throws {
        XCTAssertEqual(AccountType.defaultAccounts.count, 4)
    }
}

final class BudgetTests: XCTestCase {
    func testBudgetCreation() throws {
        let budget = Budget(category: "餐饮", amount: 2000, month: Date())
        
        XCTAssertEqual(budget.category, "餐饮")
        XCTAssertEqual(budget.amount, 2000)
    }
    
    func testBudgetStatus() throws {
        let budget = Budget(category: "餐饮", amount: 1000, month: Date())
        let status = BudgetStatus(budget: budget, spent: 800)
        
        XCTAssertEqual(status.remaining, 200)
        XCTAssertEqual(status.percentage, 0.8)
        XCTAssertFalse(status.isOverBudget)
        XCTAssertTrue(status.isWarning)
    }
    
    func testBudgetStatusOverBudget() throws {
        let budget = Budget(category: "交通", amount: 500, month: Date())
        let status = BudgetStatus(budget: budget, spent: 600)
        
        XCTAssertTrue(status.isOverBudget)
        XCTAssertFalse(status.isWarning)
    }
    
    func testOverallBudgetStatus() throws {
        let budget = OverallBudget(amount: 5000, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 4500)
        
        XCTAssertEqual(status.remaining, 500)
        XCTAssertEqual(status.percentage, 0.9)
        XCTAssertFalse(status.isOverBudget)
        XCTAssertTrue(status.isWarning)
    }
}

final class LedgerTests: XCTestCase {
    func testLedgerCreation() throws {
        let ledger = Ledger(name: "旅行", icon: "airplane", color: "orange", isDefault: false)
        
        XCTAssertEqual(ledger.name, "旅行")
        XCTAssertEqual(ledger.icon, "airplane")
        XCTAssertEqual(ledger.color, "orange")
        XCTAssertFalse(ledger.isDefault)
    }
    
    func testLedgerTypeProperties() throws {
        XCTAssertEqual(LedgerType.personal.localizedName, "个人")
        XCTAssertEqual(LedgerType.family.localizedName, "家庭")
        XCTAssertEqual(LedgerType.travel.localizedName, "旅行")
        XCTAssertEqual(LedgerType.work.localizedName, "工作")
    }
}

final class TransactionTests: XCTestCase {
    func testTransactionCreation() throws {
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())
        
        XCTAssertEqual(transaction.amount, 100)
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(transaction.category, "餐饮")
        XCTAssertEqual(transaction.note, "午餐")
    }
    
    func testTransactionTypeProperties() throws {
        XCTAssertEqual(TransactionType.income.rawValue, "收入")
        XCTAssertEqual(TransactionType.expense.rawValue, "支出")
        XCTAssertEqual(TransactionType.income.localizedName, "收入")
        XCTAssertEqual(TransactionType.expense.localizedName, "支出")
    }
}

final class AppThemeTests: XCTestCase {
    func testAppThemeCases() throws {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        XCTAssertTrue(AppTheme.allCases.contains(.system))
        XCTAssertTrue(AppTheme.allCases.contains(.light))
        XCTAssertTrue(AppTheme.allCases.contains(.dark))
    }
    
    func testAppThemeRawValues() throws {
        XCTAssertEqual(AppTheme.system.rawValue, "system")
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
    }
}

final class FrequencyTests: XCTestCase {
    func testFrequencyCases() throws {
        XCTAssertEqual(Frequency.allCases.count, 4)
    }
    
    func testFrequencyLocalizedName() throws {
        XCTAssertFalse(Frequency.daily.localizedName.isEmpty)
        XCTAssertFalse(Frequency.weekly.localizedName.isEmpty)
        XCTAssertFalse(Frequency.monthly.localizedName.isEmpty)
        XCTAssertFalse(Frequency.yearly.localizedName.isEmpty)
    }
}
