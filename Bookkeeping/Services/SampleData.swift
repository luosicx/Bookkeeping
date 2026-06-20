import Foundation
import SwiftData

struct SampleData {
    static func insertSampleData(modelContext: ModelContext) {
        // 插入默认账本
        let ledgerDescriptor = FetchDescriptor<Ledger>()
        let ledgerCount = (try? modelContext.fetchCount(ledgerDescriptor)) ?? 0
        
        if ledgerCount == 0 {
            let ledgers: [(String, String, String, Bool)] = [
                ("个人账本", "person", "blue", true),
                ("家庭账本", "house", "green", false),
                ("旅行账本", "airplane", "orange", false)
            ]
            
            for (name, icon, color, isDefault) in ledgers {
                let ledger = Ledger(name: name, icon: icon, color: color, isDefault: isDefault)
                modelContext.insert(ledger)
            }
        }
        
        // 插入默认账户
        let accountDescriptor = FetchDescriptor<Account>()
        let accountCount = (try? modelContext.fetchCount(accountDescriptor)) ?? 0
        
        if accountCount == 0 {
            let accounts: [(String, AccountType, String, Bool)] = [
                ("现金", .cash, "banknote", true),
                ("银行卡", .bank, "building.columns", false),
                ("支付宝", .alipay, "a.circle.fill", false),
                ("微信", .wechat, "w.circle.fill", false)
            ]
            
            for (name, type, icon, isDefault) in accounts {
                let account = Account(name: name, icon: icon, type: type, balance: 0, isDefault: isDefault)
                modelContext.insert(account)
            }
        }
        
        // 插入示例交易记录
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactionCount = (try? modelContext.fetchCount(transactionDescriptor)) ?? 0
        
        guard transactionCount == 0 else {
            try? modelContext.save()
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // 获取默认账户和账本
        let accounts = try? modelContext.fetch(FetchDescriptor<Account>())
        let defaultAccount = accounts?.first { $0.isDefault }
        
        let ledgers = try? modelContext.fetch(FetchDescriptor<Ledger>())
        let defaultLedger = ledgers?.first { $0.isDefault }
        
        let samples: [(Double, TransactionType, String, String, Int)] = [
            (15000, .income, "工资", "6月工资", 0),
            (2000, .income, "奖金", "项目奖金", -2),
            (35.5, .expense, "餐饮", "午餐", 0),
            (128, .expense, "餐饮", "朋友聚餐", -1),
            (6.5, .expense, "交通", "地铁", 0),
            (45, .expense, "交通", "打车", -2),
            (299, .expense, "购物", "买衣服", -3),
            (89, .expense, "购物", "日用品", -5),
            (68, .expense, "娱乐", "电影票", -4),
            (1500, .expense, "住房", "房租", -7),
            (200, .expense, "医疗", "感冒药", -6),
            (5000, .expense, "教育", "在线课程", -10),
            (3000, .income, "投资", "基金收益", -5),
            (56, .expense, "餐饮", "下午茶", -3),
            (15, .expense, "交通", "公交", -1),
        ]
        
        for (amount, type, category, note, dayOffset) in samples {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let transaction = Transaction(amount: amount, type: type, category: category, note: note, date: date, account: defaultAccount, ledger: defaultLedger)
            modelContext.insert(transaction)
            
            // 更新账户余额
            if let account = defaultAccount {
                switch type {
                case .income:
                    account.balance += amount
                case .expense:
                    account.balance -= amount
                }
            }
        }
        
        try? modelContext.save()
    }
}
