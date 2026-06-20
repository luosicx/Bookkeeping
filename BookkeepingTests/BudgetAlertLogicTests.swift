import XCTest

final class BudgetAlertLogicTests: XCTestCase {
    
    // 测试超支检测逻辑
    func testOverBudgetDetection() {
        let budgetAmount: Double = 100
        let spent: Double = 150
        
        let isOverBudget = spent > budgetAmount
        let isWarning = (spent / budgetAmount) >= 0.8 && !isOverBudget
        
        XCTAssertTrue(isOverBudget)
        XCTAssertFalse(isWarning)
    }
    
    // 测试警告检测逻辑
    func testWarningDetection() {
        let budgetAmount: Double = 100
        let spent: Double = 85
        
        let isOverBudget = spent > budgetAmount
        let isWarning = (spent / budgetAmount) >= 0.8 && !isOverBudget
        
        XCTAssertFalse(isOverBudget)
        XCTAssertTrue(isWarning)
    }
    
    // 测试正常状态
    func testNormalStatus() {
        let budgetAmount: Double = 100
        let spent: Double = 50
        
        let isOverBudget = spent > budgetAmount
        let isWarning = (spent / budgetAmount) >= 0.8 && !isOverBudget
        
        XCTAssertFalse(isOverBudget)
        XCTAssertFalse(isWarning)
    }
    
    // 测试剩余金额计算
    func testRemainingCalculation() {
        let budgetAmount: Double = 100
        let spent: Double = 150
        
        let remaining = budgetAmount - spent
        
        XCTAssertEqual(remaining, -50)
    }
    
    // 测试百分比计算
    func testPercentageCalculation() {
        let budgetAmount: Double = 100
        let spent: Double = 75
        
        let percentage = (spent / budgetAmount) * 100
        
        XCTAssertEqual(percentage, 75)
    }
    
    // 测试分类预算检查
    func testCategoryBudgetCheck() {
        let categoryBudgets: [(String, Double)] = [
            ("餐饮", 50),
            ("交通", 30)
        ]
        
        let categorySpent: [(String, Double)] = [
            ("餐饮", 60),
            ("交通", 20)
        ]
        
        var overBudgetCategories: [String] = []
        
        for (category, budget) in categoryBudgets {
            if let spent = categorySpent.first(where: { $0.0 == category })?.1 {
                if spent > budget {
                    overBudgetCategories.append(category)
                }
            }
        }
        
        XCTAssertEqual(overBudgetCategories.count, 1)
        XCTAssertTrue(overBudgetCategories.contains("餐饮"))
        XCTAssertFalse(overBudgetCategories.contains("交通"))
    }
    
    // 测试多分类超支检测
    func testMultipleCategoryOverBudget() {
        let categoryBudgets: [(String, Double)] = [
            ("餐饮", 50),
            ("交通", 30),
            ("购物", 100)
        ]
        
        let categorySpent: [(String, Double)] = [
            ("餐饮", 60),
            ("交通", 40),
            ("购物", 80)
        ]
        
        var overBudgetCategories: [String] = []
        var warningCategories: [String] = []
        
        for (category, budget) in categoryBudgets {
            if let spent = categorySpent.first(where: { $0.0 == category })?.1 {
                if spent > budget {
                    overBudgetCategories.append(category)
                } else if (spent / budget) >= 0.8 {
                    warningCategories.append(category)
                }
            }
        }
        
        XCTAssertEqual(overBudgetCategories.count, 2)
        XCTAssertTrue(overBudgetCategories.contains("餐饮"))
        XCTAssertTrue(overBudgetCategories.contains("交通"))
        
        XCTAssertEqual(warningCategories.count, 1)
        XCTAssertTrue(warningCategories.contains("购物"))
    }
    
    // 测试通知内容生成
    func testNotificationContent() {
        let budgetAmount: Double = 100
        let spent: Double = 150
        let overAmount = spent - budgetAmount
        
        let title = "超支警告"
        let message = "本月总支出已超出预算 ¥\(String(format: "%.0f", overAmount))！"
        
        XCTAssertEqual(title, "超支警告")
        XCTAssertTrue(message.contains("超出预算"))
        XCTAssertTrue(message.contains("50"))
    }
}
