import Foundation
import SwiftData

class ImportService {
    static let shared = ImportService()
    
    private init() {}
    
    func importFromCSV(url: URL, modelContext: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: "\n")
        
        guard rows.count > 1 else { return 0 }
        
        var importedCount = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for row in rows.dropFirst() {
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 4 else { continue }
            
            let dateStr = columns[0].trimmingCharacters(in: .whitespaces)
            let typeStr = columns[1].trimmingCharacters(in: .whitespaces)
            let category = columns[2].trimmingCharacters(in: .whitespaces)
            let amountStr = columns[3].trimmingCharacters(in: .whitespaces)
            let note = columns.count > 4 ? columns[4].trimmingCharacters(in: .whitespaces) : ""
            
            guard let date = dateFormatter.date(from: dateStr),
                  let amount = Double(amountStr) else { continue }
            
            let type: TransactionType = typeStr.contains("收入") || typeStr.lowercased() == "income" ? .income : .expense
            
            let transaction = Transaction(
                amount: amount,
                type: type,
                category: category,
                note: note,
                date: date
            )
            modelContext.insert(transaction)
            importedCount += 1
        }
        
        try modelContext.save()
        return importedCount
    }
    
    func importFromJSON(url: URL, modelContext: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        let backup = try JSONDecoder().decode(BackupData.self, from: data)
        
        var importedCount = 0
        
        for item in backup.transactions {
            let transaction = Transaction(
                amount: item.amount,
                type: TransactionType(rawValue: item.type) ?? .expense,
                category: item.category,
                note: item.note,
                date: item.date
            )
            modelContext.insert(transaction)
            importedCount += 1
        }
        
        try modelContext.save()
        return importedCount
    }
    
    func supportedFileTypes() -> [String] {
        return ["csv", "json", "txt"]
    }
}
