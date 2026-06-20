import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var ledgerViewModel = LedgerViewModel()
    @State private var showingAddView = false
    @State private var searchText = ""
    @State private var selectedType: TransactionType?
    @State private var selectedDate = Date()
    
    var filteredTransactions: [Transaction] {
        var result = ledgerViewModel.getTransactions(for: ledgerViewModel.selectedLedger, allTransactions: viewModel.transactions)
        
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        let calendar = Calendar.current
        result = result.filter {
            calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
        }
        
        return result
    }
    
    var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LedgerSelector(ledgerViewModel: ledgerViewModel)
                    
                    SummaryCard(balance: balance, income: totalIncome, expense: totalExpense, selectedDate: selectedDate)
                    
                    MonthSelector(selectedDate: $selectedDate)
                    
                    FilterBar(selectedType: $selectedType)
                    
                    TransactionListView(
                        transactions: filteredTransactions,
                        viewModel: viewModel
                    )
                }
                .padding()
            }
            .navigationTitle(L.homeTitle)
            .searchable(text: $searchText, prompt: L.search)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddTransactionView(viewModel: viewModel, ledgerViewModel: ledgerViewModel)
            }
            .onAppear {
                viewModel.modelContext = modelContext
                ledgerViewModel.modelContext = modelContext
                viewModel.fetchTransactions()
                ledgerViewModel.fetchLedgers()
            }
        }
    }
}

struct LedgerSelector: View {
    let ledgerViewModel: LedgerViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LedgerChip(
                    name: L.allLedgers,
                    icon: "book",
                    color: "blue",
                    isSelected: ledgerViewModel.selectedLedger == nil
                ) {
                    ledgerViewModel.selectLedger(nil)
                }
                
                ForEach(ledgerViewModel.ledgers) { ledger in
                    LedgerChip(
                        name: ledger.name,
                        icon: ledger.icon,
                        color: ledger.color,
                        isSelected: ledgerViewModel.selectedLedger?.id == ledger.id
                    ) {
                        ledgerViewModel.selectLedger(ledger)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LedgerChip: View {
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

struct MonthSelector: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Spacer()
            
            Text(selectedDate, format: .dateTime.year().month())
                .font(.headline)
            
            Spacer()
            
            Button(action: { changeMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
    
    private func changeMonth(_ offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct FilterBar: View {
    @Binding var selectedType: TransactionType?
    
    var body: some View {
        HStack(spacing: 12) {
            FilterButton(title: L.all, isSelected: selectedType == nil) {
                selectedType = nil
            }
            
            FilterButton(title: L.income, isSelected: selectedType == .income, color: .green) {
                selectedType = .income
            }
            
            FilterButton(title: L.expense, isSelected: selectedType == .expense, color: .red) {
                selectedType = .expense
            }
            
            Spacer()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SummaryCard: View {
    let balance: Double
    let income: Double
    let expense: Double
    let selectedDate: Date
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text(L.monthlyBalance)
                        .font(.body)
                        .foregroundColor(.gray)
                    Text("¥\(balance, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold))
                }
                Spacer()
            }
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text(L.income)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(income, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text(L.expense)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("¥\(expense, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TransactionListView: View {
    let transactions: [Transaction]
    let viewModel: TransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.recentTransactions)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text(L.transactionCount(transactions.count))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if transactions.isEmpty {
                EmptyStateView()
            } else {
                ForEach(transactions) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction, viewModel: viewModel)
                    } label: {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .income ? .green : .red)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.category)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(transaction.type == .income ? "+" : "-")¥\(transaction.amount, specifier: "%.2f")")
                    .font(.body)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                    .fontWeight(.semibold)
                Text(transaction.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text(L.noTransactions)
                .foregroundColor(.gray)
            Text(L.addFirstRecord)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Transaction.self, Ledger.self])
}
