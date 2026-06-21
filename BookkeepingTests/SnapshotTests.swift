import XCTest
import SwiftUI
@testable import Bookkeeping

@MainActor
final class SnapshotTests: XCTestCase {
    
    private func takeSnapshot<Content: View>(of view: Content, named name: String, file: StaticString = #file, line: UInt = #line) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        
        UIGraphicsBeginImageContextWithOptions(hostingController.view.bounds.size, false, 0)
        hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        XCTAssertNotNil(image, "Failed to capture snapshot for \(name)", file: file, line: line)
        
        // 保存快照用于视觉验证
        if let image = image {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let snapshotsPath = documentsPath.appendingPathComponent("Snapshots")
            try? FileManager.default.createDirectory(at: snapshotsPath, withIntermediateDirectories: true)
            let fileURL = snapshotsPath.appendingPathComponent("\(name).png")
            if let data = image.pngData() {
                try? data.write(to: fileURL)
            }
        }
    }
    
    func testHomeViewSnapshot() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self, Ledger.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, Ledger.self, configurations: config)
        let context = container.mainContext
        
        let samples: [(Double, TransactionType, String, String)] = [
            (15000, .income, "工资", "6月工资"),
            (35.5, .expense, "餐饮", "午餐"),
            (128, .expense, "餐饮", "聚餐"),
            (6.5, .expense, "交通", "地铁"),
            (45, .expense, "交通", "打车"),
            (299, .expense, "购物", "衣服"),
            (68, .expense, "娱乐", "电影"),
            (1500, .expense, "住房", "房租"),
        ]
        
        for (amount, type, category, note) in samples {
            let transaction = Transaction(amount: amount, type: type, category: category, note: note, date: Date())
            context.insert(transaction)
        }
        try context.save()
        
        let viewModel = TransactionViewModel()
        viewModel.modelContext = context
        viewModel.fetchTransactions()
        viewModel.filterTransactions(type: nil, searchText: "", date: Date(), ledger: nil)
        
        let view = HomeView()
            .modelContainer(container)
        
        takeSnapshot(of: view, named: "HomeView")
    }
    
    func testStatisticsViewSnapshot() throws {
        let config = ModelConfiguration(
            schema: Schema([Transaction.self]),
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Transaction.self, configurations: config)
        let context = container.mainContext
        
        let calendar = Calendar.current
        let today = Date()
        
        let samples: [(Double, TransactionType, String, Int)] = [
            (15000, .income, "工资", 0),
            (35.5, .expense, "餐饮", 0),
            (128, .expense, "餐饮", -1),
            (6.5, .expense, "交通", 0),
            (45, .expense, "交通", -2),
            (299, .expense, "购物", -3),
            (68, .expense, "娱乐", -4),
            (1500, .expense, "住房", -7),
        ]
        
        for (amount, type, category, dayOffset) in samples {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let transaction = Transaction(amount: amount, type: type, category: category, note: "", date: date)
            context.insert(transaction)
        }
        try context.save()
        
        let view = StatisticsView()
            .modelContainer(container)
        
        takeSnapshot(of: view, named: "StatisticsView")
    }
    
    func testTransactionDetailViewSnapshot() throws {
        let transaction = Transaction(
            amount: 100,
            type: .expense,
            category: "餐饮",
            note: "午餐外卖",
            date: Date()
        )
        
        let viewModel = TransactionViewModel()
        
        let view = TransactionDetailView(transaction: transaction, viewModel: viewModel)
        
        takeSnapshot(of: view, named: "TransactionDetailView")
    }
    
    func testBudgetViewSnapshot() throws {
        let view = BudgetView()
        takeSnapshot(of: view, named: "BudgetView")
    }
    
    func testDebtViewSnapshot() throws {
        let view = DebtView()
        takeSnapshot(of: view, named: "DebtView")
    }
    
    func testSettingsViewSnapshot() throws {
        let view = SettingsView()
        takeSnapshot(of: view, named: "SettingsView")
    }
    
    func testCurrencyConverterViewSnapshot() throws {
        let view = CurrencyConverterView()
        takeSnapshot(of: view, named: "CurrencyConverterView")
    }
    
    func testCalendarViewSnapshot() throws {
        let view = CalendarView()
        takeSnapshot(of: view, named: "CalendarView")
    }
    
    func testTrendAnalysisViewSnapshot() throws {
        let view = TrendAnalysisView()
        takeSnapshot(of: view, named: "TrendAnalysisView")
    }
    
    func testSavingsGoalViewSnapshot() throws {
        let view = SavingsGoalView()
        takeSnapshot(of: view, named: "SavingsGoalView")
    }
    
    func testBillReminderViewSnapshot() throws {
        let view = BillReminderView()
        takeSnapshot(of: view, named: "BillReminderView")
    }
    
    func testAccountViewSnapshot() throws {
        let view = AccountView()
        takeSnapshot(of: view, named: "AccountView")
    }
    
    func testRecurringTransactionViewSnapshot() throws {
        let view = RecurringTransactionView()
        takeSnapshot(of: view, named: "RecurringTransactionView")
    }
    
    func testExportViewSnapshot() throws {
        let view = ExportView()
        takeSnapshot(of: view, named: "ExportView")
    }
    
    func testImportViewSnapshot() throws {
        let view = ImportView()
        takeSnapshot(of: view, named: "ImportView")
    }
    
    func testBackupViewSnapshot() throws {
        let view = BackupView()
        takeSnapshot(of: view, named: "BackupView")
    }
    
    func testShareViewSnapshot() throws {
        let view = ShareView()
        takeSnapshot(of: view, named: "ShareView")
    }
    
    func testReportShareViewSnapshot() throws {
        let view = ReportShareView()
        takeSnapshot(of: view, named: "ReportShareView")
    }
    
    func testTagManagementViewSnapshot() throws {
        let view = TagManagementView()
        takeSnapshot(of: view, named: "TagManagementView")
    }
    
    func testCustomCategoryViewSnapshot() throws {
        let view = CustomCategoryView()
        takeSnapshot(of: view, named: "CustomCategoryView")
    }
    
    func testNotificationSettingsViewSnapshot() throws {
        let view = NotificationSettingsView()
        takeSnapshot(of: view, named: "NotificationSettingsView")
    }
    
    func testLedgerStatsViewSnapshot() throws {
        let view = LedgerStatsView()
        takeSnapshot(of: view, named: "LedgerStatsView")
    }
    
    func testAnnualReportViewSnapshot() throws {
        let view = AnnualReportView()
        takeSnapshot(of: view, named: "AnnualReportView")
    }
    
    func testBudgetComparisonViewSnapshot() throws {
        let view = BudgetComparisonView()
        takeSnapshot(of: view, named: "BudgetComparisonView")
    }
    
    func testAppLockViewSnapshot() throws {
        let view = AppLockView()
        takeSnapshot(of: view, named: "AppLockView")
    }
    
    func testReceiptScanViewSnapshot() throws {
        let view = ReceiptScanView { _, _ in }
        takeSnapshot(of: view, named: "ReceiptScanView")
    }
}
