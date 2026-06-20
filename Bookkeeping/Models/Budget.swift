import Foundation
import SwiftData

@Model
class OverallBudget {
    var id: UUID
    var amount: Double
    var month: Date
    var createdAt: Date
    
    init(amount: Double, month: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.month = month
        self.createdAt = Date()
    }
}

@Model
class Budget {
    var id: UUID
    var category: String
    var amount: Double
    var month: Date
    var createdAt: Date
    
    init(category: String, amount: Double, month: Date = Date()) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.month = month
        self.createdAt = Date()
    }
}

struct BudgetStatus {
    let budget: Budget
    let spent: Double
    
    var remaining: Double {
        budget.amount - spent
    }
    
    var percentage: Double {
        guard budget.amount > 0 else { return 0 }
        return spent / budget.amount
    }
    
    var isOverBudget: Bool {
        spent > budget.amount
    }
    
    var isWarning: Bool {
        percentage >= 0.8 && !isOverBudget
    }
}

struct OverallBudgetStatus {
    let budget: OverallBudget
    let spent: Double
    
    var remaining: Double {
        budget.amount - spent
    }
    
    var percentage: Double {
        guard budget.amount > 0 else { return 0 }
        return spent / budget.amount
    }
    
    var isOverBudget: Bool {
        spent > budget.amount
    }
    
    var isWarning: Bool {
        percentage >= 0.8 && !isOverBudget
    }
}
