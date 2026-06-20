import XCTest
@testable import Bookkeeping

final class VoiceCommandParserTests: XCTestCase {
    let parser = VoiceCommandParser()
    
    // MARK: - 金额提取测试
    
    func testExtractAmountWithUnit() {
        let result = parser.parse("午餐花了30元")
        XCTAssertEqual(result.amount, 30)
    }
    
    func testExtractAmountWithoutUnit() {
        let result = parser.parse("买了一杯咖啡25")
        XCTAssertEqual(result.amount, 25)
    }
    
    func testExtractDecimalAmount() {
        let result = parser.parse("午餐花了30.5元")
        XCTAssertEqual(result.amount, 30.5)
    }
    
    func testNoAmount() {
        let result = parser.parse("午餐")
        XCTAssertNil(result.amount)
    }
    
    // MARK: - 交易类型测试
    
    func testInferExpenseType() {
        let result = parser.parse("午餐花了30元")
        XCTAssertEqual(result.type, .expense)
    }
    
    func testInferIncomeType() {
        let result = parser.parse("收到工资8000元")
        XCTAssertEqual(result.type, .income)
    }
    
    func testInferIncomeWithIndicator() {
        let result = parser.parse("到账5000元")
        XCTAssertEqual(result.type, .income)
    }
    
    func testInferExpenseWithIndicator() {
        let result = parser.parse("花了200元")
        XCTAssertEqual(result.type, .expense)
    }
    
    // MARK: - 分类测试
    
    func testFoodCategory() {
        let result = parser.parse("午餐花了30元")
        XCTAssertEqual(result.categoryId, "food")
    }
    
    func testTransportCategory() {
        let result = parser.parse("打车花了25元")
        XCTAssertEqual(result.categoryId, "transport")
    }
    
    func testShoppingCategory() {
        let result = parser.parse("超市买菜花了50元")
        XCTAssertEqual(result.categoryId, "shopping")
    }
    
    func testEntertainmentCategory() {
        let result = parser.parse("看电影花了80元")
        XCTAssertEqual(result.categoryId, "entertainment")
    }
    
    func testHousingCategory() {
        let result = parser.parse("交房租3000元")
        XCTAssertEqual(result.categoryId, "housing")
    }
    
    func testMedicalCategory() {
        let result = parser.parse("去医院看病花了200元")
        XCTAssertEqual(result.categoryId, "medical")
    }
    
    func testEducationCategory() {
        let result = parser.parse("交学费花了5000元")
        XCTAssertEqual(result.categoryId, "education")
    }
    
    func testSalaryCategory() {
        let result = parser.parse("收到工资10000元")
        XCTAssertEqual(result.categoryId, "salary")
    }
    
    func testBonusCategory() {
        let result = parser.parse("发了奖金5000元")
        XCTAssertEqual(result.categoryId, "bonus")
    }
    
    func testInvestmentCategory() {
        let result = parser.parse("投资收益1000元")
        XCTAssertEqual(result.categoryId, "investment")
    }
    
    // MARK: - 备注提取测试
    
    func testExtractNote() {
        let result = parser.parse("午餐30元")
        XCTAssertNotNil(result.note)
        XCTAssertTrue(result.note?.contains("午餐") ?? false)
    }
    
    func testExtractNoteWithKeywords() {
        let result = parser.parse("打车去公司25元")
        XCTAssertNotNil(result.note)
    }
    
    // MARK: - 综合测试
    
    func testFullCommand() {
        let result = parser.parse("午餐外卖花了35元")
        XCTAssertEqual(result.amount, 35)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.categoryId, "food")
    }
    
    func testIncomeCommand() {
        let result = parser.parse("收到工资15000元")
        XCTAssertEqual(result.amount, 15000)
        XCTAssertEqual(result.type, .income)
        XCTAssertEqual(result.categoryId, "salary")
    }
}
