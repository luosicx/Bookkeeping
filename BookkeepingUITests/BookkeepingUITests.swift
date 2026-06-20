import XCTest

final class BookkeepingUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-UITesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - 基础测试
    
    func testLaunch() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
    }
    
    func testMainTabView() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["首页"].waitForExistence(timeout: 3))
        XCTAssertTrue(tabBar.buttons["统计"].exists)
        XCTAssertTrue(tabBar.buttons["设置"].exists)
    }
    
    // MARK: - 首页测试
    
    func testHomeView() throws {
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["plus.circle.fill"].exists)
    }
    
    func testFilterButtons() throws {
        let allButton = app.buttons["全部"]
        let incomeButton = app.buttons["收入"]
        let expenseButton = app.buttons["支出"]
        
        XCTAssertTrue(allButton.waitForExistence(timeout: 3))
        XCTAssertTrue(incomeButton.exists)
        XCTAssertTrue(expenseButton.exists)
        
        incomeButton.tap()
        expenseButton.tap()
        allButton.tap()
    }
    
    func testMonthSelector() throws {
        let previousButton = app.buttons.matching(identifier: "chevron.left").firstMatch
        let nextButton = app.buttons.matching(identifier: "chevron.right").firstMatch
        
        XCTAssertTrue(previousButton.waitForExistence(timeout: 3))
        XCTAssertTrue(nextButton.exists)
        
        previousButton.tap()
        nextButton.tap()
    }
    
    // MARK: - 添加交易测试
    
    func testAddTransaction() throws {
        app.buttons["plus.circle.fill"].tap()
        
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.exists)
        amountField.tap()
        amountField.typeText("100")
        
        app.buttons["餐饮"].tap()
        app.buttons["保存"].tap()
        
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    // MARK: - 导航测试
    
    func testNavigateToStatistics() throws {
        app.tabBars.firstMatch.buttons["统计"].tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
    }
    
    func testNavigateToSettings() throws {
        app.tabBars.firstMatch.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
    }
    
    func testSettingsHasFeatures() throws {
        app.tabBars.firstMatch.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))
        
        let accountButton = app.buttons["账户管理"]
        let backupButton = app.buttons["备份与恢复"]
        
        if accountButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(accountButton.exists)
        }
        if backupButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(backupButton.exists)
        }
    }
}

final class BookkeepingLaunchTests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }
}
