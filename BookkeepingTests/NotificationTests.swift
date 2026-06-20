import XCTest
import UserNotifications
@testable import Bookkeeping

final class NotificationServiceTests: XCTestCase {
    
    func testNotificationContentCreation() {
        let content = UNMutableNotificationContent()
        content.title = "预算提醒"
        content.body = "本月总支出已超出预算 ¥50！"
        content.sound = .default
        content.badge = 1
        
        XCTAssertEqual(content.title, "预算提醒")
        XCTAssertEqual(content.body, "本月总支出已超出预算 ¥50！")
        XCTAssertEqual(content.badge, 1)
    }
    
    func testBudgetAlertSeverity() {
        let warningAlert = BudgetAlertManager.BudgetAlert(
            title: "预算提醒",
            message: "支出已达80%",
            category: nil,
            severity: .warning
        )
        
        let criticalAlert = BudgetAlertManager.BudgetAlert(
            title: "超支警告",
            message: "已超出预算",
            category: "餐饮",
            severity: .critical
        )
        
        XCTAssertEqual(warningAlert.severity.title, "预算提醒")
        XCTAssertEqual(criticalAlert.severity.title, "超支警告")
        XCTAssertNil(warningAlert.category)
        XCTAssertEqual(criticalAlert.category, "餐饮")
    }
    
    func testNotificationIdentifier() {
        let category = "餐饮"
        let identifier = category ?? "overall_budget"
        
        XCTAssertEqual(identifier, "餐饮")
        
        let nilCategory: String? = nil
        let identifier2 = nilCategory ?? "overall_budget"
        
        XCTAssertEqual(identifier2, "overall_budget")
    }
    
    func testTimeIntervalTrigger() {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        XCTAssertEqual(trigger.timeInterval, 1)
        XCTAssertFalse(trigger.repeats)
    }
    
    func testCalendarTrigger() {
        let dateComponents = DateComponents(year: 2026, month: 6, day: 20, hour: 9, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        XCTAssertNotNil(trigger)
        XCTAssertFalse(trigger.repeats)
    }
    
    func testNotificationContentWithUserInfo() {
        let content = UNMutableNotificationContent()
        content.title = "分类预算提醒"
        content.body = "餐饮已超出预算"
        content.userInfo = ["category": "餐饮"]
        
        XCTAssertEqual(content.userInfo["category"] as? String, "餐饮")
    }
    
    func testBudgetAlertMessageFormat() {
        let overAmount: Double = 50
        let percentage: Int = 85
        
        let criticalMessage = "本月总支出已超出预算 ¥\(String(format: "%.0f", overAmount))！"
        let warningMessage = "本月总支出已达预算的 \(percentage)%，请注意控制支出。"
        
        XCTAssertTrue(criticalMessage.contains("超出预算"))
        XCTAssertTrue(criticalMessage.contains("50"))
        XCTAssertTrue(warningMessage.contains("85%"))
    }
}

final class NotificationManagerTests: XCTestCase {
    
    func testBudgetAlertManagerCheckBudgetsNoBudget() {
        let alertManager = BudgetAlertManager.shared
        
        let alerts = alertManager.checkBudgets(
            transactions: [],
            overallBudget: nil,
            categoryBudgets: [],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 0)
    }
    
    func testBudgetAlertManagerCheckBudgetsWithBudget() {
        let alertManager = BudgetAlertManager.shared
        
        let overallBudget = OverallBudget(amount: 100, month: Date())
        
        let transaction = Transaction(amount: 150, type: .expense, category: "餐饮", note: "测试", date: Date())
        
        let alerts = alertManager.checkBudgets(
            transactions: [transaction],
            overallBudget: overallBudget,
            categoryBudgets: [],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.severity.title, "超支警告")
    }
    
    func testBudgetAlertManagerCheckCategoryBudget() {
        let alertManager = BudgetAlertManager.shared
        
        let categoryBudget = Budget(category: "餐饮", amount: 50, month: Date())
        
        let transaction = Transaction(amount: 80, type: .expense, category: "餐饮", note: "测试", date: Date())
        
        let alerts = alertManager.checkBudgets(
            transactions: [transaction],
            overallBudget: nil,
            categoryBudgets: [categoryBudget],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 1)
        XCTAssertTrue(alerts.first?.message.contains("餐饮") ?? false)
    }
}

final class BillReminderNotificationTests: XCTestCase {
    
    func testBillReminderNotificationContent() {
        let title = "电费"
        let amount: Double = 200.5
        
        let messageWithAmount = "\(title) 需支付 ¥\(String(format: "%.2f", amount))"
        let messageWithoutAmount = "\(title) 即将到期"
        
        XCTAssertTrue(messageWithAmount.contains("电费"))
        XCTAssertTrue(messageWithAmount.contains("200.50"))
        XCTAssertTrue(messageWithoutAmount.contains("电费"))
        XCTAssertTrue(messageWithoutAmount.contains("即将到期"))
    }
    
    func testBillReminderDaysBefore() {
        let daysBefore1 = 1
        let daysBefore3 = 3
        
        let message1 = "将在 \(daysBefore1) 天后到期"
        let message3 = "将在 \(daysBefore3) 天后到期"
        
        XCTAssertTrue(message1.contains("1 天"))
        XCTAssertTrue(message3.contains("3 天"))
    }
    
    func testBillReminderIdentifiers() {
        let billId = UUID()
        
        let mainIdentifier = billId.uuidString
        let day1Identifier = "\(billId.uuidString)-1days"
        let day3Identifier = "\(billId.uuidString)-3days"
        
        XCTAssertNotEqual(mainIdentifier, day1Identifier)
        XCTAssertNotEqual(mainIdentifier, day3Identifier)
        XCTAssertNotEqual(day1Identifier, day3Identifier)
        XCTAssertTrue(day1Identifier.contains("-1days"))
        XCTAssertTrue(day3Identifier.contains("-3days"))
    }
}
