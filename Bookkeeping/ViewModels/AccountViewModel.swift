import Foundation
import SwiftData
import SwiftUI

@Observable
class AccountViewModel {
    var modelContext: ModelContext?
    var accounts: [Account] = []
    
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    func fetchAccounts() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.name)])
        do {
            accounts = try modelContext.fetch(descriptor)
            // 将默认账户移到最前面
            accounts.sort { $0.isDefault && !$1.isDefault }
        } catch {
            print("Fetch accounts failed: \(error)")
        }
    }
    
    func addAccount(name: String, type: AccountType, icon: String, balance: Double = 0, isDefault: Bool = false) {
        guard let modelContext = modelContext else { return }
        
        if isDefault {
            for account in accounts where account.isDefault {
                account.isDefault = false
            }
        }
        
        let account = Account(name: name, icon: icon, type: type, balance: balance, isDefault: isDefault)
        modelContext.insert(account)
        
        saveContext()
        fetchAccounts()
    }
    
    func updateAccount(_ account: Account, name: String? = nil, icon: String? = nil, type: AccountType? = nil, balance: Double? = nil, isDefault: Bool? = nil) {
        if let name = name { account.name = name }
        if let icon = icon { account.icon = icon }
        if let type = type { account.type = type }
        if let balance = balance { account.balance = balance }
        
        if let isDefault = isDefault, isDefault {
            for otherAccount in accounts where otherAccount.isDefault {
                otherAccount.isDefault = false
            }
            account.isDefault = true
        }
        
        saveContext()
        fetchAccounts()
    }
    
    func deleteAccount(_ account: Account) {
        guard let modelContext = modelContext else { return }
        
        // 将该账户的交易记录设为无账户
        let transactions = account.transactions ?? []
        for transaction in transactions {
            transaction.account = nil
        }
        
        modelContext.delete(account)
        saveContext()
        fetchAccounts()
    }
    
    func updateBalance(for account: Account, amount: Double, type: TransactionType) {
        switch type {
        case .income:
            account.balance += amount
        case .expense:
            account.balance -= amount
        }
        saveContext()
        fetchAccounts()
    }
    
    func getDefaultAccount() -> Account? {
        accounts.first { $0.isDefault } ?? accounts.first
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
