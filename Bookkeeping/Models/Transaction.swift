import Foundation
import SwiftData

@Model
class Transaction {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var category: String
    var note: String
    var date: Date
    var createdAt: Date
    var account: Account?
    var ledger: Ledger?
    var tags: [Tag]?
    
    init(amount: Double, type: TransactionType, category: String, note: String = "", date: Date = Date(), account: Account? = nil, ledger: Ledger? = nil, tags: [Tag]? = nil) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.createdAt = Date()
        self.account = account
        self.ledger = ledger
        self.tags = tags
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "收入"
    case expense = "支出"
    
    var localizedName: String {
        switch self {
        case .income:
            return NSLocalizedString("income_type", comment: "")
        case .expense:
            return NSLocalizedString("expense_type", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .income:
            return "green"
        case .expense:
            return "red"
        }
    }
}
