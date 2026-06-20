import XCTest
@testable import Bookkeeping

final class BudgetAlertManagerTests: XCTestCase {
    
    func testCheckBudgetsOverBudget() throws {
        let alertManager = BudgetAlertManager.shared
        
        // 模拟预算数据
        let overallBudget = MockOverallBudget(amount: 100)
        let transactions = [
            MockTransaction(amount: 150, type: .expense, category: "餐饮")
        ]
        
        let alerts = alertManager.checkBudgets(
            transactions: transactions.map { $0.toTransaction() },
            overallBudget: overallBudget.toOverallBudget(),
            categoryBudgets: [],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.severity.title, "超支警告")
        XCTAssertTrue(alerts.first?.message.contains("超出预算") ?? false)
    }
    
    func testCheckBudgetsWarning() throws {
        let alertManager = BudgetAlertManager.shared
        
        let overallBudget = MockOverallBudget(amount: 100)
        let transactions = [
            MockTransaction(amount: 85, type: .expense, category: "餐饮")
        ]
        
        let alerts = alertManager.checkBudgets(
            transactions: transactions.map { $0.toTransaction() },
            overallBudget: overallBudget.toOverallBudget(),
            categoryBudgets: [],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.severity.title, "预算提醒")
        XCTAssertTrue(alerts.first?.message.contains("85%") ?? false)
    }
    
    func testCheckBudgetsNoAlert() throws {
        let alertManager = BudgetAlertManager.shared
        
        let overallBudget = MockOverallBudget(amount: 100)
        let transactions = [
            MockTransaction(amount: 50, type: .expense, category: "餐饮")
        ]
        
        let alerts = alertManager.checkBudgets(
            transactions: transactions.map { $0.toTransaction() },
            overallBudget: overallBudget.toOverallBudget(),
            categoryBudgets: [],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 0)
    }
    
    func testCheckCategoryBudgetOverBudget() throws {
        let alertManager = BudgetAlertManager.shared
        
        let categoryBudget = MockBudget(category: "餐饮", amount: 50)
        let transactions = [
            MockTransaction(amount: 80, type: .expense, category: "餐饮")
        ]
        
        let alerts = alertManager.checkBudgets(
            transactions: transactions.map { $0.toTransaction() },
            overallBudget: nil,
            categoryBudgets: [categoryBudget.toBudget()],
            date: Date()
        )
        
        XCTAssertEqual(alerts.count, 1)
        XCTAssertTrue(alerts.first?.message.contains("餐饮") ?? false)
        XCTAssertTrue(alerts.first?.message.contains("超出预算") ?? false)
    }
}

// Mock 类型用于测试
struct MockTransaction {
    let amount: Double
    let type: TransactionType
    let category: String
    
    func toTransaction() -> Transaction {
        Transaction(amount: amount, type: type, category: category, note: "", date: Date())
    }
}

struct MockOverallBudget {
    let amount: Double
    
    func toOverallBudget() -> OverallBudget {
        OverallBudget(amount: amount, month: Date())
    }
}

struct MockBudget {
    let category: String
    let amount: Double
    
    func toBudget() -> Budget {
        Budget(category: category, amount: amount, month: Date())
    }
}
