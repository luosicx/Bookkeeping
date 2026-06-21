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
        
        let tags = [("重要", "red"), ("工作", "blue"), ("个人", "green")]
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
        
        let budgets = [("餐饮", 2000.0), ("交通", 1000.0), ("购物", 3000.0)]
        for (category, amount) in budgets {
            let budget = Budget(category: category, amount: amount, month: Date())
            context.insert(budget)
        }
        
        let overallBudget = OverallBudget(amount: 10000, month: Date())
        context.insert(overallBudget)
        
        try context.save()
    }
    
    private func renderView<Content: View>(_ view: Content) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.loadViewIfNeeded()
        hostingController.view.layoutIfNeeded()
    }
    
    // MARK: - Views with ModelContainer
    
    func testHomeViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(HomeView().modelContainer(container))
    }
    
    func testStatisticsViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(StatisticsView().modelContainer(container))
    }
    
    func testBudgetViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(BudgetView().modelContainer(container))
    }
    
    func testDebtViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(DebtView().modelContainer(container))
    }
    
    func testSavingsGoalViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(SavingsGoalView().modelContainer(container))
    }
    
    func testBillReminderViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(BillReminderView().modelContainer(container))
    }
    
    func testAccountViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(AccountView().modelContainer(container))
    }
    
    func testRecurringTransactionViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(RecurringTransactionView().modelContainer(container))
    }
    
    func testTagViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(TagView().modelContainer(container))
    }
    
    func testCustomCategoryViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(CustomCategoryView().modelContainer(container))
    }
    
    func testCalendarViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(CalendarView().modelContainer(container))
    }
    
    func testBudgetComparisonViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(BudgetComparisonView().modelContainer(container))
    }
    
    func testLedgerViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(LedgerView().modelContainer(container))
    }
    
    func testLedgerStatsViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(LedgerStatsView().modelContainer(container))
    }
    
    func testSettingsViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(SettingsView().modelContainer(container))
    }
    
    func testCurrencyConverterViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(CurrencyConverterView().modelContainer(container))
    }
    
    func testTrendAnalysisViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(TrendAnalysisView().modelContainer(container))
    }
    
    func testAnnualReportViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(AnnualReportView().modelContainer(container))
    }
    
    func testNotificationSettingsViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(NotificationSettingsView().modelContainer(container))
    }
    
    func testExportViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(ExportView().modelContainer(container))
    }
    
    func testImportViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(ImportView().modelContainer(container))
    }
    
    func testBackupViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(BackupView().modelContainer(container))
    }
    
    func testShareViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(ShareView().modelContainer(container))
    }
    
    func testReportShareViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(ReportShareView().modelContainer(container))
    }
    
    func testAppLockViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(AppLockView().modelContainer(container))
    }
    
    func testReceiptScanViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(ReceiptScanView { _, _ in }.modelContainer(container))
    }
    
    func testMainTabViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        renderView(MainTabView().modelContainer(container))
    }
    
    // MARK: - Views with ViewModel
    
    func testTransactionDetailViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(descriptor)
        
        if let transaction = transactions.first {
            let viewModel = TransactionViewModel()
            viewModel.modelContext = context
            renderView(TransactionDetailView(transaction: transaction, viewModel: viewModel).modelContainer(container))
        }
    }
    
    func testAddTransactionViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = TransactionViewModel()
        viewModel.modelContext = context
        viewModel.fetchTransactions()
        
        let ledgerViewModel = LedgerViewModel()
        ledgerViewModel.modelContext = context
        ledgerViewModel.fetchLedgers()
        
        renderView(AddTransactionView(viewModel: viewModel, ledgerViewModel: ledgerViewModel).modelContainer(container))
    }
    
    func testEditTransactionViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let descriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(descriptor)
        
        if let transaction = transactions.first {
            let viewModel = TransactionViewModel()
            viewModel.modelContext = context
            renderView(EditTransactionView(transaction: transaction, viewModel: viewModel).modelContainer(container))
        }
    }
    
    func testAddBudgetViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let budgetViewModel = BudgetViewModel()
        budgetViewModel.modelContext = context
        budgetViewModel.fetchBudgets()
        
        renderView(AddBudgetView(budgetViewModel: budgetViewModel).modelContainer(container))
    }
    
    func testAddRecurringTransactionViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = RecurringTransactionViewModel()
        viewModel.modelContext = context
        
        renderView(AddRecurringTransactionView(viewModel: viewModel).modelContainer(container))
    }
    
    func testAddAccountViewRender() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        
        let viewModel = AccountViewModel()
        viewModel.modelContext = context
        
        renderView(AddAccountView(viewModel: viewModel).modelContainer(container))
    }
    
    // MARK: - Simple Views
    
    func testVoiceInputButtonRender() throws {
        renderView(VoiceInputButton(amount: .constant("100"), category: .constant("food"), note: .constant("午餐"), transactionType: .constant(.expense)))
    }
    
    func testTransactionRowRender() throws {
        let transaction = Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐外卖", date: Date())
        renderView(TransactionRow(transaction: transaction))
    }
    
    func testTransactionRowIncomeRender() throws {
        let transaction = Transaction(amount: 5000, type: .income, category: "工资", note: "6月工资", date: Date())
        renderView(TransactionRow(transaction: transaction))
    }
    
    func testEmptyStateViewRender() throws {
        renderView(EmptyStateView())
    }
    
    func testCategoryButtonRender() throws {
        let category = Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense)
        renderView(CategoryButton(category: category, isSelected: true) {})
        renderView(CategoryButton(category: category, isSelected: false) {})
    }
    
    func testFilterButtonRender() throws {
        renderView(FilterButton(title: "全部", isSelected: true) {})
        renderView(FilterButton(title: "收入", isSelected: false, color: .green) {})
        renderView(FilterButton(title: "支出", isSelected: false, color: .red) {})
    }
    
    func testSummaryCardRender() throws {
        renderView(SummaryCard(balance: 3500, income: 15000, expense: 11500, selectedDate: Date()))
    }
    
    func testStatCardRender() throws {
        renderView(StatCard(title: "收入", amount: 15000, color: .green))
    }
    
    func testDebtRowViewRender() throws {
        let debt = Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))
        renderView(DebtRowView(debt: debt) {})
    }
    
    func testLedgerChipRender() throws {
        renderView(LedgerChip(name: "个人", icon: "person", color: "blue", isSelected: true) {})
        renderView(LedgerChip(name: "家庭", icon: "house", color: "green", isSelected: false) {})
    }
    
    func testMonthSelectorRender() throws {
        renderView(MonthSelector(selectedDate: .constant(Date())))
    }
    
    func testFilterBarRender() throws {
        renderView(FilterBar(selectedType: .constant(nil)))
    }
    
    func testChartThemeRender() throws {
        let view = VStack(spacing: 20) {
            ForEach(0..<8) { index in
                Circle()
                    .fill(ChartTheme.color(for: index))
                    .frame(width: 30, height: 30)
            }
        }
        renderView(view)
    }
}
