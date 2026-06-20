import SwiftUI
import Charts

struct LedgerStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var ledgerViewModel = LedgerViewModel()
    @State private var selectedDate = Date()
    @State private var selectedLedger: Ledger?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LedgerPicker(ledgerViewModel: ledgerViewModel, selectedLedger: $selectedLedger)
                
                MonthSelector(selectedDate: $selectedDate)
                
                LedgerSummaryCard(
                    viewModel: viewModel,
                    ledger: selectedLedger,
                    date: selectedDate
                )
                
                LedgerCategoryChart(
                    viewModel: viewModel,
                    ledger: selectedLedger,
                    date: selectedDate
                )
                
                LedgerMonthlyTrend(
                    viewModel: viewModel,
                    ledger: selectedLedger
                )
                
                LedgerTopTransactions(
                    viewModel: viewModel,
                    ledger: selectedLedger,
                    date: selectedDate
                )
            }
            .padding()
        }
        .navigationTitle(L.ledgerStats)
        .onAppear {
            viewModel.modelContext = modelContext
            ledgerViewModel.modelContext = modelContext
            viewModel.fetchTransactions()
            ledgerViewModel.fetchLedgers()
        }
    }
}

struct LedgerPicker: View {
    let ledgerViewModel: LedgerViewModel
    @Binding var selectedLedger: Ledger?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LedgerStatChip(
                    name: L.allLedgers,
                    icon: "book",
                    color: "blue",
                    isSelected: selectedLedger == nil
                ) {
                    selectedLedger = nil
                }
                
                ForEach(ledgerViewModel.ledgers) { ledger in
                    LedgerStatChip(
                        name: ledger.name,
                        icon: ledger.icon,
                        color: ledger.color,
                        isSelected: selectedLedger?.id == ledger.id
                    ) {
                        selectedLedger = ledger
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LedgerStatChip: View {
    let name: String
    let icon: String
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(color) : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct LedgerSummaryCard: View {
    let viewModel: TransactionViewModel
    let ledger: Ledger?
    let date: Date
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        return viewModel.transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            (ledger == nil || $0.ledger?.id == ledger?.id)
        }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpense
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(L.totalIncome)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalIncome, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text(L.balance)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(balance, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(balance >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(L.totalExpense)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(totalExpense, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                StatItem(title: L.transactionCount, value: "\(filteredTransactions.count)")
                StatItem(title: L.avgPerMonth, value: String(format: "¥%.0f", totalExpense / 12))
                StatItem(title: L.savingsRate, value: totalIncome > 0 ? "\(Int((balance / totalIncome) * 100))%" : "0%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LedgerCategoryChart: View {
    let viewModel: TransactionViewModel
    let ledger: Ledger?
    let date: Date
    
    private var categoryData: [(String, Double)] {
        let calendar = Calendar.current
        let filteredTransactions = viewModel.transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            (ledger == nil || $0.ledger?.id == ledger?.id) &&
            $0.type == .expense
        }
        
        var data: [String: Double] = [:]
        for transaction in filteredTransactions {
            data[transaction.category, default: 0] += transaction.amount
        }
        
        return data.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.expenseCategory)
                .font(.headline)
            
            if categoryData.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(categoryData, id: \.0) { category, amount in
                    SectorMark(
                        angle: .value(L.amount, amount),
                        innerRadius: 0.6
                    )
                    .foregroundStyle(by: .value(L.category, category))
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LedgerMonthlyTrend: View {
    let viewModel: TransactionViewModel
    let ledger: Ledger?
    
    private var monthlyData: [(String, Double, Double)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        var data: [(String, Double, Double)] = []
        
        for month in 1...12 {
            let monthTransactions = viewModel.transactions.filter {
                calendar.component(.year, from: $0.date) == year &&
                calendar.component(.month, from: $0.date) == month &&
                (ledger == nil || $0.ledger?.id == ledger?.id)
            }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            data.append(("\(month)\(L.monthAbbr)", income, expense))
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.monthlyTrend)
                .font(.headline)
            
            Chart(monthlyData, id: \.0) { month, income, expense in
                LineMark(
                    x: .value(L.month, month),
                    y: .value(L.amount, income)
                )
                .foregroundStyle(.green)
                .symbol(by: .value(L.type, L.income))
                
                LineMark(
                    x: .value(L.month, month),
                    y: .value(L.amount, expense)
                )
                .foregroundStyle(.red)
                .symbol(by: .value(L.type, L.expense))
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LedgerTopTransactions: View {
    let viewModel: TransactionViewModel
    let ledger: Ledger?
    let date: Date
    
    private var topTransactions: [Transaction] {
        let calendar = Calendar.current
        return viewModel.transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
            (ledger == nil || $0.ledger?.id == ledger?.id)
        }
        .sorted { $0.amount > $1.amount }
        .prefix(5)
        .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L.topTransactions)
                .font(.headline)
            
            if topTransactions.isEmpty {
                Text(L.noData)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(topTransactions) { transaction in
                    HStack {
                        Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(transaction.type == .income ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text(transaction.category)
                                .font(.subheadline)
                            if !transaction.note.isEmpty {
                                Text(transaction.note)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(transaction.type == .income ? "+" : "-")¥\(transaction.amount, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(transaction.type == .income ? .green : .red)
                    }
                    .padding(.vertical, 4)
                    
                    if transaction.id != topTransactions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        LedgerStatsView()
    }
    .modelContainer(for: [Transaction.self, Ledger.self])
}
