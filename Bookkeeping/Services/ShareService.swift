import Foundation
import SwiftData

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    func shareAsText(transactions: [Transaction]) -> String {
        var text = "\(L.exportTitle)\n"
        text += "\(L.exportDate): \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))\n\n"
        
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.dateComponents([.year, .month], from: transaction.date)
        }
        
        for (dateComponents, groupTransactions) in grouped.sorted(by: { ($0.key.year ?? 0) > ($1.key.year ?? 0) || ($0.key.month ?? 0) > ($1.key.month ?? 0) }) {
            let year = dateComponents.year ?? 0
            let month = dateComponents.month ?? 0
            text += "═══ \(year)年\(month)月 ═══\n"
            
            let totalIncome = groupTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalExpense = groupTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            text += "\(L.income): \(String(format: "¥%.2f", totalIncome))\n"
            text += "\(L.expense): \(String(format: "¥%.2f", totalExpense))\n"
            text += "\(L.balance): \(String(format: "¥%.2f", totalIncome - totalExpense))\n\n"
            
            for transaction in groupTransactions.sorted(by: { $0.date > $1.date }) {
                let prefix = transaction.type == .income ? "+" : "-"
                let dayStr = "\(Calendar.current.component(.day, from: transaction.date))"
                text += "  \(dayStr) \(transaction.category) \(prefix)\(String(format: "¥%.2f", transaction.amount))"
                if !transaction.note.isEmpty {
                    text += " (\(transaction.note))"
                }
                text += "\n"
            }
            text += "\n"
        }
        
        text += "═══════════\n"
        text += "\(L.sharedFrom) Bookkeeping\n"
        
        return text
    }
    
    func shareAsJSON(transactions: [Transaction]) -> Data? {
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "totalRecords": transactions.count,
            "transactions": transactions.map { transaction in
                [
                    "id": transaction.id.uuidString,
                    "date": ISO8601DateFormatter().string(from: transaction.date),
                    "type": transaction.type.rawValue,
                    "category": transaction.category,
                    "amount": transaction.amount,
                    "note": transaction.note
                ]
            }
        ]
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    func generateShareItems(transactions: [Transaction]) -> [Any] {
        let text = shareAsText(transactions: transactions)
        var items: [Any] = [text]
        
        if let jsonData = shareAsJSON(transactions: transactions) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("bookkeeping_export.json")
            try? jsonData.write(to: tempURL)
            items.append(tempURL)
        }
        
        return items
    }
}
