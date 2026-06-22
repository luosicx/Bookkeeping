import XCTest
import SwiftUI
import SwiftData
@testable import Bookkeeping

// MARK: - Snapshot 测试基类
@MainActor
class SnapshotTestCase: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    let snapshotDirectory = "Snapshots"
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self, Account.self, Tag.self, Budget.self, OverallBudget.self, Debt.self, SavingsGoal.self, BillReminder.self, RecurringTransaction.self, CustomCategory.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        container = try ModelContainer(
            for: Transaction.self, Ledger.self, Account.self, Tag.self,
            Budget.self, OverallBudget.self, Debt.self, SavingsGoal.self,
            BillReminder.self, RecurringTransaction.self, CustomCategory.self,
            configurations: config
        )
        context = container.mainContext
        try insertSampleData()
    }
    
    private func insertSampleData() throws {
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
    
    func assertSnapshot<Content: View>(_ view: Content, named name: String, file: StaticString = #file, line: UInt = #line) {
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        
        UIGraphicsBeginImageContextWithOptions(hostingController.view.bounds.size, false, 0)
        hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        XCTAssertNotNil(image, "Failed to capture snapshot for \(name)", file: file, line: line)
        
        window.isHidden = true
    }
}

// MARK: - 主视图快照测试
@MainActor
final class MainViewSnapshotTests: SnapshotTestCase {
    
    func testHomeViewSnapshot() {
        assertSnapshot(HomeView().modelContainer(container), named: "HomeView")
    }
    
    func testStatisticsViewSnapshot() {
        assertSnapshot(StatisticsView().modelContainer(container), named: "StatisticsView")
    }
    
    func testSettingsViewSnapshot() {
        assertSnapshot(SettingsView().modelContainer(container), named: "SettingsView")
    }
    
    func testMainTabViewSnapshot() {
        assertSnapshot(MainTabView().modelContainer(container), named: "MainTabView")
    }
}

// MARK: - 功能视图快照测试
@MainActor
final class FeatureViewSnapshotTests: SnapshotTestCase {
    
    func testBudgetViewSnapshot() {
        assertSnapshot(BudgetView().modelContainer(container), named: "BudgetView")
    }
    
    func testDebtViewSnapshot() {
        assertSnapshot(DebtView().modelContainer(container), named: "DebtView")
    }
    
    func testSavingsGoalViewSnapshot() {
        assertSnapshot(SavingsGoalView().modelContainer(container), named: "SavingsGoalView")
    }
    
    func testBillReminderViewSnapshot() {
        assertSnapshot(BillReminderView().modelContainer(container), named: "BillReminderView")
    }
    
    func testAccountViewSnapshot() {
        assertSnapshot(AccountView().modelContainer(container), named: "AccountView")
    }
    
    func testRecurringTransactionViewSnapshot() {
        assertSnapshot(RecurringTransactionView().modelContainer(container), named: "RecurringTransactionView")
    }
    
    func testTagViewSnapshot() {
        assertSnapshot(TagView().modelContainer(container), named: "TagView")
    }
    
    func testCustomCategoryViewSnapshot() {
        assertSnapshot(CustomCategoryView().modelContainer(container), named: "CustomCategoryView")
    }
    
    func testCalendarViewSnapshot() {
        assertSnapshot(CalendarView().modelContainer(container), named: "CalendarView")
    }
    
    func testBudgetComparisonViewSnapshot() {
        assertSnapshot(BudgetComparisonView().modelContainer(container), named: "BudgetComparisonView")
    }
    
    func testLedgerViewSnapshot() {
        assertSnapshot(LedgerView().modelContainer(container), named: "LedgerView")
    }
    
    func testLedgerStatsViewSnapshot() {
        assertSnapshot(LedgerStatsView().modelContainer(container), named: "LedgerStatsView")
    }
    
    func testCurrencyConverterViewSnapshot() {
        assertSnapshot(CurrencyConverterView().modelContainer(container), named: "CurrencyConverterView")
    }
    
    func testTrendAnalysisViewSnapshot() {
        assertSnapshot(TrendAnalysisView().modelContainer(container), named: "TrendAnalysisView")
    }
    
    func testAnnualReportViewSnapshot() {
        assertSnapshot(AnnualReportView().modelContainer(container), named: "AnnualReportView")
    }
    
    func testNotificationSettingsViewSnapshot() {
        assertSnapshot(NotificationSettingsView().modelContainer(container), named: "NotificationSettingsView")
    }
    
    func testExportViewSnapshot() {
        assertSnapshot(ExportView().modelContainer(container), named: "ExportView")
    }
    
    func testImportViewSnapshot() {
        assertSnapshot(ImportView().modelContainer(container), named: "ImportView")
    }
    
    func testBackupViewSnapshot() {
        assertSnapshot(BackupView().modelContainer(container), named: "BackupView")
    }
    
    func testShareViewSnapshot() {
        assertSnapshot(ShareView().modelContainer(container), named: "ShareView")
    }
    
    func testReportShareViewSnapshot() {
        assertSnapshot(ReportShareView().modelContainer(container), named: "ReportShareView")
    }
    
    func testAppLockViewSnapshot() {
        assertSnapshot(AppLockView().modelContainer(container), named: "AppLockView")
    }
    
    func testReceiptScanViewSnapshot() {
        assertSnapshot(ReceiptScanView { _, _ in }.modelContainer(container), named: "ReceiptScanView")
    }
}

// MARK: - 详情/编辑视图快照测试
@MainActor
final class DetailViewSnapshotTests: SnapshotTestCase {
    
    func testTransactionDetailViewSnapshot() throws {
        let tx = try context.fetch(FetchDescriptor<Bookkeeping.Transaction>()).first!
        let vm = TransactionViewModel()
        vm.modelContext = context
        assertSnapshot(TransactionDetailView(transaction: tx, viewModel: vm).modelContainer(container), named: "TransactionDetailView")
    }
    
    func testAddTransactionViewSnapshot() throws {
        let vm = TransactionViewModel()
        vm.modelContext = context
        vm.fetchTransactions()
        let lvm = LedgerViewModel()
        lvm.modelContext = context
        lvm.fetchLedgers()
        assertSnapshot(AddTransactionView(viewModel: vm, ledgerViewModel: lvm).modelContainer(container), named: "AddTransactionView")
    }
    
    func testEditTransactionViewSnapshot() throws {
        let tx = try context.fetch(FetchDescriptor<Bookkeeping.Transaction>()).first!
        let vm = TransactionViewModel()
        vm.modelContext = context
        assertSnapshot(EditTransactionView(transaction: tx, viewModel: vm).modelContainer(container), named: "EditTransactionView")
    }
    
    func testAddBudgetViewSnapshot() throws {
        let bvm = BudgetViewModel()
        bvm.modelContext = context
        bvm.fetchBudgets()
        assertSnapshot(AddBudgetView(budgetViewModel: bvm).modelContainer(container), named: "AddBudgetView")
    }
    
    func testAddRecurringTransactionViewSnapshot() throws {
        let vm = RecurringTransactionViewModel()
        vm.modelContext = context
        assertSnapshot(AddRecurringTransactionView(viewModel: vm).modelContainer(container), named: "AddRecurringTransactionView")
    }
    
    func testAddAccountViewSnapshot() throws {
        let vm = AccountViewModel()
        vm.modelContext = context
        assertSnapshot(AddAccountView(viewModel: vm).modelContainer(container), named: "AddAccountView")
    }
}

// MARK: - 组件快照测试
@MainActor
final class ComponentSnapshotTests: SnapshotTestCase {
    
    func testTransactionRowExpense() {
        assertSnapshot(TransactionRow(transaction: Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date())), named: "TransactionRowExpense")
    }
    
    func testTransactionRowIncome() {
        assertSnapshot(TransactionRow(transaction: Transaction(amount: 5000, type: .income, category: "工资", note: "工资", date: Date())), named: "TransactionRowIncome")
    }
    
    func testEmptyStateView() {
        assertSnapshot(EmptyStateView(), named: "EmptyStateView")
    }
    
    func testCategoryButtonSelected() {
        assertSnapshot(CategoryButton(category: Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense), isSelected: true) {}, named: "CategoryButtonSelected")
    }
    
    func testCategoryButtonUnselected() {
        assertSnapshot(CategoryButton(category: Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense), isSelected: false) {}, named: "CategoryButtonUnselected")
    }
    
    func testFilterButtonSelected() {
        assertSnapshot(FilterButton(title: "全部", isSelected: true) {}, named: "FilterButtonSelected")
    }
    
    func testFilterButtonIncome() {
        assertSnapshot(FilterButton(title: "收入", isSelected: false, color: .green) {}, named: "FilterButtonIncome")
    }
    
    func testFilterButtonExpense() {
        assertSnapshot(FilterButton(title: "支出", isSelected: false, color: .red) {}, named: "FilterButtonExpense")
    }
    
    func testSummaryCard() {
        assertSnapshot(SummaryCard(balance: 3500, income: 15000, expense: 11500, selectedDate: Date()), named: "SummaryCard")
    }
    
    func testStatCardIncome() {
        assertSnapshot(StatCard(title: "收入", amount: 15000, color: .green), named: "StatCardIncome")
    }
    
    func testStatCardExpense() {
        assertSnapshot(StatCard(title: "支出", amount: 11500, color: .red), named: "StatCardExpense")
    }
    
    func testStatCardBalance() {
        assertSnapshot(StatCard(title: "结余", amount: 3500, color: .blue), named: "StatCardBalance")
    }
    
    func testDebtRowView() {
        assertSnapshot(DebtRowView(debt: Debt(name: "张三", amount: 1000, type: .lend, note: "借款", date: Date(), dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()))) {}, named: "DebtRowView")
    }
    
    func testLedgerChipSelected() {
        assertSnapshot(LedgerChip(name: "个人", icon: "person", color: "blue", isSelected: true) {}, named: "LedgerChipSelected")
    }
    
    func testLedgerChipUnselected() {
        assertSnapshot(LedgerChip(name: "家庭", icon: "house", color: "green", isSelected: false) {}, named: "LedgerChipUnselected")
    }
    
    func testMonthSelector() {
        assertSnapshot(MonthSelector(selectedDate: .constant(Date())), named: "MonthSelector")
    }
    
    func testFilterBar() {
        assertSnapshot(FilterBar(selectedType: .constant(nil)), named: "FilterBar")
    }
    
    func testFilterBarIncome() {
        assertSnapshot(FilterBar(selectedType: .constant(.income)), named: "FilterBarIncome")
    }
    
    func testFilterBarExpense() {
        assertSnapshot(FilterBar(selectedType: .constant(.expense)), named: "FilterBarExpense")
    }
    
    func testTransactionListView() {
        let transactions = [
            Transaction(amount: 100, type: .expense, category: "餐饮", note: "午餐", date: Date()),
            Transaction(amount: 200, type: .income, category: "工资", note: "", date: Date()),
        ]
        let vm = TransactionViewModel()
        assertSnapshot(TransactionListView(transactions: transactions, viewModel: vm), named: "TransactionListView")
    }
    
    func testCategoryChart() {
        let vm = StatisticsViewModel()
        assertSnapshot(CategoryChart(viewModel: vm, selectedDate: Date()), named: "CategoryChart")
    }
    
    func testTrendChart() {
        let vm = StatisticsViewModel()
        assertSnapshot(TrendChart(viewModel: vm, selectedDate: Date()), named: "TrendChart")
    }
    
    func testTopCategoriesView() {
        let vm = StatisticsViewModel()
        assertSnapshot(TopCategoriesView(viewModel: vm, selectedDate: Date()), named: "TopCategoriesView")
    }
    
    func testSummarySection() {
        let vm = StatisticsViewModel()
        assertSnapshot(SummarySection(viewModel: vm, selectedDate: Date()), named: "SummarySection")
    }
    
    func testPeriodPicker() {
        assertSnapshot(PeriodPicker(selectedPeriod: .constant(.month)), named: "PeriodPicker")
    }
    
    func testVoiceInputButton() {
        assertSnapshot(VoiceInputButton(amount: .constant("100"), category: .constant("food"), note: .constant("午餐"), transactionType: .constant(.expense)), named: "VoiceInputButton")
    }
    
    func testChartThemeColors() {
        let view = HStack(spacing: 8) {
            ForEach(0..<8) { index in
                Circle()
                    .fill(ChartTheme.color(for: index))
                    .frame(width: 30, height: 30)
            }
        }
        assertSnapshot(view, named: "ChartThemeColors")
    }
}

// MARK: - BudgetStatus 逻辑测试（非快照）
@MainActor
final class BudgetStatusLogicTests: SnapshotTestCase {
    
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
    
    func testBudgetStatusZeroBudget() {
        let budget = Budget(category: "餐饮", amount: 0, month: Date())
        let status = BudgetStatus(budget: budget, spent: 100)
        XCTAssertEqual(status.percentage, 0)
        XCTAssertTrue(status.isOverBudget)
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
    
    func testOverallBudgetStatusZero() {
        let budget = OverallBudget(amount: 0, month: Date())
        let status = OverallBudgetStatus(budget: budget, spent: 100)
        XCTAssertEqual(status.percentage, 0)
        XCTAssertTrue(status.isOverBudget)
    }
}
