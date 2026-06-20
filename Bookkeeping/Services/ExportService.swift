import Foundation
import SwiftData

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case excel = "Excel"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .excel: return "xls"
        case .json: return "json"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .excel: return "application/vnd.ms-excel"
        case .json: return "application/json"
        }
    }
}

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    func exportData(modelContext: ModelContext, format: ExportFormat) throws -> URL {
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let transactions = try modelContext.fetch(descriptor)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        switch format {
        case .csv:
            return try exportToCSV(transactions: transactions, dateFormatter: dateFormatter)
        case .excel:
            return try exportToExcel(transactions: transactions, dateFormatter: dateFormatter)
        case .json:
            return try exportToJSON(transactions: transactions, dateFormatter: dateFormatter)
        }
    }
    
    private func exportToCSV(transactions: [Transaction], dateFormatter: DateFormatter) throws -> URL {
        var csv = "日期,类型,分类,金额,备注\n"
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.date)
            let type = transaction.type.localizedName
            let category = transaction.category
            let amount = String(format: "%.2f", transaction.amount)
            let note = transaction.note
                .replacingOccurrences(of: "\"", with: "\"\"")
            
            csv += "\"\(date)\",\"\(type)\",\"\(category)\",\(amount),\"\(note)\"\n"
        }
        
        let fileName = "记账数据_\(formattedDate()).csv"
        let url = try saveToFile(data: csv.data(using: .utf8)!, fileName: fileName)
        
        return url
    }
    
    private func exportToExcel(transactions: [Transaction], dateFormatter: DateFormatter) throws -> URL {
        var html = """
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns:o="urn:schemas-microsoft-com:office:office"
              xmlns:x="urn:schemas-microsoft-com:office:excel"
              xmlns="http://www.w3.org/TR/REC-html40">
        <head>
            <meta charset="UTF-8">
            <!--[if gte mso 9]>
            <xml>
                <x:ExcelWorkbook>
                    <x:ExcelWorksheets>
                        <x:ExcelWorksheet>
                            <x:Name>记账数据</x:Name>
                            <x:WorksheetOptions>
                                <x:DisplayGridlines/>
                            </x:WorksheetOptions>
                        </x:ExcelWorksheet>
                    </x:ExcelWorksheets>
                </x:ExcelWorkbook>
            </xml>
            <![endif]-->
            <style>
                table { border-collapse: collapse; width: 100%; }
                th { background-color: #4472C4; color: white; font-weight: bold; padding: 8px; text-align: left; }
                td { padding: 6px 8px; border: 1px solid #D9D9D9; }
                tr:nth-child(even) { background-color: #F2F2F2; }
                .amount { text-align: right; }
                .income { color: #2E7D32; }
                .expense { color: #C62828; }
            </style>
        </head>
        <body>
            <table>
                <tr>
                    <th>日期</th>
                    <th>类型</th>
                    <th>分类</th>
                    <th>金额</th>
                    <th>备注</th>
                </tr>
        """
        
        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.date)
            let type = transaction.type.localizedName
            let category = transaction.category
            let amount = String(format: "%.2f", transaction.amount)
            let note = transaction.note.isEmpty ? "-" : transaction.note
            let amountClass = transaction.type == .income ? "income" : "expense"
            let prefix = transaction.type == .income ? "+" : "-"
            
            html += """
                    <tr>
                        <td>\(date)</td>
                        <td>\(type)</td>
                        <td>\(category)</td>
                        <td class="amount \(amountClass)">\(prefix)\(amount)</td>
                        <td>\(note)</td>
                    </tr>
            """
        }
        
        html += """
            </table>
        </body>
        </html>
        """
        
        let fileName = "记账数据_\(formattedDate()).xls"
        let url = try saveToFile(data: html.data(using: .utf8)!, fileName: fileName)
        
        return url
    }
    
    private func exportToJSON(transactions: [Transaction], dateFormatter: DateFormatter) throws -> URL {
        var jsonArray: [[String: Any]] = []
        
        for transaction in transactions {
            let dict: [String: Any] = [
                "id": transaction.id.uuidString,
                "date": dateFormatter.string(from: transaction.date),
                "type": transaction.type.rawValue,
                "typeLocalized": transaction.type.localizedName,
                "category": transaction.category,
                "amount": transaction.amount,
                "note": transaction.note,
                "createdAt": dateFormatter.string(from: transaction.createdAt)
            ]
            jsonArray.append(dict)
        }
        
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": dateFormatter.string(from: Date()),
            "totalRecords": jsonArray.count,
            "transactions": jsonArray
        ]
        
        let data = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
        
        let fileName = "记账数据_\(formattedDate()).json"
        let url = try saveToFile(data: data, fileName: fileName)
        
        return url
    }
    
    private func saveToFile(data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("Exports")
        
        if !FileManager.default.fileExists(atPath: exportsPath.path) {
            try FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        }
        
        let fileURL = exportsPath.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    private func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return dateFormatter.string(from: Date())
    }
    
    func getExportFiles() -> [URL] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("Exports")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: exportsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            return files.filter { $0.pathExtension == "csv" || $0.pathExtension == "xls" || $0.pathExtension == "json" }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    func deleteExportFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
