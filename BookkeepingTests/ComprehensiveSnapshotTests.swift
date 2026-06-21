import XCTest
import SwiftUI
import SwiftData
@testable import Bookkeeping

@MainActor
final class ComprehensiveSnapshotTests: XCTestCase {
    
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self, Tag.self, Budget.self, OverallBudget.self, Debt.self, SavingsGoal.self, BillReminder.self, RecurringTransaction.self, CustomCategory.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: Transaction.self, Ledger.self, Account.self, Tag.self,
            Budget.self, OverallBudget.self, Debt.self, SavingsGoal.self,
            BillReminder.self, RecurringTransaction.self, CustomCategory.self,
            configurations: config
        )
    }
    
    private func insertSampleData(context: ModelContext) throws {
        let calendar = Calendar.current
        let today = Date()
        
        let samples: [(Double, TransactionType, String, String, Int)] = [
            (15000, .income, "工资", "6月工资", 0),
            (2000, .income, "奖金", "项目奖金", -2),
            (35.5, .expense, "餐饮", "午餐", 0),
            (128, .expense, "餐饮", "朋友聚餐", -1),
            (6.5, .expense, "交通", "地铁", 0),
            (45, .expense, "交通", "打车", -2),
            (299, .expense, "购物", "买衣服", -3),
            (89, .expense, "购物", "日用品", -5),
            (68, .expense, "娱乐", "电影票", -4),
            (1500, .expense, "住房", "房租", -7),
            (200, .expense, "医疗", "感冒药", -6),
            (5000, .expense, "教育", "在线课程", -10),
            (3000, .income, "投资", "基金收益", -5),
            (56, .expense, "餐饮", "下午茶", -3),
            (15, .expense, "交通", "公交", -1),
        ]
        
        for (amount, type, category, note, dayOffset) in samples {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let transaction = Transaction(amount: amount, type: type, category: category, note: note, date: date)
            context.insert(transaction)
        }
        
        let ledgers = [
            ("个人账本", "person", "blue", true),
            ("家庭账本", "house", "green", false),
            ("旅行账本", "airplane", "orange", false)
        ]
        for (name, icon, color, isDefault) in ledgers {
            let ledger = Ledger(name: name, icon: icon, color: color, isDefault: isDefault)
            context.insert(ledger)
        }
        
        let accounts = [
            ("现金", AccountType.cash, "banknote", true),
            ("银行卡", AccountType.bank, "building.columns", false),
            ("支付宝", AccountType.alipay, "a.circle.fill", false),
            ("微信", AccountType.wechat, "w.circle.fill", false)
        ]
        for (name, type, icon, isDefault) in accounts {
            let account = Account(name: name, icon: icon, type: type, balance: Double.random(in: 1000...10000), isDefault: isDefault)
            context.insert(account)
        }
        
        let tags = [
            ("重要", "red"),
            ("工作", "blue"),
            ("个人", "green"),
        ]
        for (name, color) in tags {
            let tag = Tag(name: name, color: color)
            context.insert(tag)
        }
        
        let debts = [
            ("张三", 1000.0, DebtType.lend, "借款"),
            ("李四", 500.0, DebtType.borrow, ""),
        ]
        for (name, amount, type, note) in debts {
            let debt = Debt(name: name, amount: amount, type: type, note: note, date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))
            context.insert(debt)
        }
        
        let goals = [
            ("旅行基金", "airplane", 10000.0),
            ("买车", "car", 50000.0),
        ]
        for (name, icon, target) in goals {
            let goal = SavingsGoal(name: name, icon: icon, targetAmount: target, deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()))
            context.insert(goal)
        }
        
        let reminders = [
            ("电费", 200.0, Frequency.monthly),
            ("房租", 3000.0, Frequency.monthly),
            ("保险", nil, Frequency.yearly),
        ]
        for (title, amount, freq) in reminders {
            let reminder = BillReminder(title: title, amount: amount, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, repeatFrequency: freq, note: "")
            context.insert(reminder)
        }
        
        let budgets = [
            ("餐饮", 2000.0),
            ("交通", 1000.0),
            ("购物", 3000.0),
        ]
        for (category, amount) in budgets {
            let budget = Budget(category: category, amount: amount, month: Date())
            context.insert(budget)
        }
        
        let overallBudget = OverallBudget(amount: 10000, month: Date())
        context.insert(overallBudget)
        
        try context.save()
    }
    
    func testHomeViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = HomeView().modelContainer(container)
        takeSnapshot(of: view, named: "HomeViewWithData")
    }
    
    func testStatisticsViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = StatisticsView().modelContainer(container)
        takeSnapshot(of: view, named: "StatisticsViewWithData")
    }
    
    func testBudgetViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = BudgetView().modelContainer(container)
        takeSnapshot(of: view, named: "BudgetViewWithData")
    }
    
    func testDebtViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = DebtView().modelContainer(container)
        takeSnapshot(of: view, named: "DebtViewWithData")
    }
    
    func testSavingsGoalViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = SavingsGoalView().modelContainer(container)
        takeSnapshot(of: view, named: "SavingsGoalViewWithData")
    }
    
    func testBillReminderViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = BillReminderView().modelContainer(container)
        takeSnapshot(of: view, named: "BillReminderViewWithData")
    }
    
    func testAccountViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = AccountView().modelContainer(container)
        takeSnapshot(of: view, named: "AccountViewWithData")
    }
    
    func testRecurringTransactionViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = RecurringTransactionView().modelContainer(container)
        takeSnapshot(of: view, named: "RecurringTransactionViewWithData")
    }
    
    func testTagViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = TagView().modelContainer(container)
        takeSnapshot(of: view, named: "TagViewWithData")
    }
    
    func testCustomCategoryViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = CustomCategoryView().modelContainer(container)
        takeSnapshot(of: view, named: "CustomCategoryViewWithData")
    }
    
    func testCalendarViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = CalendarView().modelContainer(container)
        takeSnapshot(of: view, named: "CalendarViewWithData")
    }
    
    func testBudgetComparisonViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = BudgetComparisonView().modelContainer(container)
        takeSnapshot(of: view, named: "BudgetComparisonViewWithData")
    }
    
    func testLedgerViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = LedgerView().modelContainer(container)
        takeSnapshot(of: view, named: "LedgerViewWithData")
    }
    
    func testLedgerStatsViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = LedgerStatsView().modelContainer(container)
        takeSnapshot(of: view, named: "LedgerStatsViewWithData")
    }
    
    func testSettingsViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = SettingsView().modelContainer(container)
        takeSnapshot(of: view, named: "SettingsViewWithData")
    }
    
    func testCurrencyConverterViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = CurrencyConverterView().modelContainer(container)
        takeSnapshot(of: view, named: "CurrencyConverterViewWithData")
    }
    
    func testTrendAnalysisViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = TrendAnalysisView().modelContainer(container)
        takeSnapshot(of: view, named: "TrendAnalysisViewWithData")
    }
    
    func testAnnualReportViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = AnnualReportView().modelContainer(container)
        takeSnapshot(of: view, named: "AnnualReportViewWithData")
    }
    
    func testNotificationSettingsViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = NotificationSettingsView().modelContainer(container)
        takeSnapshot(of: view, named: "NotificationSettingsViewWithData")
    }
    
    func testExportViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = ExportView().modelContainer(container)
        takeSnapshot(of: view, named: "ExportViewWithData")
    }
    
    func testImportViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = ImportView().modelContainer(container)
        takeSnapshot(of: view, named: "ImportViewWithData")
    }
    
    func testBackupViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = BackupView().modelContainer(container)
        takeSnapshot(of: view, named: "BackupViewWithData")
    }
    
    func testShareViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = ShareView().modelContainer(container)
        takeSnapshot(of: view, named: "ShareViewWithData")
    }
    
    func testReportShareViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = ReportShareView().modelContainer(container)
        takeSnapshot(of: view, named: "ReportShareViewWithData")
    }
    
    func testAppLockViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = AppLockView().modelContainer(container)
        takeSnapshot(of: view, named: "AppLockViewWithData")
    }
    
    func testReceiptScanViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = ReceiptScanView { _, _ in }.modelContainer(container)
        takeSnapshot(of: view, named: "ReceiptScanViewWithData")
    }
    
    func testTransactionDetailViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(descriptor)
        
        if let transaction = transactions.first {
            let viewModel = TransactionViewModel()
            viewModel.modelContext = context
            
            let view = TransactionDetailView(transaction: transaction, viewModel: viewModel)
                .modelContainer(container)
            takeSnapshot(of: view, named: "TransactionDetailViewWithData")
        }
    }
    
    func testAddTransactionViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = TransactionViewModel()
        viewModel.modelContext = context
        viewModel.fetchTransactions()
        
        let ledgerViewModel = LedgerViewModel()
        ledgerViewModel.modelContext = context
        ledgerViewModel.fetchLedgers()
        
        let view = AddTransactionView(viewModel: viewModel, ledgerViewModel: ledgerViewModel)
            .modelContainer(container)
        takeSnapshot(of: view, named: "AddTransactionViewWithData")
    }
    
    func testEditTransactionViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(descriptor)
        
        if let transaction = transactions.first {
            let viewModel = TransactionViewModel()
            viewModel.modelContext = context
            
            let view = EditTransactionView(transaction: transaction, viewModel: viewModel)
                .modelContainer(container)
            takeSnapshot(of: view, named: "EditTransactionViewWithData")
        }
    }
    
    func testAddBudgetViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let budgetViewModel = BudgetViewModel()
        budgetViewModel.modelContext = context
        budgetViewModel.fetchBudgets()
        
        let view = AddBudgetView(budgetViewModel: budgetViewModel)
            .modelContainer(container)
        takeSnapshot(of: view, named: "AddBudgetViewWithData")
    }
    
    func testAddRecurringTransactionViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = RecurringTransactionViewModel()
        viewModel.modelContext = context
        
        let view = AddRecurringTransactionView(viewModel: viewModel)
            .modelContainer(container)
        takeSnapshot(of: view, named: "AddRecurringTransactionViewWithData")
    }
    
    func testAddAccountViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = AccountViewModel()
        viewModel.modelContext = context
        
        let view = AddAccountView(viewModel: viewModel)
            .modelContainer(container)
        takeSnapshot(of: view, named: "AddAccountViewWithData")
    }
    
    func testMainTabViewWithData() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let view = MainTabView().modelContainer(container)
        takeSnapshot(of: view, named: "MainTabViewWithData")
    }
    
    func testVoiceInputButton() throws {
        let view = VoiceInputButton(
            amount: .constant("100"),
            category: .constant("food"),
            note: .constant("午餐"),
            transactionType: .constant(.expense)
        )
        takeSnapshot(of: view, named: "VoiceInputButton")
    }
    
    func testChartTheme() throws {
        let view = VStack(spacing: 20) {
            Text("ChartTheme Colors").font(.headline)
            HStack {
                ForEach(0..<8) { index in
                    Circle()
                        .fill(ChartTheme.color(for: index))
                        .frame(width: 30, height: 30)
                }
            }
            Text("Category Gradients").font(.headline)
            HStack {
                ChartTheme.categoryGradient("餐饮")
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                ChartTheme.categoryGradient("交通")
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                ChartTheme.incomeGradient()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                ChartTheme.expenseGradient()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        takeSnapshot(of: view, named: "ChartThemeView")
    }
    
    func testTransactionRow() throws {
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐外卖", date: Date())
        let view = TransactionRow(transaction: transaction)
        takeSnapshot(of: view, named: "TransactionRow")
    }
    
    func testTransactionRowIncome() throws {
        let transaction = Transaction(amount: 5000, type: .income, category: "工资", note: "6月工资", date: Date())
        let view = TransactionRow(transaction: transaction)
        takeSnapshot(of: view, named: "TransactionRowIncome")
    }
    
    func testEmptyStateView() throws {
        let view = EmptyStateView()
        takeSnapshot(of: view, named: "EmptyStateView")
    }
    
    func testCategoryButton() throws {
        let category = Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense)
        
        let view = VStack(spacing: 10) {
            CategoryButton(category: category, isSelected: true) {}
            CategoryButton(category: category, isSelected: false) {}
        }
        takeSnapshot(of: view, named: "CategoryButtons")
    }
    
    func testFilterButtons() throws {
        let view = VStack(spacing: 10) {
            FilterButton(title: "全部", isSelected: true) {}
            FilterButton(title: "收入", isSelected: false, color: .green) {}
            FilterButton(title: "支出", isSelected: false, color: .red) {}
        }
        takeSnapshot(of: view, named: "FilterButtons")
    }
    
    func testSummaryCard() throws {
        let view = SummaryCard(balance: 3500, income: 15000, expense: 11500, selectedDate: Date())
        takeSnapshot(of: view, named: "SummaryCard")
    }
    
    func testStatCard() throws {
        let view = HStack(spacing: 10) {
            StatCard(title: "收入", amount: 15000, color: .green)
            StatCard(title: "支出", amount: 11500, color: .red)
            StatCard(title: "结余", amount: 3500, color: .blue)
        }
        takeSnapshot(of: view, named: "StatCards")
    }
    
    func testBudgetStatusCard() throws {
        let budget = Budget(category: "餐饮", amount: 2000, month: Date())
        let status = BudgetStatus(budget: budget, spent: 800)
        
        let view = VStack {
            Text("Budget Status").font(.headline)
            Text("Percentage: \(Int(status.percentage * 100))%")
            Text("Remaining: ¥\(status.remaining)")
            Text("Over Budget: \(status.isOverBudget)")
            Text("Warning: \(status.isWarning)")
        }
        takeSnapshot(of: view, named: "BudgetStatusCard")
    }
    
    func testDebtRowView() throws {
        let debt = Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))
        
        let view = DebtRowView(debt: debt) {}
        takeSnapshot(of: view, named: "DebtRowView")
    }
    
    func testLedgerChip() throws {
        let view = HStack(spacing: 10) {
            LedgerChip(name: "个人", icon: "person", color: "blue", isSelected: true) {}
            LedgerChip(name: "家庭", icon: "house", color: "green", isSelected: false) {}
        }
        takeSnapshot(of: view, named: "LedgerChips")
    }
    
    func testMonthSelector() throws {
        let view = MonthSelector(selectedDate: .constant(Date()))
        takeSnapshot(of: view, named: "MonthSelector")
    }
    
    func testFilterBar() throws {
        let view = FilterBar(selectedType: .constant(nil))
        takeSnapshot(of: view, named: "FilterBar")
    }
    
    private func takeSnapshot<Content: View>(of view: Content, named name: String, file: StaticString = #file, line: UInt = #line) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        
        UIGraphicsBeginImageContextWithOptions(hostingController.view.bounds.size, false, 0)
        hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        XCTAssertNotNil(image, "Failed to capture snapshot for \(name)", file: file, line: line)
    }
}
