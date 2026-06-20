import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ShareView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var selectedDate = Date()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        return viewModel.transactions.filter {
            calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
        }
    }
    
    var body: some View {
        List {
            Section {
                MonthSelector(selectedDate: $selectedDate)
            }
            
            Section(header: Text(L.shareOptions)) {
                Button(action: shareAsText) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(L.shareAsText)
                            Text(L.shareTextHint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: shareAsJSON) {
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(L.shareAsJSON)
                            Text(L.shareJSONHint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: shareAsCSV) {
                    HStack {
                        Image(systemName: "tablecells")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text(L.shareAsCSV)
                            Text(L.shareCSVHint)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                    }
                }
                }
            
            Section(header: Text(L.sharePreview)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.sharePreview)
                        .font(.headline)
                    
                    Text("\(filteredTransactions.count) 笔交易")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    let totalIncome = filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let totalExpense = filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(L.income)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(totalIncome, specifier: "%.2f")")
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text(L.expense)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("¥\(totalExpense, specifier: "%.2f")")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(L.shareData)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchTransactions()
        }
    }
    
    private func shareAsText() {
        shareItems = [ShareService.shared.shareAsText(transactions: filteredTransactions)]
        showingShareSheet = true
    }
    
    private func shareAsJSON() {
        if let data = ShareService.shared.shareAsJSON(transactions: filteredTransactions) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("bookkeeping_export.json")
            try? data.write(to: url)
            shareItems = [url]
            showingShareSheet = true
        }
    }
    
    private func shareAsCSV() {
        var csv = "日期,类型,分类,金额,备注\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for transaction in filteredTransactions {
            let date = dateFormatter.string(from: transaction.date)
            let type = transaction.type.rawValue
            let note = transaction.note.replacingOccurrences(of: ",", with: "，")
            csv += "\(date),\(type),\(transaction.category),\(transaction.amount),\(note)\n"
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bookkeeping_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItems = [url]
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ShareView()
    }
    .modelContainer(for: Transaction.self)
}
