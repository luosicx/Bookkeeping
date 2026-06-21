import XCTest

final class BookkeepingUITestsExtended: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-UITesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabBarAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
        
        tabBar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 2))
        
        tabBar.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 2))
        
        tabBar.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Home View Tests
    
    func testHomeViewElements() throws {
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons.matching(identifier: "plus.circle.fill").firstMatch.exists)
    }
    
    func testHomeViewMonthNavigation() throws {
        let previousMonth = app.buttons.matching(identifier: "chevron.left").firstMatch
        let nextMonth = app.buttons.matching(identifier: "chevron.right").firstMatch
        
        XCTAssertTrue(previousMonth.waitForExistence(timeout: 3))
        XCTAssertTrue(nextMonth.exists)
        
        previousMonth.tap()
        usleep(1000000)
        nextMonth.tap()
        usleep(1000000)
        nextMonth.tap()
    }
    
    func testHomeViewFilterAll() throws {
        let allButton = app.buttons["全部"]
        XCTAssertTrue(allButton.waitForExistence(timeout: 3))
        allButton.tap()
    }
    
    func testHomeViewFilterIncome() throws {
        let incomeButton = app.buttons["收入"]
        XCTAssertTrue(incomeButton.waitForExistence(timeout: 3))
        incomeButton.tap()
    }
    
    func testHomeViewFilterExpense() throws {
        let expenseButton = app.buttons["支出"]
        XCTAssertTrue(expenseButton.waitForExistence(timeout: 3))
        expenseButton.tap()
    }
    
    // MARK: - Add Transaction Tests
    
    func testAddTransactionFlow() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.exists)
        amountField.tap()
        amountField.typeText("88.8")
        
        app.buttons["保存"].tap()
        
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddIncomeTransaction() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("5000")
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionCancel() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        app.buttons["取消"].tap()
        
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithNote() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("25")
        
        let noteField = app.textFields["添加备注..."]
        if noteField.waitForExistence(timeout: 2) {
            noteField.tap()
            noteField.typeText("午餐")
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    func testAddTransactionWithDatePicker() throws {
        app.buttons.matching(identifier: "plus.circle.fill").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["添加记录"].waitForExistence(timeout: 3))
        
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("50")
        
        let datePicker = app.datePickers.firstMatch
        if datePicker.waitForExistence(timeout: 2) {
            datePicker.tap()
        }
        
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记账本"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Statistics View Tests
    
    func testStatisticsView() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
    }
    
    func testStatisticsPeriodButtons() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 3))
        
        let weekButton = app.buttons["本周"]
        let monthButton = app.buttons["本月"]
        let yearButton = app.buttons["本年"]
        
        if weekButton.waitForExistence(timeout: 2) {
            weekButton.tap()
            monthButton.tap()
            yearButton.tap()
        }
    }
    
    // MARK: - Settings View Tests
    
    func testSettingsView() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
    }
    
    func testSettingsScroll() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        usleep(1000000)
        app.swipeDown()
    }
    
    // MARK: - Account Management Tests
    
    func testNavigateToAccountManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let accountButton = app.buttons["账户管理"]
        if accountButton.waitForExistence(timeout: 3) {
            accountButton.tap()
            XCTAssertTrue(app.navigationBars["账户管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Budget Management Tests
    
    func testNavigateToBudgetManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let budgetButton = app.buttons["预算管理"]
        if budgetButton.waitForExistence(timeout: 3) {
            budgetButton.tap()
            XCTAssertTrue(app.navigationBars["预算管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Ledger Management Tests
    
    func testNavigateToLedgerManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let ledgerButton = app.buttons["账本管理"]
        if ledgerButton.waitForExistence(timeout: 3) {
            ledgerButton.tap()
            XCTAssertTrue(app.navigationBars["账本管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Debt Management Tests
    
    func testNavigateToDebtManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let debtButton = app.buttons["债务管理"]
        if debtButton.waitForExistence(timeout: 5) {
            debtButton.tap()
            XCTAssertTrue(app.navigationBars["债务管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Tag Management Tests
    
    func testNavigateToTagManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let tagButton = app.buttons["标签管理"]
        if tagButton.waitForExistence(timeout: 3) {
            tagButton.tap()
            XCTAssertTrue(app.navigationBars["标签管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Calendar View Tests
    
    func testNavigateToCalendar() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let calendarButton = app.buttons["财务日历"]
        if calendarButton.waitForExistence(timeout: 3) {
            calendarButton.tap()
            XCTAssertTrue(app.navigationBars["财务日历"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Budget Comparison Tests
    
    func testNavigateToBudgetComparison() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let budgetCompButton = app.buttons["预算对比"]
        if budgetCompButton.waitForExistence(timeout: 3) {
            budgetCompButton.tap()
            XCTAssertTrue(app.navigationBars["预算对比"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Currency Converter Tests
    
    func testNavigateToCurrencyConverter() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let currencyButton = app.buttons["汇率转换"]
        if currencyButton.waitForExistence(timeout: 3) {
            currencyButton.tap()
            XCTAssertTrue(app.navigationBars["汇率转换"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Trend Analysis Tests
    
    func testNavigateToTrendAnalysis() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let trendButton = app.buttons["趋势分析"]
        if trendButton.waitForExistence(timeout: 3) {
            trendButton.tap()
            XCTAssertTrue(app.navigationBars["趋势分析"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Savings Goal Tests
    
    func testNavigateToSavingsGoals() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let savingsButton = app.buttons["储蓄目标"]
        if savingsButton.waitForExistence(timeout: 3) {
            savingsButton.tap()
            XCTAssertTrue(app.navigationBars["储蓄目标"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Recurring Transaction Tests
    
    func testNavigateToRecurringTransactions() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let recurringButton = app.buttons["定期记账"]
        if recurringButton.waitForExistence(timeout: 3) {
            recurringButton.tap()
            XCTAssertTrue(app.navigationBars["定期记账"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Bill Reminder Tests
    
    func testNavigateToBillReminders() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let billButton = app.buttons["账单提醒"]
        if billButton.waitForExistence(timeout: 3) {
            billButton.tap()
            XCTAssertTrue(app.navigationBars["账单提醒"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Export Tests
    
    func testNavigateToExport() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let exportButton = app.buttons["导出数据"]
        if exportButton.waitForExistence(timeout: 3) {
            exportButton.tap()
            XCTAssertTrue(app.navigationBars["导出数据"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Import Tests
    
    func testNavigateToImport() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let importButton = app.buttons["导入数据"]
        if importButton.waitForExistence(timeout: 3) {
            importButton.tap()
            XCTAssertTrue(app.navigationBars["导入数据"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Backup Tests
    
    func testNavigateToBackup() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let backupButton = app.buttons["备份与恢复"]
        if backupButton.waitForExistence(timeout: 3) {
            backupButton.tap()
            XCTAssertTrue(app.navigationBars["备份与恢复"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Notification Settings Tests
    
    func testNavigateToNotificationSettings() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let notifButton = app.buttons["通知设置"]
        if notifButton.waitForExistence(timeout: 3) {
            notifButton.tap()
            XCTAssertTrue(app.navigationBars["通知设置"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - App Lock Tests
    
    func testNavigateToAppLock() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let lockButton = app.buttons["应用锁"]
        if lockButton.waitForExistence(timeout: 5) {
            lockButton.tap()
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Category Management Tests
    
    func testNavigateToCategoryManagement() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let categoryButton = app.buttons["分类管理"]
        if categoryButton.waitForExistence(timeout: 3) {
            categoryButton.tap()
            XCTAssertTrue(app.navigationBars["分类管理"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Report Share Tests
    
    func testNavigateToReportShare() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        app.swipeUp()
        
        let reportButton = app.buttons["报告分享"]
        if reportButton.waitForExistence(timeout: 3) {
            reportButton.tap()
            XCTAssertTrue(app.navigationBars["报告分享"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Ledger Stats Tests
    
    func testNavigateToLedgerStats() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let statsButton = app.buttons["账本统计"]
        if statsButton.waitForExistence(timeout: 3) {
            statsButton.tap()
            XCTAssertTrue(app.navigationBars["账本统计"].waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Theme Tests
    
    func testThemePicker() throws {
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        
        let themePicker = app.pickers.firstMatch
        if themePicker.waitForExistence(timeout: 2) {
            themePicker.tap()
        }
    }
}
