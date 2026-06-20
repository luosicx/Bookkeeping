import Foundation
import SwiftData

struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let transactions: [BackupTransaction]
}

struct BackupTransaction: Codable {
    let id: UUID
    let amount: Double
    let type: String
    let category: String
    let note: String
    let date: Date
    let createdAt: Date
}

class BackupService {
    static let shared = BackupService()
    
    private init() {}
    
    func exportData(modelContext: ModelContext) throws -> URL {
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let transactions = try modelContext.fetch(descriptor)
        
        let backupTransactions = transactions.map { transaction in
            BackupTransaction(
                id: transaction.id,
                amount: transaction.amount,
                type: transaction.type.rawValue,
                category: transaction.category,
                note: transaction.note,
                date: transaction.date,
                createdAt: transaction.createdAt
            )
        }
        
        let backupData = BackupData(
            version: "1.0",
            exportDate: Date(),
            transactions: backupTransactions
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(backupData)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "Bookkeeping_Backup_\(dateFormatter.string(from: Date())).json"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    func importData(from url: URL, modelContext: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backupData = try decoder.decode(BackupData.self, from: data)
        
        var importedCount = 0
        
        for backupTransaction in backupData.transactions {
            let existingDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { $0.id == backupTransaction.id }
            )
            let existing = try modelContext.fetch(existingDescriptor)
            
            if existing.isEmpty {
                let transaction = Transaction(
                    amount: backupTransaction.amount,
                    type: TransactionType(rawValue: backupTransaction.type) ?? .expense,
                    category: backupTransaction.category,
                    note: backupTransaction.note,
                    date: backupTransaction.date
                )
                transaction.id = backupTransaction.id
                transaction.createdAt = backupTransaction.createdAt
                modelContext.insert(transaction)
                importedCount += 1
            }
        }
        
        try modelContext.save()
        
        return importedCount
    }
    
    func getBackupFiles() -> [URL] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            return files.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("Backup") }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    func deleteBackupFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
