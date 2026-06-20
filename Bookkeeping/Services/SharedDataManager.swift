import Foundation
import WidgetKit

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let suiteName = "group.com.bookkeeping.app"
    private let defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: suiteName)
    }
    
    func saveWidgetData(income: Double, expense: Double, balance: Double) {
        defaults?.set(income, forKey: "widget_income")
        defaults?.set(expense, forKey: "widget_expense")
        defaults?.set(balance, forKey: "widget_balance")
        defaults?.set(Date(), forKey: "widget_lastUpdate")
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getWidgetData() -> (income: Double, expense: Double, balance: Double) {
        let income = defaults?.double(forKey: "widget_income") ?? 0
        let expense = defaults?.double(forKey: "widget_expense") ?? 0
        let balance = defaults?.double(forKey: "widget_balance") ?? 0
        
        return (income, expense, balance)
    }
}
