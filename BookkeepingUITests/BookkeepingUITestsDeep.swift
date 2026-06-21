import XCTest

final class BookkeepingUITestsDeep: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-UITesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Add Multiple Transactions
    
    func testAddMultipleTransactions() throws {
        for i in 1...3 {
            app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
            XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
            
            let amountField = app.textFields["0.00"]
            amountField.tap()
            amountField.typeText("\(i * 10)")
            
            app.buttons["保存"].tap()
            usleep(1000000)
        }
    }
    
    func testAddTransactionAllCategories() throws {
        let categories = ["餐饮", "交通", "购物", "娱乐", "住房", "医疗", "教育"]
        
        for category in categories {
            app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
            XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
            
            let amountField = app.textFields["0.00"]
            amountField.tap()
            amountField.typeText("50")
            
            if app.buttons[category].waitForExistence(timeout: 2) {
                app.buttons[category].tap()
            }
            
            app.buttons["保存"].tap()
            usleep(1000000)
        }
    }
    
    // MARK: - Settings Deep Navigation
    
    func testSettingsAllFeatures() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        // Scroll through all settings
        for _ in 0..<5 {
            app.swipeUp()
            usleep(500000)
        }
        
        // Scroll back up
        for _ in 0..<5 {
            app.swipeDown()
            usleep(500000)
        }
    }
    
    // MARK: - Account Management Deep Test
    
    func testAccountManagementFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let accountButton = app.buttons["账户管理"]
        if accountButton.waitForExistence(timeout: 3) {
            accountButton.tap()
            XCTAssertTrue(app.navigationBars["账户管理"].waitForExistence(timeout: 3))
            
            // Try to add account
            let addButton = app.buttons.matching(identifier: "plus").firstMatch
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                usleep(1000000)
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Budget Management Deep Test
    
    func testBudgetManagementFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let budgetButton = app.buttons["预算管理"]
        if budgetButton.waitForExistence(timeout: 3) {
            budgetButton.tap()
            XCTAssertTrue(app.navigationBars["预算管理"].waitForExistence(timeout: 3))
            
            // Try to add budget
            let addButton = app.buttons.matching(identifier: "plus").firstMatch
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                usleep(1000000)
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Savings Goal Deep Test
    
    func testSavingsGoalFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let savingsButton = app.buttons["储蓄目标"]
        if savingsButton.waitForExistence(timeout: 3) {
            savingsButton.tap()
            XCTAssertTrue(app.navigationBars["储蓄目标"].waitForExistence(timeout: 3))
            
            let addButton = app.buttons.matching(identifier: "plus").firstMatch
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                usleep(1000000)
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Recurring Transaction Deep Test
    
    func testRecurringTransactionFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let recurringButton = app.buttons["定期记账"]
        if recurringButton.waitForExistence(timeout: 3) {
            recurringButton.tap()
            XCTAssertTrue(app.navigationBars["定期记账"].waitForExistence(timeout: 3))
            
            let addButton = app.buttons.matching(identifier: "plus").firstMatch
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                usleep(1000000)
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Bill Reminder Deep Test
    
    func testBillReminderFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let billButton = app.buttons["账单提醒"]
        if billButton.waitForExistence(timeout: 3) {
            billButton.tap()
            XCTAssertTrue(app.navigationBars["账单提醒"].waitForExistence(timeout: 3))
            
            let addButton = app.buttons.matching(identifier: "plus").firstMatch
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                usleep(1000000)
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Export Deep Test
    
    func testExportFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let exportButton = app.buttons["导出数据"]
        if exportButton.waitForExistence(timeout: 3) {
            exportButton.tap()
            XCTAssertTrue(app.navigationBars["导出数据"].waitForExistence(timeout: 3))
            
            // Try export buttons
            let csvButton = app.buttons["CSV"]
            if csvButton.waitForExistence(timeout: 2) {
                csvButton.tap()
                usleep(2000000)
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Backup Deep Test
    
    func testBackupFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let backupButton = app.buttons["备份与恢复"]
        if backupButton.waitForExistence(timeout: 3) {
            backupButton.tap()
            XCTAssertTrue(app.navigationBars["备份与恢复"].waitForExistence(timeout: 3))
            
            let backupDataButton = app.buttons["备份数据"]
            if backupDataButton.waitForExistence(timeout: 2) {
                backupDataButton.tap()
                usleep(2000000)
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Notification Settings Deep Test
    
    func testNotificationSettingsFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let notifButton = app.buttons["通知设置"]
        if notifButton.waitForExistence(timeout: 3) {
            notifButton.tap()
            XCTAssertTrue(app.navigationBars["通知设置"].waitForExistence(timeout: 3))
            
            // Toggle switches
            let switches = app.switches
            if switches.count > 0 {
                switches.element(boundBy: 0).tap()
                usleep(1000000)
                switches.element(boundBy: 0).tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Trend Analysis Deep Test
    
    func testTrendAnalysisFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let trendButton = app.buttons["趋势分析"]
        if trendButton.waitForExistence(timeout: 3) {
            trendButton.tap()
            XCTAssertTrue(app.navigationBars["趋势分析"].waitForExistence(timeout: 3))
            
            // Scroll through trend data
            app.swipeUp()
            usleep(1000000)
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Calendar Deep Test
    
    func testCalendarFlow() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let calendarButton = app.buttons["财务日历"]
        if calendarButton.waitForExistence(timeout: 3) {
            calendarButton.tap()
            XCTAssertTrue(app.navigationBars["财务日历"].waitForExistence(timeout: 3))
            
            // Interact with date picker
            let datePicker = app.datePickers.firstMatch
            if datePicker.waitForExistence(timeout: 2) {
                datePicker.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Statistics Deep Test
    
    func testStatisticsDeep() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
        
        // Scroll through statistics
        for _ in 0..<3 {
            app.swipeUp()
            usleep(500000)
        }
        
        for _ in 0..<3 {
            app.swipeDown()
            usleep(500000)
        }
    }
    
    // MARK: - Home View Deep Test
    
    func testHomeViewDeep() throws {
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
        
        // Scroll through home view
        for _ in 0..<3 {
            app.swipeUp()
            usleep(500000)
        }
        
        for _ in 0..<3 {
            app.swipeDown()
            usleep(500000)
        }
    }
    
    // MARK: - Transaction Detail Test
    
    func testTransactionDetail() throws {
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
        
        // Try to tap on a transaction cell
        let cells = app.cells
        if cells.count > 0 {
            cells.element(boundBy: 0).tap()
            usleep(1000000)
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Add Transaction with All Category Types
    
    func testAddTransactionWithFoodCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("35.5")
        
        if app.buttons["餐饮"].waitForExistence(timeout: 2) {
            app.buttons["餐饮"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithTransportCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("6.5")
        
        if app.buttons["交通"].waitForExistence(timeout: 2) {
            app.buttons["交通"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithShoppingCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("299")
        
        if app.buttons["购物"].waitForExistence(timeout: 2) {
            app.buttons["购物"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithEntertainmentCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("68")
        
        if app.buttons["娱乐"].waitForExistence(timeout: 2) {
            app.buttons["娱乐"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithHousingCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("1500")
        
        if app.buttons["住房"].waitForExistence(timeout: 2) {
            app.buttons["住房"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithMedicalCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("200")
        
        if app.buttons["医疗"].waitForExistence(timeout: 2) {
            app.buttons["医疗"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithEducationCategory() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("500")
        
        if app.buttons["教育"].waitForExistence(timeout: 2) {
            app.buttons["教育"].tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
}
