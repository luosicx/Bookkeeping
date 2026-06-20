import Foundation
import SwiftData

@Model
class Ledger {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Transaction.ledger)
    var transactions: [Transaction]? = []
    
    init(name: String, icon: String, color: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

enum LedgerType: String, CaseIterable {
    case personal = "个人"
    case family = "家庭"
    case travel = "旅行"
    case work = "工作"
    case other = "其他"
    
    var localizedName: String {
        switch self {
        case .personal: return NSLocalizedString("ledger_personal", comment: "")
        case .family: return NSLocalizedString("ledger_family", comment: "")
        case .travel: return NSLocalizedString("ledger_travel", comment: "")
        case .work: return NSLocalizedString("ledger_work", comment: "")
        case .other: return NSLocalizedString("ledger_other", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "person"
        case .family: return "house"
        case .travel: return "airplane"
        case .work: return "briefcase"
        case .other: return "folder"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "blue"
        case .family: return "green"
        case .travel: return "orange"
        case .work: return "purple"
        case .other: return "gray"
        }
    }
}
