import Foundation
import UserNotifications

class MonthlyReportService {
    static let shared = MonthlyReportService()
    
    private init() {}
    
    struct MonthlyReport {
        let month: Date
        let totalIncome: Double
        let totalExpense: Double
        let balance: Double
        let topCategory: String?
        let transactionCount: Int
    }
    
    func generateReport(transactions: [Transaction], for month: Date) -> MonthlyReport {
        let calendar = Calendar.current
        
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }
        
        let income = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let categoryExpenses = Dictionary(grouping: monthTransactions.filter { $0.type == .expense }) { $0.category }
        let topCategory = categoryExpenses.max(by: { $0.value.count < $1.value.count })?.key
        
        return MonthlyReport(
            month: month,
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense,
            topCategory: topCategory,
            transactionCount: monthTransactions.count
        )
    }
    
    func sendMonthlyReportNotification(report: MonthlyReport) {
        let content = UNMutableNotificationContent()
        content.title = L.monthlyReport
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let monthName = calendar.component(.month, from: report.month)
        
        var body = "\(monthName)月共 \(report.transactionCount) 笔交易\n"
        body += "收入 ¥\(String(format: "%.0f", report.totalIncome)) · 支出 ¥\(String(format: "%.0f", report.totalExpense))\n"
        
        if report.balance >= 0 {
            body += "结余 ¥\(String(format: "%.0f", report.balance))"
        } else {
            body += "超支 ¥\(String(format: "%.0f", -report.balance))"
        }
        
        if let topCategory = report.topCategory {
            body += "\n支出最多：\(topCategory)"
        }
        
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "monthly_report_\(Calendar.current.component(.month, from: report.month))",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send monthly report: \(error)")
            }
        }
    }
    
    func scheduleMonthlyReport(transactions: [Transaction]) {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month], from: now)
        components.month = (components.month ?? 1) + 1
        components.day = 1
        components.hour = 9
        components.minute = 0
        
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let report = generateReport(transactions: transactions, for: lastMonth)
        
        let content = UNMutableNotificationContent()
        content.title = L.monthlyReport
        content.sound = .default
        
        var body = "\(report.transactionCount) 笔交易 · "
        body += "结余 ¥\(String(format: "%.0f", report.balance))"
        content.body = body
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "scheduled_monthly_report",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
