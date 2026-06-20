import Foundation

struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let type: TransactionType
    
    var localizedName: String {
        NSLocalizedString("category_\(id)", comment: "")
    }
    
    static let expenseCategories: [Category] = [
        Category(id: "food", name: "餐饮", icon: "fork.knife", type: .expense),
        Category(id: "transport", name: "交通", icon: "car.fill", type: .expense),
        Category(id: "shopping", name: "购物", icon: "bag.fill", type: .expense),
        Category(id: "entertainment", name: "娱乐", icon: "gamecontroller.fill", type: .expense),
        Category(id: "housing", name: "住房", icon: "house.fill", type: .expense),
        Category(id: "medical", name: "医疗", icon: "cross.case.fill", type: .expense),
        Category(id: "education", name: "教育", icon: "book.fill", type: .expense),
        Category(id: "other_expense", name: "其他", icon: "ellipsis.circle.fill", type: .expense)
    ]
    
    static let incomeCategories: [Category] = [
        Category(id: "salary", name: "工资", icon: "dollarsign.circle.fill", type: .income),
        Category(id: "bonus", name: "奖金", icon: "gift.fill", type: .income),
        Category(id: "investment", name: "投资", icon: "chart.line.uptrend.xyaxis", type: .income),
        Category(id: "other_income", name: "其他", icon: "plus.circle.fill", type: .income)
    ]
    
    static func categories(for type: TransactionType) -> [Category] {
        switch type {
        case .income:
            return incomeCategories
        case .expense:
            return expenseCategories
        }
    }
}
