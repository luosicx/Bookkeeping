import Foundation
import SwiftData
import SwiftUI

@Observable
class SavingsGoalViewModel {
    var modelContext: ModelContext?
    var goals: [SavingsGoal] = []
    
    var totalTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }
    
    var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(totalSaved / totalTarget, 1.0)
    }
    
    func fetchGoals() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<SavingsGoal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch goals failed: \(error)")
        }
    }
    
    func addGoal(name: String, icon: String, targetAmount: Double, deadline: Date?) {
        guard let modelContext = modelContext else { return }
        let goal = SavingsGoal(name: name, icon: icon, targetAmount: targetAmount, deadline: deadline)
        modelContext.insert(goal)
        saveContext()
        fetchGoals()
    }
    
    func updateGoal(_ goal: SavingsGoal, name: String? = nil, icon: String? = nil, targetAmount: Double? = nil, deadline: Date? = nil) {
        if let name = name { goal.name = name }
        if let icon = icon { goal.icon = icon }
        if let targetAmount = targetAmount { goal.targetAmount = targetAmount }
        if let deadline = deadline { goal.deadline = deadline }
        saveContext()
        fetchGoals()
    }
    
    func deleteGoal(_ goal: SavingsGoal) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(goal)
        saveContext()
        fetchGoals()
    }
    
    func addDeposit(to goal: SavingsGoal, amount: Double) {
        goal.currentAmount += amount
        if goal.currentAmount >= goal.targetAmount {
            goal.isCompleted = true
        }
        saveContext()
        fetchGoals()
    }
    
    func withdraw(from goal: SavingsGoal, amount: Double) {
        goal.currentAmount = max(goal.currentAmount - amount, 0)
        goal.isCompleted = false
        saveContext()
        fetchGoals()
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
