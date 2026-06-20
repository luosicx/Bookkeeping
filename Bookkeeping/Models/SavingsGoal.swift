import Foundation
import SwiftData

@Model
class SavingsGoal {
    var id: UUID
    var name: String
    var icon: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var createdAt: Date
    var isCompleted: Bool
    
    init(name: String, icon: String, targetAmount: Double, deadline: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.targetAmount = targetAmount
        self.currentAmount = 0
        self.deadline = deadline
        self.createdAt = Date()
        self.isCompleted = false
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }
    
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: deadline).day
        return max(days ?? 0, 0)
    }
}
