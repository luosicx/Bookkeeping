import Foundation
import UserNotifications

class BudgetAlertManager {
    static let shared = BudgetAlertManager()
    
    private init() {}
    
    struct BudgetAlert {
        let title: String
        let message: String
        let category: String?
        let severity: AlertSeverity
    }
    
    enum AlertSeverity {
        case warning
        case critical
        
        var title: String {
            switch self {
            case .warning: return "预算提醒"
            case .critical: return "超支警告"
            }
        }
        
        var sound: UNNotificationSound {
            switch self {
            case .warning: return .default
            case .critical: return .defaultCritical
            }
        }
    }
    
    func checkBudgets(
        transactions: [Transaction],
        overallBudget: OverallBudget?,
        categoryBudgets: [Budget],
        date: Date
    ) -> [BudgetAlert] {
        var alerts: [BudgetAlert] = []
        
        let calendar = Calendar.current
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            $0.type == .expense
        }
        
        let totalSpent = monthTransactions.reduce(0) { $0 + $1.amount }
        
        if let overallBudget = overallBudget {
            let overallStatus = OverallBudgetStatus(budget: overallBudget, spent: totalSpent)
            
            if overallStatus.isOverBudget {
                let overAmount = totalSpent - overallBudget.amount
                alerts.append(BudgetAlert(
                    title: AlertSeverity.critical.title,
                    message: "本月总支出已超出预算 ¥\(String(format: "%.0f", overAmount))！",
                    category: nil,
                    severity: .critical
                ))
            } else if overallStatus.isWarning {
                let percentage = Int(overallStatus.percentage * 100)
                alerts.append(BudgetAlert(
                    title: AlertSeverity.warning.title,
                    message: "本月总支出已达预算的 \(percentage)%，请注意控制支出。",
                    category: nil,
                    severity: .warning
                ))
            }
        }
        
        for budget in categoryBudgets {
            let categorySpent = monthTransactions
                .filter { $0.category == budget.category }
                .reduce(0) { $0 + $1.amount }
            
            let status = BudgetStatus(budget: budget, spent: categorySpent)
            
            if status.isOverBudget {
                let overAmount = categorySpent - budget.amount
                alerts.append(BudgetAlert(
                    title: AlertSeverity.critical.title,
                    message: "\(budget.category) 已超出预算 ¥\(String(format: "%.0f", overAmount))！",
                    category: budget.category,
                    severity: .critical
                ))
            } else if status.isWarning {
                let percentage = Int(status.percentage * 100)
                alerts.append(BudgetAlert(
                    title: AlertSeverity.warning.title,
                    message: "\(budget.category) 已达预算的 \(percentage)%，请注意控制。",
                    category: budget.category,
                    severity: .warning
                ))
            }
        }
        
        return alerts
    }
    
    func sendAlert(_ alert: BudgetAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = alert.severity.sound
        content.badge = 1
        
        if let category = alert.category {
            content.userInfo = ["category": category]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = alert.category ?? "overall_budget"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send budget alert: \(error)")
            }
        }
    }
    
    func sendBudgetSummary(
        overallBudget: OverallBudget?,
        spent: Double,
        date: Date
    ) {
        guard let overallBudget = overallBudget else { return }
        
        let calendar = Calendar.current
        let monthName = calendar.component(.month, from: date)
        
        let content = UNMutableNotificationContent()
        content.title = "月度预算报告"
        
        let remaining = overallBudget.amount - spent
        let percentage = Int((spent / overallBudget.amount) * 100)
        
        if remaining >= 0 {
            content.body = "\(monthName)月预算剩余 ¥\(String(format: "%.0f", remaining))，已使用 \(percentage)%"
        } else {
            content.body = "\(monthName)月预算已超支 ¥\(String(format: "%.0f", -remaining))"
        }
        
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budget_summary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllBudgetAlerts() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["overall_budget", "budget_summary"]
        )
    }
}
