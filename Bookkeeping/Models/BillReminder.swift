import Foundation
import SwiftData

@Model
class BillReminder {
    var id: UUID
    var title: String
    var amount: Double?
    var dueDate: Date
    var repeatFrequency: Frequency
    var isPaid: Bool
    var note: String
    var isEnabled: Bool
    var createdAt: Date
    
    init(title: String, amount: Double? = nil, dueDate: Date, repeatFrequency: Frequency = .monthly, note: String = "") {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.repeatFrequency = repeatFrequency
        self.isPaid = false
        self.note = note
        self.isEnabled = true
        self.createdAt = Date()
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return days
    }
    
    var isOverdue: Bool {
        dueDate < Date() && !isPaid
    }
    
    var isDueSoon: Bool {
        daysUntilDue <= 3 && daysUntilDue >= 0 && !isPaid
    }
}
