import XCTest
import SwiftUI
import SwiftData
@testable import Bookkeeping

@MainActor
final class ViewExecutionTests: XCTestCase {
    
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
            context.insert(Transaction(amount: amount, type: type, category: category, note: note, date: date))
        }
        
        for (name, icon, color, isDefault) in [("个人账本", "person", "blue", true), ("家庭账本", "house", "green", false), ("旅行账本", "airplane", "orange", false)] {
            context.insert(Ledger(name: name, icon: icon, color: color, isDefault: isDefault))
        }
        
        for (name, type, icon, isDefault) in [("现金", AccountType.cash, "banknote", true), ("银行卡", AccountType.bank, "building.columns", false), ("支付宝", AccountType.alipay, "a.circle.fill", false), ("微信", AccountType.wechat, "w.circle.fill", false)] {
            context.insert(Account(name: name, icon: icon, type: type, balance: Double.random(in: 1000...10000), isDefault: isDefault))
        }
        
        for (name, color) in [("重要", "red"), ("工作", "blue"), ("个人", "green")] {
            context.insert(Tag(name: name, color: color))
        }
        
        for (name, amount, type, note) in [("张三", 1000.0, DebtType.lend, "借款"), ("李四", 500.0, DebtType.borrow, "")] {
            context.insert(Debt(name: name, amount: amount, type: type, note: note, date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())))
        }
        
        for (name, icon, target) in [("旅行基金", "airplane", 10000.0), ("买车", "car", 50000.0)] {
            context.insert(SavingsGoal(name: name, icon: icon, targetAmount: target, deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date())))
        }
        
        for (title, amount, freq) in [("电费", 200.0, Frequency.monthly), ("房租", 3000.0, Frequency.monthly), ("保险", nil, Frequency.yearly)] {
            context.insert(BillReminder(title: title, amount: amount, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, repeatFrequency: freq, note: ""))
        }
        
        for (category, amount) in [("餐饮", 2000.0), ("交通", 1000.0), ("购物", 3000.0)] {
            context.insert(Budget(category: category, amount: amount, month: Date()))
        }
        
        context.insert(OverallBudget(amount: 10000, month: Date()))
        
        try context.save()
    }
    
    private func fullyRender<Content: View>(_ view: Content) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        window.isHidden = true
    }
    
    // MARK: - Main Views
    
    func testHomeView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(HomeView().modelContainer(container))
    }
    
    func testStatisticsView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(StatisticsView().modelContainer(container))
    }
    
    func testBudgetView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(BudgetView().modelContainer(container))
    }
    
    func testDebtView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(DebtView().modelContainer(container))
    }
    
    func testSavingsGoalView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(SavingsGoalView().modelContainer(container))
    }
    
    func testBillReminderView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(BillReminderView().modelContainer(container))
    }
    
    func testAccountView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(AccountView().modelContainer(container))
    }
    
    func testRecurringTransactionView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(RecurringTransactionView().modelContainer(container))
    }
    
    func testTagView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(TagView().modelContainer(container))
    }
    
    func testCustomCategoryView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(CustomCategoryView().modelContainer(container))
    }
    
    func testCalendarView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(CalendarView().modelContainer(container))
    }
    
    func testBudgetComparisonView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(BudgetComparisonView().modelContainer(container))
    }
    
    func testLedgerView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(LedgerView().modelContainer(container))
    }
    
    func testLedgerStatsView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(LedgerStatsView().modelContainer(container))
    }
    
    func testSettingsView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(SettingsView().modelContainer(container))
    }
    
    func testCurrencyConverterView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(CurrencyConverterView().modelContainer(container))
    }
    
    func testTrendAnalysisView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(TrendAnalysisView().modelContainer(container))
    }
    
    func testAnnualReportView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(AnnualReportView().modelContainer(container))
    }
    
    func testNotificationSettingsView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(NotificationSettingsView().modelContainer(container))
    }
    
    func testExportView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(ExportView().modelContainer(container))
    }
    
    func testImportView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(ImportView().modelContainer(container))
    }
    
    func testBackupView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(BackupView().modelContainer(container))
    }
    
    func testShareView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(ShareView().modelContainer(container))
    }
    
    func testReportShareView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(ReportShareView().modelContainer(container))
    }
    
    func testAppLockView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(AppLockView().modelContainer(container))
    }
    
    func testReceiptScanView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(ReceiptScanView { _, _ in }.modelContainer(container))
    }
    
    func testMainTabView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        fullyRender(MainTabView().modelContainer(container))
    }
    
    // MARK: - Sub Views
    
    func testTransactionDetailView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let tx = try context.fetch(FetchDescriptor<Transaction>()).first!
        let vm = TransactionViewModel()
        vm.modelContext = context
        fullyRender(TransactionDetailView(transaction: tx, viewModel: vm).modelContainer(container))
    }
    
    func testAddTransactionView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let vm = TransactionViewModel()
        vm.modelContext = context
        vm.fetchTransactions()
        let lvm = LedgerViewModel()
        lvm.modelContext = context
        lvm.fetchLedgers()
        fullyRender(AddTransactionView(viewModel: vm, ledgerViewModel: lvm).modelContainer(container))
    }
    
    func testEditTransactionView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let tx = try context.fetch(FetchDescriptor<Transaction>()).first!
        let vm = TransactionViewModel()
        vm.modelContext = context
        fullyRender(EditTransactionView(transaction: tx, viewModel: vm).modelContainer(container))
    }
    
    func testAddBudgetView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let bvm = BudgetViewModel()
        bvm.modelContext = context
        bvm.fetchBudgets()
        fullyRender(AddBudgetView(budgetViewModel: bvm).modelContainer(container))
    }
    
    func testAddRecurringTransactionView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let vm = RecurringTransactionViewModel()
        vm.modelContext = context
        fullyRender(AddRecurringTransactionView(viewModel: vm).modelContainer(container))
    }
    
    func testAddAccountView() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        try insertSampleData(context: context)
        let vm = AccountViewModel()
        vm.modelContext = context
        fullyRender(AddAccountView(viewModel: vm).modelContainer(container))
    }
    
    // MARK: - Small Components
    
    func testVoiceInputButton() {
        fullyRender(VoiceInputButton(amount: .constant("100"), category: .constant("food"), note: .constant("午餐"), transactionType: .constant(.expense)))
    }
    
    func testTransactionRowExpense() {
        fullyRender(TransactionRow(transaction: Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())))
    }
    
    func testTransactionRowIncome() {
        fullyRender(TransactionRow(transaction: Transaction(amount: 5000, type: .income, category: "工资", note: "工资", date: Date())))
    }
    
    func testEmptyStateView() {
        fullyRender(EmptyStateView())
    }
    
    func testCategoryButtonSelected() {
        fullyRender(CategoryButton(category: Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense), isSelected: true) {})
    }
    
    func testCategoryButtonUnselected() {
        fullyRender(CategoryButton(category: Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense), isSelected: false) {})
    }
    
    func testFilterButtonSelected() {
        fullyRender(FilterButton(title: "全部", isSelected: true) {})
    }
    
    func testFilterButtonIncome() {
        fullyRender(FilterButton(title: "收入", isSelected: false, color: .green) {})
    }
    
    func testFilterButtonExpense() {
        fullyRender(FilterButton(title: "支出", isSelected: false, color: .red) {})
    }
    
    func testSummaryCard() {
        fullyRender(SummaryCard(balance: 3500, income: 15000, expense: 11500, selectedDate: Date()))
    }
    
    func testStatCardIncome() {
        fullyRender(StatCard(title: "收入", amount: 15000, color: .green))
    }
    
    func testStatCardExpense() {
        fullyRender(StatCard(title: "支出", amount: 11500, color: .red))
    }
    
    func testStatCardBalance() {
        fullyRender(StatCard(title: "结余", amount: 3500, color: .blue))
    }
    
    func testDebtRowView() {
        fullyRender(DebtRowView(debt: Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))) {})
    }
    
    func testLedgerChipSelected() {
        fullyRender(LedgerChip(name: "个人", icon: "person", color: "blue", isSelected: true) {})
    }
    
    func testLedgerChipUnselected() {
        fullyRender(LedgerChip(name: "家庭", icon: "house", color: "green", isSelected: false) {})
    }
    
    func testMonthSelector() {
        fullyRender(MonthSelector(selectedDate: .constant(Date())))
    }
    
    func testFilterBar() {
        fullyRender(FilterBar(selectedType: .constant(nil)))
    }
    
    func testFilterBarIncome() {
        fullyRender(FilterBar(selectedType: .constant(.income)))
    }
    
    func testFilterBarExpense() {
        fullyRender(FilterBar(selectedType: .constant(.expense)))
    }
    
    func testChartThemeColors() {
        for i in 0..<8 {
            _ = ChartTheme.color(for: i)
        }
    }
    
    func testChartThemeGradients() {
        _ = ChartTheme.incomeGradient()
        _ = ChartTheme.expenseGradient()
        _ = ChartTheme.balanceGradient()
        for category in ["餐饮", "交通", "购物", "娱乐", "住房", "医疗", "教育", "其他", "工资", "奖金", "投资"] {
            _ = ChartTheme.categoryGradient(category)
        }
    }
    
    func testPeriodPicker() {
        fullyRender(PeriodPicker(selectedPeriod: .constant(.month)))
    }
    
    func testTransactionListView() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date()),
        ]
        let vm = TransactionViewModel()
        fullyRender(TransactionListView(transactions: transactions, viewModel: vm))
    }
    
    func testCategoryChart() {
        let vm = StatisticsViewModel()
        fullyRender(CategoryChart(viewModel: vm, selectedDate: Date()))
    }
    
    func testTrendChart() {
        let vm = StatisticsViewModel()
        fullyRender(TrendChart(viewModel: vm, selectedDate: Date()))
    }
    
    func testTopCategoriesView() {
        let vm = StatisticsViewModel()
        fullyRender(TopCategoriesView(viewModel: vm, selectedDate: Date()))
    }
    
    func testSummarySection() {
        let vm = StatisticsViewModel()
        fullyRender(SummarySection(viewModel: vm, selectedDate: Date()))
    }
    
    func testTransactionListRow() {
        let tx = Transaction(amount: 50, type: .expense, category: "交通", note: "打车", date: Date())
        fullyRender(TransactionRow(transaction: tx))
    }
    
    func testBudgetStatusOnTrack() {
        let budget = Budget(category: "餐饮", amount: 1000, month: Date())
        let status = BudgetStatus(budget: budget, spent: 500)
        XCTAssertEqual(status.remaining, 500)
        XCTAssertEqual(status.percentage, 0.5)
        XCTAssertFalse(status.isOverBudget)
        XCTAssertFalse(status.isWarning)
    }
    
    func testBudgetStatusWarning() {
        let budget = Budget(category: "餐饮", amount: 1000, month: Date())
        let status = BudgetStatus(budget: budget, spent: 850)
        XCTAssertEqual(status.percentage, 0.85)
        XCTAssertFalse(status.isOverBudget)
        XCTAssertTrue(status.isWarning)
    }
    
    func testBudgetStatusOverBudget() {
        let budget = Budget(category: "餐饮", amount: 1000, month: Date())
        let status = BudgetStatus(budget: budget, spent: 1200)
        XCTAssertEqual(status.remaining, -200)
        XCTAssertTrue(status.isOverBudget)
        XCTAssertFalse(status.isWarning)
    }
    
    func testOverallBudgetStatus() {
        let budget = OverallBudget(amount: 5000, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 4500)
        XCTAssertEqual(status.percentage, 0.9)
        XCTAssertTrue(status.isWarning)
        XCTAssertFalse(status.isOverBudget)
    }
    
    func testOverallBudgetStatusOver() {
        let budget = OverallBudget(amount: 5000, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 6000)
        XCTAssertTrue(status.isOverBudget)
    }
}
