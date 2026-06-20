import Foundation
import SwiftData

@Model
class Debt {
    var id: UUID
    var name: String
    var amount: Double
    var type: DebtType
    var note: String
    var date: Date
    var dueDate: Date?
    var isSettled: Bool
    var settledDate: Date?
    var createdAt: Date
    
    init(name: String, amount: Double, type: DebtType, note: String = "", date: Date = Date(), dueDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.type = type
        self.note = note
        self.date = date
        self.dueDate = dueDate
        self.isSettled = false
        self.settledDate = nil
        self.createdAt = Date()
    }
}

enum DebtType: String, Codable, CaseIterable {
    case lend = "借出"
    case borrow = "借入"
    
    var localizedName: String {
        switch self {
        case .lend: return NSLocalizedString("debt_lend", comment: "")
        case .borrow: return NSLocalizedString("debt_borrow", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .lend: return "arrow.up.circle.fill"
        case .borrow: return "arrow.down.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .lend: return "orange"
        case .borrow: return "purple"
        }
    }
}
