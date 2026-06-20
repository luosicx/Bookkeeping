import Foundation
import SwiftData

@Model
class Account {
    var id: UUID
    var name: String
    var icon: String
    var type: AccountType
    var balance: Double
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]? = []
    
    init(name: String, icon: String, type: AccountType, balance: Double = 0, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.type = type
        self.balance = balance
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

enum AccountType: String, Codable, CaseIterable {
    case cash = "现金"
    case bank = "银行卡"
    case alipay = "支付宝"
    case wechat = "微信"
    case credit = "信用卡"
    case other = "其他"
    
    var localizedName: String {
        switch self {
        case .cash: return NSLocalizedString("account_cash", comment: "")
        case .bank: return NSLocalizedString("account_bank", comment: "")
        case .alipay: return NSLocalizedString("account_alipay", comment: "")
        case .wechat: return NSLocalizedString("account_wechat", comment: "")
        case .credit: return NSLocalizedString("account_credit", comment: "")
        case .other: return NSLocalizedString("account_other", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .bank: return "building.columns"
        case .alipay: return "a.circle.fill"
        case .wechat: return "w.circle.fill"
        case .credit: return "creditcard"
        case .other: return "wallet.bifold"
        }
    }
    
    var defaultName: String {
        switch self {
        case .cash: return "现金"
        case .bank: return "银行卡"
        case .alipay: return "支付宝"
        case .wechat: return "微信"
        case .credit: return "信用卡"
        case .other: return "其他"
        }
    }
    
    static let defaultAccounts: [(AccountType, String, String)] = [
        (.cash, "现金", "banknote"),
        (.bank, "银行卡", "building.columns"),
        (.alipay, "支付宝", "a.circle.fill"),
        (.wechat, "微信", "w.circle.fill")
    ]
}
