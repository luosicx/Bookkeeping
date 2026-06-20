import Foundation
import SwiftData

@Model
class RecurringTransaction {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var category: String
    var note: String
    var frequency: Frequency
    var dayOfMonth: Int
    var dayOfWeek: Int
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var lastGenerated: Date?
    var account: Account?
    var createdAt: Date
    
    init(amount: Double, type: TransactionType, category: String, note: String = "", frequency: Frequency, dayOfMonth: Int = 1, dayOfWeek: Int = 1, startDate: Date = Date(), endDate: Date? = nil, account: Account? = nil) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.frequency = frequency
        self.dayOfMonth = dayOfMonth
        self.dayOfWeek = dayOfWeek
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.lastGenerated = nil
        self.account = account
        self.createdAt = Date()
    }
}

enum Frequency: String, Codable, CaseIterable {
    case daily = "每天"
    case weekly = "每周"
    case monthly = "每月"
    case yearly = "每年"
    
    var localizedName: String {
        switch self {
        case .daily: return NSLocalizedString("frequency_daily", comment: "")
        case .weekly: return NSLocalizedString("frequency_weekly", comment: "")
        case .monthly: return NSLocalizedString("frequency_monthly", comment: "")
        case .yearly: return NSLocalizedString("frequency_yearly", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "clock"
        case .weekly: return "calendar"
        case .monthly: return "calendar.circle"
        case .yearly: return "calendar.badge.clock"
        }
    }
}
