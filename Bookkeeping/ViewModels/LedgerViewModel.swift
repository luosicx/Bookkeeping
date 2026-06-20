import Foundation
import SwiftData
import SwiftUI

@Observable
class LedgerViewModel {
    var modelContext: ModelContext?
    var ledgers: [Ledger] = []
    var selectedLedger: Ledger?
    
    func fetchLedgers() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Ledger>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            ledgers = try modelContext.fetch(descriptor)
            if selectedLedger == nil {
                selectedLedger = ledgers.first { $0.isDefault } ?? ledgers.first
            }
        } catch {
            print("Fetch ledgers failed: \(error)")
        }
    }
    
    func addLedger(name: String, icon: String, color: String, isDefault: Bool = false) {
        guard let modelContext = modelContext else { return }
        
        if isDefault {
            for ledger in ledgers where ledger.isDefault {
                ledger.isDefault = false
            }
        }
        
        let ledger = Ledger(name: name, icon: icon, color: color, isDefault: isDefault)
        modelContext.insert(ledger)
        
        saveContext()
        fetchLedgers()
    }
    
    func updateLedger(_ ledger: Ledger, name: String? = nil, icon: String? = nil, color: String? = nil, isDefault: Bool? = nil) {
        if let name = name { ledger.name = name }
        if let icon = icon { ledger.icon = icon }
        if let color = color { ledger.color = color }
        
        if let isDefault = isDefault, isDefault {
            for otherLedger in ledgers where otherLedger.isDefault {
                otherLedger.isDefault = false
            }
            ledger.isDefault = true
        }
        
        saveContext()
        fetchLedgers()
    }
        
    func deleteLedger(_ ledger: Ledger) {
        guard let modelContext = modelContext else { return }
        
        let transactions = ledger.transactions ?? []
        for transaction in transactions {
            transaction.ledger = nil
        }
        
        modelContext.delete(ledger)
        saveContext()
        fetchLedgers()
        
        if selectedLedger?.id == ledger.id {
            selectedLedger = ledgers.first
        }
    }
    
    func selectLedger(_ ledger: Ledger?) {
        selectedLedger = ledger
    }
    
    func getDefaultLedger() -> Ledger? {
        ledgers.first { $0.isDefault } ?? ledgers.first
    }
    
    func getTransactions(for ledger: Ledger?, allTransactions: [Transaction]) -> [Transaction] {
        guard let ledger = ledger else {
            return allTransactions.filter { $0.ledger == nil }
        }
        return allTransactions.filter { $0.ledger?.id == ledger.id }
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
